// game_core_v8_flat.v
// Flat signal version for Icarus Verilog compatibility
// Maintains 4 moving boxes with friction, collisions, and hit tracking
`timescale 1ns/1ps

module game_core_v8 #(
    parameter SCREEN_W = 640,
    parameter SCREEN_H = 480,
    parameter BOX_W = 48,   
    parameter BOX_H = 32,   
    parameter N = 4         // 4 dogs
)(
    input  wire clk,           
    input  wire rst_n,
    input  wire frame_tick,    
    
    // Flat individual ports instead of arrays
    output reg [9:0] posx0, posx1, posx2, posx3,
    output reg [8:0] posy0, posy1, posy2, posy3,
    output reg signed [9:0] velx0, velx1, velx2, velx3,
    output reg signed [9:0] vely0, vely1, vely2, vely3,
    output reg [7:0] hits0, hits1, hits2, hits3,
    output reg [2:0] color_idx0, color_idx1, color_idx2, color_idx3,
    output reg [1:0] power_state0, power_state1, power_state2, power_state3
);

    // Simple PRNG LFSR
    reg [15:0] lfsr;
    wire lfsr_bit = lfsr[0] ^ lfsr[2] ^ lfsr[3] ^ lfsr[5];
    
    // Mass table for each dog
    reg [1:0] mass0, mass1, mass2, mass3;
    reg [7:0] power_timer0, power_timer1, power_timer2, power_timer3;
    
    // Collision cooldown timers
    reg [3:0] cd_timer_01, cd_timer_02, cd_timer_03, cd_timer_12, cd_timer_13, cd_timer_23;

    // Helper macro for updating position, velocity, and applying physics
    // For a given dog index, update position with friction, boundary conditions
    
    // Initialize on reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= 16'hACE1;
            
            // Dog 0: horizontal position 20, vertical 40
            posx0 <= 10'd20;   posy0 <= 9'd40;
            velx0 <= 10'sd512; vely0 <= -10'sd256;  // Right, up
            hits0 <= 8'd0;     color_idx0 <= 3'd0;    power_state0 <= 2'd0;
            power_timer0 <= 8'd0;  mass0 <= 2'b01;    // 1.0x
            
            // Dog 1: horizontal position 90, vertical 104
            posx1 <= 10'd90;   posy1 <= 9'd104;
            velx1 <= -10'sd512; vely1 <= -10'sd256;  // Left, up
            hits1 <= 8'd0;     color_idx1 <= 3'd1;    power_state1 <= 2'd0;
            power_timer1 <= 8'd0;  mass1 <= 2'b10;    // 1.5x
            
            // Dog 2: horizontal position 160, vertical 40
            posx2 <= 10'd160;  posy2 <= 9'd40;
            velx2 <= 10'sd512; vely2 <= 10'sd256;     // Right, down
            hits2 <= 8'd0;     color_idx2 <= 3'd2;    power_state2 <= 2'd0;
            power_timer2 <= 8'd0;  mass2 <= 2'b11;    // 2.0x
            
            // Dog 3: horizontal position 230, vertical 104
            posx3 <= 10'd230;  posy3 <= 9'd104;
            velx3 <= -10'sd512; vely3 <= 10'sd256;    // Left, down
            hits3 <= 8'd0;     color_idx3 <= 3'd3;    power_state3 <= 2'd0;
            power_timer3 <= 8'd0;  mass3 <= 2'b00;    // 0.8x
            
            // Clear collision timers
            cd_timer_01 <= 4'd0;
            cd_timer_02 <= 4'd0;
            cd_timer_03 <= 4'd0;
            cd_timer_12 <= 4'd0;
            cd_timer_13 <= 4'd0;
            cd_timer_23 <= 4'd0;
        end else begin
            lfsr <= {lfsr[14:0], lfsr_bit};
            
            if (frame_tick) begin
                // ========== PHYSICS UPDATE ==========
                
                // Apply friction to velocities (multiply by 254/256)
                velx0 <= (velx0 * 254) / 256;
                vely0 <= (vely0 * 254) / 256;
                velx1 <= (velx1 * 254) / 256;
                vely1 <= (vely1 * 254) / 256;
                velx2 <= (velx2 * 254) / 256;
                vely2 <= (vely2 * 254) / 256;
                velx3 <= (velx3 * 254) / 256;
                vely3 <= (vely3 * 254) / 256;
                
                // ========== DOG 0 MOVEMENT ==========
                posx0 <= posx0 + (velx0 >> 8);
                posy0 <= posy0 + (vely0 >> 8);
                
                if (posx0 <= 0) begin
                    posx0 <= 0;
                    velx0 <= -(velx0 * 204) / 256;
                end else if (posx0 + BOX_W >= SCREEN_W) begin
                    posx0 <= SCREEN_W - BOX_W;
                    velx0 <= -(velx0 * 204) / 256;
                end
                
                if (posy0 <= 0) begin
                    posy0 <= 0;
                    vely0 <= -(vely0 * 204) / 256;
                end else if (posy0 + BOX_H >= SCREEN_H) begin
                    posy0 <= SCREEN_H - BOX_H;
                    vely0 <= -(vely0 * 204) / 256;
                end
                
                // ========== DOG 1 MOVEMENT ==========
                posx1 <= posx1 + (velx1 >> 8);
                posy1 <= posy1 + (vely1 >> 8);
                
                if (posx1 <= 0) begin
                    posx1 <= 0;
                    velx1 <= -(velx1 * 204) / 256;
                end else if (posx1 + BOX_W >= SCREEN_W) begin
                    posx1 <= SCREEN_W - BOX_W;
                    velx1 <= -(velx1 * 204) / 256;
                end
                
                if (posy1 <= 0) begin
                    posy1 <= 0;
                    vely1 <= -(vely1 * 204) / 256;
                end else if (posy1 + BOX_H >= SCREEN_H) begin
                    posy1 <= SCREEN_H - BOX_H;
                    vely1 <= -(vely1 * 204) / 256;
                end
                
                // ========== DOG 2 MOVEMENT ==========
                posx2 <= posx2 + (velx2 >> 8);
                posy2 <= posy2 + (vely2 >> 8);
                
                if (posx2 <= 0) begin
                    posx2 <= 0;
                    velx2 <= -(velx2 * 204) / 256;
                end else if (posx2 + BOX_W >= SCREEN_W) begin
                    posx2 <= SCREEN_W - BOX_W;
                    velx2 <= -(velx2 * 204) / 256;
                end
                
                if (posy2 <= 0) begin
                    posy2 <= 0;
                    vely2 <= -(vely2 * 204) / 256;
                end else if (posy2 + BOX_H >= SCREEN_H) begin
                    posy2 <= SCREEN_H - BOX_H;
                    vely2 <= -(vely2 * 204) / 256;
                end
                
                // ========== DOG 3 MOVEMENT ==========
                posx3 <= posx3 + (velx3 >> 8);
                posy3 <= posy3 + (vely3 >> 8);
                
                if (posx3 <= 0) begin
                    posx3 <= 0;
                    velx3 <= -(velx3 * 204) / 256;
                end else if (posx3 + BOX_W >= SCREEN_W) begin
                    posx3 <= SCREEN_W - BOX_W;
                    velx3 <= -(velx3 * 204) / 256;
                end
                
                if (posy3 <= 0) begin
                    posy3 <= 0;
                    vely3 <= -(vely3 * 204) / 256;
                end else if (posy3 + BOX_H >= SCREEN_H) begin
                    posy3 <= SCREEN_H - BOX_H;
                    vely3 <= -(vely3 * 204) / 256;
                end
                
                // ========== COLLISION DETECTION ==========
                // Check collision between dog 0 and 1
                if (!(posx0 + BOX_W < posx1 || posx0 > posx1 + BOX_W ||
                      posy0 + BOX_H < posy1 || posy0 > posy1 + BOX_H)) begin
                    if (cd_timer_01 == 0) begin
                        velx0 <= -velx0; vely0 <= -vely0;
                        velx1 <= -velx1; vely1 <= -vely1;
                        if (hits0 != 8'hFF) hits0 <= hits0 + 1;
                        if (hits1 != 8'hFF) hits1 <= hits1 + 1;
                        color_idx0 <= color_idx0 + 1;
                        color_idx1 <= color_idx1 + 1;
                        cd_timer_01 <= 4'd5;
                    end
                end
                
                // Check collision between dog 0 and 2
                if (!(posx0 + BOX_W < posx2 || posx0 > posx2 + BOX_W ||
                      posy0 + BOX_H < posy2 || posy0 > posy2 + BOX_H)) begin
                    if (cd_timer_02 == 0) begin
                        velx0 <= -velx0; vely0 <= -vely0;
                        velx2 <= -velx2; vely2 <= -vely2;
                        if (hits0 != 8'hFF) hits0 <= hits0 + 1;
                        if (hits2 != 8'hFF) hits2 <= hits2 + 1;
                        color_idx0 <= color_idx0 + 1;
                        color_idx2 <= color_idx2 + 1;
                        cd_timer_02 <= 4'd5;
                    end
                end
                
                // Check collision between dog 0 and 3
                if (!(posx0 + BOX_W < posx3 || posx0 > posx3 + BOX_W ||
                      posy0 + BOX_H < posy3 || posy0 > posy3 + BOX_H)) begin
                    if (cd_timer_03 == 0) begin
                        velx0 <= -velx0; vely0 <= -vely0;
                        velx3 <= -velx3; vely3 <= -vely3;
                        if (hits0 != 8'hFF) hits0 <= hits0 + 1;
                        if (hits3 != 8'hFF) hits3 <= hits3 + 1;
                        color_idx0 <= color_idx0 + 1;
                        color_idx3 <= color_idx3 + 1;
                        cd_timer_03 <= 4'd5;
                    end
                end
                
                // Check collision between dog 1 and 2
                if (!(posx1 + BOX_W < posx2 || posx1 > posx2 + BOX_W ||
                      posy1 + BOX_H < posy2 || posy1 > posy2 + BOX_H)) begin
                    if (cd_timer_12 == 0) begin
                        velx1 <= -velx1; vely1 <= -vely1;
                        velx2 <= -velx2; vely2 <= -vely2;
                        if (hits1 != 8'hFF) hits1 <= hits1 + 1;
                        if (hits2 != 8'hFF) hits2 <= hits2 + 1;
                        color_idx1 <= color_idx1 + 1;
                        color_idx2 <= color_idx2 + 1;
                        cd_timer_12 <= 4'd5;
                    end
                end
                
                // Check collision between dog 1 and 3
                if (!(posx1 + BOX_W < posx3 || posx1 > posx3 + BOX_W ||
                      posy1 + BOX_H < posy3 || posy1 > posy3 + BOX_H)) begin
                    if (cd_timer_13 == 0) begin
                        velx1 <= -velx1; vely1 <= -vely1;
                        velx3 <= -velx3; vely3 <= -vely3;
                        if (hits1 != 8'hFF) hits1 <= hits1 + 1;
                        if (hits3 != 8'hFF) hits3 <= hits3 + 1;
                        color_idx1 <= color_idx1 + 1;
                        color_idx3 <= color_idx3 + 1;
                        cd_timer_13 <= 4'd5;
                    end
                end
                
                // Check collision between dog 2 and 3
                if (!(posx2 + BOX_W < posx3 || posx2 > posx3 + BOX_W ||
                      posy2 + BOX_H < posy3 || posy2 > posy3 + BOX_H)) begin
                    if (cd_timer_23 == 0) begin
                        velx2 <= -velx2; vely2 <= -vely2;
                        velx3 <= -velx3; vely3 <= -vely3;
                        if (hits2 != 8'hFF) hits2 <= hits2 + 1;
                        if (hits3 != 8'hFF) hits3 <= hits3 + 1;
                        color_idx2 <= color_idx2 + 1;
                        color_idx3 <= color_idx3 + 1;
                        cd_timer_23 <= 4'd5;
                    end
                end
                
                // Decrement collision cooldown timers
                if (cd_timer_01 > 0) cd_timer_01 <= cd_timer_01 - 1;
                if (cd_timer_02 > 0) cd_timer_02 <= cd_timer_02 - 1;
                if (cd_timer_03 > 0) cd_timer_03 <= cd_timer_03 - 1;
                if (cd_timer_12 > 0) cd_timer_12 <= cd_timer_12 - 1;
                if (cd_timer_13 > 0) cd_timer_13 <= cd_timer_13 - 1;
                if (cd_timer_23 > 0) cd_timer_23 <= cd_timer_23 - 1;
            end
        end
    end

endmodule
