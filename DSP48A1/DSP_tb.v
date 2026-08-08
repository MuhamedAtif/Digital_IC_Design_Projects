module DSP48A1_tb();
parameter A0REG = 0 ;
parameter A1REG = 1 ;
parameter B0REG = 0 ;
parameter B1REG = 1 ;
parameter CREG = 1; 
parameter DREG = 1 ; 
parameter MREG = 1 ; 
parameter PREG = 1 ; 
parameter CARRYINREG = 1 ; 
parameter CARRYOUTREG = 1 ; 
parameter OPMODEREG = 1;
parameter CARRYINSEL = "OPMODE5" ;
parameter B_INPUT = "DIRECT" ;
parameter RSTTYPE = "SYNC" ; 

reg [17:0] A, B, D;
reg [47:0] C, PCIN;
reg CLK, CARRYIN;
reg [7:0] OPMODE;
reg RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE;
reg CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE;
reg [17:0] BCIN;
wire [17:0] BCOUT;
wire [47:0] PCOUT, P;
wire [35:0] M;
wire CARRYOUT, CARRYOUTF;

// Variables for Path 3
reg [47:0] prev_P;
reg prev_CARRYOUT;

DSP48A1 #(.A0REG(A0REG),.A1REG(A1REG),.B0REG(B0REG),.B1REG(B1REG),.CREG(CREG),.DREG(DREG),.MREG(MREG),.PREG(PREG),.CARRYINREG(CARRYINREG),.CARRYOUTREG(CARRYOUTREG),
        .OPMODEREG(OPMODEREG),.CARRYINSEL(CARRYINSEL),.B_INPUT(B_INPUT),.RSTTYPE(RSTTYPE)) DUT (.A(A),.B(B),.D(D),.C(C),.CLK(CLK),.CARRYIN(CARRYIN),.OPMODE(OPMODE),
        .BCIN(BCIN),.RSTA(RSTA),.RSTB(RSTB),.RSTM(RSTM),.RSTP(RSTP),.RSTC(RSTC),.RSTD(RSTD),.RSTCARRYIN(RSTCARRYIN),.RSTOPMODE(RSTOPMODE),.CEA(CEA),.CEB(CEB),.CEM(CEM),
        .CEP(CEP),.CEC(CEC),.CED(CED),.CECARRYIN(CECARRYIN),.CEOPMODE(CEOPMODE),.PCIN(PCIN),.BCOUT(BCOUT),.PCOUT(PCOUT),.P(P),.M(M),.CARRYOUT(CARRYOUT),.CARRYOUTF(CARRYOUTF));

initial begin
    CLK = 0;
    forever 
    #1 CLK = ~CLK; 
end

initial begin
    // Initialize and reset signals
    RSTA = 1; RSTB = 1; RSTM = 1; RSTP = 1; RSTC = 1; RSTD = 1; RSTCARRYIN = 1; RSTOPMODE = 1;
    CEA = 1; CEB = 1; CEM = 1; CEP = 1; CEC = 1; CED = 1; CECARRYIN = 1; CEOPMODE = 1;
    A = 18'hABCD; B = 18'h1234; C = 48'hDEADBEEF; D = 18'h5678; CARRYIN = 1; BCIN = 18'hFFF; PCIN = 48'h123456;
    OPMODE = 8'hFF;
    
    @(negedge CLK);
    
    // Reset Self-checking
    if (P !== 0 || M !== 0 || CARRYOUT !== 0 || BCOUT !== 0) 
        $display("FAIL [Reset]: Outputs are not zero");
    else 
        $display("PASS [Reset]: Outputs are zero");

    // Release resets
    RSTA = 0; RSTB = 0; RSTM = 0; RSTP = 0; RSTC = 0; RSTD = 0; RSTCARRYIN = 0; RSTOPMODE = 0;

    // Test case 1: Verify DSP Path 1 
    A = 20; B = 10; C = 350; D = 25; CARRYIN = 1; BCIN = 18'hABC; PCIN = 48'h5A5A5A;
    OPMODE = 8'b11011101; 
    repeat(4) @(negedge CLK);
    if (BCOUT !== 18'hf || M !== 36'h12c || P !== 48'h32 || PCOUT !== 48'h32 || CARRYOUT !== 1'b0) 
        $display("FAIL [Path 1]");
    else 
        $display("PASS [Path 1]");

    // Test case 2: Verify DSP Path 2 
    A = 20; B = 10; C = 350; D = 25; CARRYIN = 1; BCIN = 18'h333; PCIN = 48'hABCDEF;
    OPMODE = 8'b00010000; 
    repeat(3) @(negedge CLK);
    if (BCOUT !== 18'h23 || M !== 36'h2bc || P !== 48'h0 || PCOUT !== 48'h0 || CARRYOUT !== 1'b0) 
        $display("FAIL [Path 2]");
    else 
        $display("PASS [Path 2]");
        
    // Store values for Path 3 checking
    prev_P = P;
    prev_CARRYOUT = CARRYOUT;

    // Test case 3: Verify DSP Path 3 
    A = 20; B = 10; C = 350; D = 25; CARRYIN = 1; BCIN = 18'h777; PCIN = 48'hF0F0F0;
    OPMODE = 8'b00001010; 
    repeat(3) @(negedge CLK);
    if (BCOUT !== 18'ha || M !== 36'hc8 || P !== prev_P || PCOUT !== prev_P || CARRYOUT !== prev_CARRYOUT) 
        $display("FAIL [Path 3]");
    else 
        $display("PASS [Path 3]");

    // Test case 4: Verify DSP Path 4 
    A = 5; B = 6; C = 350; D = 25; CARRYIN = 1; BCIN = 18'hAAA; PCIN = 3000;
    OPMODE = 8'b10100111; 
    repeat(3) @(negedge CLK);
    if (BCOUT !== 18'h6 || M !== 36'h1e || P !== 48'hfe6fffec0bb1 || PCOUT !== 48'hfe6fffec0bb1 || CARRYOUT !== 1'b1) 
        $display("FAIL [Path 4]");
    else 
        $display("PASS [Path 4]");

    // Reset all signals and finish
    RSTA = 1; RSTB = 1; RSTM = 1; RSTP = 1; RSTC = 1; RSTD = 1; RSTCARRYIN = 1; RSTOPMODE = 1;
    CEA = 0; CEB = 0; CEM = 0; CEP = 0; CEC = 0; CED = 0; CECARRYIN = 0; CEOPMODE = 0;
    A = 0; B = 0; C = 0; D = 0; CARRYIN = 0; BCIN = 0; PCIN = 0; OPMODE = 8'b00000000;
    repeat(10) @(negedge CLK);
    $stop;
end

//Test Monitor & Results
initial begin
    $monitor("A=%d, B=%d, C=%d, D=%d, CARRYIN=%d ,PCIN=%d , OPMODE=%b, P=%d,BCOUT=%d ,M=%d ,CARRYOUT=%d", A, B, C, D,CARRYIN ,PCIN , OPMODE, P,BCOUT ,M , CARRYOUT);
end
endmodule