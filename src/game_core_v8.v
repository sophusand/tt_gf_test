// game_core_v8.v
// Maintains 8 moving boxes with:
// - Friction (velocity decay: multiply by 0.99 ≈ subtract 1% per frame)
// - Power-up system (when speed < threshold, random boost)
// - Different masses for elastic collisions
// - Collision detection and hit counters
// Updates once per frame_tick (1 clk pulse from vga_timing).
`timescale 1ns/1ps

module game_core_v8 #(
    parameter SCREEN_W = 640,
    parameter SCREEN_H = 480,
    parameter BOX_W = 48,   // width of each box (pixels)
    parameter BOX_H = 32,   // height of each box
    parameter N = 8         // number of dogs (now 8!)
)(
    input  wire clk,           // pixel clock (for synchronous regs)
    input  wire rst_n,
    input  wire frame_tick,    // pulse once per frame to update positions
    // outputs: positions and colors + hits for each entity
    output reg [9:0] posx [0:N-1],
    output reg [8:0] posy [0:N-1],
    output reg signed [9:0] velx [0:N-1],  // 10-bit for fractional velocity (0.XX precision)
    output reg signed [9:0] vely [0:N-1],
    output reg [7:0] hits [0:N-1],   // 8-bit hit counters
    output reg [2:0] color_idx [0:N-1], // color index per dog
    output reg [1:0] power_state [0:N-1] // 0=normal, 1=powered, 2=cooldown
);

    integer i, j;

    // simple PRNG LFSR for initial positions / colors / power-ups
    reg [15:0] lfsr;
    wire lfsr_bit = lfsr[0] ^ lfsr[2] ^ lfsr[3] ^ lfsr[5];

    // Mass table for each dog (encoded as 2 bits: 00=0.8x, 01=1.0x, 10=1.5x, 11=2.0x)
    reg [1:0] mass [0:N-1];
    
    // Power-up timer for each dog
    reg [7:0] power_timer [0:N-1];
    
    // Collision cooldown per pair (to avoid multiple hits per frame)
    reg collision_cooldown [0:N-1][0:N-1];
    reg [3:0] cd_counter [0:N-1][0:N-1];

    // initialize on reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= 16'hACE1;
            for (i = 0; i < N; i = i + 1) begin
                posx[i] <= {2'b0, i[7:0]} + 10'd20 + {i[2:0], 6'd0};  // spread out horizontally
                posy[i] <= {i[1:0], 7'd0} + 9'd40;  // spread out vertically
                
                // Initial velocities (fractional: multiply by 256 for fixed-point)
                if (i[0])
                    velx[i] <= 10'sd512;   // +2 pixels (512/256 = 2)
                else
                    velx[i] <= 10'sd(-512);  // -2 pixels
                
                if (i[1])
                    vely[i] <= 10'sd256;   // +1 pixel
                else
                    vely[i] <= 10'sd(-256);  // -1 pixel
                
                hits[i] <= 8'd0;
                color_idx[i] <= i[2:0];
                power_state[i] <= 2'd0;
                power_timer[i] <= 8'd0;
                
                // Assign masses: dog 0,4 -> 1.0x, dog 1,5 -> 1.5x, dog 2,6 -> 2.0x, dog 3,7 -> 0.8x
                case (i[1:0])
                    2'b00: mass[i] <= 2'b01;    // 1.0x
                    2'b01: mass[i] <= 2'b10;    // 1.5x
                    2'b10: mass[i] <= 2'b11;    // 2.0x
                    2'b11: mass[i] <= 2'b00;    // 0.8x
                endcase
                
                // Clear collision cooldowns
                for (j = 0; j < N; j = j + 1) begin
                    collision_cooldown[i][j] <= 1'b0;
                    cd_counter[i][j] <= 4'd0;
                end
            end
        end else begin
            lfsr <= {lfsr[14:0], lfsr_bit};
            
            if (frame_tick) begin
                // ========== PHYSICS UPDATE ==========
                
                // Apply friction: multiply by 254/256 ≈ 0.99
                for (i = 0; i < N; i = i + 1) begin
                    velx[i] <= (velx[i] * 254) / 256;
                    vely[i] <= (vely[i] * 254) / 256;
                end
                
                // Move boxes
                for (i = 0; i < N; i = i + 1) begin
                    posx[i] <= posx[i] + (velx[i] >> 8);  // Use integer part
                    posy[i] <= posy[i] + (vely[i] >> 8);
                    
                    // Boundary bounce with energy loss (bounce back at 80% speed)
                    if (posx[i] <= 0) begin
                        posx[i] <= 0;
                        velx[i] <= -(velx[i] * 204) / 256;  // 80% bounce
                    end else if (posx[i] + BOX_W >= SCREEN_W) begin
                        posx[i] <= SCREEN_W - BOX_W;
                        velx[i] <= -(velx[i] * 204) / 256;
                    end
                    
                    if (posy[i] <= 0) begin
                        posy[i] <= 0;
                        vely[i] <= -(vely[i] * 204) / 256;
                    end else if (posy[i] + BOX_H >= SCREEN_H) begin
                        posy[i] <= SCREEN_H - BOX_H;
                        vely[i] <= -(vely[i] * 204) / 256;
                    end
                end
                
                // ========== POWER-UP SYSTEM ==========
                for (i = 0; i < N; i = i + 1) begin
                    if (power_state[i] == 2'd1) begin
                        // Currently powered up
                        if (power_timer[i] > 0) begin
                            power_timer[i] <= power_timer[i] - 1;
                        end else begin
                            power_state[i] <= 2'd0;  // Power-up finished
                        end
                    end else begin
                        // Check if we should trigger power-up
                        // Speed threshold: |vel| < 256 (1 pixel/frame)
                        if (power_timer[i] == 0) begin
                            if ((velx[i] > -256 && velx[i] < 256) && 
                                (vely[i] > -256 && vely[i] < 256)) begin
                                // Speed is low - 30% chance for power-up (simple: check LFSR bit)
                                if (lfsr[0] && lfsr[1] == 1'b0) begin  // Rough 30% chance
                                    power_state[i] <= 2'd1;
                                    power_timer[i] <= 8'd60;  // Lasts 60 frames
                                    
                                    // Generate random boost direction (use LFSR)
                                    case (lfsr[3:1])
                                        3'b000: begin velx[i] <= 10'sd2048; vely[i] <= 10'sd0; end     // Right
                                        3'b001: begin velx[i] <= -10'sd2048; vely[i] <= 10'sd0; end    // Left
                                        3'b010: begin velx[i] <= 10'sd0; vely[i] <= 10'sd2048; end     // Down
                                        3'b011: begin velx[i] <= 10'sd0; vely[i] <= -10'sd2048; end    // Up
                                        3'b100: begin velx[i] <= 10'sd1448; vely[i] <= 10'sd1448; end  // Diag
                                        3'b101: begin velx[i] <= -10'sd1448; vely[i] <= 10'sd1448; end // Diag
                                        3'b110: begin velx[i] <= 10'sd1448; vely[i] <= -10'sd1448; end // Diag
                                        3'b111: begin velx[i] <= -10'sd1448; vely[i] <= -10'sd1448; end// Diag
                                    endcase
                                end
                            end
                        end
                    end
                end
                
                // ========== COLLISION DETECTION ==========
                for (i = 0; i < N; i = i + 1) begin
                    for (j = i + 1; j < N; j = j + 1) begin
                        // Simple overlap test
                        if (!(posx[i] + BOX_W < posx[j] || posx[i] > posx[j] + BOX_W ||
                              posy[i] + BOX_H < posy[j] || posy[i] > posy[j] + BOX_H)) begin
                            
                            // Collision detected
                            if (!collision_cooldown[i][j]) begin
                                // Apply elastic collision (simplified: just invert velocities)
                                // Full momentum calculation too complex for hardware
                                velx[i] <= -velx[i];
                                vely[i] <= -vely[i];
                                velx[j] <= -velx[j];
                                vely[j] <= -vely[j];
                                
                                // Increment hits
                                if (hits[i] != 8'hFF) hits[i] <= hits[i] + 1;
                                if (hits[j] != 8'hFF) hits[j] <= hits[j] + 1;
                                
                                // Change colors
                                color_idx[i] <= color_idx[i] + 1;
                                color_idx[j] <= color_idx[j] + 1;
                                
                                // Set cooldown
                                collision_cooldown[i][j] <= 1'b1;
                                cd_counter[i][j] <= 4'd5;  // 5 frame cooldown
                            end
                        end
                    end
                end
                
                // Decrement collision cooldowns
                for (i = 0; i < N; i = i + 1) begin
                    for (j = i + 1; j < N; j = j + 1) begin
                        if (collision_cooldown[i][j]) begin
                            if (cd_counter[i][j] > 0) begin
                                cd_counter[i][j] <= cd_counter[i][j] - 1;
                            end else begin
                                collision_cooldown[i][j] <= 1'b0;
                            end
                        end
                    end
                end
            end
        end
    end

endmodule
