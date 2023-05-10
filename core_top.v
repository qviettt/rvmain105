module core_top(clk,reset, sha256);
	input clk;
	input reset;
  output [255:0] sha256;

	wire [31:0] mem_out; //Data Memory Output
	wire [31:0] rs2_val_sx, alu_addr; //Data Memory Input, Address Input
	wire [3:0] mem_we_in; //Input to Data Memory - Write Enable
	wire [31:0] instruction;
	wire [31:0] pc_out;

  
  assign sha256 = {main_core.register_file.regFile[10],
                   main_core.register_file.regFile[11],
                   main_core.register_file.regFile[12],
                   main_core.register_file.regFile[13],
                   main_core.register_file.regFile[14],
                   main_core.register_file.regFile[15],
                   main_core.register_file.regFile[16],
                   main_core.register_file.regFile[17]};
    core main_core(
    .rs2_val_sx(rs2_val_sx),
    .alu_addr(alu_addr),
    .mem_we_in(mem_we_in),
    .pc_out(pc_out),
    .clk(clk),
    .rst_n(reset),
    .mem_out(mem_out),
    .instruction(instruction)
  );
	

	data_mem data_memory( 
	.dout(mem_out)		, 
	.addr(alu_addr)		, 
	.clk(clk)			, 
	.din(rs2_val_sx)	,
	.mem_we(mem_we_in)
);

	
	insn_mem insn_memory( 
	.insn(instruction)	,
	.insn_addr(pc_out)
	);

endmodule


