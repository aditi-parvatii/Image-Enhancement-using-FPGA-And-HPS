`timescale 1ns/1ps 
`include "operation.v"			

module tb_simulation;
reg clk, Reset;
wire vsync;
wire hsync;
wire [ 7 : 0] data_R0;
wire [ 7 : 0] data_G0;
wire [ 7 : 0] data_B0;
wire [ 7 : 0] data_R1;
wire [ 7 : 0] data_G1;
wire [ 7 : 0] data_B1;
wire [ 7 : 0] data_R2;
wire [ 7 : 0] data_G2;
wire [ 7 : 0] data_B2;
wire enc_done;
image_read 
#(.INFILE(`Inputfile))
	u_image_read
( 
    .clk(clk),
    .Reset(Reset),
    .Vsync(vsync),
    .Hsync(hsync),
    .R0_out(data_R0 ),
    .G0_out(data_G0 ),
    .B0_out(data_B0 ),
    .R1_out(data_R1 ),
    .G1_out(data_G1 ),
    .B1_out(data_B1 ),
	.R2_out(data_R2 ),
    .G2_out(data_G2 ),
    .B2_out(data_B2 ),
	.flag(enc_done)
); 

image_write 
#(.INFILE(`Outputfile))
	u_image_write
(
	.clk(clk),
	.Reset(Reset),
	.hsync(hsync),
   .R0_write(data_R0),
   .G0_write(data_G0),
   .B0_write(data_B0),
   .R1_write(data_R1),
   .G1_write(data_G1),
   .B1_write(data_B1),
   .R2_write(data_R2),
   .G2_write(data_G2),
   .B2_write(data_B2),
	.Write_Done()
);	
initial begin 
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    Reset  = 0;
    #25 Reset = 1;
end


endmodule
