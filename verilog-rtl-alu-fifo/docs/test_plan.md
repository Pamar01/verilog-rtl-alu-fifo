# Test Plan and Results Template

## ALU (`rtl/alu.v`, `tb/alu_tb.v`)
| ID | Objective | Method | Expected result |
|----|-----------|--------|-----------------|
| ALU-1 | Correct result for every opcode | Exhaustive: 8 opcodes x 256 x 256 operand pairs | `result` matches reference model |
| ALU-2 | Carry / borrow flag | Same sweep | `carry` matches reference (add carry-out, subtract borrow, shifted-out bit) |
| ALU-3 | Signed overflow flag | Same sweep | `overflow` matches signed 32-bit reference arithmetic |
| ALU-4 | Zero flag | Same sweep | `zero` = 1 only when `result` = 0 |

## Synchronous FIFO (`rtl/sync_fifo.v`, `tb/sync_fifo_tb.v`)
| ID | Objective | Method | Expected result |
|----|-----------|--------|-----------------|
| FIFO-1 | Reset state | Hold `rst_n` low, then check flags | empty = 1, full = 0, count = 0 |
| FIFO-2 | Fill and overflow protection | Write DEPTH items, then 2 extra writes | full = 1, extra writes ignored |
| FIFO-3 | Ordering and underflow protection | Read DEPTH items, then 2 extra reads | data in FIFO order, extra reads ignored |
| FIFO-4 | Simultaneous read/write | Write and read in the same cycle | count stable, data correct |
| FIFO-5 | Asynchronous reset mid-traffic | Pulse `rst_n` while active | FIFO empties immediately |
| FIFO-6 | Randomised traffic | 5000 random cycles, fixed seed | data and flags match scoreboard every cycle |

## Results log (fill in after running `make test`)
| Date | Tool / version | ALU result | FIFO result | Notes |
|------|----------------|------------|-------------|-------|
|      |                |            |             |       |
