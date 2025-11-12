// top.v
// Top-level: divides 50MHz -> 25MHz, instantiates vga_timing and game_core,
// generates pixel RGB outputs (3-bit R, 3-bit G, 2-bit B).
`timescale 1ns/1ps
module top (
    input  wire clk50,    // external 50 MHz clock
    input  wire rst_n,
    output wire vga_hs,
    output wire vga_vs,
    output wire [2:0] vga_r,
    output wire [2:0] vga_g,
    output wire [1:0] vga_b
);

    // divide-by-2 to get ~25MHz pixel clock
    reg pix_clk;
    always @(posedge clk50 or negedge rst_n) begin
        if (!rst_n) pix_clk <= 0;
        else pix_clk <= ~pix_clk;
    end

    // VGA timing
    wire active;
    wire [9:0] px;
    wire [8:0] py;
    wire frame_tick;
    vga_timing vt (
        .clk(pix_clk),
        .rst_n(rst_n),
        .hsync(vga_hs),
        .vsync(vga_vs),
        .active(active),
        .x(px),
        .y(py),
        .frame_tick(frame_tick)
    );

    // game core parameters
    localparam BOX_W = 48;
    localparam BOX_H = 32;
    localparam N = 4;

    // instantiate game_core
    wire [9:0] gx [0:N-1];
    wire [8:0] gy [0:N-1];
    wire signed [7:0] gvx [0:N-1];
    wire signed [7:0] gvy [0:N-1];
    wire [7:0] ghits [0:N-1];
    wire [2:0] gcolor [0:N-1];

    // connect arrays using regs in game_core outputs — instantiate as module with unpacked outputs
    // For synth-friendly connection, instantiate and wire via intermediate regs handled by module ports.
    // We'll instantiate game_core and connect to internal nets by using generate/unpacked style via top-level signals.

    // Declarations for game_core outputs (regs inside module will drive these via port connection)
    genvar gi;
    // We need to build port list manually since Verilog-2001 doesn't support unpacked port arrays easily.
    // For simplicity we instantiate and then assign outputs from module to wires using localparams.
    // Here we'll create flattened nets and rely on tool to wire correctly via named connections.

    // Flattened nets:
    wire [9:0] posx0; wire [9:0] posx1; wire [9:0] posx2; wire [9:0] posx3;
    wire [8:0] posy0; wire [8:0] posy1; wire [8:0] posy2; wire [8:0] posy3;
    wire signed [7:0] velx0; wire signed [7:0] velx1; wire signed [7:0] velx2; wire signed [7:0] velx3;
    wire signed [7:0] vely0; wire signed [7:0] vely1; wire signed [7:0] vely2; wire signed [7:0] vely3;
    wire [7:0] hits0; wire [7:0] hits1; wire [7:0] hits2; wire [7:0] hits3;
    wire [2:0] col0; wire [2:0] col1; wire [2:0] col2; wire [2:0] col3;

    // Instantiate game_core with explicit parameter N=4; map each output
    game_core #(.SCREEN_W(640), .SCREEN_H(480), .BOX_W(BOX_W), .BOX_H(BOX_H), .N(4)) gc (
        .clk(pix_clk),
        .rst_n(rst_n),
        .frame_tick(frame_tick),

        // manual mapping to flattened ports (module uses unpacked arrays; some synthesis tools accept)
        // to keep compatibility, assume game_core compiled in same toolchain supports array ports.
        // If tool complains, modify game_core to use explicit indexed ports.
        .posx({posx3, posx2, posx1, posx0}),
        .posy({posy3, posy2, posy1, posy0}),
        .velx({velx3, velx2, velx1, velx0}),
        .vely({vely3, vely2, vely1, vely0}),
        .hits({hits3, hits2, hits1, hits0}),
        .color_idx({col3, col2, col1, col0})
    );

    // Pixel generation: draw background gradient and boxes + hit bars
    reg [2:0] out_r;
    reg [2:0] out_g;
    reg [1:0] out_b;

    // Helper function: check if pixel inside box i
    function inside_box;
        input [9:0] pxi;
        input [8:0] pyi;
        input [9:0] bx;
        input [8:0] by;
        begin
            inside_box = (pxi >= bx) && (pxi < bx + BOX_W) && (pyi >= by) && (pyi < by + BOX_H);
        end
    endfunction

    // Map hits to small bar height (0..BOX_H)
    function [5:0] hits_to_height;
        input [7:0] h;
        begin
            // max displayed height = BOX_H (clamp at 255 -> full)
            if (h > 8'd255) h = 8'd255;
            // scale 0..255 -> 0..BOX_H
            hits_to_height = (h * BOX_H) / 255;
        end
    endfunction

    always @(posedge pix_clk or negedge rst_n) begin
        if (!rst_n) begin
            out_r <= 3'b000;
            out_g <= 3'b000;
            out_b <= 2'b00;
        end else begin
            if (!active) begin
                // blanking period -> outputs 0
                out_r <= 3'b000; out_g <= 3'b000; out_b <= 2'b00;
            end else begin
                // simple background gradient
                out_r <= px[9:7];      // 3 bits from X
                out_g <= py[8:6];      // 3 bits from Y
                out_b <= {px[6]^py[6], px[5]^py[5]};

                // draw boxes (priority: box 3 highest)
                if (inside_box(px, py, posx0, posy0)) begin
                    // color mapping from col0
                    out_r <= {col0[2], col0[2], col0[1]}; // crude mapping
                    out_g <= {col0[1], col0[1], col0[0]};
                    out_b <= {col0[0], col0[1]};
                end
                if (inside_box(px, py, posx1, posy1)) begin
                    out_r <= {col1[2], col1[2], col1[1]};
                    out_g <= {col1[1], col1[1], col1[0]};
                    out_b <= {col1[0], col1[1]};
                end
                if (inside_box(px, py, posx2, posy2)) begin
                    out_r <= {col2[2], col2[2], col2[1]};
                    out_g <= {col2[1], col2[1], col2[0]};
                    out_b <= {col2[0], col2[1]};
                end
                if (inside_box(px, py, posx3, posy3)) begin
                    out_r <= {col3[2], col3[2], col3[1]};
                    out_g <= {col3[1], col3[1], col3[0]};
                    out_b <= {col3[0], col3[1]};
                end

                // draw hit bars above each box: vertical bar (width = 6 px)
                // For box0
                if ((px >= posx0) && (px < posx0 + 6)) begin
                    if (py >= posy0 - hits_to_height(hits0) && py < posy0) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
                // box1
                if ((px >= posx1) && (px < posx1 + 6)) begin
                    if (py >= posy1 - hits_to_height(hits1) && py < posy1) begin
                        out_r <= 3'b000; out_g <= 3'b111; out_b <= 2'b00;
                    end
                end
                // box2
                if ((px >= posx2) && (px < posx2 + 6)) begin
                    if (py >= posy2 - hits_to_height(hits2) && py < posy2) begin
                        out_r <= 3'b000; out_g <= 3'b000; out_b <= 2'b11;
                    end
                end
                // box3
                if ((px >= posx3) && (px < posx3 + 6)) begin
                    if (py >= posy3 - hits_to_height(hits3) && py < posy3) begin
                        out_r <= 3'b111; out_g <= 3'b111; out_b <= 2'b11;
                    end
                end
            end
        end
    end

    assign vga_r = out_r;
    assign vga_g = out_g;
    assign vga_b = out_b;

endmodule
