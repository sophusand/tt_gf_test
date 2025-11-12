/*
 * Copyright (c) 2024 Sophus Andreassen
 * SPDX-License-Identifier: Apache-2.0
 * 
 * Dog Battle Game - 8 dogs with physics simulation on VGA
 */

`default_nettype none

module tt_um_SophusAndreassen_dogbattle (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // 50 MHz clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Instantiate dogbattle_top_v8 (VGA output with 8-dog game engine)
  wire [2:0] vga_r;
  wire [2:0] vga_g;
  wire [1:0] vga_b;
  wire vga_hs;
  wire vga_vs;

  dogbattle_top_v8 game_top (
    .clk50(clk),
    .rst_n(rst_n),
    .vga_hs(vga_hs),
    .vga_vs(vga_vs),
    .vga_r(vga_r),
    .vga_g(vga_g),
    .vga_b(vga_b)
  );

  // Map VGA outputs to TinyTapeout pins (8 outputs available)
  // uo[7:0] = {vga_r[1:0], vga_g[1:0], vga_b[1:0], vga_hs, vga_vs}
  assign uo_out = {vga_r[2:1], vga_g[2:1], vga_b[1:0], vga_hs, vga_vs};
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule
