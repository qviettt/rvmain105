module load_stall(delayed_rd, delayed_addr, delayed_load, lxx_in, rd, alu_out, clk, rst);

	input lxx_in, clk, rst;
	input [4:0] rd;
	input [31:0] alu_out;

	output reg [4:0] delayed_rd;
	output reg [31:0] delayed_addr;
	output reg delayed_load;

	always @(posedge clk or negedge rst)
	if (!rst) begin
	  delayed_load = 1'b0;
	  delayed_addr = 31'd0;
	  delayed_rd = 5'd0;
	end
	else begin
		delayed_load <= lxx_in & rst;
		delayed_rd <= rd;
		delayed_addr <= alu_out;
	end

endmodule