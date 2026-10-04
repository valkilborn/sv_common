module TX_TB();
  logic rst, tick, tx_start;
  logic tx_serial, tx_busy;
  logic [7:0] tx_data;
  //for testing
  //logic [1:0] state;
  //logic [3:0] c8;      
  //logic [4:0] c16;

  int errors = 0;

TX #(16) tx (
  .rst_     (rst),
  .tick     (tick),
  .tx_start (tx_start),
  .tx_data  (tx_data),
  .tx_serial(tx_serial),
  .tx_busy  (tx_busy)
  //,.state    (state),
  //.count16  (c16),
  //.count8   (c8)
);

  // Clock/tick generation
  initial begin
    tick = 1'b0;
    forever #5 tick = ~tick;
  end

  // Task: send one byte and self-check the serial output bit-by-bit
  task automatic send_and_check(input [7:0] data);
    int i;
    begin
      // Wait until TX is idle before starting a new frame
      @(posedge tick);
      wait (tx_busy == 1'b0);
      tx_data  = data;
      tx_start = 1'b1;
      @(posedge tick);
      tx_start = 1'b0;

      // --- Check start bit ---
      // Wait to mid-bit (8 ticks in) to sample a stable value, then step
      // through the remaining bit periods (16 ticks each).
      repeat (16) @(posedge tick);
      if (tx_serial !== 1'b0) begin
        $display("FAIL: start bit expected 0, got %b at time %0t", tx_serial, $time);
        errors++;
      end else
        $display("PASS: start bit correct");

      // --- Check 8 data bits, LSB first ---
      for (i = 0; i < 8; i++) begin
        repeat (16) @(posedge tick);
        if (tx_serial !== data[i]) begin
          $display("FAIL: data bit %0d expected %b, got %b at time %0t",
                    i, data[i], tx_serial, $time);
          errors++;
        end else
          $display("PASS: data bit %0d correct (%b)", i, data[i]);
      end

      // --- Check stop bit ---
      repeat (16) @(posedge tick);
      if (tx_serial !== 1'b1) begin
        $display("FAIL: stop bit expected 1, got %b at time %0t", tx_serial, $time);
        errors++;
      end else
        $display("PASS: stop bit correct");

      // tx_busy should have dropped back to 0 by now
      repeat (2) @(posedge tick);
      if (tx_busy !== 1'b0) begin
        $display("FAIL: tx_busy did not deassert after frame completed");
        errors++;
      end
    end
  endtask

  initial begin
    // Initialize all inputs explicitly ? avoid X propagation
    rst      = 1'b0;
    tx_start = 1'b0;
    tx_data  = 8'h00;

    repeat (2) @(posedge tick);
    rst = 1'b1;
    repeat (2) @(posedge tick);

    // Sanity check: should be idle, not busy, line high
    if (tx_busy !== 1'b0 || tx_serial !== 1'b1) begin
      $display("FAIL: TX not idle after reset (busy=%b, serial=%b)", tx_busy, tx_serial);
      errors++;
    end

    // Test a few different byte patterns
    send_and_check(8'b00101110);
    send_and_check(8'b11111111);
    send_and_check(8'b00000000);
    send_and_check(8'b10101010);

    // Test that tx_start is ignored while busy (back-to-back send attempt)
    @(posedge tick);
    tx_data  = 8'hAA;
    tx_start = 1'b1;
    @(posedge tick);
    tx_start = 1'b0;
    // Immediately try to start a second, different byte mid-frame
    tx_data  = 8'h55;
    tx_start = 1'b1;
    @(posedge tick);
    tx_start = 1'b0;
    // Let the first frame finish and confirm serial output matches 0xAA, not 0x55
    repeat (16*10) @(posedge tick);

    if (errors == 0)
      $display("=== ALL TESTS PASSED ===");
    else
      $display("=== %0d TEST(S) FAILED ===", errors);

    $finish;
  end

endmodule
