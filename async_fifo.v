module async_fifo(wr_clk_i,rd_clk_i,rst_i,wr_en_i,rd_en_i,wdata_i,rdata_o,full_o,empty_o,overflow_o,underflow_o);
	parameter DEPTH = 16;
	parameter DATA_WIDTH = 32;
	parameter PTR_WIDTH = $clog2(DEPTH);
	
	input wr_clk_i,rd_clk_i,rst_i;
	input wr_en_i,rd_en_i;
	input [DATA_WIDTH-1:0] wdata_i;
	output reg [DATA_WIDTH-1:0] rdata_o;
	output reg full_o,empty_o,overflow_o,underflow_o;
	integer i;
	
	//Internal signals
	reg [PTR_WIDTH-1:0] wr_pntr, rd_pntr;
	reg [PTR_WIDTH-1:0] wr_pntr_rd_clk, rd_pntr_wr_clk;

	reg wr_tggle, rd_tggle;
	reg wr_tggle_rd_clk, rd_tggle_wr_clk;
	

	reg [DATA_WIDTH-1:0] fifo [DEPTH-1:0];
	always@(posedge wr_clk_i) begin
		if(rst_i == 1) begin
			rdata_o = 0;
			full_o = 0;
			empty_o = 1;
			overflow_o = 0;
			underflow_o = 0;
			wr_pntr = 0;
			rd_pntr = 0;
			wr_tggle = 0;
			rd_tggle = 0;
			wr_pntr_rd_clk = 0;
			rd_pntr_wr_clk = 0;
			wr_tggle_rd_clk = 0;
			rd_tggle_wr_clk = 0;
			for(i = 0;i<DEPTH;i=i+1) begin
				fifo[i] = 0;
			end
		end
		else
		//write
		if(wr_en_i == 1) begin
			overflow_o = 0;
			underflow_o = 0;
			if(full_o == 1) begin
				overflow_o = 1;
			end
			else begin
				fifo[wr_pntr] = wdata_i;
				if(wr_pntr == DEPTH-1) begin
					wr_pntr = 0;
					wr_tggle = ~wr_tggle;
				end
				else begin
					wr_pntr = wr_pntr + 1;
				end
			end
		end
	end

	always@(posedge rd_clk_i) begin
		if(rst_i == 0) begin
		//read
		if(rd_en_i == 1) begin
			underflow_o = 0;
			overflow_o = 0;
			if(empty_o == 1)
				underflow_o = 1;
			else begin
				rdata_o = fifo[rd_pntr];
				if(rd_pntr == DEPTH-1) begin
					rd_pntr = 0;
					rd_tggle = ~rd_tggle;
				end
				else begin
					rd_pntr = rd_pntr + 1;
				end
			end
		end
	end
end
always@(posedge wr_clk_i) begin
	rd_pntr_wr_clk <= rd_pntr;
	rd_tggle_wr_clk <=  rd_tggle;
end

always@(posedge rd_clk_i) begin
	wr_pntr_rd_clk	<= wr_pntr;
	wr_tggle_rd_clk <= wr_tggle;
end


always@(*) begin
	empty_o = 0;
	full_o = 0;
	overflow_o = 0;
	underflow_o = 0;
	//full
	if(wr_pntr == rd_pntr_wr_clk && wr_tggle != rd_tggle_wr_clk) begin
		full_o = 1;
	end
	if(wr_pntr_rd_clk == rd_pntr && wr_tggle_rd_clk == rd_tggle) begin
		empty_o = 1;
	end
		
end


endmodule
