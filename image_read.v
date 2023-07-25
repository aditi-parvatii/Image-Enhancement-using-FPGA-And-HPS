`include "operation.v" 						
module image_read
#(
  parameter Im_width 	= 768, 					
			Im_height 	= 512, 						
			INFILE  = "hexop.hex", 	
			Vsync_delay = 100, 				
			Hsync_delay = 160,					
			brt_value= 100,								
			THRESHOLD= 90,
			SIGN=1,																				
			valueToAdd = 10,					
			valueToSubstract = 15
			
)
(
	input clk,															
	input Reset,									
	output Vsync,								
	output reg Hsync,								
    output reg [7:0]  R0_out,				
    output reg [7:0]  G0_out,				
    output reg [7:0]  B0_out,				
    output reg [7:0]  R1_out,				
    output reg [7:0]  G1_out,				
    output reg [7:0]  B1_out,
	output reg [7:0]  R2_out,				
    output reg [7:0]  G2_out,				
    output reg [7:0]  B2_out,
	output flag					
);			

parameter clour_bit = 8;					
parameter Ttl_rgb = 1179648; 		
localparam		Idle_st 	= 2'b00,		
				Vsync_st	= 2'b01,			
				Hsync_st	= 2'b10,			
				Data_st		= 2'b11;		
reg [1:0] cstate, 						
		  nstate;									
reg start;									
reg Reset_d;								
reg 		Vsync_run; 				
reg [8:0]	Vsync_cnt;			
reg 		Hsync_run;				
reg [8:0]	Hsync_cnt;			
reg 		Data_run;					
reg [7 : 0]   total_memory [0 : Ttl_rgb-1];	
integer temp_BMP   [0 : Im_width*Im_height*3 - 1];			
integer org_R  [0 : Im_width*Im_height - 1]; 	
integer org_G  [0 : Im_width*Im_height - 1];	
integer org_B  [0 : Im_width*Im_height - 1];	
integer i, j;
integer tempR0,tempR1,tempG0,tempG1,tempB0,tempB1,tempR2,tempG2,tempB2; 
integer value,value1,value2,value4,value6;
reg [ 9:0] row; 
reg [10:0] col; 
reg [18:0] data_count; 

initial begin
    $readmemh(INFILE,total_memory,0,Ttl_rgb-1); 
end

always@(start) begin
    if(start == 1'b1) begin
        for(i=0; i<Im_width*Im_height*3 ; i=i+1) begin
            temp_BMP[i] = total_memory[i+0][7:0]; 
        end
        
        for(i=0; i<Im_height; i=i+1) begin
            for(j=0; j<Im_width; j=j+1) begin
                org_R[Im_width*i+j] = temp_BMP[Im_width*3*(Im_height-i-1)+3*j+0]; 
                org_G[Im_width*i+j] = temp_BMP[Im_width*3*(Im_height-i-1)+3*j+1];
                org_B[Im_width*i+j] = temp_BMP[Im_width*3*(Im_height-i-1)+3*j+2];
            end
        end
    end
end

always@(posedge clk,negedge Reset)
begin
    if(!Reset) begin
        start <= 0;
		Reset_d <= 0;
    end
    else begin											       					
        Reset_d <= Reset;							
		if(Reset == 1'b1 && Reset_d == 1'b0)		
			start <= 1'b1;
		else
			start <= 1'b0;
    end
end


always@(posedge clk,negedge Reset)
begin
    if(~Reset) begin
        cstate <= Idle_st;
    end
    else begin
        cstate <= nstate; 
    end
end

always @(*) begin
	case(cstate)
		Idle_st: begin
			if(start)
				nstate = Vsync_st;
			else
				nstate = Idle_st;
		end			
		Vsync_st: begin
			if(Vsync_cnt == Vsync_delay) 
				nstate = Hsync_st;
			else
				nstate = Vsync_st;
		end
		Hsync_st: begin
			if(Hsync_cnt == Hsync_delay) 
				nstate = Data_st;
			else
				nstate = Hsync_st;
		end		
		Data_st: begin
			if(flag)
				nstate = Idle_st;
			else begin
				if(col == Im_width - 3)
					nstate = Hsync_st;
				else
					nstate = Data_st;
			end
		end
	endcase
end

always @(*) begin
	Vsync_run = 0;
	Hsync_run = 0;
	Data_run  = 0;
	case(cstate)
		Vsync_st: 	begin Vsync_run = 1; end 	
		Hsync_st: 	begin Hsync_run = 1; end	
		Data_st: 	begin Data_run  = 1; end	
	endcase
end

always@(posedge clk,negedge Reset)
begin
    if(~Reset) begin
        Vsync_cnt <= 0;
		Hsync_cnt <= 0;
    end
    else begin
        if(Vsync_run)
			Vsync_cnt <= Vsync_cnt + 1; 
		else 
			Vsync_cnt <= 0;
			
        if(Hsync_run)
			Hsync_cnt <= Hsync_cnt + 1;		
		else
			Hsync_cnt <= 0;
    end
end

always@(posedge clk,negedge Reset)
begin
    if(~Reset) begin
        row <= 0;
		col <= 0;
    end
	else begin
		if(Data_run) begin
			if(col == Im_width - 3) begin
				row <= row + 1;
			end
			if(col == Im_width - 3) 
				col <= 0;
			else 
				col <= col + 3; 
		end
	end
end

always@(posedge clk,negedge Reset)
begin
    if(~Reset) begin
        data_count <= 0;
    end
    else begin
        if(Data_run)
			data_count <= data_count + 1;
    end
end
assign Vsync = Vsync_run;
assign flag = (data_count == 131071)? 1'b1: 1'b0; 

always @(*) begin
	
	Hsync   = 1'b0;
	R0_out = 0;
	G0_out = 0;
	B0_out = 0;                                       
	R1_out = 0;
	G1_out = 0;
	B1_out = 0; 
    R2_out = 0;
	G2_out = 0;
	B2_out = 0; 	
	if(Data_run) begin
		
		Hsync   = 1'b1;
		`ifdef BRIGHTNESS_OPERATION	
		
		if(SIGN == 1) begin
		
		tempR0 = org_R[Im_width * row + col   ] + brt_value;
		if (tempR0 > 255)
			R0_out = 255;
		else
			R0_out = org_R[Im_width * row + col   ] + brt_value;
			
		tempR1 = org_R[Im_width * row + col+1   ] + brt_value;
		if (tempR1 > 255)
			R1_out = 255;
		else
			R1_out = org_R[Im_width * row + col+1   ] + brt_value;	
		
		tempR2 = org_R[Im_width * row + col+2   ] + brt_value;
		if (tempR2 > 255)
			R2_out = 255;
		else
			R2_out = org_R[Im_width * row + col+2   ] + brt_value;
		
		tempG0 = org_G[Im_width * row + col   ] + brt_value;
		if (tempG0 > 255)
			G0_out = 255;
		else
			G0_out = org_G[Im_width * row + col   ] + brt_value;
		tempG1 = org_G[Im_width * row + col+1   ] + brt_value;
		if (tempG1 > 255)
			G1_out = 255;
		else
			G1_out = org_G[Im_width * row + col+1   ] + brt_value;		
		tempG2 = org_G[Im_width * row + col+2   ] + brt_value;
		if (tempG2 > 255)
			G2_out = 255;
		else
			G2_out = org_G[Im_width * row + col+2   ] + brt_value;	
			
		tempB0 = org_B[Im_width * row + col   ] + brt_value;
		if (tempB0 > 255)
			B0_out = 255;
		else
			B0_out = org_B[Im_width * row + col   ] + brt_value;
		tempB1 = org_B[Im_width * row + col+1   ] + brt_value;
		if (tempB1 > 255)
			B1_out = 255;
		else
			B1_out = org_B[Im_width * row + col+1   ] + brt_value;
		tempB2 = org_B[Im_width * row + col+2   ] + brt_value;
		if (tempB2 > 255)
			B2_out = 255;
		else
			B2_out = org_B[Im_width * row + col+2   ] + brt_value;
	end
	else begin
	
		tempR0 = org_R[Im_width * row + col   ] - brt_value;
		if (tempR0 < 0)
			R0_out = 0;
		else
			R0_out = org_R[Im_width * row + col   ] - brt_value;
		
		tempR1 = org_R[Im_width * row + col+1   ] - brt_value;
		if (tempR1 < 0)
			R1_out = 0;
		else
			R1_out = org_R[Im_width * row + col+1   ] - brt_value;	
		tempR2 = org_R[Im_width * row + col+2   ] - brt_value;
		if (tempR2 < 0)
			R2_out = 0;
		else
			R2_out = org_R[Im_width * row + col+2   ] - brt_value;	
			
		tempG0 = org_G[Im_width * row + col   ] - brt_value;
		if (tempG0 < 0)
			G0_out = 0;
		else
			G0_out = org_G[Im_width * row + col   ] - brt_value;
		tempG1 = org_G[Im_width * row + col+1   ] - brt_value;
		if (tempG1 < 0)
			G1_out = 0;
		else
			G1_out = org_G[Im_width * row + col+1   ] - brt_value;		
		tempG2 = org_G[Im_width * row + col+2   ] - brt_value;
		if (tempG2 < 0)
			G2_out = 0;
		else
			G2_out = org_G[Im_width * row + col+2   ] - brt_value;		
	
		tempB0 = org_B[Im_width * row + col   ] - brt_value;
		if (tempB0 < 0)
			B0_out = 0;
		else
			B0_out = org_B[Im_width * row + col   ] - brt_value;
		tempB1 = org_B[Im_width * row + col+1   ] - brt_value;
		if (tempB1 < 0)
			B1_out = 0;
		else
			B1_out = org_B[Im_width * row + col+1   ] - brt_value;
		tempB2 = org_B[Im_width * row + col+2   ] - brt_value;
		if (tempB2 < 0)
			B2_out = 0;
		else
			B2_out = org_B[Im_width * row + col+2   ] - brt_value;
	 end
		`endif
	
		
		`ifdef INVERT_OPERATION	
			value2 = (org_B[Im_width * row + col  ] + org_R[Im_width * row + col  ] +org_G[Im_width * row + col  ])/3;
			R0_out=255-value2;
			G0_out=255-value2;
			B0_out=255-value2;
			value4 = (org_B[Im_width * row + col+1  ] + org_R[Im_width * row + col+1  ] +org_G[Im_width * row + col+1  ])/3;
			R1_out=255-value4;
			G1_out=255-value4;
			B1_out=255-value4;	
			value6 = (org_B[Im_width * row + col+2  ] + org_R[Im_width * row + col+2  ] +org_G[Im_width * row + col+2  ])/3;
			R2_out=255-value6;
			G2_out=255-value6;
			B2_out=255-value6;	
		`endif
		
		`ifdef THRESHOLD_OPERATION

		value = (org_R[Im_width * row + col   ]+org_G[Im_width * row + col   ]+org_B[Im_width * row + col   ])/3;
		if(value > THRESHOLD) begin
			R0_out=255;
			G0_out=255;
			B0_out=255;
		end
		else begin
			R0_out=0;
			G0_out=0;
			B0_out=0;
		end
		value1 = (org_R[Im_width * row + col+1   ]+org_G[Im_width * row + col+1   ]+org_B[Im_width * row + col+1   ])/3;
		if(value1 > THRESHOLD) begin
			R1_out=255;
			G1_out=255;
			B1_out=255;
		end
		else begin
			R1_out=0;
			G1_out=0;
			B1_out=0;
		end	
		value2 = (org_R[Im_width * row + col+2   ]+org_G[Im_width * row + col+2   ]+org_B[Im_width * row + col+2   ])/3;
		if(value2 > THRESHOLD) begin
			R2_out=255;
			G2_out=255;
			B2_out=255;
		end
		else begin
			R2_out=0;
			G2_out=0;
			B2_out=0;
		end	
		`endif
		
		
		`ifdef CONTRAST_OPERATION
		value1 = (org_R[Im_width * row + col ]+org_G[Im_width * row + col   ]+org_B[Im_width * row + col   ])/3;
		value2 = (org_R[Im_width * row + col +1]+org_G[Im_width * row + col+1 ]+org_B[Im_width * row + col+1 ])/3;
		value4 = (org_R[Im_width * row + col +2]+org_G[Im_width * row + col+2 ]+org_B[Im_width * row + col+2 ])/3;
		if(SIGN==1)begin
		if(value1>THRESHOLD)begin
			tempR0 = org_R[Im_width * row + col   ] + valueToAdd;
			tempG0 = org_G[Im_width * row + col   ] + valueToAdd;
			tempB0 = org_B[Im_width * row + col   ] + valueToAdd;
			
			if(tempR0>256)
				R0_out = 255;
			else
				R0_out = org_R[Im_width * row + col   ] + valueToAdd;
			if(tempG0>256)
				G0_out = 255;
			else
				G0_out = org_G[Im_width * row + col   ] + valueToAdd;
			if(tempB0>256)
				B0_out = 255;
			else
				B0_out = org_B[Im_width * row + col   ] + valueToAdd;
			
		end
		if(value2>THRESHOLD)begin
			tempR1 = org_R[Im_width * row + col+1 ] + valueToAdd;
			tempG1 = org_G[Im_width * row + col +1 ] + valueToAdd;
			tempB1 = org_B[Im_width * row + col +1] + valueToAdd;
			if(tempR1>256)
				R1_out = 255;
			else
				R1_out = org_R[Im_width * row + col+1 ] + valueToAdd;
			if(tempG1>256)
				G1_out = 255;
			else
				G1_out = org_G[Im_width * row + col +1 ] + valueToAdd;
			if(tempB1>256)
				B1_out = 255;
			else
				B1_out = org_B[Im_width * row + col +1] + valueToAdd;
		end
		if(value4>THRESHOLD)begin
			tempR2 = org_R[Im_width * row + col+2 ] + valueToAdd;
			tempG2 = org_G[Im_width * row + col +2 ] + valueToAdd;
			tempB2 = org_B[Im_width * row + col +2] + valueToAdd;
			if(tempR2>256)
				R2_out = 255;
			else
				R2_out = org_R[Im_width * row + col+2 ] + valueToAdd;
			if(tempG2>256)
				G2_out = 255;
			else
				G2_out = org_G[Im_width * row + col +2 ] + valueToAdd;
			if(tempB2>256)
				B2_out = 255;
			else
				B2_out = org_B[Im_width * row + col +2] + valueToAdd;
		end
		end
		if(SIGN==0)begin
		if(value1<THRESHOLD)begin
			tempR0 = org_R[Im_width * row + col   ] - valueToSubstract;
			tempG0 = org_G[Im_width * row + col   ] - valueToSubstract;
			tempB0 = org_B[Im_width * row + col   ] - valueToSubstract;
			
			if(tempR0<0)
				R0_out = 0;
			else
				R0_out = org_R[Im_width * row + col   ] - valueToSubstract;
			if(tempG0<0)
				G0_out = 0;
			else
				G0_out = org_G[Im_width * row + col   ] - valueToSubstract;
			if(tempB0<0)
				B0_out = 0;
			else
				B0_out = org_B[Im_width * row + col   ] - valueToSubstract;
			
		end
		if(value2<THRESHOLD)begin
			tempR1 = org_R[Im_width * row + col+1 ] - valueToSubstract;
			tempG1 = org_G[Im_width * row + col +1 ] - valueToSubstract;
			tempB1 = org_B[Im_width * row + col +1] - valueToSubstract;
			if(tempR1<0)
				R1_out = 0;
			else
				R1_out = org_R[Im_width * row + col+1 ] - valueToSubstract;
			if(tempG1<0)
				G1_out = 0;
			else
				G1_out = org_G[Im_width * row + col+1 ] - valueToSubstract;
			if(tempB1<0)
				B1_out = 0;
			else
				B1_out = org_B[Im_width * row + col+1 ] - valueToSubstract;
		end
		if(value4<THRESHOLD)begin
			tempR2 = org_R[Im_width * row + col+2 ] - valueToSubstract;
			tempG2 = org_G[Im_width * row + col +2 ] - valueToSubstract;
			tempB2 = org_B[Im_width * row + col +2] - valueToSubstract;
			if(tempR2<0)
				R2_out = 0;
			else
				R2_out = org_R[Im_width * row + col+2 ] - valueToSubstract;
			if(tempG2<0)
				G2_out = 0;
			else
				G2_out = org_G[Im_width * row + col+2 ] - valueToSubstract;
			if(tempB2<0)
				B2_out = 0;
			else
				B2_out = org_B[Im_width * row + col+2 ] - valueToSubstract;
		end
		end
		`endif
	end
end

endmodule