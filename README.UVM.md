# UVM Library Modifications for Verilator Compatibility

This document describes the modifications required to create a Verilator-compatible UVM subset. The standard UVM library (UVM 1.2) is designed for commercial simulators (VCS, Questa, Xcelium) and uses features that Verilator does not support.

## Table of Contents

- [Verilator Limitations](#verilator-limitations)
- [Architectural Changes](#architectural-changes)
- [File Structure](#file-structure)
- [Detailed Modifications](#detailed-modifications)
- [Usage](#usage)

---

## Verilator Limitations

Verilator is a fast, open-source simulator that compiles SystemVerilog to C++. However, it has several limitations compared to commercial simulators:

### 1. **No DPI-C Support**
- **Standard UVM**: Uses DPI-C extensively for core functionality
- **Impact**: Cannot use standard UVM library
- **Solution**: Pure SystemVerilog implementation

### 2. **Limited Randomization Support**
- **Standard UVM**: Relies on `randomize()` with complex constraints
- **Impact**: `randomize()` may fail or behave unpredictably
- **Solution**: Use direct assignments with `$urandom()` and `$urandom_range()`

### 3. **No Support for `ref` Arguments with Virtual Interfaces**
- **Standard UVM**: `uvm_config_db#(T)::get(ref T value)`
- **Impact**: Compilation errors with virtual interface types
- **Solution**: Use `output` instead of `ref` for config_db

### 4. **Limited Nested Class Support**
- **Standard UVM**: Uses `type_id::create()` pattern with nested static classes
- **Impact**: Parser errors with `::type_id::create` syntax
- **Solution**: Flatten to `static function T create_object()`

### 5. **Strict Encapsulation**
- **Standard UVM**: May access protected members internally
- **Impact**: Access violations that commercial simulators allow
- **Solution**: Make internal members public with comments

### 6. **No Support for Recursive `automatic` Tasks in Packages**
- **Standard UVM**: Uses recursive phase execution
- **Impact**: Internal Verilator error
- **Solution**: Use iterative approach with queues

### 7. **Macro Expansion Limitations**
- **Standard UVM**: Complex nested macros (e.g., `uvm_revision`)
- **Impact**: Parser errors
- **Solution**: Hardcode values or simplify macros

---

## Architectural Changes

### Standard UVM → Minimal UVM for Verilator

| Feature | Standard UVM | Minimal UVM for Verilator |
|---------|--------------|---------------------------|
| **DPI-C** | Required | Eliminated |
| **Factory Pattern** | Full dynamic creation | Simplified static factory |
| **Randomization** | Constraint solver | Direct assignment |
| **Phases** | Dynamic phase graph | Fixed linear phases |
| **TLM** | Full TLM 1.0/2.0 | Simplified ports only |
| **Reporting** | Complex reporting system | Simple macros |
| **Configuration** | Hierarchical config DB | Simplified key-value store |
| **Objections** | Drain time, callbacks | Simple counter |

---

## File Structure

```
verilator_uvm/
├── uvm_pkg.sv           # Main UVM package
├── uvm_macros.svh       # Simplified UVM macros
└── uvm_minimal_tlm.sv   # TLM and parameterized classes
```

### Dependencies

- **uvm_pkg.sv**: Core classes (object, component, phase, sequence)
- **uvm_macros.svh**: Utility macros for common patterns
- **uvm_minimal_tlm.sv**: Parameterized TLM ports and config_db

---

## Detailed Modifications

### 1. uvm_pkg.sv Changes

#### A. Base Classes

**Protected → Public Members**

```systemverilog
// BEFORE (Standard UVM)
class uvm_object extends uvm_void;
  protected string m_name;

// AFTER (Verilator-compatible)
class uvm_object extends uvm_void;
  string m_name;  // Public for Verilator
```

**Reason**: Verilator strictly enforces access control.

#### B. Phase Execution

**Recursive → Iterative**

```systemverilog
// BEFORE (Standard UVM - recursive)
task automatic run_phases(uvm_component comp, uvm_phase phase, bit is_top = 0);
  comp.build_phase(phase);
  foreach (comp.m_children[i])
    run_phases(comp.m_children[i], phase, 0);  // Recursion
endtask

// AFTER (Verilator-compatible - iterative)
task run_phases(uvm_component comp, uvm_phase phase);
  uvm_component comp_queue[$];
  uvm_component current;

  phase.m_name = "build";
  comp_queue.push_back(comp);
  while (comp_queue.size() > 0) begin
    current = comp_queue.pop_front();
    current.build_phase(phase);
    foreach (current.m_children[i])
      comp_queue.push_back(current.m_children[i]);
  end
endtask
```

**Reason**: Verilator cannot handle recursive `automatic` tasks in packages.

#### C. Sequence Mechanism

**Add Sequencer Handling**

```systemverilog
// BEFORE (Standard UVM)
virtual task start(uvm_sequencer_base sequencer);
  // Complex sequencer registration
endtask

// AFTER (Verilator-compatible)
class uvm_sequence_base extends uvm_object;
  uvm_component m_sequencer;  // Store sequencer

  virtual task pre_start();
    // Hook for derived classes
  endtask

  virtual task start(uvm_component sequencer);
    m_sequencer = sequencer;
    pre_start();
    pre_body();
    body();
    post_body();
    post_start();
  endtask
endclass
```

**Reason**: Simplified sequencer management without factory complexity.

### 2. uvm_macros.svh Changes

#### A. Factory Pattern Workaround

**Nested Type ID → Static Create Function**

```systemverilog
// BEFORE (Standard UVM)
`define uvm_object_utils(T) \
  typedef uvm_object_registry#(T, `"T`") type_id; \
  static function type_id get_type();

// AFTER (Verilator-compatible)
`define uvm_object_utils(T) \
  virtual function string get_type_name(); \
    return `"T`"; \
  endfunction \
  typedef T type_id; \
  static function T create_object(string name = "obj"); \
    T obj = new(name); \
    return obj; \
  endfunction
```

**Usage Change**:
```systemverilog
// BEFORE: trans = transaction::type_id::create("trans");
// AFTER:  trans = transaction::create_object("trans");
```

**Reason**: Verilator doesn't support `::type_id::create` nested class syntax.

#### B. P-Sequencer Declaration

**Add Pre-Start Hook**

```systemverilog
// BEFORE (Standard UVM)
`define uvm_declare_p_sequencer(SEQUENCER) \
  SEQUENCER p_sequencer;

// AFTER (Verilator-compatible)
`define uvm_declare_p_sequencer(SEQUENCER) \
  SEQUENCER p_sequencer; \
  virtual task pre_start(); \
    super.pre_start(); \
    if (m_sequencer != null) begin \
      if (!$cast(p_sequencer, m_sequencer)) \
        `uvm_fatal(get_type_name(), "Failed to cast") \
    end \
  endtask
```

**Reason**: Must manually cast and assign p_sequencer from base m_sequencer.

### 3. uvm_minimal_tlm.sv Changes

#### A. Config DB

**Ref → Output + Wildcard Support**

```systemverilog
// BEFORE (Standard UVM)
static function bit get(uvm_component cntxt, string inst_name,
                       string field_name, ref T value);

// AFTER (Verilator-compatible)
static function bit get(uvm_component cntxt, string inst_name,
                       string field_name, output T value);
  string key = {inst_name, ".", field_name};

  // Try exact match
  if (db.exists(key)) begin
    value = db[key];
    return 1;
  end

  // Try wildcard match
  if (db.exists({"*.", field_name})) begin
    value = db[{"*.", field_name}];
    return 1;
  end

  return 0;
endfunction
```

**Reason**: Verilator doesn't support `ref` with virtual interface types.

#### B. Parameterized Classes

**Simplified Implementation**

```systemverilog
// AFTER (Verilator-compatible)
class uvm_sequencer #(type REQ = uvm_pkg::uvm_sequence_item,
                      type RSP = REQ)
  extends uvm_pkg::uvm_sequencer_base;

  uvm_seq_item_pull_export#(REQ, RSP) seq_item_export;

  function new(string name, uvm_pkg::uvm_component parent = null);
    super.new(name, parent);
    seq_item_export = new("seq_item_export", this);
  endfunction
endclass
```

**Reason**: Simplified to avoid complex parameterization that Verilator struggles with.

---

## Usage

### Compiling with Verilator

```makefile
VERILATOR_FLAGS = --cc --exe --build \
                  -sv --assert --timing \
                  --bbox-unsup --bbox-sys \
                  -Wno-UNUSED -Wno-UNDRIVEN \
                  -Iverilator_uvm

verilator $(VERILATOR_FLAGS) verilator_uvm/uvm_pkg.sv your_tb.sv
```

### Including in Testbench

```systemverilog
`include "uvm_macros.svh"
import uvm_pkg::*;

// Your testbench code
```

### Creating Objects

```systemverilog
// Use create_object instead of type_id::create
my_transaction trans = my_transaction::create_object("trans");
```

---

## Comparison Matrix

| Feature | Standard UVM | Minimal UVM | Notes |
|---------|--------------|-------------|-------|
| Object Creation | `::type_id::create()` | `::create_object()` | Static function |
| Randomization | `randomize()` with constraints | `$urandom()` | Direct assignment |
| Config DB Get | `get(ref T)` | `get(output T)` | Output parameter |
| Phases | Dynamic graph | Fixed linear | Simplified |
| Protected Members | Widely used | Made public | Access control |
| Recursive Tasks | Supported | Iterative only | Queue-based |
| DPI-C | Extensive | None | Pure SV |
| Factory | Full dynamic | Static create | No registry |

---

## Limitations of Minimal UVM

### Not Supported
- ❌ Full UVM factory with overrides
- ❌ Dynamic phase graph
- ❌ Complex randomization constraints
- ❌ Sequence item export/import with handshake
- ❌ Full TLM 1.0/2.0 implementation
- ❌ UVM register layer (RAL)
- ❌ Coverage integration
- ❌ Transaction recording

### Supported
- ✅ Basic class hierarchy (object, component)
- ✅ Linear phase execution
- ✅ Sequences and virtual sequences
- ✅ Agents with driver/monitor/sequencer
- ✅ Scoreboards
- ✅ Config DB (simplified)
- ✅ Basic reporting (info/warning/error/fatal)
- ✅ Objections (simple counter)
- ✅ Analysis ports
- ✅ Parameterized classes

---

## License

This Verilator-compatible UVM subset is provided as-is for educational and reference purposes.

## References

- [Verilator Manual](https://verilator.org/guide/latest/)
- [SystemVerilog LRM](https://ieeexplore.ieee.org/document/8299595)
- [UVM 1.2 Class Reference](https://www.accellera.org/downloads/standards/uvm)
