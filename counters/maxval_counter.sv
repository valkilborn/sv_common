//counts to maxval, resets
module maxval_counter #(parameter N=16) (input [N-1:0] maxval, input clk, rst, output logic [N-1:0] count);
logic [N-1:0] ncount; 
assign ncount = (count < maxval) ? count +1: {N{1'b0}};
always_ff @(posedge clk or posedge rst)
	if(rst)
		count <= {N{1'b0}};
	else
		count <= ncount;	
endmodule 