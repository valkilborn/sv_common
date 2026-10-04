//only update if enabled, reset whenever
module ShiftRightReg #(parameter N=8) (input b, clk, rst, en, output logic [N-1:0] array);
always_ff @ (posedge clk or posedge rst)
	if (rst)
		array <= {N{1'b0}};
	else if (clk && en) 
		array <= {b, array[N-1:1]};
endmodule 