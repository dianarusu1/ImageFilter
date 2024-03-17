`timescale 1ns / 1ps

module process(
	input clk,				// clock 
	input [23:0] in_pix,	// valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
	output reg [5:0] row, col, 	// selecteaza un rand si o coloana din imagine
	output reg out_we, 			// activeaza scrierea pentru imaginea de iesire (write enable)
	output reg [23:0] out_pix,	// valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
	output reg mirror_done,		// semnaleaza terminarea actiunii de oglindire (activ pe 1)
	output reg gray_done,		// semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
	output reg filter_done);	// semnaleaza terminarea actiunii de aplicare a filtrului de sharpness (activ pe 1)

// TODO add your finite state machines here
parameter S0 = 5'b00000; //stare de start
parameter S1 = 5'b00001; //stare de citire a pixelului pe row si col
parameter S2 = 5'b00010; //stare de citire a pixelului pe 63-row si col, interschimb, scriu 63-row si col
parameter S3 = 5'b00011; //stare de mirror de scriere a pixelului pe row si col, row care e salvat pe aux_row
parameter S4 = 5'b00100; //stare de mirror done
parameter S5 = 5'b00101; //stare de grayscale
parameter S6 = 5'b00110; //stare de gray_done
parameter S7 = 5'b00111; //citire in_pix ca sa vad elem in jurul caruia trebuie sa caut 
parameter S8 = 5'b01000; //citire primul pixel din matricea noastra 00
parameter S9 = 5'b01001; //citire el 01 
parameter S10 = 5'b01010;//citire el 02 
parameter S11 = 5'b01011;//citire el 10
parameter S12 = 5'b01100;//citire el 11
parameter S13 = 5'b01101;//citire el 12
parameter S14 = 5'b01110;//citire el 20
parameter S15 = 5'b01111;//citire el 21
parameter S16 = 5'b10000;//citire el 22
parameter S17 = 5'b10001;//scriem outpix
parameter S18 = 5'b10010;//filterdone


reg [5:0] state, next_state;

reg[5:0] aux_row;

reg[23:0] val1,val2,aux_val;

reg [7:0] R,G,B, max, min;

reg [3:0] matrix_convolution[0:2][0:2];
initial begin
    matrix_convolution[0][0] = -1; // -1 în binar
    matrix_convolution[0][1] = -1;
    matrix_convolution[0][2] = -1;
    matrix_convolution[1][0] = -1;
    matrix_convolution[1][1] = 9;// 9 în binar
    matrix_convolution[1][2] = -1;
    matrix_convolution[2][0] = -1;
    matrix_convolution[2][1] = -1;
    matrix_convolution[2][2] = -1;
end

reg [23:0] matrix_filter[0:2][0:2];
reg [23:0] valoare_initiala[0:2][0:63];
reg[12:0] sum_R,sum_G,sum_B;
reg[23:0] element_filtru;  
reg[5:0] linie,coloana,row_buf,col_buf;
reg[23:0] memorare_pixeli[0:1][0:63];

always @(posedge clk) begin

		state<= next_state;
		case(state)
			S0:begin
				row <= 6'b000000;
				col <= 6'b000000;
				//out_pix <= 0;
				 //aux_row <= 0;
				 //val1 <= 0;
				 //val2 <= 0;
				// aux_val <= 0;
			end
			S1: begin
				if(row <= 31)
						//val1 <= in_pix;
						//aux_row <= row;
						row <= 63 - row;
			end 
			S2:begin
				if(row >= 31)
						//val2 <= in_pix;
						row <= 63-row;
						//row <= aux_row;
						//val1 <= val2;
						//val2 <= val1;
						//out_pix <= val1;
				end
			S3: begin
						//out_pix <= val2;
						if(col <= 63) begin
							if(row == 31) begin
								row <= 0;
								col <= col+1;
							end else begin
								row <= row+1;
							end
						end 
					end
			S4: begin 
					row <= 6'b000000;
					col <= 6'b000000;
				end
			S5:begin
				if(col <= 63) begin
					if(row == 63) begin
								row <= 0;
								col <= col+1;
					end else begin
							row <= row+1;
					end
				end
			end
		  S6: begin 
					row <= 6'b000000;
					col <= 6'b000000;
				end
		 S7: begin
				row <= row - 1;
				col <= col- 1;
			end
		S8:begin
			col <= col+1;
		end
		S9:begin
			col <= col + 1;
		end
		S10:begin
			col <= col-2;
			row <= row+1;
		end
		S11:begin
			col <= col + 1;
		end
		S12:begin
			col <= col+1;
		end
		S13:begin
			row <= row+1;
			col <= col-2;
		end
		S14:begin
			col <= col + 1;
		end
		S15:begin
			col <= col + 1;
		end
		S16:begin
			row <= linie;
			col <= coloana;
		end
		S17:begin
			 if(col <= 63) begin
					if(row == 63) begin
								row <= 0;
								col <= col+1;
					end else begin
							row <= row+1;
					end
				end
		end
		endcase
end

initial begin
	state = S0;
end

always @(*) begin

  	mirror_done = 0;
	gray_done = 0;
	filter_done = 0;



	case(state)
		S0:begin
			    out_we = 0;
				 mirror_done = 0;
				 gray_done = 0;
				 filter_done = 0;
				 out_pix = 0;
				 aux_row = 0;
				 val1 = 0;
				 val2 = 0;
				 aux_val = 0;
				 next_state = S1;
				 R = 0;
				 G = 0;
				 B = 0;
				 max = 0;
				 min = 0;
		end
	 S1:begin  
			out_we = 0;
			val1 = in_pix;
			next_state = S2;
		end
	S2: begin
			val2 = in_pix;
			aux_val = val1;
			val1 = val2;
			val2 = aux_val;
			out_we=1;
			out_pix = val2;
		   next_state = S3;
		end
		//s1 row col citire 63-row tb sa fie aici, s2 63-row, col; s3 intersc, s4 scriere row, col si s5 scriere 63-row col
		//toate op tb sa fie cu un ceas in spate
	S3:begin
			out_we = 1;
			out_pix = val1;
			if(col == 63 && row == 31)
						next_state = S4; 
			else next_state = S1;
		end
	S4:begin
			mirror_done = 1;
			next_state = S5;
		end
	S5:
		begin
			out_we = 0;
			R = in_pix[23:16];
			G = in_pix[15:8];
			B = in_pix[7:0];
			if (R > B && R > G) begin
						max = R;
					if (G < B)
						min = G;
					else
						min = B;
			end else if (G > R && G > B) begin
								max = G;
								if (R < B)
									min = R;
								else
									min = B;
		 end else begin
						max = B;
						if (R < G)
							min = R;
						else
							min = G;
			end
			G = (max+min)/2;
			R = 0;
			B = 0;
			out_we=1;
			out_pix ={8'b0,G,8'b0};
			if(col == 63&& row == 63)
				next_state = S6;
			else
				next_state = S5;
		end
	S6:begin
			gray_done = 1;
			next_state = S7;
		end
	S7:begin
		out_we = 0;
		R = in_pix[23:16];
		G = in_pix[15:8];
		B = in_pix[7:0];
      if(row %2 == 1)
			row_buf = 1;
		else
			row_buf = 0;
		col_buf = col;
		element_filtru ={R,G,B};
		memorare_pixeli[row_buf][col_buf] =in_pix;
		sum_B = 0;
		sum_R = 0;
		sum_G = 0;
		next_state = S8;
		linie = row;
		coloana = col;
		next_state = S8;
	end
	S8:begin
		//R = in_pix[23:16];
		//G = in_pix[15:8];
		//B = in_pix[7:0];
		row_buf = 0;
		col_buf = col;
		if(linie == 0 || coloana == 0)
			matrix_filter[0][0] = 0;
		else if(linie > 0 && coloana > 0)
					matrix_filter[0][0] = memorare_pixeli[row_buf][col_buf];
		sum_B = sum_B + matrix_filter[0][0][7:0]*matrix_convolution[0][0];
		sum_G = sum_G+ matrix_filter[0][0][15:8]*matrix_convolution[0][0];
		sum_R = sum_R + matrix_filter[0][0][23:16]*matrix_convolution[0][0];
		next_state = S9;
	end
	S9:begin
		//R = in_pix[23:16];
		//G = in_pix[15:8];
		//B = in_pix[7:0];
		row_buf = 0;
		col_buf = col;
		if(linie == 0)
			matrix_filter[0][1] = 0;
		else begin
			matrix_filter[0][1] = memorare_pixeli[row_buf][col_buf];
		end
		sum_B = sum_B + matrix_filter[0][1][7:0]*matrix_convolution[0][1];
		sum_G = sum_G + matrix_filter[0][1][15:8]*matrix_convolution[0][1];
		sum_R = sum_R + matrix_filter[0][1][23:16]*matrix_convolution[0][1];
		next_state = S10;
	end
	S10: begin
		//R = in_pix[23:16];
		//G = in_pix[15:8];
		//B = in_pix[7:0];
		G = in_pix[15:8];
		row_buf = 0;
		col_buf = col;
		if(linie == 0 || coloana == 63) //ideea e ca ele tb sa preia in_pixul, iar in_pixul se schimba cand ai setat row si col
			matrix_filter[0][2] = 0;
		else begin
			matrix_filter[0][2] = memorare_pixeli[row_buf][col_buf];
		end
		sum_B = sum_B + matrix_filter[0][2][7:0]*matrix_convolution[0][2];
		sum_G = sum_G + matrix_filter[0][2][15:8]*matrix_convolution[0][2];
		sum_R = sum_R + matrix_filter[0][2][23:16]*matrix_convolution[0][2];
		next_state = S11;
	end
	S11:begin
		//R = in_pix[23:16];
		//G = in_pix[15:8];
		//B = in_pix[7:0];
		row_buf = 1;
		col_buf = col;
		if(coloana == 0)
			matrix_filter[1][0] = 0;
		else begin
			matrix_filter[1][0] = memorare_pixeli[row_buf][col_buf];
		end
		sum_B = sum_B + matrix_filter[1][0][7:0]*matrix_convolution[1][0];
		sum_G = sum_G + matrix_filter[1][0][15:8]*matrix_convolution[1][0];
		sum_R = sum_R + matrix_filter[1][0][23:16]*matrix_convolution[1][0];
		next_state = S12;
	end
	S12:begin
		matrix_filter[1][1] = element_filtru;
		sum_B = sum_B + matrix_filter[1][1][7:0]*matrix_convolution[1][1];
		sum_G = sum_G + matrix_filter[1][1][15:8]*matrix_convolution[1][1];
		sum_R = sum_R + matrix_filter[1][1][23:16]*matrix_convolution[1][1];
		next_state = S13;
	end
	S13:begin
		R = in_pix[23:16];
		G = in_pix[15:8];
		B = in_pix[7:0];
		if(coloana == 63)
			matrix_filter[1][2] = 0;
		else begin
			matrix_filter[1][2] = {R,G,B};
		end
		sum_B = sum_B + matrix_filter[1][2][7:0]*matrix_convolution[1][2];
		sum_G = sum_G + matrix_filter[1][2][15:8]*matrix_convolution[1][2];
		sum_R = sum_R + matrix_filter[1][2][23:16]*matrix_convolution[1][2];
		next_state = S14;
	end
	S14:begin
		R = in_pix[23:16];
		G = in_pix[15:8];
		B = in_pix[7:0];
		if(linie == 63 || coloana == 0)
			matrix_filter[2][0] = 0;
		else 
			matrix_filter[2][0] = {R,G,B};
		sum_B = sum_B + matrix_filter[2][0][7:0]*matrix_convolution[2][0];
		sum_G = sum_G + matrix_filter[2][0][15:8]*matrix_convolution[2][0];
		sum_R = sum_R + matrix_filter[2][0][23:16]*matrix_convolution[2][0];
		next_state = S15;
	end
	S15:begin
		R = in_pix[23:16];
		G = in_pix[15:8];
		B = in_pix[7:0];
		if(linie == 63)
			matrix_filter[2][1] = 0;
		else
			matrix_filter[2][1] ={R,G,B};
		sum_B = sum_B + matrix_filter[2][1][7:0]*matrix_convolution[2][1];
		sum_G = sum_G + matrix_filter[2][1][15:8]*matrix_convolution[2][1];
		sum_R = sum_R + matrix_filter[2][1][23:16]*matrix_convolution[2][1];
		next_state = S16;
	end
	S16:begin
		R = in_pix[23:16];
		G = in_pix[15:8];
		B = in_pix[7:0];
		if(linie == 63 || coloana == 63)
			matrix_filter[2][2] = 0;
		else
			matrix_filter[2][2] = {R,G,B};
		sum_B = sum_B+ matrix_filter[2][2][7:0]*matrix_convolution[2][2];
		sum_G = sum_G + matrix_filter[2][2][15:8]*matrix_convolution[2][2];
		sum_R = sum_R + matrix_filter[2][2][23:16]*matrix_convolution[2][2];
		next_state = S17;
	end
	S17:begin
		if(sum_B > 255)
			sum_B = 255;
		if(sum_G>255)
			sum_G = 255;
		if( sum_R > 255 )
			sum_R = 255;
		if(sum_B <0)
			sum_B = 0;
		if(sum_G<0)
			sum_G = 0;
		if( sum_R < 0 )
			sum_R = 0;
		out_we = 1;
		out_pix = {sum_R[7:0],sum_G[7:0],sum_B[7:0]};
		if(col == 63 && row == 63)
						next_state = S18; 
		else next_state = S7;
	end
	S18:begin
		filter_done = 1;
		next_state = S0;
	end
	endcase			
end				
						
endmodule