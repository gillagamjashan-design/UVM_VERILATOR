# Verilator UVM Status Report

## Current Situation

We've attempted to compile the AXI LITE UVM testbench with Verilator 5.032, and have encountered fundamental limitations:

### Issues Encountered

1. **DPI (Direct Programming Interface) Limitations**
   - UVM 1.2 heavily relies on DPI-C calls for core functionality
   - Verilator has limited DPI support compared to commercial simulators
   - Error: `uvm_dpi.svh` contains DPI calls that Verilator cannot process

2. **Macro Processing Issues**
   - UVM macros (`uvm_object_utils`, `uvm_component_utils`, etc.) expand into complex code
   - Verilator's preprocessor struggles with nested macro expansions
   - Errors about unterminated `ifdef` and quotes

3. **SystemVerilog Class Support**
   - While Verilator 5.x has improved class support, UVM's advanced OOP features are still problematic
   - Virtual methods, inheritance hierarchies, and dynamic processes are limited

4. **Missing Runtime Features**
   - UVM's phasing mechanism relies on dynamic process control
   - Factory pattern uses reflection-like features not supported
   - TLM ports and exports use advanced SystemVerilog features

## What Works

✅ RTL (axi_passthrough.sv) - fully Verilator compatible
✅ Interfaces (axi_interface.sv) - works with Verilator
✅ Basic SystemVerilog constructs - supported

## What Doesn't Work

❌ UVM base library (uvm_pkg)
❌ UVM macros and factory
❌ DPI calls in UVM
❌ Dynamic phasing and objections
❌ UVM sequences and sequencers (depend on base library)

## Recommendations

### Option 1: Use Commercial Simulator (Recommended for UVM)
- **QuestaSim/ModelSim**: Best UVM support
- **VCS**: Excellent UVM support
- **Xcelium**: Full UVM compliance
- All have free/academic licenses available

### Option 2: cocotb with Verilator (Python-based Testing)
- Use Verilator for DUT simulation (fast, free, works great)
- Use cocotb (Python framework) for testbench
- Can still have sequences, randomization, and coverage
- Example provided in `cocotb_example/`

### Option 3: Simplified SystemVerilog TB with Verilator
- Remove UVM framework entirely
- Use simple SystemVerilog tasks/functions
- Direct interface-based testing
- Example provided in `simple_sv_tb/`

### Option 4: Use Icarus Verilog (Limited UVM Support)
- Open-source simulator with better UVM support than Verilator
- Still limited compared to commercial tools
- Worth trying if commercial tools unavailable

## Next Steps

Choose one of the following:

1. **Stick with UVM + Commercial Simulator**:
   ```bash
   # Use the provided run.sh script
   ./run.sh -sim vcs -test axi_simple_test
   ```

2. **Switch to cocotb**:
   ```bash
   cd cocotb_example
   make
   ```

3. **Use Simplified TB**:
   ```bash
   cd simple_sv_tb
   make
   ```

## Files Status

| File/Component | Verilator Compatible | Notes |
|----------------|---------------------|-------|
| rtl/axi_passthrough.sv | ✅ Yes | Works perfectly |
| tb/axi_interface.sv | ✅ Yes | Interface syntax supported |
| tb/axi_transaction.sv | ❌ No | Uses UVM macros |
| tb/agents/* | ❌ No | Extends UVM classes |
| tb/env/* | ❌ No | Uses UVM components |
| tb/sequences/* | ❌ No | UVM sequences |
| tb/tests/* | ❌ No | UVM test infrastructure |
| tb/tb_top.sv | ⚠️ Partial | Module OK, UVM calls fail |

## Conclusion

While Verilator is an excellent tool for RTL simulation and has been making strides in SystemVerilog support, **full UVM verification is not practically achievable with Verilator as of version 5.032**.

For learning UVM and running this testbench as designed, a UVM-compatible simulator is necessary. Alternatively, the verification methodology can be adapted to Verilator's capabilities using cocotb or simplified SystemVerilog.
