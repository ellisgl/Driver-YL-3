`timescale 1ns / 1ps
// Mojo V3 top: same "HELLO" demo as top.v, retimed for the 50 MHz clock.
// Pins are in mojo.ucf.
module mojo_top #(
    parameter integer SEG_FIRST = 1,  // 1 = module wants {segments, digit}, 0 = {digit, segments} (original YL-3)
    parameter integer DIGIT_XOR = 4   // 4 = module has its two 4-digit halves swapped, 0 = original YL-3
)(
    input  clk,    // 50 MHz
    input  rst_n,  // Reset button, active low

    output DIO,    // 595 DS
    output RCK,    // 595 STCP
    output SCK     // 595 SHCP
);

  top #(
    .FRAME_TICKS (25_000_000),  // 0.5 s per animation frame
    .BIT_DIV     (500),         // 10 us per driver tick, same as 270 at 27 MHz
    .SEG_FIRST   (SEG_FIRST),
    .DIGIT_XOR   (DIGIT_XOR)
  ) demo (
    .clk   (clk),
    .rst_n (rst_n),
    .DIO   (DIO),
    .RCK   (RCK),
    .SCK   (SCK)
  );

endmodule
