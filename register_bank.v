module register_bank(rst_n,clk,reg_we,rs1,rs2,rd,rd_val,rs1_val,rs2_val);

 input rst_n,clk,reg_we;
 input [4:0] rs1,rs2,rd;
 input [31:0] rd_val;
 output [31:0] rs1_val,rs2_val;
  
 reg [31:0] regFile [0:31];
  
//  integer i;
//  initial begin
//    for (i = 0; i < 32; i = i + 1) begin
//       regFile[i] = 0;
//    end
//  end
integer file, i;
initial begin
        file = $fopen("RegFiles_Content.txt", "w");

        //while (!in_exe_finished) begin
            #5000;
        //end

        for (i = 0; i < 32; i = i + 1) begin
            $fwrite(file, "%d", regFile[i], "\n");
        end 

        $fclose(file);
 end
    
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      regFile[0] <= 32'd0;
      regFile[1] <= 32'd0;
      regFile[2] <= 32'd0;
      regFile[3] <= 32'd0;
      regFile[4] <= 32'd0;
      regFile[5] <= 32'd0;
      regFile[6] <= 32'd0;
      regFile[7] <= 32'd0;
      regFile[8] <= 32'd0;
      regFile[9] <= 32'd0;
      regFile[10] <= 32'd0;
      regFile[11] <= 32'd0;
      regFile[12] <= 32'd0;
      regFile[13] <= 32'd0;
      regFile[14] <= 32'd0;
      regFile[15] <= 32'd0;
      regFile[16] <= 32'd0;
      regFile[17] <= 32'd0;
      regFile[18] <= 32'd0;
      regFile[19] <= 32'd0;
      regFile[20] <= 32'd0;
      regFile[21] <= 32'd0;
      regFile[22] <= 32'd0;
      regFile[23] <= 32'd0;
      regFile[24] <= 32'd0;
      regFile[25] <= 32'd0;
      regFile[26] <= 32'd0;
      regFile[27] <= 32'd0;
      regFile[28] <= 32'd0;
      regFile[29] <= 32'd0;
      regFile[30] <= 32'd0;
      regFile[31] <= 32'd0;
    end
    else begin
      if(reg_we && rd) begin// reg 0 luon = 0
        regFile[rd] <= rd_val;
      end
    end
  end
  
 // assign rs1_val = (rs1 != 5'b0) ? //ko xai reg x0 = 0,
   //                   (((reg_we == 1'b1)&&(rs1 == rd)) ? // neu doc va ghi cung 1 reg thi g/tri doc = g/tri ghi
     //                 rd_val : regFile[rs1]) : 32'b0;
                      
  //assign rs2_val = (rs2 != 5'b0) ? //ko xai reg x0 = 0
    //                  (((reg_we == 1'b1)&&(rs2 == rd)) ? 
      //               rd_val : regFile[rs2]) : 32'b0;

  assign rs1_val = regFile[rs1];
  assign rs2_val = regFile[rs2];

endmodule

