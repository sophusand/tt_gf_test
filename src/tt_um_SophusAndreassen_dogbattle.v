// tt_um_SophusAndreassen_dogbattle.v
// Tiny Tapeout wrapper for Dog Battle VGA game
`timescale 1ns/1ps

module tt_um_SophusAndreassen_dogbattle (
    input  wire [7:0] ui_in,    // User inputs
    output wire [7:0] uo_out,   // User outputs
    input  wire [7:0] uio_in,   // Bidirectional (unused)
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,      // Always 1 when enabled
    input  wire       clk,      // 50 MHz clock
    input  wire       rst_n     // Active-low reset
);
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // VGA signals
    wire vga_hs, vga_vs;
    wire [2:0] vga_r;
    wire [2:0] vga_g;
    wire [1:0] vga_b;

    // Instantiate main Dog Battle design
    dogbattle_top game_inst (
        .clk50(clk),
        .rst_n(rst_n),
        .vga_hs(vga_hs),
        .vga_vs(vga_vs),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

    // Map to Tiny Tapeout outputs
    assign uo_out = {vga_b, vga_g, vga_r[1:0], vga_hs};

endmodule
