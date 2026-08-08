`timescale 1ns/1ps

module axi4_lite_slave_tb;

  reg         aclk, aresetn;
  reg  [31:0] awaddr, araddr, wdata;
  reg  [3:0]  wstrb;
  reg         awvalid, wvalid, bready, arvalid, rready;

  wire        awready, wready;
  wire [1:0]  bresp, rresp;
  wire        bvalid, arready, rvalid;
  wire [31:0] rdata;

  // DUT Instantiation
  axi4_lite_slave dut (
    .aclk(aclk),
    .aresetn(aresetn),
    .awaddr(awaddr),
    .awvalid(awvalid),
    .awready(awready),
    .wdata(wdata),
    .wstrb(wstrb),
    .wvalid(wvalid),
    .wready(wready),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),
    .araddr(araddr),
    .arvalid(arvalid),
    .arready(arready),
    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid),
    .rready(rready)
  );

  always #5 aclk = ~aclk;

  // Variables for tracking and expected values
  integer pass_cnt, fail_cnt, i;
  reg [31:0] exp_data, got_data, d1, d2;

  // AXI Write Task
  task axi_write;
    input [31:0] addr;
    input [31:0] data;
    input [3:0]  strb;
    begin
      @(posedge aclk); #1;
      awaddr  = addr; 
      awvalid = 1;
      wdata   = data; 
      wstrb   = strb; 
      wvalid  = 1;
      
      while (!awready || !wready) @(posedge aclk);
      @(posedge aclk); #1;
      awvalid = 0; 
      wvalid  = 0;
      bready  = 1;
      
      while (!bvalid) @(posedge aclk);
      @(posedge aclk); #1;
      bready = 0;
    end
  endtask

  // AXI Read Task
  task axi_read;
    input  [31:0] addr;
    output [31:0] data;
    begin
      @(posedge aclk); #1;
      araddr  = addr; 
      arvalid = 1;
      
      while (!arready) @(posedge aclk);
      @(posedge aclk); #1; 
      arvalid = 0;
      rready  = 1;
      
      while (!rvalid) @(posedge aclk);
      data = rdata;
      @(posedge aclk); #1; 
      rready = 0;
    end
  endtask

  // Main Test Sequence
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, axi4_lite_slave_tb);
    
    aclk = 0; aresetn = 0;
    awvalid = 0; wvalid = 0; bready = 0;
    arvalid = 0; rready = 0;
    pass_cnt = 0; fail_cnt = 0;

    $display("=== AXI4-Lite Slave TB ===");
    repeat(3) @(posedge aclk); aresetn = 1;

    // Test 1: Write and read back all 4 registers
    $display("-- Reg Write/Read Test --");
    for (i = 0; i < 4; i = i + 1) begin
      exp_data = 32'hA000_0000 | i;
      axi_write(i * 4, exp_data, 4'hF);
      axi_read(i * 4, got_data);
      
      if (got_data == exp_data) begin
        $display("  PASS  reg[%0d] = 0x%0h", i, got_data); 
        pass_cnt = pass_cnt + 1;
      end else begin
        $display("  FAIL  reg[%0d] got=0x%0h exp=0x%0h", i, got_data, exp_data); 
        fail_cnt = fail_cnt + 1;
      end
    end

    // Test 2: Byte-strobe test (write upper byte only)
    $display("-- Byte Strobe Test --");
    axi_write(32'h00, 32'hDEAD_BEEF, 4'b1000); 
    axi_read(32'h00, d1);
    
    if (d1[31:24] == 8'hDE) begin
      $display("  PASS  Byte strobe: upper byte=0xDE"); 
      pass_cnt = pass_cnt + 1;
    end else begin
      $display("  FAIL  Byte strobe: got upper=0x%0h", d1[31:24]); 
      fail_cnt = fail_cnt + 1;
    end

    // Check if lower bytes were preserved
    if (d1[23:0] == 24'h00_00_00) begin
      $display("  PASS  Byte strobe: lower bytes preserved"); 
      pass_cnt = pass_cnt + 1;
    end else begin
      $display("  FAIL  Byte strobe: lower bytes got=0x%0h exp=0x000000", d1[23:0]); 
      fail_cnt = fail_cnt + 1;
    end

    // Test 3: Back-to-back transactions
    $display("-- Back-to-back Test --");
    axi_write(32'h04, 32'hCAFE_BABE, 4'hF);
    axi_write(32'h08, 32'h1234_5678, 4'hF);
    
    axi_read(32'h04, d1);
    axi_read(32'h08, d2);
    
    if (d1 == 32'hCAFE_BABE && d2 == 32'h1234_5678) begin
      $display("  PASS  Back-to-back writes verified"); 
      pass_cnt = pass_cnt + 1;
    end else begin
      $display("  FAIL  Back-to-back: d1=0x%0h d2=0x%0h", d1, d2); 
      fail_cnt = fail_cnt + 1;
    end

    // Final Report
    $display("\n=== %0d passed, %0d failed ===", pass_cnt, fail_cnt);
    if (fail_cnt == 0) $display("PASS");
    else               $display("FAIL");
    $finish;
  end

endmodule