module BiCounter_tb();
logic clk, rst, c;
logic [15:0] maxval;
assign maxval =  5'd16;

BiCounter #(5) bic (5'd16, clk, rst, c);

 // 1. Independent Clock Generation (10 time-unit period)
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

initial begin 
	#80;
end
endmodule 