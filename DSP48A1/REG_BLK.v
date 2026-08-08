module BLK (D,SEL,CLK,RST,CE,BLK_OUT);

parameter WIDTH = 18; 
parameter RSTTYPE = "SYNC";

input SEL,CLK,RST,CE;
input [WIDTH-1:0] D;

reg [WIDTH-1:0] Q;

output [WIDTH-1:0] BLK_OUT;
generate
	if (RSTTYPE == "SYNC") begin
		always @(posedge CLK) begin
			if (RST) begin
				Q<=0;
			end
			else if (CE) begin
				Q<=D;
			end
		end
	end	
	else if (RSTTYPE == "ASYNC") begin
		always @(posedge CLK or posedge RST) begin
			if (RST) begin
				Q<=0;
			end
			else if (CE) begin
				Q<=D;
			end
		end
	end
endgenerate
assign BLK_OUT = (SEL)? Q : D ;

endmodule