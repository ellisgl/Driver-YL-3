`timescale 1ns / 1ps
// "HELLO" demo top: bounces "HELLO" across an 8-digit 2x 74HC595 display.
// Defaults are for the Tang Nano 9K (27 MHz); mojo_top.v reuses it for the Mojo V3.
module top #(
    parameter integer FRAME_TICKS = 13_500_000, // CLK cycles per animation frame (0.5 s at 27 MHz)
    parameter integer BIT_DIV     = 270,        // CLK cycles per driver tick (see seg7x8_595.v)
    parameter integer SEG_FIRST   = 1,          // 1 = this module wants {segments, digit}, 0 = {digit, segments}
    parameter integer DIGIT_XOR   = 4           // 4 = this module has its two 4-digit halves swapped
)(
    input  clk,    // 27 MHz
    input  rst_n,  // S1, active low

    output DIO,    // 595 DS
    output RCK,    // 595 STCP
    output SCK     // 595 SHCP
);

  localparam integer NFRAMES = 6;

  // Power-on reset: hold everything in reset for ~2.4 ms after configuration
  reg  [15:0] por_cnt = 16'd0;
  wire        por_done  = &por_cnt;
  wire        sys_rst_n = rst_n & por_done;

  always @(posedge clk)
    if (!por_done)
      por_cnt <= por_cnt + 16'd1;

  // Frame text: leftmost character in [63:56]
  function [63:0] frame_text;
    input [2:0] f;
    begin
      case (f)
        3'd0:    frame_text = "   HELLO";
        3'd1:    frame_text = "  HELLO ";
        3'd2:    frame_text = " HELLO  ";
        3'd3:    frame_text = "HELLO   ";
        3'd4:    frame_text = " HELLO  ";
        default: frame_text = "  HELLO ";
      endcase
    end
  endfunction

  reg [2:0]  frame;
  reg [31:0] tick;

  always @(posedge clk) begin
    if (!sys_rst_n) begin
      frame <= 3'd0;
      tick  <= 32'd0;
    end else if (tick == FRAME_TICKS - 1) begin
      tick  <= 32'd0;
      frame <= (frame == NFRAMES - 1) ? 3'd0 : frame + 3'd1;
    end else begin
      tick  <= tick + 32'd1;
    end
  end

  seg7x8_595 #(
    .BIT_DIV   (BIT_DIV),
    .SEG_FIRST (SEG_FIRST),
    .DIGIT_XOR (DIGIT_XOR)
  ) disp (
    .CLK       (clk),
    .nRST      (sys_rst_n),
    .DATA      (frame_text(frame)),
    .SCK       (SCK),
    .DIO       (DIO),
    .RCK       (RCK),
    .SCAN_DONE ()
  );

endmodule
