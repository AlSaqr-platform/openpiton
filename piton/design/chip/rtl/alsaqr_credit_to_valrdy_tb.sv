module alsaqr_credit_to_valrdy_tb;

reg  clk;
reg  reset;
reg [`DATA_WIDTH-1:0]  data_in;
reg  valid_in;
reg     ready_out;
    
wire    yummy_in;
wire    valid_out;
wire [`DATA_WIDTH-1:0] data_out;


always
begin
clk = 0;
#10;
clk = 1;
#10;
end

initial
begin 
reset = 0;
data_in = 0;
valid_in = 0;
ready_out = 1;

#10000

reset = 1;
#10
repeat(1)@(posedge clk);
data_in = 64'h800000008084c008;
valid_in = 1;
repeat(1)@(posedge clk);
data_in = 64'h00fff10100000300;
valid_in = 1;
repeat(1)@(posedge clk);
data_in = 64'h0;
valid_in= 1;
repeat(1)@(posedge clk);
valid_in= 0;

end 

ibra_credit_to_valrdy req_ctv(
   .clk(clk),
   .reset(reset),
   //credit based interface   
   .data_in(data_in),
   .valid_in(valid_in),
   .yummy_in(yummy_in),
            
   //val/rdy interface
   .data_out(data_out),
   .valid_out(valid_out),
   .ready_out(ready_out)
);

endmodule