// dogbattle_top_v8.v
// Top-level for 8-dog battle with VGA output
// Divides 50MHz -> 25MHz for VGA timing
`timescale 1ns/1ps

module dogbattle_top_v8 (
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
    localparam N = 8;  // 8 dogs now!

    // Flattened nets for 8 dogs:
    wire [9:0] posx0, posx1, posx2, posx3, posx4, posx5, posx6, posx7;
    wire [8:0] posy0, posy1, posy2, posy3, posy4, posy5, posy6, posy7;
    wire signed [9:0] velx0, velx1, velx2, velx3, velx4, velx5, velx6, velx7;
    wire signed [9:0] vely0, vely1, vely2, vely3, vely4, vely5, vely6, vely7;
    wire [7:0] hits0, hits1, hits2, hits3, hits4, hits5, hits6, hits7;
    wire [2:0] col0, col1, col2, col3, col4, col5, col6, col7;
    wire [1:0] pwr0, pwr1, pwr2, pwr3, pwr4, pwr5, pwr6, pwr7;

    // Instantiate game_core_v8
    game_core_v8 #(.SCREEN_W(640), .SCREEN_H(480), .BOX_W(BOX_W), .BOX_H(BOX_H), .N(8)) gc (
        .clk(pix_clk),
        .rst_n(rst_n),
        .frame_tick(frame_tick),
        .posx({posx7, posx6, posx5, posx4, posx3, posx2, posx1, posx0}),
        .posy({posy7, posy6, posy5, posy4, posy3, posy2, posy1, posy0}),
        .velx({velx7, velx6, velx5, velx4, velx3, velx2, velx1, velx0}),
        .vely({vely7, vely6, vely5, vely4, vely3, vely2, vely1, vely0}),
        .hits({hits7, hits6, hits5, hits4, hits3, hits2, hits1, hits0}),
        .color_idx({col7, col6, col5, col4, col3, col2, col1, col0}),
        .power_state({pwr7, pwr6, pwr5, pwr4, pwr3, pwr2, pwr1, pwr0})
    );

    // Pixel generation
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

    // Map hits to bar height
    function [5:0] hits_to_height;
        input [7:0] h;
        begin
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
                out_r <= 3'b000; 
                out_g <= 3'b000; 
                out_b <= 2'b00;
            end else begin
                // Background gradient
                out_r <= px[9:7];
                out_g <= py[8:6];
                out_b <= {px[6]^py[6], px[5]^py[5]};

                // Draw all 8 boxes with priority
                if (inside_box(px, py, posx0, posy0)) begin
                    out_r <= {col0[2], col0[2], col0[1]};
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
                if (inside_box(px, py, posx4, posy4)) begin
                    out_r <= {col4[2], col4[2], col4[1]};
                    out_g <= {col4[1], col4[1], col4[0]};
                    out_b <= {col4[0], col4[1]};
                end
                if (inside_box(px, py, posx5, posy5)) begin
                    out_r <= {col5[2], col5[2], col5[1]};
                    out_g <= {col5[1], col5[1], col5[0]};
                    out_b <= {col5[0], col5[1]};
                end
                if (inside_box(px, py, posx6, posy6)) begin
                    out_r <= {col6[2], col6[2], col6[1]};
                    out_g <= {col6[1], col6[1], col6[0]};
                    out_b <= {col6[0], col6[1]};
                end
                if (inside_box(px, py, posx7, posy7)) begin
                    out_r <= {col7[2], col7[2], col7[1]};
                    out_g <= {col7[1], col7[1], col7[0]};
                    out_b <= {col7[0], col7[1]};
                end

                // Draw hit bars above each dog (red bars)
                if ((px >= posx0) && (px < posx0 + 6)) begin
                    if (py >= posy0 - hits_to_height(hits0) && py < posy0) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
                if ((px >= posx1) && (px < posx1 + 6)) begin
                    if (py >= posy1 - hits_to_height(hits1) && py < posy1) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
                if ((px >= posx2) && (px < posx2 + 6)) begin
                    if (py >= posy2 - hits_to_height(hits2) && py < posy2) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
                if ((px >= posx3) && (px < posx3 + 6)) begin
                    if (py >= posy3 - hits_to_height(hits3) && py < posy3) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
                if ((px >= posx4) && (px < posx4 + 6)) begin
                    if (py >= posy4 - hits_to_height(hits4) && py < posy4) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
                if ((px >= posx5) && (px < posx5 + 6)) begin
                    if (py >= posy5 - hits_to_height(hits5) && py < posy5) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
                if ((px >= posx6) && (px < posx6 + 6)) begin
                    if (py >= posy6 - hits_to_height(hits6) && py < posy6) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
                if ((px >= posx7) && (px < posx7 + 6)) begin
                    if (py >= posy7 - hits_to_height(hits7) && py < posy7) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
            end
        end
    end

    assign vga_r = out_r;
    assign vga_g = out_g;
    assign vga_b = out_b;

endmodule
