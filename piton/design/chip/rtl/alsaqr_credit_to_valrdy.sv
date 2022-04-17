`include "network_define.v"

module alsaqr_credit_to_valrdy (
   clk,
   reset,
   //credit based interface   
   data_in,
   valid_in,
   yummy_in,
            
   //val/rdy interface
   data_out,
   valid_out,
   ready_out
);

   input  clk;
   input  reset;
   input [`DATA_WIDTH-1:0]  data_in;
   input  valid_in;
   input  ready_out;
    
   output reg yummy_in;
   output reg valid_out;
   output reg [`DATA_WIDTH-1:0] data_out;
   
reg[1:0] State;


/* states  
0 idle no data to send, and have no data 
1 getting data and sending credit back
2 waiting to send valid/ready data to AXI
*/

reg[3:0] msgCounter;
reg[3:0] outCounter;
reg[15:0][`DATA_WIDTH-1:0] mybuffer;

always @(posedge clk) begin 
   if(~reset) begin
   State   <= 0;
   msgCounter     <= 0;
   yummy_in       <= 0;
   valid_out      <= 0;
   data_out       <= 0;
   outCounter     <= 0;
   end else begin
      case (State)
      2'b00  : 
      begin
         if (valid_in == 1)
         begin
            State <= 1;
            mybuffer[msgCounter]    <= data_in;
            msgCounter              <= msgCounter + 1;
            yummy_in                <= 1;
         end
      end
      2'b01  :
      begin 
         mybuffer[msgCounter]    <= data_in;
         msgCounter              <= msgCounter + 1;
         yummy_in                <= 1;
         if (valid_in == 0) begin
            State       <= 2;
            yummy_in    <= 0;
         end
         else begin
            State   <= 1;
         end
      end
      2'b10  :
      begin 
         if (ready_out == 0)
               State <= 2;
         else begin
            if (msgCounter > 1) begin
               data_out    <= mybuffer[outCounter];
               valid_out   <= 1;
               State       <= 2;
               msgCounter  <= msgCounter - 1;
               outCounter  <= outCounter + 1;
            end
            else begin
               State       <= 0;
               msgCounter  <= 0;
               valid_out   <= 0;
               outCounter  <= 0;
            end
         end
      end
    endcase
   end
end


endmodule



