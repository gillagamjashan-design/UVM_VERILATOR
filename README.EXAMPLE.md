# Converting UVM Testbench from Commercial Simulators to Verilator

This document explains the changes required to convert a standard UVM testbench (designed for VCS/Questa/Xcelium) to work with Verilator.

## Table of Contents

- [Quick Start](#quick-start)
- [Build and Run](#build-and-run)
- [Required Code Changes](#required-code-changes)
- [Testbench Structure](#testbench-structure)
- [Common Issues and Solutions](#common-issues-and-solutions)

---

## Quick Start

### Prerequisites

```bash
# Install Verilator (version 5.0+)
sudo apt-get install verilator

# Verify installation
verilator --version
```

### Clone and Compile

```bash
# Compile all tests once
make compile

# Run different tests without recompilation
make run TEST=axi_simple_test
make run TEST=axi_burst_test
make run TEST=axi_random_test
make run TEST=axi_multi_vseq_test

# View waveforms
make waves

# Clean
make clean
```

---

## Build and Run

### Makefile Structure

The Makefile is optimized for compile-once, run-many workflow:

```makefile
# Compile all tests together (no TEST in CFLAGS!)
VERILATOR_FLAGS = --cc --exe --build -sv \
                  -CFLAGS "-std=c++14"

# Run-time test selection
sim:
    $(VEXE) +TEST=$(TEST) +VERBOSITY=$(VERBOSITY)
```

**Key Points:**
- ✅ Compile once with all tests included
- ✅ Select test at runtime with `+TEST=<name>`
- ✅ No recompilation needed for different tests

### Workflow Comparison

| Approach | Commercial Sim | Verilator (This Example) |
|----------|----------------|--------------------------|
| Compilation | Per test run | Once for all tests |
| Test Selection | Compile-time | Runtime `+TEST=` |
| Speed | Slower compile | Fast test switching |
| Makefile | `run: compile sim` | `run: sim` only |

---

## Required Code Changes

### 1. Factory Pattern Changes

**Commercial Simulator Code:**
```systemverilog
class my_sequence extends uvm_sequence#(my_transaction);
  `uvm_object_utils(my_sequence)

  virtual task body();
    req = my_transaction::type_id::create("req");  // ← This syntax fails in Verilator
  endtask
endclass
```

**Verilator-Compatible Code:**
```systemverilog
class my_sequence extends uvm_sequence#(my_transaction);
  `uvm_object_utils(my_sequence)

  virtual task body();
    req = my_transaction::create_object("req");  // ← Use create_object()
  endtask
endclass
```

**Automated Conversion:**
Create a script to convert all files:

```bash
#!/bin/bash
# scripts/fix_type_id.sh
find tb -name "*.sv" -exec sed -i 's/::type_id::create/::create_object/g' {} \;
```

### 2. Randomization Changes

**Commercial Simulator Code:**
```systemverilog
class my_sequence extends base_sequence;
  virtual task body();
    my_transaction trans;
    trans = my_transaction::create_object("trans");
    start_item(trans);
    assert(trans.randomize() with {
      addr inside {[32'h1000:32'h1FFF]};
      data dist {0 := 10, [1:100] := 90};
    });
    finish_item(trans);
  endtask
endclass
```

**Verilator-Compatible Code:**
```systemverilog
class my_sequence extends base_sequence;
  virtual task body();
    my_transaction trans;
    trans = my_transaction::create_object("trans");
    start_item(trans);
    // Direct assignment instead of randomize()
    trans.addr = $urandom_range(32'h1000, 32'h1FFF);
    trans.data = ($urandom_range(0, 99) < 10) ? 0 : $urandom_range(1, 100);
    finish_item(trans);
  endtask
endclass
```

**Conversion Rules:**
| Constraint | Replacement |
|------------|-------------|
| `randomize()` | `$urandom()` |
| `randomize() with {x inside {[a:b]}}` | `x = $urandom_range(a, b)` |
| `randomize() with {x == value}` | `x = value` |
| `randomize() with {x dist {...}}` | Manual distribution logic |

### 3. Test Selection Mechanism

**Commercial Simulator Code:**
```systemverilog
// tb_top.sv
initial begin
  run_test();  // Test selected via +UVM_TESTNAME=
end
```

**Verilator-Compatible Code:**
```systemverilog
// tb_top.sv
initial begin
  string test_name;
  uvm_component test_inst;
  uvm_phase phase;

  // Get test name from plusarg
  if (!$value$plusargs("TEST=%s", test_name))
    test_name = "my_default_test";

  // Create test using simple factory
  test_inst = create_test(test_name);

  // Run phases
  phase = new("uvm_phase");
  run_phases(test_inst, phase);
end

// Simple test factory
function uvm_component create_test(string test_name);
  case (test_name)
    "test1": return test1::create_object("test", null);
    "test2": return test2::create_object("test", null);
    default: return default_test::create_object("test", null);
  endcase
endfunction
```

### 4. Virtual Interface Handling

**Commercial Simulator Code:**
```systemverilog
// In driver/monitor build_phase
if (!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))
  `uvm_fatal("NOVIF", "Virtual interface not found")
```

**Verilator-Compatible Code:**
```systemverilog
// tb_top.sv - Use wildcard pattern
uvm_config_db#(virtual axi_interface)::set(null, "*", "vif", axi_if);

// In driver/monitor - Same code works due to wildcard support
if (!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))
  `uvm_fatal("NOVIF", "Virtual interface not found")
```

**Config DB Enhancement:**
The minimal UVM config_db supports wildcard matching:
```systemverilog
// Set with wildcard
set(null, "*", "vif", interface_handle);

// Get tries multiple patterns
get(this, "", "vif", value);  // Tries: ".", "*.vif", "vif"
```

### 5. Interface Signal Initialization

**Commercial Simulator Code:**
```systemverilog
interface axi_interface(input logic clk, input logic rst_n);
  logic [31:0] awaddr;
  logic        awvalid;
  // ... other signals
endinterface
```

**Problem:** Verilator with combinational pass-through DUT causes convergence errors.

**Verilator-Compatible Code:**
```systemverilog
interface axi_interface(input logic clk, input logic rst_n);
  logic [31:0] awaddr  = '0;  // Initialize all signals
  logic        awvalid = '0;
  // ... all signals initialized to avoid X propagation
endinterface
```

### 6. DUT Modifications

**Commercial Simulator Code (Combinational Pass-Through):**
```systemverilog
module axi_passthrough(...);
  // Pure combinational - causes Verilator convergence error
  assign slave_awaddr  = master_awaddr;
  assign slave_awvalid = master_awvalid;
  assign master_awready = slave_awready;
  // ...
endmodule
```

**Verilator-Compatible Code (Registered):**
```systemverilog
module axi_passthrough(input logic clk, input logic rst_n, ...);
  // Registered to break combinational loops
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      slave_awaddr  <= '0;
      slave_awvalid <= '0;
      master_awready <= '0;
      // ... initialize all
    end else begin
      slave_awaddr  <= master_awaddr;
      slave_awvalid <= master_awvalid;
      master_awready <= slave_awready;
      // ... forward all signals
    end
  end
endmodule
```

**Reason:** Verilator's sensitivity analysis detects combinational loops between interface signals driven from both testbench and DUT.

---

## Testbench Structure

### Directory Layout

```
UVM_EXAMPLE/
├── Makefile                      # Compile-once, run-many workflow
├── README.md                     # Project overview
├── README.UVM.md                 # UVM library changes
├── README.EXAMPLE.md             # This file
│
├── verilator_uvm/                # Minimal UVM for Verilator
│   ├── uvm_pkg.sv
│   ├── uvm_macros.svh
│   └── uvm_minimal_tlm.sv
│
├── rtl/
│   └── axi_passthrough.sv        # DUT (registered, not combinational)
│
├── tb/
│   ├── axi_interface.sv          # Protocol interface (initialized signals)
│   ├── axi_tb_pkg.sv             # Package import
│   ├── tb_top.sv                 # Top-level with test factory
│   │
│   ├── agents/
│   │   ├── axi_master/
│   │   │   ├── axi_master_driver.sv
│   │   │   ├── axi_master_monitor.sv
│   │   │   ├── axi_master_sequencer.sv
│   │   │   └── axi_master_agent.sv
│   │   └── axi_slave/
│   │       ├── axi_slave_driver.sv
│   │       ├── axi_slave_monitor.sv
│   │       ├── axi_slave_sequencer.sv
│   │       └── axi_slave_agent.sv
│   │
│   ├── env/
│   │   ├── axi_env.sv
│   │   ├── axi_scoreboard.sv
│   │   └── axi_virtual_sequencer.sv
│   │
│   ├── sequences/
│   │   ├── axi_base_sequence.sv         # No randomize(), use direct assignment
│   │   └── axi_virtual_sequence.sv      # P-sequencer with pre_start hook
│   │
│   └── tests/
│       └── axi_base_test.sv             # Runtime test selection
│
└── scripts/
    └── fix_type_id.sh                   # Automated conversion script
```

---

## Common Issues and Solutions

### Issue 1: "::type_id::create" Syntax Error

**Error:**
```
%Error: syntax error, unexpected SCOPE
transaction::type_id::create("trans");
```

**Solution:**
```bash
# Run conversion script
./scripts/fix_type_id.sh

# Or manually change all occurrences
find tb -name "*.sv" -exec sed -i 's/::type_id::create/::create_object/g' {} \;
```

### Issue 2: Randomize Assertion Failures

**Error:**
```
%Error: Assertion failed in sequence.body: 'assert' failed
assert(trans.randomize() with {...});
```

**Solution:**
Replace `randomize()` with direct assignments:
```systemverilog
// BEFORE
assert(trans.randomize() with { addr inside {[0:255]}; });

// AFTER
trans.addr = $urandom_range(0, 255);
```

### Issue 3: Null Pointer with p_sequencer

**Error:**
```
%Error: Null pointer dereferenced
vseq.start(p_sequencer.master_sequencer);
```

**Solution:**
Ensure `uvm_declare_p_sequencer` macro includes `pre_start()` hook to cast `m_sequencer`:

```systemverilog
// In minimal UVM macros
`define uvm_declare_p_sequencer(SEQUENCER) \
  SEQUENCER p_sequencer; \
  virtual task pre_start(); \
    super.pre_start(); \
    if (!$cast(p_sequencer, m_sequencer)) \
      `uvm_fatal(get_type_name(), "Cast failed") \
  endtask
```

### Issue 4: Virtual Interface Not Found

**Error:**
```
[FATAL] Virtual interface not set for driver
```

**Solution:**
```systemverilog
// In tb_top.sv, use wildcard pattern
uvm_config_db#(virtual axi_interface)::set(null, "*", "vif", axi_if);

// Config DB get() will try multiple patterns:
// 1. Exact match: "path.to.component.vif"
// 2. Wildcard: "*.vif"
// 3. Field only: "vif"
```

### Issue 5: Input Combinational Region Did Not Converge

**Error:**
```
%Error: tb/tb_top.sv:7: Input combinational region did not converge
```

**Solution:**
1. **Initialize all interface signals** to break X propagation loops:
   ```systemverilog
   logic awvalid = '0;  // Not just: logic awvalid;
   ```

2. **Use registered DUT** instead of pure combinational:
   ```systemverilog
   always_ff @(posedge clk) begin
     slave_signals <= master_signals;  // Registered
   end
   // Not: assign slave_signals = master_signals;  // Combinational
   ```

### Issue 6: Recursive Task Error

**Error:**
```
%Error: Internal Error: No clone for package function
task automatic run_phases(...);
```

**Solution:**
Use iterative approach with queue instead of recursion:
```systemverilog
task run_phases(uvm_component comp, uvm_phase phase);
  uvm_component comp_queue[$];
  comp_queue.push_back(comp);
  while (comp_queue.size() > 0) begin
    current = comp_queue.pop_front();
    // Process component...
  end
endtask
```

### Issue 7: Test Not Found at Runtime

**Error:**
```
Warning: Unknown test 'my_test', using default
```

**Solution:**
Add test to factory function in `tb_top.sv`:
```systemverilog
function uvm_component create_test(string test_name);
  case (test_name)
    "my_test": return my_test::create_object("test", null);  // Add this line
    // ... other tests
  endcase
endfunction
```

---

## Performance Comparison

| Metric | Commercial Sim (VCS) | Verilator |
|--------|---------------------|-----------|
| Compile Time | 30-60s per test | 90s once, 0s for reruns |
| Runtime | 5-10s | 1-2s |
| Memory | 500MB-2GB | 50-200MB |
| Waveform | VPD/FSDB | VCD |
| Debug | GUI debugger | GDB + GTKWave |

**Verilator Advantages:**
- ✅ Much faster simulation
- ✅ Lower memory usage
- ✅ Free and open-source
- ✅ Compile once, run many tests

**Verilator Limitations:**
- ❌ No full UVM support
- ❌ Limited randomization
- ❌ No DPI-C
- ❌ Simpler debug tools

---

## Verification Checklist

When converting your testbench:

### Code Changes
- [ ] Replace `::type_id::create` with `::create_object`
- [ ] Replace `randomize()` with `$urandom()` / `$urandom_range()`
- [ ] Remove or simplify complex constraints
- [ ] Add `pre_start()` hook for `p_sequencer` casting
- [ ] Initialize all interface signals
- [ ] Use registered DUT logic (not pure combinational)
- [ ] Set config_db with wildcard: `set(null, "*", "vif", ...)`
- [ ] Create test factory function in tb_top

### Makefile Changes
- [ ] Remove TEST from VERILATOR_FLAGS
- [ ] Make `run` target not depend on `compile`
- [ ] Add `+TEST=` runtime argument to executable
- [ ] Add `build_and_run` target for first-time use

### Testing
- [ ] Run `make compile` once
- [ ] Test all tests without recompilation
- [ ] Verify plusarg test selection works
- [ ] Check waveforms are generated
- [ ] Confirm objection handling works

---

## Example Output

### Successful Run

```bash
$ make run TEST=axi_simple_test
=========================================
Running simulation...
Test: axi_simple_test
=========================================
========================================
UVM Testbench (Verilator compatible)
Test: axi_simple_test
========================================
test (axi_simple_test)
  env (axi_env)
    master_agent (axi_master_agent)
    slave_agent (axi_slave_agent)
    scoreboard (axi_scoreboard)
    virtual_sequencer (axi_virtual_sequencer)
[INFO] @0 [OBJECTION] Raised by vseq: count=1
[INFO] @0 [axi_simple_vseq] Starting Simple Virtual Sequence
[INFO] @10000 [axi_write_sequence] Write executed: addr=0x1d9c data=0x9efdd502
[INFO] @20000 [axi_write_sequence] Write executed: addr=0x1378 data=0xbbd58ebc
...
[INFO] @100000 [axi_read_sequence] Read executed: addr=0x1b10
[INFO] @200000 [axi_simple_vseq] Completed Simple Virtual Sequence
[INFO] @200000 [OBJECTION] Dropped by vseq: count=0
========================================
Test Complete
========================================
```

### Test Switching (No Recompilation)

```bash
$ make compile                    # Compile once
$ make run TEST=axi_simple_test   # Run test 1
$ make run TEST=axi_burst_test    # Run test 2 (no recompile!)
$ make run TEST=axi_random_test   # Run test 3 (no recompile!)
```

---

## Advanced Topics

### Adding New Tests

1. **Create test class:**
   ```systemverilog
   class my_new_test extends axi_base_test;
     `uvm_component_utils(my_new_test)
     // ... implementation
   endclass
   ```

2. **Add to factory:**
   ```systemverilog
   // In tb_top.sv
   function uvm_component create_test(string test_name);
     case (test_name)
       "my_new_test": return my_new_test::create_object("test", null);
       // ...
     endcase
   endfunction
   ```

3. **Recompile and run:**
   ```bash
   make compile
   make run TEST=my_new_test
   ```

### Debugging

```bash
# Generate waveforms
make run TEST=my_test

# View with GTKWave
make waves

# Add signals to view
# - Open axi_test.vcd in GTKWave
# - Navigate hierarchy: tb_top -> axi_if
# - Add signals of interest
```

### Coverage (Limited)

Verilator supports line and toggle coverage:

```makefile
VERILATOR_FLAGS += --coverage

# After simulation
verilator_coverage --annotate logs/annotated coverage.dat
```

---

## Conclusion

Converting UVM testbenches to Verilator requires systematic changes to work around tool limitations. The main modifications are:

1. **Factory pattern**: Static `create_object()` instead of dynamic `type_id::create()`
2. **Randomization**: Direct assignment with `$urandom()` instead of `randomize()`
3. **Test selection**: Runtime `+TEST=` with manual factory instead of UVM_TESTNAME
4. **Build flow**: Compile once with all tests, select at runtime

The result is a fast, open-source simulation environment suitable for regression testing and CI/CD integration.

---

## License

This example is provided for educational purposes. See LICENSE for details.

## Support

For issues and questions:
- GitHub Issues: https://github.com/yourusername/UVM_EXAMPLE/issues
- Verilator Documentation: https://verilator.org/guide/latest/
- UVM Reference: https://www.accellera.org/downloads/standards/uvm
