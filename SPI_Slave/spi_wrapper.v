module SPI_Wrapper(MOSI, MISO, SS_n, clk, rst_n);
// Ports
input MOSI, clk, rst_n, SS_n;
output MISO;

// Internal Signals
wire [9:0] rx_data;
wire rx_valid;
wire [7:0] tx_data;
wire tx_valid;

// Instantiations
SPI_Slave SPI_SLAVE (.MOSI(MOSI), .MISO(MISO), .SS_n(SS_n), .clk(clk), .rst_n(rst_n),.rx_data(rx_data),.rx_valid(rx_valid), .tx_valid(tx_valid), .tx_data(tx_data));
RAM #(.ADDR_SIZE(8), .MEM_DEPTH(256)) SPI_RAM (.din(rx_data), .rx_valid(rx_valid), .clk(clk),.rst_n(rst_n), .dout(tx_data),.tx_valid(tx_valid));
endmodule