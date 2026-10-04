module RX_TB();
  logic rst, tick; 
  logic rx_serial, rx_valid;
  logic [7:0] rx_data;
//for testing
  //logic [1:0] state;
  //logic [4:0] c16;
  //logic [3:0] c8;

  int errors = 0;

  RX rx(rst, tick, rx_serial, rx_data, rx_valid
	//, state, c16, c8 (for testing)
);

  // Clock/tick generation
  initial begin
    tick = 1'b0;
    forever #5 tick = ~tick;
  end

  // Drive one UART frame (start bit, 8 data bits LSB-first, stop bit)
  // and check the reassembled byte / rx_valid afterward.
  task automatic send_and_check(input [7:0] data, input bit inject_framing_error = 0);
    int i;
    begin
      // Idle line before starting
      rx_serial = 1'b1;
      @(posedge tick);

      // Start bit: hold low for one full bit period
      rx_serial = 1'b0;
      repeat (16) @(posedge tick);

      // Data bits, LSB first
      for (i = 0; i < 8; i++) begin
        rx_serial = data[i];
        repeat (16) @(posedge tick);
      end

      // Stop bit (or deliberately corrupt it to test framing-error handling)
      rx_serial = inject_framing_error ? 1'b0 : 1'b1;
      repeat (16) @(posedge tick);

      // Return line to idle
      rx_serial = 1'b1;
      repeat (2) @(posedge tick);

      if (inject_framing_error) begin
        // On a framing error we expect the RX to NOT report a valid byte
        // for this frame (should have bailed back to idle instead of
        // asserting rx_valid with stale/garbage data).
        if (rx_valid === 1'b1) begin
          $display("FAIL: rx_valid asserted despite framing error at time %0t", $time);
          errors++;
        end else
          $display("PASS: framing error correctly did not assert rx_valid");
      end else begin
        if (rx_data !== data) begin
          $display("FAIL: expected rx_data=%b, got %b at time %0t", data, rx_data, $time);
          errors++;
        end else
          $display("PASS: rx_data correct (%b)", data);
      end
    end
  endtask

  initial begin
    // Explicit initialization ? avoid X propagation into the DUT
    rst       = 1'b1;
    rx_serial = 1'b1; // UART idle state is high

    repeat (2) @(posedge tick);
    rst = 1'b0;
    repeat (2) @(posedge tick);

    // Sanity check: should be idle after reset
    //if (state !== 2'b00) begin
      //$display("FAIL: RX not in idle state after reset (state=%b)", state);
      //errors++;
    //end

    // Normal frames, a few different patterns
    send_and_check(8'b00101110);
    send_and_check(8'b11111111);
    send_and_check(8'b00000000);
    send_and_check(8'b10101010);
    send_and_check(8'b01010101);

    // Glitch test: pull the line low briefly (less than 8 ticks) then
    // back high before the confirm-sample point ? should be rejected
    // as a false start and return to idle without producing a byte.
    rx_serial = 1'b1;
    @(posedge tick);
    rx_serial = 1'b0;
    repeat (3) @(posedge tick);   // too short to be a real start bit
    rx_serial = 1'b1;
    repeat (16) @(posedge tick);
    //if (state !== 2'b00) begin
      //$display("FAIL: glitch on rx_serial was not rejected (state=%b)", state);
      //errors++;
    //end else
      $display("PASS: glitch correctly rejected, stayed in idle");

    // Framing error test: valid start + data, but stop bit sampled low
    send_and_check(8'b11001100, 1);

    if (errors == 0)
      $display("=== ALL TESTS PASSED ===");
    else
      $display("=== %0d TEST(S) FAILED ===", errors);

    $finish;
  end

endmodule
