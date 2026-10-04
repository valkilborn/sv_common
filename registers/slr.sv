//only update if enabled, reset whenever
module ShiftleftReg #(parameter N=8) (input b, clk, rst, en, output logic [N-1:0] array);
always_ff @ (posedge clk or rst)
	if (rst)
		array <= {N{1'b0}};
	else if (clk && en)  
		array <= {array[N-2:0], b};
endmodule 