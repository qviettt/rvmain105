module riscv_crypto_fu (rs1, rs2, instruction, rd);

input [31:0] rs1   ; 
input [31:0] rs2   ; 

input [19:0] instruction;

wire op_ssha256_sig0,op_ssha256_sig1,op_ssha256_sum0,op_ssha256_sum1; 

wire [1:0] imm;

output [31:0] rd;	

assign imm = instruction[19:18];
//assign imm = instruction[5:4];

assign op_ssha256_sig0  = instruction[13]; // SHA256 Sigma 0
assign op_ssha256_sig1  = instruction[12]; // SHA256 Sigma 1
assign op_ssha256_sum0  = instruction[11]; // SHA256 Sum 0
assign op_ssha256_sum1  = instruction[10]; // SHA256 Sum 1


`define GATE_INPUTS(LEN,SEL,SIG) ({LEN{SEL}} & SIG[LEN-1:0])

//
// SHA256 Instructions
// ------------------------------------------------------------

wire        ssha256_valid ;
wire [31:0] ssha256_rs1   ;
wire [31:0] ssha256_result;

assign ssha256_rs1   = `GATE_INPUTS(32,ssha256_valid, rs1);
assign ssha256_valid = op_ssha256_sig0 || op_ssha256_sig1 || op_ssha256_sum0 || op_ssha256_sum1 ;

    riscv_crypto_fu_ssha256 i_riscv_crypto_fu_ssha256(
        .rs1            (ssha256_rs1     ), // Source register 1. 32-bits.
        .op_ssha256_sig0(op_ssha256_sig0 ), // SHA256 Sigma 0
        .op_ssha256_sig1(op_ssha256_sig1 ), // SHA256 Sigma 1
        .op_ssha256_sum0(op_ssha256_sum0 ), // SHA256 Sum 0
        .op_ssha256_sum1(op_ssha256_sum1 ), // SHA256 Sum 1
        .rd             (ssha256_result  )  // Result
    );



assign rd   = {32{ssha256_valid     }} & ssha256_result;


`undef GATE_INPUTS 

endmodule