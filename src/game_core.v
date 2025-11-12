// game_core.v - Flat signal version for Icarus compatibility
// Maintains 4 moving boxes with collision detection and hit counters
`timescale 1ns/1ps

module game_core #(
    parameter SCREEN_W = 640,
    parameter SCREEN_H = 480,
    parameter BOX_W = 48,
    parameter BOX_H = 32,
    parameter N = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire frame_tick,
    
    // Flat individual ports for 4 dogs
    output reg [9:0] posx0, posx1, posx2, posx3,
    output reg [8:0] posy0, posy1, posy2, posy3,
    output reg signed [7:0] velx0, velx1, velx2, velx3,
    output reg signed [7:0] vely0, vely1, vely2, vely3,
    output reg [7:0] hits0, hits1, hits2, hits3,
    output reg [2:0] color_idx0, color_idx1, color_idx2, color_idx3
);

    reg [15:0] lfsr;
    wire lfsr_bit = lfsr[0] ^ lfsr[2] ^ lfsr[3] ^ lfsr[5];
    
    reg [3:0] cd_timer_01, cd_timer_02, cd_timer_03, cd_timer_12, cd_timer_13, cd_timer_23;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= 16'hACE1;
            
            // Dog 0
            posx0 <= 10'd20;   posy0 <= 9'd20;
            velx0 <= 8'sd2;    vely0 <= -8'sd1;
            hits0 <= 8'd0;     color_idx0 <= 3'd0;
            
            // Dog 1
            posx1 <= 10'd80;   posy1 <= 9'd60;
            velx1 <= -8'sd2;   vely1 <= -8'sd1;
            hits1 <= 8'd0;     color_idx1 <= 3'd1;
            
            // Dog 2
            posx2 <= 10'd140;  posy2 <= 9'd20;
            velx2 <= 8'sd2;    vely2 <= 8'sd1;
            hits2 <= 8'd0;     color_idx2 <= 3'd2;
            
            // Dog 3
            posx3 <= 10'd200;  posy3 <= 9'd60;
            velx3 <= -8'sd2;   vely3 <= 8'sd1;
            hits3 <= 8'd0;     color_idx3 <= 3'd3;
            
            cd_timer_01 <= 4'd0;
            cd_timer_02 <= 4'd0;
            cd_timer_03 <= 4'd0;
            cd_timer_12 <= 4'd0;
            cd_timer_13 <= 4'd0;
            cd_timer_23 <= 4'd0;
        end else begin
            lfsr <= {lfsr[14:0], lfsr_bit};
            
            if (frame_tick) begin
                // Move dog 0
                posx0 <= posx0 + velx0;
                posy0 <= posy0 + vely0;
                if (posx0 <= 0 || posx0 + BOX_W >= SCREEN_W) velx0 <= -velx0;
                if (posy0 <= 0 || posy0 + BOX_H >= SCREEN_H) vely0 <= -vely0;
                
                // Move dog 1
                posx1 <= posx1 + velx1;
                posy1 <= posy1 + vely1;
                if (posx1 <= 0 || posx1 + BOX_W >= SCREEN_W) velx1 <= -velx1;
                if (posy1 <= 0 || posy1 + BOX_H >= SCREEN_H) vely1 <= -vely1;
                
                // Move dog 2
                posx2 <= posx2 + velx2;
                posy2 <= posy2 + vely2;
                if (posx2 <= 0 || posx2 + BOX_W >= SCREEN_W) velx2 <= -velx2;
                if (posy2 <= 0 || posy2 + BOX_H >= SCREEN_H) vely2 <= -vely2;
                
                // Move dog 3
                posx3 <= posx3 + velx3;
                posy3 <= posy3 + vely3;
                if (posx3 <= 0 || posx3 + BOX_W >= SCREEN_W) velx3 <= -velx3;
                if (posy3 <= 0 || posy3 + BOX_H >= SCREEN_H) vely3 <= -vely3;
                
                // Collision 0-1
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
                
                // Collision 0-2
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
                
                // Collision 0-3
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
                
                // Collision 1-2
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
                
                // Collision 1-3
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
                
                // Collision 2-3
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
                
                // Decrement timers
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
