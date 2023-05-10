module control_unit (
  imm_val, rs1, rs2, rd, mux_a_sel, mux_b_sel, alu_func, is_scalar_crypto, is_bitmanip, rd_sel, reg_we, pc_add_sel, pc_next_sel, 
  mem_we, sx_size, crypto_instruction, bitmanip_instruction, sysi_o, eq, a_lt_b, a_lt_ub, instruction, clk, rst, jal_sel, load_o
);
	input eq, a_lt_b, a_lt_ub;
    input [31:0] instruction;
    input clk, rst;

//    input delayed_load;
//    input [4:0] delayed_rd;
  
//    input delayed_clmul; 
// JAL, JALR //
    output jal_sel;
//-----------//	
    wire func7;
    wire [6:0] opcode;
    wire [2:0] func3;

    output [31:0] imm_val;
    output [4:0] rs1, rs2, rd;
    output is_scalar_crypto;
    output sysi_o;
    output load_o;

    wire fn3_0_o, fn3_1_o, fn3_2_o, fn3_3_o, fn3_4_o, fn3_5_o, fn3_6_o, fn3_7_o;
    wire lui_o, auipc_o, branch_o, store_o, imm_o, alu_o;
    wire eq_o, neq_o, lt_o, ltu_o, ge_o, geu_o;
    wire add_o, jal_o, jalr_o, sub_o, sll_o, slt_o, sltu_o, xor_o, srl_o, sra_o, or_o, and_o, alu_jalr_o;
    wire mem_byte, mem_half, mem_word, mem_byte_u, mem_half_u;
    wire reg_we_temp;

    wire scalar_crypto_op, scalar_crypto_op_imm, is_scalar_crypto_hash, is_scalar_crypto_block;

    wire scalar_crypto_sm3, scalar_crypto_sha256, scalar_crypto_sha512, scalar_crypto_sha512_high, scalar_crypto_sha512_low,
        scalar_crypto_aes, scalar_crypto_sm4;

    wire op_saes32_encs ,op_saes32_encsm,op_saes32_decs,op_saes32_decsm,
    op_ssha256_sig0,op_ssha256_sig1,op_ssha256_sum0,op_ssha256_sum1, 
    op_ssha512_sum0r, op_ssha512_sum1r ,op_ssha512_sig0l,op_ssha512_sig0h ,op_ssha512_sig1l,op_ssha512_sig1h ,
    op_ssm3_p0 ,op_ssm3_p1 , op_ssm4_ks ,op_ssm4_ed;
    //op_lut4lo, op_lut4hi;

    wire op_clmul, op_clmulh, op_xperm_n, op_xperm_b, op_ror, op_rol, op_rori, op_andn, op_orn, op_xnor,
    op_pack, op_packu, op_packh, op_grevi, op_shfl, op_unshfl;

    output is_bitmanip;
    output [20:0] bitmanip_instruction;

    //wire invalid_opcode;

 //   output stall;

	output [3:0] alu_func;
	output [2:0] sx_size;
	output [1:0] rd_sel;
	output mux_a_sel, mux_b_sel, pc_add_sel, reg_we, mem_we, pc_next_sel;

    output [19:0] crypto_instruction;
//    output [5:0] crypto_instruction;

//    assign rs1 = rst ? instruction[19:15] : 5'd0;
 //   assign rs2 = rst ? instruction[24:20] : 5'd0;
   // assign rd  = rst ? instruction[11:7] : 5'd0;
          assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    //assign rd  = instruction[11:7];
    assign rd = !rst ? 5'd0: 
