// game_core_simple.v - Simplified version with 2 dogs for 1x1 tile
// Basic physics: movement, boundary bounce, collision detection
`timescale 1ns/1ps

module game_core_v8 #(
    parameter SCREEN_W = 640,
    parameter SCREEN_H = 480,
    parameter BOX_W = 48,   
    parameter BOX_H = 32,   
    parameter N = 2
)(
    input  wire clk,           
    input  wire rst_n,
    input  wire frame_tick,    
    
    // Only 2 dogs - minimal ports
    output reg [9:0] posx0, posx1, posx2, posx3,
    output reg [8:0] posy0, posy1, posy2, posy3,
    output reg signed [9:0] velx0, velx1, velx2, velx3,
    output reg signed [9:0] vely0, vely1, vely2, vely3,
    output reg [7:0] hits0, hits1, hits2, hits3,
    output reg [2:0] color_idx0, color_idx1, color_idx2, color_idx3,
    output reg [1:0] power_state0, power_state1, power_state2, power_state3
);

    // Collision cooldown
    reg [3:0] cd_timer;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Dog 0
            posx0 <= 10'd100;  posy0 <= 9'd100;
            velx0 <= 10'sd256; vely0 <= 10'sd128;
            hits0 <= 8'd0;     color_idx0 <= 3'd1;
            
            // Dog 1
            posx1 <= 10'd400;  posy1 <= 9'd300;
            velx1 <= -10'sd256; vely1 <= -10'sd128;
            hits1 <= 8'd0;     color_idx1 <= 3'd3;
            
            // Dogs 2-3 unused but must be driven
            posx2 <= 10'd0; posy2 <= 9'd0; velx2 <= 10'sd0; vely2 <= 10'sd0;
            hits2 <= 8'd0; color_idx2 <= 3'd0; power_state2 <= 2'd0;
            posx3 <= 10'd0; posy3 <= 9'd0; velx3 <= 10'sd0; vely3 <= 10'sd0;
            hits3 <= 8'd0; color_idx3 <= 3'd0; power_state3 <= 2'd0;
            
            power_state0 <= 2'd0;
            power_state1 <= 2'd0;
            cd_timer <= 4'd0;
        end else begin
            if (frame_tick) begin
                // Simple friction (use shift instead of division)
                velx0 <= (velx0 * 255) >>> 8;
                vely0 <= (vely0 * 255) >>> 8;
                velx1 <= (velx1 * 255) >>> 8;
                vely1 <= (vely1 * 255) >>> 8;
                
                // Move dog 0
                posx0 <= posx0 + (velx0 >>> 8);
                posy0 <= posy0 + (vely0 >>> 8);
                
                // Boundary bounce dog 0 (shift instead of division)
                if (posx0 <= 0) begin
                    posx0 <= 0;
                    velx0 <= -(velx0 >>> 1);
                end else if (posx0 + BOX_W >= SCREEN_W) begin
                    posx0 <= SCREEN_W - BOX_W;
                    velx0 <= -(velx0 >>> 1);
                end
                
                if (posy0 <= 0) begin
                    posy0 <= 0;
                    vely0 <= -(vely0 >>> 1);
                end else if (posy0 + BOX_H >= SCREEN_H) begin
                    posy0 <= SCREEN_H - BOX_H;
                    vely0 <= -(vely0 >>> 1);
                end
                
                // Move dog 1
                posx1 <= posx1 + (velx1 >>> 8);
                posy1 <= posy1 + (vely1 >>> 8);
                
                // Boundary bounce dog 1 (shift instead of division)
                if (posx1 <= 0) begin
                    posx1 <= 0;
                    velx1 <= -(velx1 >>> 1);
                end else if (posx1 + BOX_W >= SCREEN_W) begin
                    posx1 <= SCREEN_W - BOX_W;
                    velx1 <= -(velx1 >>> 1);
                end
                
                if (posy1 <= 0) begin
                    posy1 <= 0;
                    vely1 <= -(vely1 >>> 1);
                end else if (posy1 + BOX_H >= SCREEN_H) begin
                    posy1 <= SCREEN_H - BOX_H;
                    vely1 <= -(vely1 >>> 1);
                end
                
                // Collision detection
                if (!(posx0 + BOX_W < posx1 || posx0 > posx1 + BOX_W ||
                      posy0 + BOX_H < posy1 || posy0 > posy1 + BOX_H)) begin
                    if (cd_timer == 0) begin
                        velx0 <= -velx0;
                        vely0 <= -vely0;
                        velx1 <= -velx1;
                        vely1 <= -vely1;
                        if (hits0 != 8'hFF) hits0 <= hits0 + 1;
                        if (hits1 != 8'hFF) hits1 <= hits1 + 1;
                        color_idx0 <= color_idx0 + 1;
                        color_idx1 <= color_idx1 + 1;
                        cd_timer <= 4'd5;
                    end
                end
                
                // Decrement timer
                if (cd_timer > 0) cd_timer <= cd_timer - 1;
            end
        end
    end

endmodule
