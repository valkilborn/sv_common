//Dregister 
module Dreg #(parameter N=4) (input [N-1:0] d, input clk, rst, output logic [N-1:0] q);
always_ff @ (posedge clk or posedge rst)
	if(rst)
		q <= {N{1'b0}};
	else
		q<= d;
endmodule 