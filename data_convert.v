`timescale 1ns/1ps
module data_convert (
	input  RSTN,
	input  CLK_30MHz,
	input  DIN,
	input  [1:0]MODE,
	input  CLK_48MHz,
	output reg CLK_OUT,
	output reg VALID,
	output  wire DOUT_A,
	output wire DOUT_B,
	output wire DOUT_C
);

reg [12:0] cnt;
reg [3:0] out_data_cnt;
reg [8:0] out_cnt;
reg [3:0] width_cnt;
reg [9:0] data_cnt;
reg [9:0] data [719:0];
reg full;
reg  data_reg1;
reg  data_reg2;
reg  data_reg3;
reg[1:0] state;
reg[1:0] div4_cnt;
reg[2:0] div6_cnt;
always @(posedge CLK_30MHz or negedge RSTN) 
begin
	if(~RSTN) begin
		VALID<=1'b0;
		state<=2'b00;
		cnt<=1'b0;
		data_cnt<=1'b0;
		width_cnt<=1'b0;
	end
	else begin
	case(state)
		2'b00:begin
			VALID <= 0;
			if(DIN == 1'b1) begin
				if(cnt<9) begin
					cnt<=cnt+1;
				end
				else begin
					state <=2'b01;
					cnt<=0;
				end
				end
			else begin
				cnt<=0;
			end
			end
		2'b01:begin
			if (cnt<32'd7200) begin
				full<=0;
				cnt <= cnt+1;
				width_cnt <=width_cnt+1; 
				if (width_cnt >= 9)
					begin
					width_cnt <= 0;
					data_cnt <= data_cnt+1;
					end
				data[data_cnt]<={data[data_cnt][8:0],DIN};
				VALID <= 1;
			end
			else begin 
				state <=2'b10;
				cnt<=0;
				data_cnt<=0; 
				width_cnt<=0;
				full<=1;
				end

		end
		2'b10:begin
			#6666
			state<=2'b00;
		end

	endcase

end

end

//四分频
always @(posedge CLK_48MHz or negedge RSTN)
begin
	if(!RSTN)
		div4_cnt<=2'b00;
	else
		div4_cnt<=div4_cnt+1'b1;
end
//六分频
always @(posedge CLK_48MHz or negedge RSTN)
begin
	if(!RSTN)
		div6_cnt<=3'b00;
	else
		begin
			if(div6_cnt==5) div6_cnt<=0;
			else div6_cnt<=div6_cnt+1;
		end
end

always @(posedge CLK_48MHz or negedge RSTN)
begin
	if(!RSTN)
		CLK_OUT<=1'b0;

	else 
	begin
	case(MODE)
	2'b00:
	if(div4_cnt==2'b00||div4_cnt==2'b10)
		CLK_OUT<=~CLK_OUT;
	else
		CLK_OUT<=CLK_OUT;
	2'b01:
	if(div4_cnt==2'b00||div4_cnt==2'b10)
		CLK_OUT<=~CLK_OUT;
	else
		CLK_OUT<=CLK_OUT;
	2'b10:
		if(div6_cnt<3) CLK_OUT<=1;
		else CLK_OUT<=0;
	2'b11:
		if(div6_cnt<3) CLK_OUT<=1;
		else CLK_OUT<=0;
	
	endcase
	end
end 



always @(posedge CLK_OUT or negedge RSTN)
begin
	if (~RSTN) begin 
		out_cnt<=0;
		data_reg1<=1'b0;
		data_reg2<=1'b0;
		data_reg3<=1'b0;
		out_data_cnt<=0;
		end
	else begin
	if (VALID) begin
	case (MODE)
		2'b00:begin
			if(full==1 && out_cnt<359) begin
			data_reg1<=data[0+2*out_cnt][9-out_data_cnt];
			data_reg2<=data[1+2*out_cnt][9-out_data_cnt];
			data_reg3<=1'b0;
			out_data_cnt<=out_data_cnt+1;
			if(out_data_cnt>=7) begin
				out_data_cnt<=0;
				out_cnt<=out_cnt+1;
			end
			end
		end
		2'b01:begin
			if(full==1 && out_cnt<359) 
			begin
			data_reg1<=data[718-3*out_cnt][9-out_data_cnt];
			data_reg2<=data[719-3*out_cnt][9-out_data_cnt];
			data_reg3<=1'b0;
			out_data_cnt<=out_data_cnt+1;
			if(out_data_cnt>=7) begin
				out_data_cnt<=0;
				out_cnt<=out_cnt+1;
			end
			end
		end
		2'b10:begin
			if(full==1 && out_cnt<239) begin
			data_reg1<=data[0+3*out_cnt][9-out_data_cnt];
			data_reg2<=data[1+3*out_cnt][9-out_data_cnt];
			data_reg3<=data[2+3*cnt][9-out_data_cnt];
			out_data_cnt<=out_data_cnt+1;
			if(out_data_cnt>=7) begin
				out_data_cnt<=0;
				out_cnt<=out_cnt+1;
			end
			end
		end
		2'b11:begin
			if(full==1 && out_cnt<239) begin
			data_reg1<=data[717-3*out_cnt][9-out_data_cnt];
			data_reg2<=data[718-3*out_cnt][9-out_data_cnt];
			data_reg3<=data[719-3*out_cnt][9-out_data_cnt];
			out_data_cnt<=out_data_cnt+1;
			if(out_data_cnt>=7) begin
				out_data_cnt<=0;
				out_cnt<=out_cnt+1;
			end
		end
		end
	endcase
	end else begin
		data_reg1 <= 1'b0;
		data_reg2 <= 1'b0;
		data_reg3 <= 1'b0;
end
end
end
assign DOUT_A = data_reg1;
assign DOUT_B = data_reg2;
assign DOUT_C = data_reg3;

endmodule