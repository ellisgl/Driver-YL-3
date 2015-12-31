module mojo_top(
    // 50MHz clock input
    input clk,
    // Input from reset button (active low)
    input rst_n,
    // cclk input from AVR, high when AVR is ready
    input cclk,

    // AVR SPI connections
    output spi_miso,
    input spi_ss,
    input spi_mosi,
    input spi_sck,
    // AVR ADC channel select
    output [3:0] spi_channel,
    // Serial connections
    input avr_tx, // AVR Tx => FPGA Rx
    output avr_rx, // AVR Rx => FPGA Tx
    input avr_rx_busy, // AVR Rx buffer full
    
    output DIO, // Data of YL-3
    output RCK, // Latch of YL-3
    output SCK,  // Clock of Yl-3
    output [7:0] led
    );

  reg  [7:0]  ledreg    = 8'b0;
  assign led            = ledreg;

  reg         eno       = 1'b1;
  reg  [63:0] data;
  reg         load;
  reg  [2:0]  aidx      = 3'b0;
  reg  [16:0] nxtcnt    = 17'b0;
  
  wire [7:0]  str [0:5][0:7];
  wire rst              = ~rst_n; // make reset active high
  wire ready;
  
  localparam  nxt       = 17'd124999;
  
  assign str[0][0] = " ";
  assign str[0][1] = " ";
  assign str[0][2] = " ";
  assign str[0][3] = "H";
  assign str[0][4] = "E";
  assign str[0][5] = "L";
  assign str[0][6] = "L";
  assign str[0][7] = "O";
  

  assign str[1][0] = " ";
  assign str[1][1] = " ";
  assign str[1][2] = "H";
  assign str[1][3] = "E";
  assign str[1][4] = "L";
  assign str[1][5] = "L";
  assign str[1][6] = "O";
  assign str[1][7] = " ";

  assign str[2][0] = " ";
  assign str[2][1] = "H";
  assign str[2][2] = "E";
  assign str[2][3] = "L";
  assign str[2][4] = "L";
  assign str[2][5] = "O";
  assign str[2][6] = " ";
  assign str[2][7] = " ";

  assign str[3][0] = "H";
  assign str[3][1] = "E";
  assign str[3][2] = "L";
  assign str[3][3] = "L";
  assign str[3][4] = "O";
  assign str[3][5] = " ";
  assign str[3][6] = " ";
  assign str[3][7] = " ";

  assign str[4][0] = " ";
  assign str[4][1] = "H";
  assign str[4][2] = "E";
  assign str[4][3] = "L";
  assign str[4][4] = "L";
  assign str[4][5] = "O";
  assign str[4][6] = " ";
  assign str[4][7] = " ";
  
  assign str[5][0] = " ";
  assign str[5][1] = " ";
  assign str[5][2] = "H";
  assign str[5][3] = "E";
  assign str[5][4] = "L";
  assign str[5][5] = "L";
  assign str[5][6] = "O";
  assign str[5][7] = " ";

  // these signals should be high-z when not used
  assign spi_miso    = 1'bz;
  assign avr_rx      = 1'bz;
  assign spi_channel = 4'bzzzz;

  driver_yl3 yl3_display(
    .clk(clk),
    .rst_n(rst_n),
    .data(data),
    .load(load),
    .sclk(SCK),
    .sda(DIO),
    .slatch(RCK),
    .ready(ready)
  );

  always @(posedge clk)
    begin
      if(ready == 1'b1)
        begin
         aidx <= (aidx == 3'd6) ? 3'd0 : aidx;

          if(nxtcnt == 20'b0)
            begin
              case(aidx)
                0: 
                  begin
                    ledreg <= 8'b0000_0001;
                  end
                1: 
                  begin
                    ledreg <= 8'b0000_0010;
                  end
                2: 
                  begin
                    ledreg <= 8'b0000_0100;
                  end
                3: 
                  begin
                    ledreg <= 8'b0000_1000;
                  end
                4: 
                  begin
                    ledreg <= 8'b0001_0000;
                  end
                5: 
                  begin
                    ledreg <= 8'b0010_0000;
                  end
                6: 
                  begin
                    ledreg <= 8'b0100_0000;
                  end
                7: 
                  begin
                    ledreg <= 8'b1000_0000;
                  end                  
              endcase

              data   <= {str[aidx][0], str[aidx][1], str[aidx][2], str[aidx][3], str[aidx][4], str[aidx][5], str[aidx][6], str[aidx][7]};
              aidx   <= aidx + 1'b1;
              load   <= 1'b1;
            end

          nxtcnt <= (nxtcnt < nxt) ? nxtcnt + 1'b1 : nxtcnt <= 17'b0;
        end
      else
        begin
        end
    end
endmodule
