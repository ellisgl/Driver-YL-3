`timescale 1ns / 1ps
// SPDX-License-Identifier: MIT
// Copyright 2023 Kenneth McCall
//
// Driver for 8-digit multiplexed 7-segment displays behind two daisy-chained
// 74HC595 shift registers (YL-3 and similar modules).
//
// Continuously scans the 8 digits. Per digit: shift 16 bits MSB-first, then
// pulse RCK. Only one output changes per tick, so an edge on one wire can't
// couple onto another mid-transition and fake a clock. DATA is sampled once
// per full scan so a text change never tears mid-scan.
//
// Module wiring differs between boards, so the word layout is configurable:
//   SEG_FIRST   0 = shift {digit, segments}, 1 = shift {segments, digit}
//   DIGIT_XOR   XORed into the digit index (4 = the two 4-digit halves are swapped)
//   DIGIT_INV   1 = digit select is active low
//   SEG_INV     1 = segments are active high (segment table is active low)
//
// Timing: one tick = BIT_DIV CLK cycles, 3 ticks per bit, 51 ticks per digit.
// At 27 MHz with BIT_DIV = 270 that's a ~33 kHz SCK and a ~245 Hz full refresh.
module seg7x8_595 #(
  parameter integer BIT_DIV   = 270,
  parameter integer SEG_FIRST = 0,
  parameter integer DIGIT_XOR = 0,
  parameter integer DIGIT_INV = 0,
  parameter integer SEG_INV   = 0
)(
  input  wire        CLK,
  input  wire        nRST,
  input  wire [63:0] DATA,      // 8 x ASCII, leftmost character in [63:56]
  output reg         SCK,       // 595 SHCP
  output reg         DIO,       // 595 DS
  output reg         RCK,       // 595 STCP
  output reg         SCAN_DONE  // 1-cycle pulse after digit 7 is latched
);

  localparam [2:0] S_LOAD  = 3'd0,
                   S_LOW   = 3'd1,
                   S_HIGH  = 3'd2,
                   S_FALL  = 3'd3,
                   S_LATCH = 3'd4;

  localparam [2:0] DXOR = DIGIT_XOR;

  reg [2:0]  state;
  reg [63:0] text;
  reg [2:0]  digit;
  reg [15:0] sr;
  reg [3:0]  bitn;
  reg [15:0] div;

  // Active-low segments, bit order .GFEDCBA
  function [7:0] seg_of;
    input [7:0] c;
    begin
      case (c)
        "0", "O":      seg_of = 8'b1100_0000;
        "1":           seg_of = 8'b1111_1001;
        "2":           seg_of = 8'b1010_0100;
        "3":           seg_of = 8'b1011_0000;
        "4":           seg_of = 8'b1001_1001;
        "5", "S", "s": seg_of = 8'b1001_0010;
        "6":           seg_of = 8'b1000_0010;
        "7":           seg_of = 8'b1111_1000;
        "8":           seg_of = 8'b1000_0000;
        "9":           seg_of = 8'b1001_1000;
        "A":           seg_of = 8'b1000_1000;
        "a":           seg_of = 8'b1010_0000;
        "B", "b":      seg_of = 8'b1000_0011;
        "C":           seg_of = 8'b1100_0110;
        "c":           seg_of = 8'b1010_0111;
        "D", "d":      seg_of = 8'b1010_0001;
        "E":           seg_of = 8'b1000_0110;
        "e":           seg_of = 8'b1000_0100;
        "F", "f":      seg_of = 8'b1000_1110;
        "G", "g":      seg_of = 8'b1001_0000;
        "H":           seg_of = 8'b1000_1001;
        "h":           seg_of = 8'b1000_1011;
        "J":           seg_of = 8'b1111_0001;
        "j":           seg_of = 8'b1111_0011;
        "L":           seg_of = 8'b1100_0111;
        "l":           seg_of = 8'b1110_0111;
        "N", "n":      seg_of = 8'b1010_1011;
        "o":           seg_of = 8'b1010_0011;
        "P", "p":      seg_of = 8'b1000_1100;
        "Q":           seg_of = 8'b0100_0000;
        "q":           seg_of = 8'b1001_1000;
        "R":           seg_of = 8'b1100_1110;
        "r":           seg_of = 8'b1010_1111;
        "T", "t":      seg_of = 8'b1000_0111;
        "U":           seg_of = 8'b1100_0001;
        "u":           seg_of = 8'b1110_0011;
        "-":           seg_of = 8'b1011_1111;
        "_":           seg_of = 8'b1111_0111;
        8'hB0:         seg_of = 8'b1001_1100; // degree sign (Latin-1)
        ".":           seg_of = 8'b0111_1111;
        default:       seg_of = 8'b1111_1111; // blank
      endcase
    end
  endfunction

  wire [7:0] sel  = (8'b0000_0001 << (digit ^ DXOR)) ^ {8{DIGIT_INV[0]}};
  wire [7:0] segs = seg_of(text[8*(7-digit) +: 8]) ^ {8{SEG_INV[0]}};

  always @(posedge CLK) begin
    if (!nRST) begin
      state     <= S_LOAD;
      text      <= DATA;
      digit     <= 3'd0;
      sr        <= 16'd0;
      bitn      <= 4'd0;
      div       <= 16'd0;
      SCK       <= 1'b0;
      DIO       <= 1'b0;
      RCK       <= 1'b0;
      SCAN_DONE <= 1'b0;
    end else begin
      SCAN_DONE <= 1'b0;

      if (div != 16'd0) begin
        div <= div - 16'd1;
      end else begin
        div <= BIT_DIV - 1;

        case (state)
          S_LOAD: begin
            sr    <= SEG_FIRST ? {segs, sel} : {sel, segs};
            bitn  <= 4'd0;
            state <= S_LOW;
          end

          S_LOW: begin                    // SCK already low, present data (setup)
            DIO   <= sr[15];
            state <= S_HIGH;
          end

          S_HIGH: begin                   // rising edge clocks DIO into the 595
            SCK   <= 1'b1;
            sr    <= {sr[14:0], 1'b0};
            state <= S_FALL;
          end

          S_FALL: begin                   // SCK low, DIO held
            SCK <= 1'b0;
            if (bitn == 4'd15) begin
              state <= S_LATCH;
            end else begin
              bitn  <= bitn + 4'd1;
              state <= S_LOW;
            end
          end

          S_LATCH: begin
            if (!RCK) begin               // RCK high (SCK already low)
              RCK <= 1'b1;
            end else begin                // RCK low, next digit
              RCK   <= 1'b0;
              digit <= digit + 3'd1;
              if (digit == 3'd7) begin
                text      <= DATA;
                SCAN_DONE <= 1'b1;
              end
              state <= S_LOAD;
            end
          end

          default: state <= S_LOAD;       // Recover from an unused state
        endcase
      end
    end
  end

endmodule
