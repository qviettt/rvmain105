module data_mem (dout, addr, clk, din, mem_we);

	//read_addr and write_addr combined
	input [31:0] addr, din;
	input [3:0] mem_we;
	input clk;
	output [31:0] dout;

	reg [31:0] mem [0:200]; 

  integer i;
  initial begin
    for (i = 0; i < 121; i = i + 1) begin
       mem[i] = 32'd0;
    end
  end

	always @(posedge clk) 
		begin
		//mem[addr]<=din; addr[9:0] because 2^10=1024
			mem[addr[11:2]][7:0] <= mem_we[0] ? din[7:0] : mem[addr[11:2]][7:0];
      		mem[addr[11:2]][15:8] <= mem_we[1] ? din[15:8] : mem[addr[11:2]][15:8];
      		mem[addr[11:2]][23:16] <= mem_we[2] ? din[23:16] : mem[addr[11:2]][23:16];
      		mem[addr[11:2]][31:24] <= mem_we[3] ? din[31:24] : mem[addr[11:2]][31:24];
			//dout = mem[addr[11:2]][31:0];    
	end
	assign dout = mem[addr[11:2]][31:0];    

endmodule