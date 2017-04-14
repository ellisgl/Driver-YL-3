`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Dual 74HC595 interface (16 bit) for the YL-3
// Original Engineer: Jon Carrier (https://gist.github.com/jjcarrier/1692155)
// Re-written: EllisGL
//
// Dependencies:   CLK=50MHz. Slower clocks should also work. If a faster CLK is 
//            used, the parameters below may need adjusting
//
////////////////////////////////////////////////////////////////////////////////
/**
 * Control Signals
 * CLK     <=50 Mhz cloc
 * DATA_IN 16 bit data input - Position (MSB = Right to Left posision so 1000_0000 is the most right element),Character (inverted GFEDCBA 1 = off 0 = on)
 * EN_IN   Data is valid, output data
 * RDY     Ready to accept data input
 *
 * Output pins
 * RCLK    = RCK
 * SRCLK   = SCK
 * SER_OUT = DIO
 */
module YL3_Shift_Register(
  input        CLK,
  input [15:0] DATA_IN,
  input        EN_IN,
  output       RDY,
  output       RCLK,
  output       SRCLK,
  output       SER_OUT
);

  // Registers and initial settings
  reg [16:0] shift = 0;
  reg RCLK         = 0; 
  reg SRCLK        = 0; 
  reg RDY          = 1;
  
  
  //==============================================================================
  //--------------------------------PARAMETERS------------------------------------
  //==============================================================================
  //If we assume CLK=50MHz, then T=20nS
  //If VCC=5V, SRCLK at worst case is capable of 5MHz and at best 29MHz
  //Lets assume SRCLK=10MHz, T_SCLK=100nS
  //See page 7 of the SN74HC595 datasheet for the parameters below
  
  //------------------------------NUMBER OF BITS----------------------------------
  parameter N = 3; //This parameter is used on several registers/parameters below
  
  //---------------------PULSE DURATION PARAMETER (PAGE7)-------------------------
  //This parameter is used to specify in how many clock cycles of CLK must 
  //occur prior to setting or unsetting SRCLK/RCLK HI or LO
  parameter [N-1:0] pulse_duration = 6;  //safety time > 100ns, >=6 CLK cycles
  
  //---------------------SETUP TIME PARAMETER (PAGE7)-----------------------------
  //This parameter is used to control how much time is required to setup the 
  //SER_OUT signal prior to setting SRCLK HI.
  //Note there is no required hold duration, once the signal is written to SER, 
  //and SRCLK has gone HI, the next signal can be immediately setup
  parameter [N-1:0] setup_time = 7;    //Safety time > 125ns, >=7 CLK cycles
  
  //==============================================================================
  //----------------------------ASSIGN THE SER_OUT--------------------------------
  //==============================================================================
  //The SER_OUT port can be thought of as a wire to the MSB of an 16-bit shift reg
  wire   SER_OUT;
  assign SER_OUT = shift[16]; //shift data out using MSBF
  
  //==============================================================================
  //--------------------------CREATE THE SRCLK SIGNAL-----------------------------
  
  //==============================================================================
  //Create the SRCLK signal that will be used to clock-in the serial data
  reg [N-1:0] clk_cnt      = 0;
  reg [1:0]   SRCLK_state  = 0;
  reg         SRCLK_toggle = 0; //Instructs the process to toggle SRCLK for a period of time
  
  always @(posedge CLK)
    begin
      case(SRCLK_state)
        0:
         begin //Wait for SRCLK_toggle=1
            if(SRCLK_toggle == 1)
              begin
                SRCLK_state <= SRCLK_state + 1;
                SRCLK       <= 0; //Make sure SRCLK is low
                clk_cnt     <= 0;
              end
            end
        1:
          begin //Wait for the defined setup time, prior to setting SRCLK HI
            if(clk_cnt == setup_time - 1)
              begin
                SRCLK       <= 1;
                clk_cnt     <= 0;
                SRCLK_state <= SRCLK_state + 1;
              end
            else
              begin
                clk_cnt <= clk_cnt + 1;
              end
          end
        2:
          begin //Wait for the defined pulse duration, prior to setting SRCLK LO
            if(clk_cnt == pulse_duration - 1)
              begin
              SRCLK       <= 0;
              clk_cnt     <= 0;
              SRCLK_state <= SRCLK_state + 1;
            end
          else
            begin
              clk_cnt <= clk_cnt + 1;
            end    
          end
        3:
          begin //Wait for SRCLK_toggle=0
            if(SRCLK_toggle == 0)
              begin
                SRCLK_state<=0;
              end
          end  
      endcase
    end
  
  //==============================================================================
  //--------------------------CREATE THE RCLK SIGNAL------------------------------
  //==============================================================================
  //Create the RCLK signal that will be used to clock-out the parallel data
  reg [N-1:0] clk_cnt2    = 0;
  reg [1:0]   RCLK_state  = 0;
  reg         RCLK_toggle = 0; //Instructs the process to toggle RCLK for a period of time
  
  always @(posedge CLK)
    begin
      case(RCLK_state)
        0:
          begin //Wait for RCLK_toggle=1
            if(RCLK_toggle == 1)
              begin
                RCLK_state <= RCLK_state + 1;
                RCLK       <= 0; //Make sure RCLK is low
                clk_cnt2   <= 0;
              end
          end
        1:
          begin //Wait for the defined setup time, prior to setting RCLK HI
            if(clk_cnt2 == setup_time - 1)
              begin
                RCLK       <= 1;
                clk_cnt2   <= 0;
                RCLK_state <= RCLK_state + 1;
              end
            else
              begin
                clk_cnt2 <= clk_cnt2 + 1;
              end
          end
      2:
        begin //Wait for the defined pulse duration, prior to setting SRCLK LO
          if(clk_cnt2 == pulse_duration - 1)
            begin
              RCLK       <= 0;
              clk_cnt2   <= 0;
              RCLK_state <= RCLK_state + 1;
            end 
          else
            begin
              clk_cnt2 <= clk_cnt2 + 1;
             end    
        end
      3:
        begin //Wait for RCLK_toggle=0
          if(RCLK_toggle==0)
            begin
             RCLK_state <= 0;
            end
        end  
      endcase
    end
  
  //==============================================================================
  //-------------------CREATE THE FUNCTIONAL SWITCHING LOGIC----------------------
  //==============================================================================
  reg [1:0] state     = 0; //Statemachine variable
  reg [1:0] substate  = 0;
  reg [3:0] cnt       = 0;
  reg       init_done = 0; 

  always @(posedge CLK)
    begin
      case(state)
        0:
          begin //-----------------------------Populate the FPGA's shift register
            if(EN_IN==1)
              begin //Only start the statemachine when input is enabled
                shift[15:0]  <= DATA_IN;
                cnt          <= 0;
                state        <= state + 1;
                RDY          <= 0;
                SRCLK_toggle <= 0;
                RCLK_toggle  <= 0;
                substate     <= 0;
              end
            else
              begin
                RDY          <= 1;
                cnt          <= 0;
                SRCLK_toggle <= 0;
                RCLK_toggle  <= 0;
                state        <= 0;
                substate     <= 0;
              end
          end
        1:
          begin //-----------------------------------------Push the bits out MSBF
            case(substate)
              0:
                begin //PUSH DATA ON SER    
                  shift[16:1] <= shift[15:0];
                  shift[0]    <= 0;  
                  substate    <= substate + 1;
                end
              1:
                begin //PULSE SRCLK  
                  SRCLK_toggle <= 1;
                  substate     <= substate + 1;
                end
              2:
                begin //TURN OFF THE TOGGLE BIT
                  if(SRCLK == 1)
                    begin
                      SRCLK_toggle <= 0;
                      substate     <= substate + 1;
                    end
                end
              3:
                begin //WHEN SRCLK GOES LOW, CHECK & UPDATE cnt
                  if(SRCLK == 0)
                    begin
                      if(cnt == 15)
                        begin
                          //All bits have been shifted
                          state <= state + 1;
                          cnt   <= 0;
                        end
                      else
                        begin
                          //We have more bits to shift
                          cnt <= cnt + 1;
                        end

                      substate <= 0;
                    end
                end
            endcase
          end
        2:
          begin //--------------------------Update & Activate the parallel output
            //First Pulse RCLK
            //Then indicate init_done
            case(substate)        
              0:
                begin //PULSE RCLK
                  RCLK_toggle <= 1;
                  substate    <= substate + 1;
                end
              1:
                begin //TURN OFF THE TOGGLE BIT
                  if(RCLK == 1)
                    begin
                      RCLK_toggle <= 0;
                      substate    <= substate + 1;
                    end
                end
              2:
                begin //WHEN RCLK GOES LOW, CHECK & UPDATE cnt
                  if(RCLK == 0)
                    begin
                      state     <= 0;
                      substate  <= 0;
                      init_done <= 1;
                      RDY       <= 1;
                    end
                end
            endcase
          end
        default:
          begin
            state     <= 0;
            substate  <= 0;
            init_done <= 0;
            RDY       <= 1;
          end
      endcase
    end
endmodule