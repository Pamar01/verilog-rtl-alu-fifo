// -----------------------------------------------------------------------------
// 8-bit ALU
//
//  op   operation        carry flag                      overflow flag
//  000  a + b            carry out                       signed overflow
//  001  a - b            borrow (a < b, unsigned)        signed overflow
//  010  a & b            0                               0
//  011  a | b            0                               0
//  100  a ^ b            0                               0
//  101  ~a               0                               0
//  110  a << 1           bit shifted out (a[7])          0
//  111  a >> 1 (logical) bit shifted out (a[0])          0
//
//  zero = 1 when result == 0
// -----------------------------------------------------------------------------
module alu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [2:0] op,
    output reg  [7:0] result,
    output reg        carry,
    output reg        overflow,
    output wire       zero
);

    reg [8:0] tmp;

    always @* begin
        // defaults keep every output assigned on every path (no latches)
        tmp      = 9'd0;
        result   = 8'd0;
        carry    = 1'b0;
        overflow = 1'b0;

        case (op)
            3'b000: begin
                tmp      = {1'b0, a} + {1'b0, b};
                result   = tmp[7:0];
                carry    = tmp[8];
                overflow = (a[7] == b[7]) && (tmp[7] != a[7]);
            end
            3'b001: begin
                tmp      = {1'b0, a} - {1'b0, b};
                result   = tmp[7:0];
                carry    = tmp[8];               // borrow
                overflow = (a[7] != b[7]) && (tmp[7] != a[7]);
            end
            3'b010: result = a & b;
            3'b011: result = a | b;
            3'b100: result = a ^ b;
            3'b101: result = ~a;
            3'b110: begin
                result = {a[6:0], 1'b0};
                carry  = a[7];
            end
            3'b111: begin
                result = {1'b0, a[7:1]};
                carry  = a[0];
            end
            default: result = 8'd0;
        endcase
    end

    assign zero = (result == 8'd0);

endmodule
