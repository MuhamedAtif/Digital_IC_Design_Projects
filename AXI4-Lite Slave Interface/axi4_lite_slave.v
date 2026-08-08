module axi4_lite_slave #(
  parameter ADDR_W = 32,
  parameter DATA_W = 32
)(
  input  wire               aclk,
  input  wire               aresetn,      // Active-low reset

  // Write address channel
  input  wire [ADDR_W-1:0]  awaddr,
  input  wire               awvalid,
  output reg                awready,

  // Write data channel
  input  wire [DATA_W-1:0]  wdata,
  input  wire [DATA_W/8-1:0] wstrb,       // Byte strobes
  input  wire               wvalid,
  output reg                wready,

  // Write response channel
  output reg  [1:0]         bresp,
  output reg                bvalid,
  input  wire               bready,

  // Read address channel
  input  wire [ADDR_W-1:0]  araddr,
  input  wire               arvalid,
  output reg                arready,

  // Read data channel
  output reg  [DATA_W-1:0]  rdata,
  output reg  [1:0]         rresp,
  output reg                rvalid,
  input  wire               rready
);

  // 4x32-bit Registers
  reg [DATA_W-1:0] regs [0:3];

  // State tracking flags
  reg [ADDR_W-1:0] aw_addr_lat; 
  reg              aw_done;       
  reg              w_done;        

  integer i, j; // Loop variables

  // Write State Machine
  always @(posedge aclk) begin
    if (!aresetn) begin
      awready     <= 1'b1;
      wready      <= 1'b1;
      bvalid      <= 1'b0;
      bresp       <= 2'b00;
      aw_done     <= 1'b0;
      w_done      <= 1'b0;
      aw_addr_lat <= 0;
      for (i = 0; i < 4; i = i + 1) regs[i] <= 0;
    end else begin
      // 1. Accept write address
      if (awvalid && awready) begin
        aw_addr_lat <= awaddr;
        aw_done     <= 1'b1;
        awready     <= 1'b0;
      end

      // 2. Accept write data
      if (wvalid && wready) begin
        w_done <= 1'b1;
        wready <= 1'b0;
      end

      // 3. Commit write when both channels are done
      if (aw_done && w_done) begin
        case (aw_addr_lat[3:2])
          2'd0: for (j = 0; j < DATA_W/8; j = j + 1) if (wstrb[j]) regs[0][j*8 +: 8] <= wdata[j*8 +: 8];
          2'd1: for (j = 0; j < DATA_W/8; j = j + 1) if (wstrb[j]) regs[1][j*8 +: 8] <= wdata[j*8 +: 8];
          2'd2: for (j = 0; j < DATA_W/8; j = j + 1) if (wstrb[j]) regs[2][j*8 +: 8] <= wdata[j*8 +: 8];
          2'd3: for (j = 0; j < DATA_W/8; j = j + 1) if (wstrb[j]) regs[3][j*8 +: 8] <= wdata[j*8 +: 8];
        endcase
        bvalid  <= 1'b1;
        bresp   <= 2'b00; // OKAY
        aw_done <= 1'b0;
        w_done  <= 1'b0;
      end

      // 4. Clear response after master accepts
      if (bvalid && bready) begin
        bvalid  <= 1'b0;
        awready <= 1'b1;
        wready  <= 1'b1;
      end
    end
  end

  // Read State Machine
  always @(posedge aclk) begin
    if (!aresetn) begin
      arready <= 1'b1;
      rvalid  <= 1'b0;
      rdata   <= 0;
      rresp   <= 2'b00;
    end else begin
      // Provide read data and response
      if (arvalid && arready) begin
        arready <= 1'b0;
        rvalid  <= 1'b1;
        rresp   <= 2'b00; // Default: OKAY
        case (araddr[3:2])
          2'd0: rdata <= regs[0];
          2'd1: rdata <= regs[1];
          2'd2: rdata <= regs[2];
          2'd3: rdata <= regs[3];
          default: begin 
            rdata <= 0; 
            rresp <= 2'b10; // SLVERR for unmapped addresses
          end  
        endcase
      end

      // Reset read channels once accepted
      if (rvalid && rready) begin
        rvalid  <= 1'b0;
        arready <= 1'b1;
      end
    end
  end

endmodule