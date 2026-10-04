//High at maxval, low otherwise
module BiCounter #(parameter N=16) (input [N-1:0] maxval, input clk, rst, output logic c);
logic [N-1:0] count, ncount; 
assign ncount = (count < maxval) ? count +1: {N{1'b0}};
always_ff @(posedge clk or posedge rst)
	if(rst)
		count <= {N{1'b0}};
	else
		count <= ncount;	
assign c = (count == maxval) ? 1'b1: 1'b0;
endmodule 