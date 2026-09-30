IVERILOG ?= iverilog
VVP      ?= vvp
BUILD    := build

.PHONY: all test test-alu test-fifo clean

all: test

test: test-alu test-fifo

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/alu_sim: rtl/alu.v tb/alu_tb.v | $(BUILD)
	$(IVERILOG) -Wall -o $@ rtl/alu.v tb/alu_tb.v

$(BUILD)/fifo_sim: rtl/sync_fifo.v tb/sync_fifo_tb.v | $(BUILD)
	$(IVERILOG) -Wall -o $@ rtl/sync_fifo.v tb/sync_fifo_tb.v

test-alu: $(BUILD)/alu_sim
	cd $(BUILD) && $(VVP) alu_sim > alu.log; cat alu.log
	@grep -q "ALL TESTS PASSED" $(BUILD)/alu.log

test-fifo: $(BUILD)/fifo_sim
	cd $(BUILD) && $(VVP) fifo_sim > fifo.log; cat fifo.log
	@grep -q "ALL TESTS PASSED" $(BUILD)/fifo.log

clean:
	rm -rf $(BUILD)
