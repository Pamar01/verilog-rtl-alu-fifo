# Verilog RTL: 8-bit ALU and Synchronous FIFO

Two small, fully verified digital designs written in synthesizable Verilog, each with a
self-checking testbench, a test plan and automated simulation in GitHub Actions.

| Block | File | Summary |
|-------|------|---------|
| 8-bit ALU | `rtl/alu.v` | Add, subtract, AND, OR, XOR, NOT, shift left/right with carry, overflow and zero flags |
| Synchronous FIFO | `rtl/sync_fifo.v` | Parameterised width/depth, full/empty/count, overflow and underflow protection, async reset |

## ALU operations
| op | Operation | carry | overflow |
|----|-----------|-------|----------|
| 000 | a + b | carry out | signed overflow |
| 001 | a - b | borrow (a < b) | signed overflow |
| 010 | a AND b | 0 | 0 |
| 011 | a OR b | 0 | 0 |
| 100 | a XOR b | 0 | 0 |
| 101 | NOT a | 0 | 0 |
| 110 | a << 1 | a[7] | 0 |
| 111 | a >> 1 (logical) | a[0] | 0 |

## Verification approach
- **ALU:** exhaustive test of every opcode with all 65,536 operand pairs (524,288 checks) against
  an independent reference model written with integer arithmetic.
- **FIFO:** directed tests (reset, fill, overflow, drain, underflow, simultaneous read/write,
  asynchronous reset) plus 5,000 randomised cycles checked every cycle against a scoreboard model.
- Each testbench prints `PASS`/`FAIL` lines and finishes with `ALL TESTS PASSED` when clean.
- See `docs/test_plan.md` for the test plan and a results log template.

## Run the simulations
Install [Icarus Verilog](https://steveicarus.github.io/iverilog/):

```bash
# Ubuntu / Debian
sudo apt-get install iverilog
# macOS
brew install icarus-verilog
# Windows: use the installer from bleyer.org/icarus
```

Then:

```bash
make test          # run both testbenches
make test-alu      # ALU only
make test-fifo     # FIFO only
make clean
```

Waveforms (`build/*.vcd`) can be opened with GTKWave: `gtkwave build/sync_fifo_tb.vcd`.

## Design notes
- FIFO read data is registered: `rd_data` is valid one clock after `rd_en`.
- FIFO depth is `2**ADDR_WIDTH`; `count` has `ADDR_WIDTH + 1` bits so it can represent "full".
- The ALU is purely combinational; every output is assigned on every path to avoid latches.

## Repository layout
```
rtl/   synthesizable design files
tb/    self-checking testbenches
docs/  test plan and results template
.github/workflows/ci.yml   runs `make test` on every push
```
