#!/bin/bash

# Run script for AXI LITE UVM Testbench
# Supports VCS and Xcelium simulators

# Default values
SIMULATOR="vcs"
TEST="axi_simple_test"
VERBOSITY="UVM_MEDIUM"
GUI=0
CLEAN=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -sim|--simulator)
      SIMULATOR="$2"
      shift 2
      ;;
    -test|--test)
      TEST="$2"
      shift 2
      ;;
    -verb|--verbosity)
      VERBOSITY="$2"
      shift 2
      ;;
    -gui|--gui)
      GUI=1
      shift
      ;;
    -clean|--clean)
      CLEAN=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  -sim, --simulator <vcs|xcelium>  Specify simulator (default: vcs)"
      echo "  -test, --test <test_name>        Specify test name (default: axi_simple_test)"
      echo "  -verb, --verbosity <level>       Set UVM verbosity (default: UVM_MEDIUM)"
      echo "  -gui, --gui                      Run in GUI mode"
      echo "  -clean, --clean                  Clean before running"
      echo "  -h, --help                       Show this help message"
      echo ""
      echo "Available tests:"
      echo "  axi_simple_test      - Simple write/read test"
      echo "  axi_burst_test       - Burst write-read test"
      echo "  axi_random_test      - Random transactions test"
      echo "  axi_multi_vseq_test  - Multiple virtual sequences test"
      echo ""
      echo "Examples:"
      echo "  $0 -test axi_simple_test"
      echo "  $0 -sim xcelium -test axi_burst_test -verb UVM_HIGH"
      echo "  $0 -test axi_random_test -gui"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Clean if requested
if [ $CLEAN -eq 1 ]; then
  echo "Cleaning build artifacts..."
  rm -rf csrc simv* *.log *.vcd *.key *.vpd DVEfiles INCA_libs *.shm xcelium.d .simvision
  echo "Clean complete!"
fi

# Setup include directories
INCDIRS="+incdir+tb \
         +incdir+tb/agents/axi_master \
         +incdir+tb/agents/axi_slave \
         +incdir+tb/env \
         +incdir+tb/sequences \
         +incdir+tb/tests"

# Source files
RTL_FILES="rtl/axi_passthrough.sv"
TB_FILES="tb/axi_interface.sv tb/axi_tb_pkg.sv tb/tb_top.sv"

echo "========================================="
echo "AXI LITE UVM Testbench Simulation"
echo "========================================="
echo "Simulator: $SIMULATOR"
echo "Test:      $TEST"
echo "Verbosity: $VERBOSITY"
echo "GUI Mode:  $GUI"
echo "========================================="

# Run based on simulator
if [ "$SIMULATOR" == "vcs" ]; then
  echo "Running with VCS..."

  # VCS compilation options
  VCS_OPTS="-full64 \
            -sverilog \
            -timescale=1ns/1ps \
            -ntb_opts uvm-1.2 \
            -CFLAGS -DVCS \
            $INCDIRS \
            -debug_access+all \
            -kdb \
            -lca"

  # Compile
  echo "Compiling..."
  vcs $VCS_OPTS $RTL_FILES $TB_FILES -top tb_top -l compile.log

  if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed! Check compile.log"
    exit 1
  fi

  # Run simulation
  echo "Running simulation..."
  if [ $GUI -eq 1 ]; then
    ./simv +UVM_TESTNAME=$TEST +UVM_VERBOSITY=$VERBOSITY -gui -l sim.log
  else
    ./simv +UVM_TESTNAME=$TEST +UVM_VERBOSITY=$VERBOSITY -l sim.log
  fi

elif [ "$SIMULATOR" == "xcelium" ]; then
  echo "Running with Xcelium..."

  # Xcelium compilation options
  XCELIUM_OPTS="-64bit \
                -sv \
                -timescale 1ns/1ps \
                -uvmhome CDNS-1.2 \
                $INCDIRS \
                -access +rwc \
                -linedebug"

  # Compile
  echo "Compiling..."
  xrun $XCELIUM_OPTS $RTL_FILES $TB_FILES \
       -top tb_top \
       +UVM_TESTNAME=$TEST \
       +UVM_VERBOSITY=$VERBOSITY \
       -log xrun.log

  if [ $? -ne 0 ]; then
    echo "ERROR: Simulation failed! Check xrun.log"
    exit 1
  fi

else
  echo "ERROR: Unknown simulator: $SIMULATOR"
  echo "Supported simulators: vcs, xcelium"
  exit 1
fi

echo "========================================="
echo "Simulation complete!"
echo "Check log files for results"
echo "========================================="
