module MASTER();
//Signals Declaration
reg MOSI; 
reg SS_n; 
reg clk;  
reg rst_n;
wire MISO;
//DUT Instantiation
SPI_Wrapper DUT(.MOSI(MOSI),.MISO(MISO),.SS_n(SS_n),.clk(clk),.rst_n(rst_n));
//Clock Generation
initial begin
	clk = 0;
	forever 
		#5 clk = ~clk;
end
//Test Stimiulus Generator
initial begin
	//Activate Reset ,Un-Enable SS_n& Initialize all signals
	rst_n = 0;
	SS_n  = 1;
	MOSI  = 0;
	@(negedge clk);
	//De-Activate Reset& Start testing
	rst_n = 1;

	//Test Writing Address
	SS_n = 0;
	@(negedge clk);

	MOSI = 0;//Write
	@(negedge clk);
	
	MOSI = 0;
	@(negedge clk);
	MOSI = 0;
	@(negedge clk);
	//2'b00 >> To write address
	repeat(3) begin
		MOSI = 0;
		@(negedge clk);
		MOSI = 1;
		@(negedge clk);
		MOSI = 1;
		@(negedge clk);
		MOSI = 1;
		@(negedge clk);
	end
	//Address : 8'b01110111
	SS_n = 1;
	@(negedge clk);

	//Test Writing Data
	SS_n = 0;
	@(negedge clk);
	MOSI = 0;//Wtite
	@(negedge clk);

	MOSI = 0;
	@(negedge clk);
	MOSI = 1;
	@(negedge clk);
	//2'b01 >> To write Data
	MOSI = 1;
	@(negedge clk);
	MOSI = 0;
	@(negedge clk);
	MOSI = 1;
	@(negedge clk);
	MOSI = 0;
	@(negedge clk);
	MOSI = 1;
	@(negedge clk);
	MOSI = 0;
	@(negedge clk);
	MOSI = 1;
	@(negedge clk);
	MOSI = 0;
	@(negedge clk);	
	//Data:8'b10101010
	SS_n = 1;
	@(negedge clk);

	//Test Reading Address
	SS_n = 0;
	@(negedge clk);

	MOSI = 1;//Read
	@(negedge clk);

	MOSI = 1;
	@(negedge clk);
	MOSI = 0;
	@(negedge clk);
	//2'b10 >> To Read address
	repeat(3) begin
		MOSI = 0;
		@(negedge clk);
		MOSI = 1;
		@(negedge clk);
		MOSI = 1;
		@(negedge clk);
		MOSI = 1;
		@(negedge clk);
	end
	//Address : 8'b01110111
	SS_n = 1;
	@(negedge clk);

	//Test Reading Data
	SS_n = 0;
	@(negedge clk);

	MOSI = 1;//Read
	@(negedge clk);

	MOSI = 1;
	@(negedge clk);
	MOSI = 1;
	@(negedge clk);
	//2'b11 >> To Read Data
	MOSI = 0;
	@(negedge clk);
	MOSI = 1;
	@(negedge clk);
	MOSI = 1;
	@(negedge clk);
	MOSI = 0;
	@(negedge clk);
	MOSI = 1;
	@(negedge clk);
	MOSI = 0;
	@(negedge clk);
	MOSI = 0;
	@(negedge clk);
	MOSI = 0;
	@(negedge clk);	
	//Dummy Data
	repeat(8) @(negedge clk);
	SS_n = 1;

	$stop;
end 
//Test Monitor & Results
initial begin
    $monitor("MOSI = %b, MISO = %b, SS_n = %b",MOSI, MISO, SS_n);
end
endmodule 