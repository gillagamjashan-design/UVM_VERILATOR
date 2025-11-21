# Makefile for AXI LITE UVM Testbench with Verilator

# Directories
TB_DIR = tb
RTL_DIR = rtl
OBJ_DIR = obj_dir

# Verilator
VERILATOR = verilator
VERILATOR_ROOT ?= $(shell verilator --getenv VERILATOR_ROOT)

# UVM Home - using Verilator-compatible minimal UVM
UVM_HOME = verilator_uvm

# Default test and verbosity
TEST ?= axi_simple_test
VERBOSITY ?= UVM_MEDIUM

# Include directories
INCDIRS = -I$(TB_DIR) \
          -I$(TB_DIR)/agents/axi_master \
          -I$(TB_DIR)/agents/axi_slave \
          -I$(TB_DIR)/env \
          -I$(TB_DIR)/sequences \
          -I$(TB_DIR)/tests \
          -I$(UVM_HOME)

# Verilator flags for UVM support
VERILATOR_FLAGS = --cc \
                  --exe \
                  --build \
                  -sv \
                  --assert \
                  --timing \
                  -Wall \
                  -Wno-fatal \
                  -Wno-UNUSED \
                  -Wno-UNDRIVEN \
                  -Wno-DECLFILENAME \
                  -Wno-PINMISSING \
                  -Wno-IMPORTSTAR \
                  -Wno-PKGNODECL \
                  -Wno-CONSTRAINTIGN \
                  -Wno-WIDTHTRUNC \
                  -Wno-SYMRSVDWORD \
                  -Wno-REALCVT \
                  -Wno-VARHIDDEN \
                  --bbox-unsup \
                  --bbox-sys \
                  --trace \
                  --trace-structs \
                  --main \
                  --top-module tb_top \
                  $(INCDIRS) \
                  -CFLAGS "-std=c++14" \
                  -LDFLAGS "-lpthread"

# Source files
RTL_SOURCES = $(RTL_DIR)/axi_passthrough.sv

UVM_SOURCES = $(UVM_HOME)/uvm_pkg.sv

TB_SOURCES = $(TB_DIR)/axi_interface.sv \
             $(TB_DIR)/axi_tb_pkg.sv \
             $(TB_DIR)/tb_top.sv

ALL_SOURCES = $(RTL_SOURCES) $(UVM_SOURCES) $(TB_SOURCES)

# Output executable
VEXE = $(OBJ_DIR)/Vtb_top

.PHONY: all clean compile sim run help lint

all: compile

help:
	@echo "========================================="
	@echo "AXI LITE UVM Testbench Makefile (Verilator)"
	@echo "========================================="
	@echo "Available targets:"
	@echo "  make compile         - Compile all tests (do this once)"
	@echo "  make sim TEST=<name> - Run simulation (no recompilation)"
	@echo "  make run TEST=<name> - Same as 'make sim' (no recompilation)"
	@echo "  make build_and_run   - Compile and run (first time only)"
	@echo "  make lint            - Run Verilator lint checks"
	@echo "  make waves           - View waveforms with GTKWave"
	@echo "  make clean           - Clean build artifacts"
	@echo ""
	@echo "Available tests (use with +TEST= at runtime):"
	@echo "  axi_simple_test      - Simple write/read test (default)"
	@echo "  axi_burst_test       - Burst write-read test"
	@echo "  axi_random_test      - Random transactions test"
	@echo "  axi_multi_vseq_test  - Multiple virtual sequences test"
	@echo ""
	@echo "Workflow:"
	@echo "  1. make compile                    # Compile once"
	@echo "  2. make run TEST=axi_simple_test   # Run test 1"
	@echo "  3. make run TEST=axi_burst_test    # Run test 2 (no recompile)"
	@echo "  4. make run TEST=axi_random_test   # Run test 3 (no recompile)"
	@echo ""
	@echo "Examples:"
	@echo "  make compile"
	@echo "  make run TEST=axi_simple_test"
	@echo "  make run TEST=axi_burst_test VERBOSITY=UVM_HIGH"
	@echo "  make lint"
	@echo "========================================="
	@echo "Note: All tests are compiled together."
	@echo "Select test at runtime with +TEST=<name>."
	@echo "========================================="

# Lint only - useful for checking syntax
lint:
	@echo "Running Verilator lint..."
	$(VERILATOR) --lint-only \
	             -sv \
	             --timing \
	             --bbox-unsup \
	             --bbox-sys \
	             -Wno-UNUSED \
	             -Wno-UNDRIVEN \
	             -Wno-DECLFILENAME \
	             -Wno-WIDTHTRUNC \
	             $(INCDIRS) \
	             --top-module tb_top \
	             $(ALL_SOURCES)
	@echo "Lint complete!"

# Compile with Verilator (only once)
compile:
	@echo "========================================="
	@echo "Compiling with Verilator..."
	@echo "========================================="
	$(VERILATOR) $(VERILATOR_FLAGS) $(ALL_SOURCES)
	@echo "Compilation complete!"
	@echo "Executable: $(VEXE)"

# Run simulation (without recompiling)
sim:
	@echo "========================================="
	@echo "Running simulation..."
	@echo "Test: $(TEST)"
	@echo "Verbosity: $(VERBOSITY)"
	@echo "========================================="
	@if [ -f $(VEXE) ]; then \
		$(VEXE) +TEST=$(TEST) +VERBOSITY=$(VERBOSITY); \
	else \
		echo "Error: Executable not found. Run 'make compile' first."; \
		exit 1; \
	fi

# Run alias (just runs sim, no recompilation)
run: sim

# Build and run (for first time use)
build_and_run: compile sim

# View waveforms
waves:
	@echo "Opening waveforms with GTKWave..."
	@if [ -f axi_test.vcd ]; then \
		gtkwave axi_test.vcd; \
	else \
		echo "Error: VCD file not found. Run simulation first."; \
		exit 1; \
	fi

# Clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(OBJ_DIR)
	rm -f *.vcd
	rm -f *.log
	rm -f *.fst
	@echo "Clean complete!"

# Individual test targets for convenience
simple:
	$(MAKE) run TEST=axi_simple_test

burst:
	$(MAKE) run TEST=axi_burst_test

random:
	$(MAKE) run TEST=axi_random_test

multi:
	$(MAKE) run TEST=axi_multi_vseq_test

# Run all tests
test_all: clean
	@echo "Running all tests..."
	-$(MAKE) run TEST=axi_simple_test
	-$(MAKE) run TEST=axi_burst_test
	-$(MAKE) run TEST=axi_random_test
	-$(MAKE) run TEST=axi_multi_vseq_test
	@echo "All tests complete!"

# Check Verilator installation
check:
	@echo "Checking Verilator installation..."
	@which $(VERILATOR) > /dev/null && echo "Verilator: $(shell $(VERILATOR) --version)" || echo "Error: Verilator not found!"
	@echo "Verilator root: $(VERILATOR_ROOT)"
