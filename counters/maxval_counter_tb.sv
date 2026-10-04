module maxval_counter_tb();
logic clk, rst;
logic [15:0] maxval, c;
assign maxval =  5'd16;

maxval_counter #(5) count (5'd16, clk, rst, c);

 // 1. Independent Clock Generation (10 time-unit period)
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

initial begin 
	rst = 1'b1; #5 rst=1'b0; #5;
	#80;
end
endmodule 