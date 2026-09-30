`timescale 1ns/1ps
// Self-checking, exhaustive testbench for alu.v
// Every opcode is tested against every (a, b) pair: 8 * 256 * 256 = 524,288 checks.
module alu_tb;

    reg  [7:0] a, b;
    reg  [2:0] op;
    wire [7:0] result;
    wire       carry, overflow, zero;

    integer errors;
    integer checks;
    integer op_errors;
    integer i, j, k;

    alu dut (
        .a(a), .b(b), .op(op),
        .result(result), .carry(carry), .overflow(overflow), .zero(zero)
    );

    // Apply one stimulus and compare against an independent reference model
    task check;
        input [2:0] op_i;
        input [7:0] a_i;
        input [7:0] b_i;
        reg  [7:0] exp_res;
        reg        exp_c;
        reg        exp_v;
        integer    isum;
        integer    sa, sb, sr;
        begin
            a  = a_i;
            b  = b_i;
            op = op_i;
            #1;

            exp_res = 8'd0;
            exp_c   = 1'b0;
            exp_v   = 1'b0;
            sa = $signed(a_i);
            sb = $signed(b_i);

            case (op_i)
                3'b000: begin
                    isum    = a_i + b_i;
                    exp_res = isum % 256;
                    exp_c   = (isum > 255);
                    sr      = sa + sb;
                    exp_v   = (sr > 127) || (sr < -128);
                end
                3'b001: begin
                    exp_res = a_i - b_i;
                    exp_c   = (a_i < b_i);
                    sr      = sa - sb;
                    exp_v   = (sr > 127) || (sr < -128);
                end
                3'b010: exp_res = a_i & b_i;
                3'b011: exp_res = a_i | b_i;
                3'b100: exp_res = a_i ^ b_i;
                3'b101: exp_res = ~a_i;
                3'b110: begin
                    exp_res = {a_i[6:0], 1'b0};
                    exp_c   = a_i[7];
                end
                3'b111: begin
                    exp_res = {1'b0, a_i[7:1]};
                    exp_c   = a_i[0];
                end
            endcase

            checks = checks + 1;
            if (result !== exp_res || carry !== exp_c ||
                overflow !== exp_v || zero !== (exp_res == 8'd0)) begin
                errors    = errors + 1;
                op_errors = op_errors + 1;
                if (errors <= 20)
                    $display("FAIL op=%b a=%0d b=%0d | got res=%0d c=%b v=%b z=%b | exp res=%0d c=%b v=%b z=%b",
                             op_i, a_i, b_i, result, carry, overflow, zero,
                             exp_res, exp_c, exp_v, (exp_res == 8'd0));
            end
        end
    endtask

    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        errors = 0;
        checks = 0;
        a = 8'd0; b = 8'd0; op = 3'd0;

        $display("ALU testbench: exhaustive check of all opcodes");
        for (k = 0; k < 8; k = k + 1) begin
            op_errors = 0;
            for (i = 0; i < 256; i = i + 1) begin
                for (j = 0; j < 256; j = j + 1) begin
                    check(k[2:0], i[7:0], j[7:0]);
                end
            end
            if (op_errors == 0)
                $display("PASS  op=%b (65536 checks)", k[2:0]);
            else
                $display("FAIL  op=%b (%0d errors)", k[2:0], op_errors);
        end

        if (errors == 0)
            $display("ALL TESTS PASSED (%0d checks)", checks);
        else
            $display("TESTS FAILED: %0d errors in %0d checks", errors, checks);
        $finish;
    end

endmodule
