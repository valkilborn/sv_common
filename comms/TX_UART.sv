/*
Transmitter (TX)

Takes a byte you hand it and serializes it out onto a single wire, one bit at a time, framed with a start bit and stop bit so the receiver on the other end knows where each byte begins and ends.
- parameters: `samples` (defaults to 16, so each frame is 16 ticks)
- Inputs: `clk`, `rst`, `tick` (from baud gen), `tx_data[7:0]` (the byte to send), `tx_start` (a pulse telling it "send this now")
- Outputs: `tx_serial` (the actual bit stream going out the pin), `tx_busy` (high while a byte is currently being shifted out ? tells whoever's feeding you not to hand over a new byte yet)
  1. **Idle** ? line held high, waiting for `tx_start`.
  2. **Start bit** ? drive the line low for one full bit period (this is what tells the receiver "a byte is coming").
  3. **Data bits** ? shift out all 8 bits of `tx_data`, one per bit period (UART convention: least-significant bit first).
  4. **Stop bit** ? drive the line high for one bit period, signaling "byte's done."
  5. Back to Idle, ready for the next `tx_start`.
*/

module TX #(samples=16)(input rst_, tick, tx_start, input [7:0] tx_data, 
           output logic tx_serial, tx_busy 
           //These output signals are just for testing 
           //,output logic [1:0] state, 
           //output logic [4:0] count16, 
           //output logic [3:0] count8
);   

localparam idle = 2'b00, startbit = 2'b01, databits = 2'b10, stopbit = 2'b11;

logic [1:0] nstate;
logic [1:0] state;
logic [$clog2(samples):0] cSamples;    
logic [3:0] c8;    
logic supress_counter8; 

Dreg #(2) dreg (nstate, tick, !rst_, state);

//one thing to note here is that counter8 increments every time counter16 goes back to zero
//which for the most part is good except it means counter8 starts at 1 rather than zero for databits
//so there are some odd things later on to adjust for this
//lmk if you have better ideas on this...I could use another counter :(
Counter #($clog2(samples)) counterSamples ((samples-1), tick, ((state == idle) && tx_start) || !rst_, cSamples);
Counter #(4) counter8 (4'd8, cSamples == {($clog2(samples)){1'b0}}, ((state == !databits ) || !rst_ ), c8);  

always_comb begin
	case(state)
	idle: 		nstate = (tx_start) ? startbit:idle;  
	startbit: 	nstate =(cSamples == (samples-1) )? databits:startbit;
			//4'd8 due to counter quirk explained above 
	databits: 	nstate = (c8==4'd8 & cSamples == (samples-1) )? stopbit:databits; 
	stopbit: 	nstate =(cSamples == (samples-1))? idle: stopbit; 
	default: 	nstate = idle; 
	endcase 
end

assign tx_busy = (state != idle);
//c8-1 due to counter quirk explained above 
assign tx_serial = (state==databits)? tx_data[c8-1]: 
			(state==startbit)? 1'b0:
			(state==stopbit)? 1'b1: 1'b1;
//these are just for testing 
//assign count16=cSamples;
//assign count8=c8;
endmodule