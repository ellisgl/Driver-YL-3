`timescale 1ns / 1ps
/**
 * YL-3 Driver (http://www.dx.com/p/diy8-x-seven-segment-displays-module-for-arduino-595-driver-250813#.VoG5SPkrKHs)
 * Modules based on diver_74hc595.v from Crazy_Bingo
 * clk    = Clock from FPGA (50 MHz - Mojo V3)
 * rst_n  = reset (inverted)
 * data   = 8x8 (64 bits of the array)
 * load    = load the data
 *
 * ready  = Ready for data to be loaded
 * sclk   = SCK / Serial Data Clock
 * sda    = DIO / Serial Data 
 * slatch = RCK / Serial Latch 
 */ 

module driver_yl3(
  input        clk,    // External Clock (50Mhz in my project)
  input        rst_n,  // Inverted Reset
  input [63:0] data,   // All 8 Characters (8 x 8 bits)
  input        load,   // Load the data in

  output       ready,  // Ready for input to be loaded
  output reg   sda,    // Serial data output
  output reg   sclk,   // Serial data clock
  output reg   slatch  // Serial latch (Display 
);

  localparam  DELAY_CNT    = 4'd5;       // "Clock Divider"
  localparam  ST_READY     = 2'b00;      // Ready to load data
  localparam  ST_READCHR   = 2'b01;      // Read Character
  localparam  ST_SHIFT     = 2'b10;      // Shift Character
  localparam  ST_LATCH     = 2'b11;      // Serial latch
  
  reg  [7:0]  chrarr [0:7];              // 8 Character array
  reg  [3:0]  aidx;                      // Index of our array
  reg  [7:0]  posreg;                    // Position on display
  reg  [7:0]  chrreg;                    // Character in .GFEDBC inverse binary
  reg  [15:0] dataout;                   // Concatinated position and character data to output to YL-3
  reg  [3:0]  delaycnt;                  // Clock divider
  reg  [4:0]  bitcnt;                    // Counter / state-machine for which bit has been shifted
  reg  [2:0]  lchcnt;                    // Counter for holding the latch high.
  reg  [1:0]  state;                     // Our current state
  reg         loaded;                    // Data is loaded

  // Load our data
  always @(posedge clk)
    begin
      if(!rst_n)
        begin
          state      <= ST_READY;
          chrarr[0]   = 0;
          chrarr[1]   = 0;
          chrarr[2]   = 0;
          chrarr[3]   = 0;
          chrarr[4]   = 0;
          chrarr[5]   = 0;
          chrarr[6]   = 0;
          chrarr[7]   = 0;
          aidx       <= 4'b0;
          posreg     <= 8'b0;
          chrreg     <= 8'b0;
          dataout    <= 16'b1111_1111_1111_1111;
          delaycnt   <= 4'b0;
          lchcnt     <= 3'b0;
          bitcnt     <= 5'b0;
          loaded     <= 1'b0;
          sda        <= 1'b0;
          sclk       <= 1'b0;
          slatch     <= 1'b0;
        end
      else
        begin
          if(state != ST_SHIFT)
            begin
              delaycnt   <= 4'b0;
              sclk       <= 1'b0;
            end

          // Deal with the states
          case(state)
            ST_READY:
              begin
                // Read to Load data, so lets do so
                if(load == 1)
                  begin
                    //$display("ST_READY STATE -  LOAD = 1");
                    if({chrarr[0], chrarr[1], chrarr[2], chrarr[3], chrarr[4], chrarr[5], chrarr[6], chrarr[7]} != data)
                      begin
                        //$display("NEEDS TO LOAD DATA");
                        chrarr[0] = data[63:56];
                        chrarr[1] = data[55:48];
                        chrarr[2] = data[47:40];
                        chrarr[3] = data[39:32];
                        chrarr[4] = data[31:24];
                        chrarr[5] = data[23:16];
                        chrarr[6] = data[15:8];
                        chrarr[7] = data[7:0];
                      end
                    else
                      begin
                        //$display("DATA: %h", data);
                        //$display("ARRY: %h", {chrarr[0], chrarr[1], chrarr[2], chrarr[3], chrarr[4], chrarr[5], chrarr[6], chrarr[7]});
                        //$display("DATA LOADED");
                        loaded <= 1'b1;
                        state  <= ST_READCHR;
                      end
                  end
              end

            ST_READCHR:
              begin
                // Read the character from memory, convert it to 16 bit binary for position and 7-Segment leds.
                //$display("DATAOUT: %b", dataout);
                //$display("POSCHR : %b", {posreg, chrreg});
                delaycnt <= 4'b0;

                if({posreg, chrreg} != dataout)
                  begin
                    //$display("DATAOUT NEEDS TO BE CREATED!");
                    case (aidx)
                      0:
                        begin
                          posreg <= 8'b0000_0001;
                        end
                      1:
                        begin
                          posreg <= 8'b0000_0010;
                        end
                      2:
                        begin
                          posreg <= 8'b0000_0100;
                        end
                      3:
                        begin
                          posreg <= 8'b0000_1000;
                        end
                      4:
                        begin
                          posreg <= 8'b0001_0000;
                        end
                      5:
                        begin
                          posreg <= 8'b0010_0000;
                        end
                      6:
                        begin
                          posreg <= 8'b0100_0000;
                        end
                      7:
                        begin
                          posreg <= 8'b1000_0000;
                        end
                      default:
                        begin
                          //posreg <= 8'b0000_0001;
                        end
                    endcase
                    
                    case (chrarr[aidx])
                      "0", "O":
                        begin
                          chrreg <= 8'b1100_0000;
                        end
                      "1":
                        begin
                          chrreg <= 8'b1111_1001;
                        end
                      "2":
                        begin
                          chrreg <= 8'b1010_0100;
                        end
                      "3":
                        begin
                          chrreg <= 8'b1011_0000;
                        end
                      "4":
                        begin
                          chrreg <= 8'b1001_1001;
                        end
                      "5", "S", "s":
                        begin
                          chrreg <= 8'b1001_0010;
                        end
                      "6":
                        begin
                          chrreg <= 8'b1000_0010;
                        end
                      "7":
                        begin
                          chrreg <= 8'b1111_1000;
                        end
                      "8":
                        begin
                          chrreg <= 8'b1000_0000;
                        end
                      "9":
                        begin
                          chrreg <= 8'b1001_1000;
                        end
                      "A":
                        begin
                          chrreg <= 8'b1000_1000;
                        end
                      "a":
                        begin
                          chrreg <= 8'b1010_0000;
                        end
                      "B", "b":
                        begin
                          chrreg <= 8'b1000_0011;
                        end
                      "C":
                        begin
                          chrreg <= 8'b1100_0110;
                        end
                      "c":
                        begin
                          chrreg <= 8'b1010_0111;
                        end
                      "D", "d":
                        begin
                          chrreg <= 8'b1010_0001;
                        end
                      "E":
                        begin
                          chrreg <= 8'b1000_0110;
                        end
                      "e":
                        begin
                          chrreg <= 8'b1000_0100;
                        end
                      "F", "f":
                        begin
                          chrreg <= 8'b1000_1110;
                        end
                      "G", "g":
                        begin
                          chrreg <= 8'b1001_0000;
                        end              
                      "H":
                        begin
                          chrreg <= 8'b1000_1001;
                        end
                      "h":
                        begin
                          chrreg <= 8'b1000_1011;
                        end
                      "J":
                        begin
                          chrreg <= 8'b1111_0001;
                        end
                      "j":
                        begin
                          chrreg <= 8'b1111_0011;
                        end
                      "L":
                        begin
                          chrreg <= 8'b1100_0111;
                        end
                      "l":
                        begin
                          chrreg <= 8'b1110_0111;
                        end
                      "N", "n":
                        begin
                          chrreg <= 8'b1010_1011;
                        end
                      "o":
                        begin
                          chrreg <= 8'b1010_0011;
                        end
                      "P", "p":
                        begin
                          chrreg <= 8'b1000_1100;
                        end
                      "Q":
                        begin
                          chrreg <= 8'b100_0000;
                        end
                      "q":
                        begin
                          chrreg <= 8'b0010_0011;
                        end
                      "R": 
                        begin
                          chrreg <= 8'b1100_1110;
                        end
                      "r":  
                        begin
                          chrreg <= 8'b1010_1111;
                        end
                      "T", "t":
                        begin
                          chrreg <= 8'b1000_0111;
                        end
                      "U":
                        begin
                          chrreg <= 8'b1100_0001;
                        end
                      "u":
                        begin
                          chrreg <= 8'b1110_0011;
                        end
                      "°":
                        begin
                          chrreg <= 8'b1001_1100;
                        end
                      ".":
                        begin
                          chrreg <= 8'b0111_1111;
                        end
                      default:
                        begin
                          chrreg <= 8'b1111_1111;
                        end
                    endcase
                    
                    dataout <= {posreg, chrreg};
                  end
                else
                  begin
                    //$display("DATAOUT GOOD");
                    //$display("DATAOUT: %b", dataout);
                    aidx    <= aidx + 1'b1;
                    state   <= ST_SHIFT;
                  end          
              end

            ST_SHIFT:
              begin
                // Lets shift the data on to the SDA bus.
                
                // Divide clock for serial data clock and serial data out.
                // Deal with states
                // 'Shift Flag'
                if(delaycnt == DELAY_CNT - 1'b1 && !sclk)
                  begin
                    if(bitcnt < 16)
                      begin
                        //$display("ST_SHIFT -> ST_SHIFT");
                        //$display("BITCNT: %d", bitcnt);
                        //$display("DATAOUT[%d]: %b", 15-bitcnt, dataout[15-bitcnt]);
                        sda    <= dataout[8'd15 - bitcnt]; // Output bit to SDA
                        bitcnt <= bitcnt + 1'b1;           // Increment our bit position counter
                        
                        // Send next bit
                        state  <= ST_SHIFT;
                      end
                    else
                      begin
                        //$display("ST_SHIFT -> ST_LATCH");
                        // Reset counters and SDA
                        bitcnt   <= 1'b0;
                        delaycnt <= 1'b0;
                        sda      <= 1'b0;
                        
                        // Latch our data.
                        state    <= ST_LATCH;
                      end
                  end

                  // SCLK - Seral Data Clock (Divided from main clk)
                  if(delaycnt == DELAY_CNT)
                    begin
                      sclk     <= ~sclk;
                    end

              // Increment or reset out clock diver counter
              delaycnt <= (delaycnt < DELAY_CNT) ? delaycnt + 1'b1 : 4'b0;
                
                end

            ST_LATCH:
              begin
                // Set the latch, make the YL-3 display the data
                if(lchcnt < 3)
                  begin
                    // Don't latch for 3 clk's
                    //$display("LCHCNT: %d", lchcnt);
                    lchcnt <= lchcnt + 1'b1;
                    state  <= ST_LATCH;
                    slatch <= 1'b0;
                  end
                else if(lchcnt > 2 && lchcnt < 6)
                  begin
                    // Latch for 3 clk's
                    lchcnt <= lchcnt + 1'b1;
                    state  <= ST_LATCH;
                    slatch <= 1'b1;
                  end
                else
                  begin
                    // No more latching
                    lchcnt <= 1'b0;
                    slatch <= 1'b0;

                    if(aidx < 8)
                      begin
                        // Not done with our array (string), get next character
                        //$display("ST_LATCH -> ST_READCHR");
                        posreg  <= 8'b0;
                        chrreg  <= 8'b0;
                        dataout <= 16'b1;
                        state   <= ST_READCHR;
                      end
                    else
                      begin
                        // We are done with our array (string) and let go back into ready mode.
                        //$display("ST_LATCH -> ST_READY");
                        loaded <= 1'b0;
                        state  <= ST_READY;
                      end
                  end                
              end
          endcase
        end
    end
 
  // Assign the ready state output.
  assign ready  = (state == ST_READY && loaded == 0)  ? 1'b1 : 1'b0;
endmodule
