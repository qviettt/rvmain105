module core(pc_out, clk, rst_n, instruction, rs2_val_sx, alu_addr, mem_we_in, mem_out, instruction);
    input rst_n;
	input clk;
	input [31:0] instruction; //Data Memory Output, Insn Mem Output
	output [31:0] pc_out;
	//Wires
	//DMEM
	input [31:0] mem_out;
	output [3:0] mem_we_in;
	output [31:0] alu_addr;
	output [31:0] rs2_val_sx;
	wire [2:0] sx_size;
	wire [31:0] mem_out_sx;
	wire mem_we;
	wire [31:0] delayed_addr;
	wire load_o;
	wire [4:0] delayed_rd;
  //ALU
  wire [31:0] mux_a_out;
  wire [31:0] mux_b_out;
  wire mux_a_sel;
  wire mux_b_sel;
  wire [3:0] alu_func;
  wire [31:0] alu_out;
	//Register File
//	wire reg_we;
//	wire [31:0] instruction_mux_out;
	wire [4:0] rs1, rs2, rd;
	wire [31:0] rd_val, rs1_val, rs2_val;
	wire [1:0] rd_sel;

	//Program Counter
	wire [31:0] pc, pc_add_out, pc_add_in, pc_mux_out;
	wire pc_next_sel, pc_add_sel;

    wire [31:0] imm_x;
// JAL, JALR
  wire jal_sel;
  wire [31:0] pc_add_out_next;  
//CRYPTO
  wire [19:0] crypto_insn;
  wire [31:0] crypto_rd;
  wire is_scalar_crypto;
 	wire [31:0] rd_mux_out;
  
	assign pc_out = pc;
	assign alu_addr = alu_out;
	

	//Datapath

	//Register File
register_bank register_file(
	.clk 	 (clk)		,
	.rst_n	 (rst_n)	,  // Reset Neg
	.reg_we	 (reg_we)	,
	.rs1	 (rs1)		,  // Address of r1 Read
	.rs2     (rs2)		,  // Address of r2 Read
	.rd		 (rd)		,  // Addres of Write Register
	.rd_val	 (rd_mux_out)	,  // Data to write
	.rs1_val (rs1_val)	,  // Output register 1
	.rs2_val (rs2_val)	   // Output register 2
	);
	
	mux32four rd_mux(
	.i0(alu_out)		,
	.i1(imm_x)			,
	.i2(pc_add_out_next),
	.i3(mem_out_sx)		,
	.sel(rd_sel)		,
	.out(rd_val)
	);

	
	mux32two jal_mux(
	.i0 (pc_add_out), .i1 (pc_out+32'd4), .sel (jal_sel), .out (pc_add_out_next));
	//Memory

	mbr_sx_load mem_to_reg(
	.sx(mem_out_sx)			, 
	.mbr(mem_out)		, 
	.size(sx_size)		, 
	.delayed_addr(delayed_addr)
);
	
	mbr_sx_store reg_to_mem(
  //.rst(ext_reset)     ,  
	.sx(rs2_val_sx)		, 
	.w_en(mem_we_in)	,	 
	.mbr(rs2_val)		, 
	.size(sx_size)		, 
	.mem_we(mem_we)		, 
	.addr(alu_out)
);

/*
load_stall stall_unit(
	.delayed_rd(delayed_rd)			, 
	.delayed_addr(delayed_addr)	, 
	.delayed_load(delayed_load)		, 
	.lxx_in(stall)					, 
	.rd(instruction[11:7]) 			, 
	.alu_out(alu_out) 				, 
	.clk(clk) 						, 
	.rst(rst_n)
	);
*/

	//Program Counter
	mux32two pc_add_mux(
	.i0 (32'h4), .i1 (imm_x), .sel (pc_add_sel), .out (pc_add_in));
	
	add32 pc_adder (
	.sum (pc_add_out), .A (pc), .B(pc_add_in));
	
	mux32two pc_mux(
	.i0 (pc_add_out), .i1(alu_out), .sel(pc_next_sel), .out(pc_mux_out));
	
//	mux32two stall_mux(
//	.i0 (pc_mux_out), .i1(pc), .sel(1'b0), .out(new_pc_in));

	
	program_counter pc_latch(
		.D(pc_mux_out),.clk(clk),.rst(rst_n),.Q(pc));


	//ALU
	mux32two alu_a_mux(
	.i0 (rs1_val), .i1 (pc), .sel (mux_a_sel), .out (mux_a_out));
	//mux_a_sel
	mux32two alu_b_mux (
	.i0 (rs2_val), .i1 (imm_x), .sel (mux_b_sel), .out (mux_b_out));
	//mux_b_sel
	alu core_alu(
//   .rst(ext_reset)     ,  
	.alu_out(alu_out)	, 
	.eq(eq)				, 
	.a_lt_b(a_lt_b)		, 
	.a_lt_ub(a_lt_ub)	, 
	.func(alu_func)		, 
	.A(mux_a_out)		, 
	.B(mux_b_out)
	);

	//Control Unit
//	parameter NOP_STALL = 32'b00000000000000000000000000010011; // no operation signal which is equivalent to addi x0, x0, 0

//	mux32two instruction_mux(
//	.i0 (instruction), .i1 (NOP_STALL), .sel (delayed_load), .out (instruction_mux_out));

	wire sysi_o;

control_unit core_control(
	.imm_val(imm_x)			, 
	.rs1(rs1)				, 
	.rs2(rs2)				, 
	.rd(rd)					, 
	.mux_a_sel(mux_a_sel)	, 
	.mux_b_sel(mux_b_sel)	,	 
	.alu_func(alu_func)		, 
	.is_scalar_crypto(is_scalar_crypto),
	.is_bitmanip(is_bitmanip),
	.rd_sel(rd_sel)			, 
	.reg_we(reg_we), 
	.pc_add_sel(pc_add_sel)	, 
	.pc_next_sel(pc_next_sel), 
	.mem_we(mem_we)			, 
	.sx_size(sx_size)		, 
	.crypto_instruction(crypto_insn),
	.bitmanip_instruction(bitmanip_insn),
	.sysi_o(sysi_o)			,
	.eq(eq) 				, 
	.a_lt_b(a_lt_b)			, 
	.a_lt_ub(a_lt_ub)		,	 
	.instruction(instruction), 
	.clk(clk)				, 
	.rst(rst_n) ,  
    .jal_sel(jal_sel),
	.load_o(load_o)
);

	//Scalar Crypto
	mux32three crypto_mux(
	.i0 (rd_val), .i1 (crypto_rd), .i2(0), .sel ({1'b0, is_scalar_crypto}), .out (rd_mux_out));

	riscv_crypto_fu crypto_fu(
	.rs1(rs1_val), 
	.rs2(rs2_val), 
	.instruction(crypto_insn), 
	.rd(crypto_rd)
);


endmodule