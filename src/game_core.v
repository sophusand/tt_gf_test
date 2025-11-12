// game_core.v
// Maintains 4 moving boxes, velocities, collision detection and hit counters.
// Updates once per frame_tick (1 clk pulse from vga_timing).
`timescale 1ns/1ps
module game_core #(
    parameter SCREEN_W = 640,
    parameter SCREEN_H = 480,
    parameter BOX_W = 48,   // width of each box (pixels)
    parameter BOX_H = 32,   // height of each box
    parameter N = 4         // number of dogs
)(
    input  wire clk,           // pixel clock (for synchronous regs)
    input  wire rst_n,
    input  wire frame_tick,    // pulse once per frame to update positions
    // outputs: positions and colors + hits for each entity
    output reg [9:0] posx [0:N-1],
    output reg [8:0] posy [0:N-1],
    output reg signed [7:0] velx [0:N-1],
    output reg signed [7:0] vely [0:N-1],
    output reg [7:0] hits [0:N-1],   // 8-bit hit counters
    output reg [2:0] color_idx [0:N-1] // small color index per box
);

    integer i,j;

    // simple PRNG LFSR for initial positions / colors
    reg [15:0] lfsr;
    wire lfsr_bit = lfsr[0] ^ lfsr[2] ^ lfsr[3] ^ lfsr[5];

    // initialize on reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= 16'hACE1;
            for (i=0;i<N;i=i+1) begin
                posx[i] <= 10'd(20 + i*60);
                posy[i] <= 9'd(20 + i*40);
                velx[i] <= (i[0] ? 8'sd2 : -8'sd2);
                vely[i] <= (i[1] ? 8'sd1 : -8'sd1);
                hits[i] <= 8'd0;
                color_idx[i] <= i[0 +:3];
            end
        end else begin
            lfsr <= {lfsr[14:0], lfsr_bit};
            if (frame_tick) begin
                // Move boxes and bounce on screen edges
                for (i=0; i<N; i=i+1) begin
                    // update pos
                    posx[i] <= posx[i] + velx[i];
                    posy[i] <= posy[i] + vely[i];

                    // boundary bounce X
                    if (posx[i] <= 0) begin
                        posx[i] <= 0;
                        velx[i] <= -velx[i];
                    end else if (posx[i] + BOX_W >= SCREEN_W) begin
                        posx[i] <= SCREEN_W - BOX_W;
                        velx[i] <= -velx[i];
                    end

                    // boundary bounce Y
                    if (posy[i] <= 0) begin
                        posy[i] <= 0;
                        vely[i] <= -vely[i];
                    end else if (posy[i] + BOX_H >= SCREEN_H) begin
                        posy[i] <= SCREEN_H - BOX_H;
                        vely[i] <= -vely[i];
                    end
                end

                // Collision detection (pairwise). When newly colliding, invert velocities and increment hits.
                // Use simple overlap test; to avoid multiple counting a simple cooldown per pair could be added.
                // Here we increment on every frame while overlapping (simple).
                for (i=0; i<N; i=i+1) begin
                    for (j=i+1; j<N; j=j+1) begin
                        // overlap test
                        if (!(posx[i] + BOX_W < posx[j] || posx[i] > posx[j] + BOX_W ||
                              posy[i] + BOX_H < posy[j] || posy[i] > posy[j] + BOX_H)) begin
                            // invert velocities
                            velx[i] <= -velx[i];
                            vely[i] <= -vely[i];
                            velx[j] <= -velx[j];
                            vely[j] <= -vely[j];

                            // increment hits (saturate at 255)
                            if (hits[i] != 8'hFF) hits[i] <= hits[i] + 1;
                            if (hits[j] != 8'hFF) hits[j] <= hits[j] + 1;

                            // optionally change color index
                            color_idx[i] <= color_idx[i] + 1;
                            color_idx[j] <= color_idx[j] + 1;
                        end
                    end
                end
            end
        end
    end
endmodule
