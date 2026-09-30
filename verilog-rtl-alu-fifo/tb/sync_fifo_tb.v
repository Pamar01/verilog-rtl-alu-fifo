`timescale 1ns/1ps
// Self-checking testbench for sync_fifo.v
// Uses a behavioural scoreboard (model) and compares data + flags every cycle.
module sync_fifo_tb;

    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;
    localparam DEPTH      = 1 << ADDR_WIDTH;

    reg                   clk;
    reg                   rst_n;
    reg                   wr_en;
    reg  [DATA_WIDTH-1:0] wr_data;
    reg                   rd_en;
    wire [DATA_WIDTH-1:0] rd_data;
    wire                  full, empty;
    wire [ADDR_WIDTH:0]   count;

    sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data),
        .rd_en(rd_en), .rd_data(rd_data),
        .full(full), .empty(empty), .count(count)
    );

    always #5 clk = ~clk;

    // ---- scoreboard model -------------------------------------------------
    reg [DATA_WIDTH-1:0] m_mem [0:DEPTH-1];
    integer m_head, m_tail, m_count;
    reg [DATA_WIDTH-1:0] exp_data;

    integer errors;
    integer cycles;
    integer seed;
    integer n;

    task model_reset;
        begin
            m_head   = 0;
            m_tail   = 0;
            m_count  = 0;
            exp_data = 0;
        end
    endtask

    task expect_true;
        input       cond;
        input [255:0] msg;
        begin
            if (!cond) begin
                errors = errors + 1;
                $display("FAIL: %0s (time %0t)", msg, $time);
            end
        end
    endtask

    // Drive one clock cycle (called at a falling edge, returns at next falling edge)
    task cycle;
        input                   wr;
        input [DATA_WIDTH-1:0]  wdata;
        input                   rd;
        reg do_wr, do_rd;
        begin
            wr_en   = wr;
            wr_data = wdata;
            rd_en   = rd;

            do_wr = wr && (m_count < DEPTH);
            do_rd = rd && (m_count > 0);
            if (do_rd) begin
                exp_data = m_mem[m_head];
                m_head   = (m_head + 1) % DEPTH;
            end
            if (do_wr) begin
                m_mem[m_tail] = wdata;
                m_tail        = (m_tail + 1) % DEPTH;
            end
            if (do_wr) m_count = m_count + 1;
            if (do_rd) m_count = m_count - 1;

            @(negedge clk);
            cycles = cycles + 1;

            if (rd_data !== exp_data) begin
                errors = errors + 1;
                $display("FAIL: rd_data=%0h expected=%0h (time %0t)", rd_data, exp_data, $time);
            end
            if (full !== (m_count == DEPTH)) begin
                errors = errors + 1;
                $display("FAIL: full flag wrong, count=%0d (time %0t)", m_count, $time);
            end
            if (empty !== (m_count == 0)) begin
                errors = errors + 1;
                $display("FAIL: empty flag wrong, count=%0d (time %0t)", m_count, $time);
            end
            if (count !== m_count[ADDR_WIDTH:0]) begin
                errors = errors + 1;
                $display("FAIL: count=%0d expected=%0d (time %0t)", count, m_count, $time);
            end
        end
    endtask

    integer i;
    integer r;

    initial begin
        $dumpfile("sync_fifo_tb.vcd");
        $dumpvars(0, sync_fifo_tb);

        clk = 0; rst_n = 0; wr_en = 0; wr_data = 0; rd_en = 0;
        errors = 0; cycles = 0; seed = 12345;
        model_reset;

        // ---- Test 1: reset state ------------------------------------------
        @(negedge clk);
        @(negedge clk);
        expect_true(empty === 1'b1 && full === 1'b0 && count === 0, "reset state: empty, not full");
        rst_n = 1;
        @(negedge clk);
        $display("Test 1 done: reset state");

        // ---- Test 2: fill to full, then try to overflow --------------------
        for (i = 0; i < DEPTH; i = i + 1) cycle(1, i + 8'h10, 0);
        expect_true(full === 1'b1, "FIFO full after DEPTH writes");
        cycle(1, 8'hEE, 0);
        cycle(1, 8'hEF, 0);
        expect_true(count === DEPTH, "overflow writes ignored");
        $display("Test 2 done: fill and overflow");

        // ---- Test 3: drain in order, then try to underflow ------------------
        for (i = 0; i < DEPTH; i = i + 1) cycle(0, 0, 1);
        expect_true(empty === 1'b1, "FIFO empty after DEPTH reads");
        cycle(0, 0, 1);
        cycle(0, 0, 1);
        expect_true(count === 0, "underflow reads ignored");
        $display("Test 3 done: drain and underflow");

        // ---- Test 4: simultaneous read and write ---------------------------
        cycle(1, 8'hA1, 0);
        cycle(1, 8'hA2, 0);
        for (i = 0; i < 10; i = i + 1) cycle(1, 8'hB0 + i, 1);
        $display("Test 4 done: simultaneous read/write");

        // ---- Test 5: asynchronous reset in the middle of traffic -----------
        #1;
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        #1;
        expect_true(empty === 1'b1 && count === 0, "async reset clears FIFO");
        model_reset;
        @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        cycle(1, 8'h55, 0);
        cycle(0, 0, 1);
        $display("Test 5 done: asynchronous reset");

        // ---- Test 6: randomised traffic (fixed seed => repeatable) ---------
        for (n = 0; n < 5000; n = n + 1) begin
            r = $random(seed);
            // bias: ~50% writes, ~50% reads, occasionally both
            cycle(r[0], r[15:8], r[1]);
        end
        $display("Test 6 done: 5000 randomised cycles");

        if (errors == 0)
            $display("ALL TESTS PASSED (%0d cycles)", cycles);
        else
            $display("TESTS FAILED: %0d errors in %0d cycles", errors, cycles);
        $finish;
    end

endmodule
