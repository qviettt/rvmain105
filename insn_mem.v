module insn_mem (insn, insn_addr);

	input [31:0] insn_addr;
	output [31:0] insn;	 
	reg [31:0] mem [0:200];
	

  initial begin
        $readmemh("mem_nor.bin", mem);
  end
	assign insn = mem[insn_addr[11:2]];
		       

endmodule
