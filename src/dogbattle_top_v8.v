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
    localparam N = 4;  // Simplified to 4 dogs

    // Flattened nets for 4 dogs:
    wire [9:0] posx0, posx1, posx2, posx3;
    wire [8:0] posy0, posy1, posy2, posy3;
    wire signed [9:0] velx0, velx1, velx2, velx3;
    wire signed [9:0] vely0, vely1, vely2, vely3;
    wire [7:0] hits0, hits1, hits2, hits3;
    wire [2:0] col0, col1, col2, col3;
    wire [1:0] pwr0, pwr1, pwr2, pwr3;

    // Instantiate game_core_v8
    // Use reg arrays to interface with game_core_v8
    reg [9:0] posx_arr[0:3];
    reg [8:0] posy_arr[0:3];
    reg signed [9:0] velx_arr[0:3];
    reg signed [9:0] vely_arr[0:3];
    reg [7:0] hits_arr[0:3];
    reg [2:0] color_idx_arr[0:3];
    reg [1:0] power_state_arr[0:3];

    // Instantiate game_core_v8 with packed arrays
    game_core_v8 #(.SCREEN_W(640), .SCREEN_H(480), .BOX_W(BOX_W), .BOX_H(BOX_H), .N(4)) gc (
        .clk(pix_clk),
        .rst_n(rst_n),
        .frame_tick(frame_tick),
        .posx({posx_arr[3], posx_arr[2], posx_arr[1], posx_arr[0]}),
        .posy({posy_arr[3], posy_arr[2], posy_arr[1], posy_arr[0]}),
        .velx({velx_arr[3], velx_arr[2], velx_arr[1], velx_arr[0]}),
        .vely({vely_arr[3], vely_arr[2], vely_arr[1], vely_arr[0]}),
        .hits({hits_arr[3], hits_arr[2], hits_arr[1], hits_arr[0]}),
        .color_idx({color_idx_arr[3], color_idx_arr[2], color_idx_arr[1], color_idx_arr[0]}),
        .power_state({power_state_arr[3], power_state_arr[2], power_state_arr[1], power_state_arr[0]})
    );

    // Wire up the individual signals to array elements
    assign posx0 = posx_arr[0];
    assign posx1 = posx_arr[1];
    assign posx2 = posx_arr[2];
    assign posx3 = posx_arr[3];

    assign posy0 = posy_arr[0];
    assign posy1 = posy_arr[1];
    assign posy2 = posy_arr[2];
    assign posy3 = posy_arr[3];

    assign velx0 = velx_arr[0];
    assign velx1 = velx_arr[1];
    assign velx2 = velx_arr[2];
    assign velx3 = velx_arr[3];

    assign vely0 = vely_arr[0];
    assign vely1 = vely_arr[1];
    assign vely2 = vely_arr[2];
    assign vely3 = vely_arr[3];

    assign hits0 = hits_arr[0];
    assign hits1 = hits_arr[1];
    assign hits2 = hits_arr[2];
    assign hits3 = hits_arr[3];

    assign col0 = color_idx_arr[0];
    assign col1 = color_idx_arr[1];
    assign col2 = color_idx_arr[2];
    assign col3 = color_idx_arr[3];

    assign pwr0 = power_state_arr[0];
    assign pwr1 = power_state_arr[1];
    assign pwr2 = power_state_arr[2];
    assign pwr3 = power_state_arr[3];

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
            end
        end
    end

    assign vga_r = out_r;
    assign vga_g = out_g;
    assign vga_b = out_b;

endmodule
