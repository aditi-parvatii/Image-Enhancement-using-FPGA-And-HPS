module image_write
#(parameter Im_width 	= 768,							
			Im_height 	= 512,								
			INFILE  = "output2.bmp",						
			BMP_HEADER_NUM = 54							
)
(
	input clk,												
	input Reset,											
	input hsync,																
    input [7:0]  R0_write,						
    input [7:0]  G0_write,						
    input [7:0]  B0_write,						
    input [7:0]  R1_write,						
    input [7:0]  G1_write,						
    input [7:0]  B1_write,	
	input [7:0]  R2_write,						
    input [7:0]  G2_write,						
    input [7:0]  B2_write,	
	output 	reg	 Write_Done
);	
integer BMP_header [0 : BMP_HEADER_NUM - 1];		
reg [7:0] out_BMP  [0 : Im_width*Im_height*3 - 1];		
reg [18:0] data_count;									
wire done;													
integer i;
integer k, l, m;
integer fd; 
initial begin
	BMP_header[ 0] = 66;BMP_header[28] =24;
	BMP_header[ 1] = 77;BMP_header[29] = 0;
	BMP_header[ 2] = 54;BMP_header[30] = 0;
	BMP_header[ 3] =  0;BMP_header[31] = 0;
	BMP_header[ 4] = 18;BMP_header[32] = 0;
	BMP_header[ 5] =  0;BMP_header[33] = 0;
	BMP_header[ 6] =  0;BMP_header[34] = 0;
	BMP_header[ 7] =  0;BMP_header[35] = 0;
	BMP_header[ 8] =  0;BMP_header[36] = 0;
	BMP_header[ 9] =  0;BMP_header[37] = 0;
	BMP_header[10] = 54;BMP_header[38] = 0;
	BMP_header[11] =  0;BMP_header[39] = 0;
	BMP_header[12] =  0;BMP_header[40] = 0;
	BMP_header[13] =  0;BMP_header[41] = 0;
	BMP_header[14] = 40;BMP_header[42] = 0;
	BMP_header[15] =  0;BMP_header[43] = 0;
	BMP_header[16] =  0;BMP_header[44] = 0;
	BMP_header[17] =  0;BMP_header[45] = 0;
	BMP_header[18] =  0;BMP_header[46] = 0;
	BMP_header[19] =  3;BMP_header[47] = 0;
	BMP_header[20] =  0;BMP_header[48] = 0;
	BMP_header[21] =  0;BMP_header[49] = 0;
	BMP_header[22] =  0;BMP_header[50] = 0;
	BMP_header[23] =  2;BMP_header[51] = 0;	
	BMP_header[24] =  0;BMP_header[52] = 0;
	BMP_header[25] =  0;BMP_header[53] = 0;
	BMP_header[26] =  1;
	BMP_header[27] =  0;
end
always@(posedge clk,negedge Reset) begin
    if(!Reset) begin
        l <= 0;
        m <= 0;
    end else begin
        if(hsync) begin
            if(m == Im_width/3-1) begin
                m <= 0;
                l <= l + 1; 
            end else begin
                m <= m + 1; 
            end
        end
    end
end
always@(posedge clk,negedge Reset) begin
    if(!Reset) begin
        for(k=0;k<Im_width*Im_height*3;k=k+1) begin
            out_BMP[k] <= 0;
        end
    end else begin
        if(hsync) begin
            out_BMP[Im_width*3*(Im_height-l-1)+9*m+2] <= R0_write;
            out_BMP[Im_width*3*(Im_height-l-1)+9*m+1] <= G0_write;
            out_BMP[Im_width*3*(Im_height-l-1)+9*m  ] <= B0_write;
            out_BMP[Im_width*3*(Im_height-l-1)+9*m+5] <= R1_write;
            out_BMP[Im_width*3*(Im_height-l-1)+9*m+4] <= G1_write;
            out_BMP[Im_width*3*(Im_height-l-1)+9*m+3] <= B1_write;
        end
    end
end
always@(posedge clk,negedge Reset)
begin
    if(~Reset) begin
        data_count <= 0;
    end
    else begin
        if(hsync)
			data_count <= data_count + 1;
    end
end
assign done = (data_count == 131071)? 1'b1: 1'b0; 
always@(posedge clk,negedge Reset)
begin
    if(~Reset) begin
        Write_Done <= 0;
    end
    else begin
		Write_Done <= done;
    end
end
initial begin
    fd = $fopen(INFILE, "wb+");
end
always@(Write_Done) begin 
    if(Write_Done == 1'b1) begin
        for(i=0; i<BMP_HEADER_NUM; i=i+1) begin
            $fwrite(fd, "%c", BMP_header[i][7:0]);
        end
        for(i=0; i<Im_width*Im_height*3; i=i+6) begin
            $fwrite(fd, "%c", out_BMP[i  ][7:0]);
            $fwrite(fd, "%c", out_BMP[i+1][7:0]);
            $fwrite(fd, "%c", out_BMP[i+2][7:0]);
            $fwrite(fd, "%c", out_BMP[i+3][7:0]);
            $fwrite(fd, "%c", out_BMP[i+4][7:0]);
            $fwrite(fd, "%c", out_BMP[i+5][7:0]);
        end
    end
end
endmodule