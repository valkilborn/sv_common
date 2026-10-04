//4 to 1 FSM
module FSM41 #(parameter N=2) (input [N-1:0] a, b, c, d, input [1:0] sel, output logic [N-1:0] q);
always_comb begin
q = {N{1'b0}};
	case (sel)  
	2'b00: q = a; 
	2'b01: q = b; 
	2'b10: q = c; 
	2'b11: q = d; 
	default: q = {N{1'b0}};
endcase
end
endmodule