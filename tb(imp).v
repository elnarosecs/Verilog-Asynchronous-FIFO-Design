`define DEPTH 13
`define DATA_WIDTH 32
`define PNTR_WIDTH $clog2(`DEPTH)
`include "async_fifo.v"

module top;

    reg wr_clk_i, rd_clk_i;
    reg rst_i, wr_en_i, rd_en_i;
    reg [`DATA_WIDTH-1:0] wdata_i;

    wire [`DATA_WIDTH-1:0] rdata_o;
    wire full_o, empty_o, underflow_o, overflow_o;

    async_fifo dut (
        .wr_clk_i(wr_clk_i),
        .rd_clk_i(rd_clk_i),
        .rst_i(rst_i),
        .wr_en_i(wr_en_i),
        .rd_en_i(rd_en_i),
        .wdata_i(wdata_i),
        .rdata_o(rdata_o),
        .full_o(full_o),
        .empty_o(empty_o),
        .underflow_o(underflow_o),
        .overflow_o(overflow_o)
    );

    // Write clock generation
    initial begin
        wr_clk_i = 0;
        forever #2 wr_clk_i = ~wr_clk_i;
    end

    // Read clock generation
    initial begin
        rd_clk_i = 0;
        forever #5 rd_clk_i = ~rd_clk_i;
    end

    // Reset task
    task reset;
        begin
            wr_en_i = 0;
            rd_en_i = 0;
            wdata_i = 0;
            repeat(2) @(posedge wr_clk_i);
        end
    endtask`:wq

    // Write task
    task write(input integer N);
        integer i;
        begin
            for (i = 0; i < N; i = i + 1) begin
                @(negedge wr_clk_i);
                wr_en_i = 1;
                wdata_i = $random;
            end

            @(negedge wr_clk_i);
            wr_en_i = 0;
            wdata_i = 0;
        end
    endtask

    // Read task
    task read(input integer N);
        integer i;
        begin
            for (i = 0; i < N; i = i + 1) begin
                @(negedge rd_clk_i);
                rd_en_i = 1;
            end

            @(negedge rd_clk_i);
            rd_en_i = 0;
        end
    endtask

    // Test scenarios
    initial begin
        rst_i = 1;
       
        reset();// output is already getting 0 inside the code only

        // Release reset
        @(negedge wr_clk_i);
        rst_i = 0;

        // Allow reset synchronization to settle
        repeat(4) @(posedge rd_clk_i);

        // Test 1: Write until FIFO becomes full
        write(`DEPTH);

        // Allow write pointer synchronization
        repeat(4) @(posedge rd_clk_i);

        // Test 2: Read until FIFO becomes empty
        read(`DEPTH);

        // Allow read pointer synchronization
        repeat(4) @(posedge wr_clk_i);

        // Test 3: Overflow test
        write(`DEPTH + 1);

        // Test 4: Underflow test
        repeat(4) @(posedge rd_clk_i);
        read(`DEPTH + 1);

        // Test 5: Concurrent write and read
        fork
            write(10);
            read(10);
        join

        #100 $finish;
    end

endmodule
