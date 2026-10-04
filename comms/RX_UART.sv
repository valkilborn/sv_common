/*
Receiver (RX)
The mirror image of TX ? watches the incoming serial line, detects when a byte starts arriving, samples each bit at the right moment, and reassembles the original byte.

- **Inputs:** `clk`, `rst`, `tick` (from baud gen), `rx_serial` (the incoming bit stream)
- **Outputs:** `rx_data[8:0]` (the reassembled byte), `rx_valid` (a single-cycle pulse meaning "a new byte just landed, go read it")
  1. **Idle** ? continuously watch `rx_serial` for a falling edge (line going from high to low), which signals a start bit.
  2. **Confirm start bit** ? once you see the falling edge, wait 8 ticks (half a bit period) and sample again to confirm it's really a start bit and not just line noise. This is the whole reason for oversampling ? it lets you center your sample point.
  3. **Sample data bits** ? from that centered point, wait a full 16 ticks (one bit period) between each subsequent sample, reading 8 bits, LSB first, to match how TX sent them.
  4. **Check stop bit** ? sample where the stop bit should be; if it's not high, you have a framing error (optional to handle now, but worth knowing this is where you'd catch it).
  5. Assert `rx_valid` for one clk with the completed byte on `rx_data`, then back to Idle.

*/
module RX #(samples=16) (input rst, tick, rx_serial, output logic [7:0] rx_data, output logic rx_valid
//for testing
//, output logic [1:0] state, output logic [4:0] cSamples, output logic [3:0] count8
);

localparam idle = 2'b00, startbit = 2'b01, databits = 2'b10, stopbit = 2'b11;
logic [1:0] state;
logic [4:0] count8;
logic [$clog2(samples):0] cSamples; 
logic [1:0] nstate;

//rest counter 16 @ enter startbit, 8 ticks into startbit, and enter stopbit
Counter #($clog2(samples)) counterSamples ((samples-1), tick, (state==idle && ~rx_serial) || rst , cSamples);
Counter #(4) counter8 (4'd8, cSamples == '0, (state !=databits) || rst, count8);

Dreg #(2) statereg (nstate, tick, rst, state);

always_comb begin
	case(state)
	idle: 		nstate = (rx_serial)? idle: startbit;
	//if serial low as midsample => false startbit, return to idle.
	startbit:	nstate = (rx_serial && (cSamples == (((samples+1)/2)-2)))? idle : (~rx_serial && (cSamples == (((samples+1)/2)-2)))? databits: startbit;
	//remember we entered databit state halfway thru start bit, thus we must exit when count16 ==8 and we've taken 8 samples. 
	//if there is a framing error throw out the line and go back to idle. 
	databits: 	nstate =  (count8 == 4'd8 && (cSamples == samples-1) && rx_serial)? stopbit : databits;
	stopbit: 	nstate =  (cSamples == samples-1) ? idle : stopbit;
	default: 	nstate = idle;
	endcase
end

//implement logic for constructing rx_data and rx_valid signals
ShiftRightReg #(8) ByteReg (rx_serial, (cSamples == ((samples+1)/2)), rst, state == databits, rx_data);
assign rx_valid = (state == stopbit && (cSamples == ((samples+1)/2)) && rx_serial) ? 1'b1:1'b0;
endmodule
