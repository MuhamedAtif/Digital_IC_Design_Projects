module DSP48A1 (A,B,D,C,CLK,CARRYIN,OPMODE,BCIN,RSTA,RSTB,RSTM,
RSTP,RSTC,RSTD,RSTCARRYIN,RSTOPMODE,CEA,CEB,CEM,CEP,CEC,CED,
CECARRYIN,CEOPMODE,PCIN,BCOUT,PCOUT,P,M,CARRYOUT,CARRYOUTF);

parameter A0REG       = 0; 
parameter A1REG       = 1; 
parameter B0REG       = 0; 
parameter B1REG       = 1; 
parameter CREG        = 1; 
parameter DREG        = 1; 
parameter PREG        = 1; 
parameter MREG        = 1; 
parameter CARRYINREG  = 1; 
parameter CARRYOUTREG = 1; 
parameter OPMODEREG   = 1; 
parameter CARRYINSEL  = "OPMODE5"; // Carry-in source select  
parameter B_INPUT     = "DIRECT";  // B port source select    
parameter RSTTYPE     = "SYNC";    // Reset type for all regs 

// Data Ports
input  [17:0] A, B, D;
input  [47:0] C;
output [35:0] M;
output [47:0] P;
input         CARRYIN;
output        CARRYOUT, CARRYOUTF;

// Control Input Ports
input        CLK;
input  [7:0] OPMODE;

// Clock Enable Input Ports
input CEA, CEB, CEC, CECARRYIN, CED, CEM, CEOPMODE, CEP;

// Reset Input Ports 
input RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP;

// Cascade Ports
input  [17:0] BCIN;
output [17:0] BCOUT;
input  [47:0] PCIN;
output [47:0] PCOUT;

// Stage 1 
// D path
wire [17:0] d_pipe_out;
BLK #(.WIDTH(18),.RSTTYPE(RSTTYPE)) D_STAGE
    (.D(D),.SEL(DREG),.CLK(CLK),.RST(RSTD),.CE(CED),.BLK_OUT(d_pipe_out));
// B0 path 
wire [17:0] b_input_mux;
assign b_input_mux = (B_INPUT == "DIRECT")  ? B    :
                     (B_INPUT == "CASCADE") ? BCIN : 18'd0;
wire [17:0] b0_pipe_out;
BLK #(.WIDTH(18),.RSTTYPE(RSTTYPE)) B0_STAGE
    (.D(b_input_mux),.SEL(B0REG),.CLK(CLK),.RST(RSTB),.CE(CEB),.BLK_OUT(b0_pipe_out));
// A0 path
wire [17:0] a0_pipe_out;
BLK #(.WIDTH(18),.RSTTYPE(RSTTYPE)) A0_STAGE
    (.D(A),.SEL(A0REG),.CLK(CLK),.RST(RSTA),.CE(CEA),.BLK_OUT(a0_pipe_out));
// C path 
wire [47:0] c_pipe_out;
BLK #(.WIDTH(48),.RSTTYPE(RSTTYPE)) C_STAGE
    (.D(C),.SEL(CREG),.CLK(CLK),.RST(RSTC),.CE(CEC),.BLK_OUT(c_pipe_out));

// Stage 2 
// OPMODE path 
wire [7:0] opmode_pipe_out;
BLK #(.WIDTH(8),.RSTTYPE(RSTTYPE)) OPMODE_STAGE
    (.D(OPMODE),.SEL(OPMODEREG),.CLK(CLK),.RST(RSTOPMODE),.CE(CEOPMODE),.BLK_OUT(opmode_pipe_out));
// Pre-add/sub
wire [17:0] pre_adder_out;
assign pre_adder_out = (opmode_pipe_out[6]) ? (d_pipe_out - b0_pipe_out)
                                            : (d_pipe_out + b0_pipe_out);
wire [17:0] pre_mux_out;
assign pre_mux_out = (opmode_pipe_out[4]) ? pre_adder_out : b0_pipe_out;

// Stage 3 
// B1 path
wire [17:0] b1_pipe_out;
BLK #(.WIDTH(18),.RSTTYPE(RSTTYPE)) B1_STAGE
    (.D(pre_mux_out),.SEL(B1REG),.CLK(CLK),.RST(RSTB),.CE(CEB),.BLK_OUT(b1_pipe_out));
// A1 path 
wire [17:0] a1_pipe_out;
BLK #(.WIDTH(18),.RSTTYPE(RSTTYPE)) A1_STAGE
    (.D(a0_pipe_out),.SEL(A1REG),.CLK(CLK),.RST(RSTA),.CE(CEA),.BLK_OUT(a1_pipe_out));

// Stage 4 
// B1 output
assign BCOUT = b1_pipe_out;
//Multiplier output
wire [35:0] mult_raw_out;
assign mult_raw_out = b1_pipe_out * a1_pipe_out;
// M path 
wire [35:0] m_pipe_out;
BLK #(.WIDTH(36),.RSTTYPE(RSTTYPE)) M_STAGE
    (.D(mult_raw_out),.SEL(MREG),.CLK(CLK),.RST(RSTM),.CE(CEM),.BLK_OUT(m_pipe_out));
// M FPGA output  
assign M = m_pipe_out;
// Carry-in source mux
wire carry_src_mux;
assign carry_src_mux = (CARRYINSEL == "OPMODE5") ? opmode_pipe_out[5] :
                       (CARRYINSEL == "CARRYIN") ? CARRYIN            : 1'b0;
// CYI 
wire cin_reg_out;
BLK #(.WIDTH(1),.RSTTYPE(RSTTYPE)) CYI_STAGE
    (.D(carry_src_mux),.SEL(CARRYINREG),.CLK(CLK),.RST(RSTCARRYIN),.CE(CECARRYIN),.BLK_OUT(cin_reg_out));

// Stage 5 
wire [47:0] dab_concat;
assign dab_concat = {D[11:0], A[17:0], B[17:0]};
// X mux 
wire [47:0] x_mux_out;
assign x_mux_out = (opmode_pipe_out[1:0] == 2'd0) ? 48'd0      :
                   (opmode_pipe_out[1:0] == 2'd1) ? {12'd0, m_pipe_out} :
                   (opmode_pipe_out[1:0] == 2'd2) ? P           : dab_concat;
// Z mux
wire [47:0] z_mux_out;
assign z_mux_out = (opmode_pipe_out[3:2] == 2'd0) ? 48'd0    :
                   (opmode_pipe_out[3:2] == 2'd1) ? PCIN      :
                   (opmode_pipe_out[3:2] == 2'd2) ? P         : c_pipe_out;
// Post-adder/subtracter 
wire [47:0] post_adder_sum;
wire        post_adder_cout;
assign {post_adder_cout, post_adder_sum} =
    (opmode_pipe_out[7]) ? (z_mux_out - (x_mux_out + cin_reg_out))
                         : (z_mux_out + x_mux_out  + cin_reg_out);
// CYO 
BLK #(.WIDTH(1),.RSTTYPE(RSTTYPE)) CYO_STAGE
    (.D(post_adder_cout),.SEL(CARRYOUTREG),.CLK(CLK),.RST(RSTCARRYIN),.CE(CECARRYIN),.BLK_OUT(CARRYOUT));
assign CARRYOUTF = CARRYOUT;
// P path 
BLK #(.WIDTH(48),.RSTTYPE(RSTTYPE)) P_STAGE
    (.D(post_adder_sum),.SEL(PREG),.CLK(CLK),.RST(RSTP),.CE(CEP),.BLK_OUT(P));
assign PCOUT = P;
endmodule