//                delayed_load ? delayed_rd : 
//    	           0 ? rs1: instruction[11:7];
                scalar_crypto_op & is_scalar_crypto_block ? rs1: instruction[11:7];

    //In second cycle of load instruction, rd = delayed_rd
    //Scalar Crypto AES/ SM4 - Destructive Encoding - rd sourced from rs1

   //assign func7 = rst ? instruction[30] : 0;
   //assign func3 = rst ? instruction[14:12] : 3'd0;
   //assign opcode = rst ? instruction[6:0] : 7'd0;
    assign func7 = instruction[30];
    assign func3 = instruction[14:12];
    assign opcode = instruction[6:0];

    imm_sx gen_imm(.imm_x(imm_val), .insn(instruction));

	//Opcodes

	parameter OPCODE_U_LUI 	= 7'b0110111,
     		OPCODE_U_AUIPC 	= 7'b0010111,
     		OPCODE_J_JAL 	= 7'b1101111,
     		OPCODE_I_JALR	= 7'b1100111,
     		OPCODE_B_BRANCH = 7'b1100011,
     		OPCODE_I_LOAD 	= 7'b0000011,
     		OPCODE_S_STORE 	= 7'b0100011,  
     		OPCODE_I_IMM 	= 7'b0010011,
     		OPCODE_R_ALU 	= 7'b0110011,
            OPCODE_I_SYSTEM = 7'b1110011,
            OPCODE_I_FENCE  = 7'b0001111;

    assign lui_o    = (opcode===OPCODE_U_LUI);
    assign auipc_o  = (opcode===OPCODE_U_AUIPC);
    assign jal_o    = (opcode===OPCODE_J_JAL);
    assign jalr_o   = (opcode===OPCODE_I_JALR);
    assign branch_o = (opcode===OPCODE_B_BRANCH);
    assign load_o   = (opcode===OPCODE_I_LOAD);
    assign store_o  = (opcode===OPCODE_S_STORE);
    assign imm_o    = (opcode===OPCODE_I_IMM);
    assign alu_o    = (opcode===OPCODE_R_ALU);
    assign sysi_o   = (opcode===OPCODE_I_SYSTEM) || (opcode===OPCODE_I_FENCE);
 
    assign fn3_0_o = func3 == 3'b000; //*******/
    assign fn3_1_o = func3 == 3'b001;
    assign fn3_2_o = func3 == 3'b010;
    assign fn3_3_o = func3 == 3'b011;
    assign fn3_4_o = func3 == 3'b100;
    assign fn3_5_o = func3 == 3'b101;
    assign fn3_6_o = func3 == 3'b110;
    assign fn3_7_o = func3 == 3'b111;

    assign eq_o     = branch_o & fn3_0_o & eq ;
    assign neq_o    = branch_o & fn3_1_o & (!eq);
    assign lt_o     = branch_o & fn3_4_o & a_lt_b;
    assign ge_o     = branch_o & fn3_5_o & (!a_lt_b);
    assign ltu_o    = branch_o & fn3_6_o & a_lt_ub;
    assign geu_o    = branch_o & fn3_7_o & (!a_lt_ub);

    assign add_o    = jal_o|auipc_o|branch_o|load_o|store_o|(alu_o&fn3_0_o&!func7)|(imm_o&fn3_0_o); //ADD, ADDI
    assign sub_o    = (alu_o&fn3_0_o&func7);                            //SUB
    assign sll_o    = (alu_o&fn3_1_o)|(imm_o&fn3_1_o);                  //SLL, SLLI
    assign slt_o    = (alu_o&fn3_2_o)|(imm_o&fn3_2_o);                  //SLT, SLTI
    assign sltu_o   = (alu_o&fn3_3_o)|(imm_o&fn3_3_o);                  //SLTU, SLTIU
    assign xor_o    = (alu_o&fn3_4_o)|(imm_o&fn3_4_o);                  //XOR, XORI
    assign srl_o    = (alu_o&fn3_5_o&!func7)|(imm_o&fn3_5_o&!func7);    //SRL, SRLI
    assign sra_o    = (alu_o&fn3_5_o&func7)|(imm_o&fn3_5_o&func7);      //SRA, SRAI
    assign or_o     = (alu_o&fn3_6_o)|(imm_o&fn3_6_o);                  //OR, ORI
    assign and_o    = (alu_o&fn3_7_o)|(imm_o&fn3_7_o);                  //AND, ANDI
    assign alu_jalr_o = jalr_o; //Add and then trim

    // JAL, JALR //
    assign jal_sel = jal_o | jalr_o;
    //-----------//
    assign mem_byte = (load_o&fn3_0_o)|(store_o&fn3_0_o); 
    assign mem_half = (load_o&fn3_1_o)|(store_o&fn3_1_o);  
    assign mem_word = (load_o&fn3_2_o)|(store_o&fn3_2_o); 
    assign mem_byte_u = (load_o&fn3_4_o);  
    assign mem_half_u = (load_o&fn3_5_o); 

    // ALU FUNC values 		
    parameter func_ADD  	= 4'b0000, 
		func_SUB 	= 4'b0001,  
		func_SLL 	= 4'b0010,
		func_SLT  	= 4'b0011,
		func_SLTU 	= 4'b0100,
		func_XOR 	= 4'b0101,
		func_SRL	= 4'b0110,
		func_SRA 	= 4'b0111,
		func_OR  	= 4'b1000,
		func_AND 	= 4'b1001,
		func_ADD_JALR =4'b1010;

    parameter bit8  = 3'b000,
        bit_u8  = 3'b001,
        bit16   = 3'b010,
        bit_u16 = 3'b011,
        bit32   = 3'b100;

    //MUX Selects
    assign mux_a_sel = !rst ? 0 : 
                       (jal_o|lui_o|auipc_o) ? 1 : 0; 
    assign mux_b_sel = !rst ? 0 :
                       (lui_o|auipc_o|jal_o|jalr_o|load_o|store_o|imm_o)? 1 : 0; 
    
    assign pc_next_sel = !rst ? 0 :
                         (jalr_o) ? 1 : 0;
    
    assign pc_add_sel = !rst ? 0 :
                        (jal_o|eq_o|neq_o|lt_o|ltu_o|ge_o|geu_o)? 1 : 0;
    
    assign reg_we_temp = (!rst ? 0 :
                         lui_o|auipc_o|jal_o|jalr_o|alu_o|imm_o|load_o)? 1 : 0; 
    assign reg_we = !rst ? 0 :
                    reg_we_temp & |rd & rst; //Disable if rd=0
    
    assign mem_we = !rst ? 0 : store_o;

    assign rd_sel = !rst ? 0 :
                    (lui_o)         ? 2'b01 :
                    (jalr_o|jal_o)  ? 2'b10 : 
                    //(delayed_load)        ? 2'b11 :   
                    (load_o)        ? 2'b11 :  
                    2'b0;
  /* 
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
          sx_size = 3'b0;
        end
        else if(load_o |store_o) begin
                sx_size =  mem_byte ? bit8 :   
                           mem_half ? bit16 :
                           mem_word ? bit32 :
                           mem_byte_u ? bit_u8 :   
                           mem_half_u ? bit_u16 :
                           3'b0;                        //Memory Formatting
        end
    end
*/
assign sx_size = !rst ? 3'b0 : 
                 !(load_o | store_o) ? 3'b0:
                 mem_byte ? bit8 :   
                 mem_half ? bit16 :
                 mem_word ? bit32 :
                 mem_byte_u ? bit_u8 :   
                 mem_half_u ? bit_u16 :
                 3'b0;

 //   assign stall = rst & load_o;
  //  assign stall = 1'b0;
    assign alu_func =   !rst        ? 4'b0 :
                        (add_o)     ? func_ADD :   
                        (sub_o)     ? func_SUB :
                        (sll_o)     ? func_SLL :
                        (slt_o)     ? func_SLT :   
                        (sltu_o)    ? func_SLTU :
                        (xor_o)     ? func_XOR :
                        (srl_o)     ? func_SRL :
                        (sra_o)     ? func_SRA :
                        (or_o)      ? func_OR :
                        (and_o)     ? func_AND :
                        (jalr_o)    ? func_ADD_JALR :
                        4'b0; 


    //RISCV Crypto

    assign scalar_crypto_op_imm = !rst ? 0 : imm_o & fn3_1_o & instruction[28] & ~(|({instruction[31:29],instruction[27:25]}));
    assign scalar_crypto_op     = !rst ? 0 : alu_o & fn3_0_o & instruction[28] &  (|({instruction[31:29],instruction[27:25]}));
    assign is_scalar_crypto     = !rst ? 0 : scalar_crypto_op | scalar_crypto_op_imm ;

    assign is_scalar_crypto_hash  = !rst ? 0 : ~instruction[29];
    assign is_scalar_crypto_block = !rst ? 0 : instruction[29];

    assign scalar_crypto_sha256 =!rst ? 0 : instruction[24:22] == 3'b000;

    assign op_ssha256_sum0  = !rst ? 0 : scalar_crypto_op_imm & scalar_crypto_sha256 & instruction[21:20] == 2'b00;// & is_scalar_crypto_hash; //      SHA256 Sum 0
    assign op_ssha256_sum1  = !rst ? 0 : scalar_crypto_op_imm & scalar_crypto_sha256 & instruction[21:20] == 2'b01;// & is_scalar_crypto_hash; //      SHA256 Sum 1
    assign op_ssha256_sig0  = !rst ? 0 : scalar_crypto_op_imm & scalar_crypto_sha256 & instruction[21:20] == 2'b10;// & is_scalar_crypto_hash; //      SHA256 Sigma 0
    assign op_ssha256_sig1  = !rst ? 0 : scalar_crypto_op_imm & scalar_crypto_sha256 & instruction[21:20] == 2'b11;// & is_scalar_crypto_hash; //      SHA256 Sigma 1

    wire [1:0] bs;
    
    assign bs = !rst ? 0 : instruction[31:30];

    assign crypto_instruction = {
     bs, 1'b0 ,1'b0,1'b0,1'b0,
     op_ssha256_sig0,op_ssha256_sig1,op_ssha256_sum0,op_ssha256_sum1, 
     1'b0, 1'b0 ,1'b0,1'b0 ,1'b0,1'b0 ,
     1'b0 ,1'b0,  
     1'b0 ,1'b0
    };


    
endmodule