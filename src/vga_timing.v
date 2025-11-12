// vga_timing.v
// 640x480 @60Hz timing generator. Pixel clock input should be ~25 MHz.
`timescale 1ns/1ps
module vga_timing (
    input  wire clk,      // pixel clock (~25 MHz)
    input  wire rst_n,
    output reg  hsync,
    output reg  vsync,
    output reg  active,   // high during visible area
    output reg [9:0] x,   // 0..639
    output reg [8:0] y,   // 0..479
    output reg  frame_tick // pulse (1 clk) at start of frame (when x=0,y=0)
);

    // standard 640x480 @60 parameters
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_PULSE   = 96;
    localparam H_BACK    = 48;
    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_PULSE   = 2;
    localparam V_BACK    = 33;

    localparam H_TOTAL = H_VISIBLE + H_FRONT + H_PULSE + H_BACK; // 800
    localparam V_TOTAL = V_VISIBLE + V_FRONT + V_PULSE + V_BACK; // 525

    reg [11:0] hcnt;
    reg [11:0] vcnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hcnt <= 0;
            vcnt <= 0;
            hsync <= 1;
            vsync <= 1;
            active <= 0;
            x <= 0;
            y <= 0;
            frame_tick <= 0;
        end else begin
            // increment horizontal
            if (hcnt == H_TOTAL - 1) begin
                hcnt <= 0;
                if (vcnt == V_TOTAL - 1) vcnt <= 0; else vcnt <= vcnt + 1;
            end else begin
                hcnt <= hcnt + 1;
            end

            // generate sync (active low)
            hsync <= !(hcnt >= (H_VISIBLE + H_FRONT) && hcnt < (H_VISIBLE + H_FRONT + H_PULSE));
            vsync <= !(vcnt >= (V_VISIBLE + V_FRONT) && vcnt < (V_VISIBLE + V_FRONT + V_PULSE));

            // visible area?
            if (hcnt < H_VISIBLE && vcnt < V_VISIBLE) begin
                active <= 1;
                x <= hcnt[9:0];
                y <= vcnt[8:0];
            end else begin
                active <= 0;
                x <= 0;
                y <= 0;
            end

            // frame tick when new frame starts: choose pulse when hcnt==0 and vcnt==0
            frame_tick <= (hcnt == 0 && vcnt == 0) ? 1'b1 : 1'b0;
        end
    end
endmodule
