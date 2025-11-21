// Minimal UVM package for Verilator
// Replacement for standard UVM

`ifndef VERILATOR_UVM_PKG_SV
`define VERILATOR_UVM_PKG_SV

`include "uvm_macros.svh"

package uvm_pkg;

  // ===== TYPES AND ENUMS =====

  typedef enum {
    UVM_NONE = 0,
    UVM_LOW = 100,
    UVM_MEDIUM = 200,
    UVM_HIGH = 300,
    UVM_FULL = 400,
    UVM_DEBUG = 500
  } uvm_verbosity;

  typedef enum {
    UVM_INFO,
    UVM_WARNING,
    UVM_ERROR,
    UVM_FATAL
  } uvm_severity;

  typedef enum int {
    UVM_NO_ACTION = 0,
    UVM_DISPLAY   = 1,
    UVM_LOG       = 2,
    UVM_COUNT     = 4,
    UVM_EXIT      = 8,
    UVM_CALL_HOOK = 16,
    UVM_STOP      = 32,
    UVM_RM_RECORD = 64
  } uvm_action_type;

  parameter UVM_ALL_ON = -1;

  typedef enum bit {
    UVM_PASSIVE = 0,
    UVM_ACTIVE = 1
  } uvm_active_passive_enum;

  typedef enum {
    UVM_PHASE_BUILD,
    UVM_PHASE_CONNECT,
    UVM_PHASE_END_OF_ELABORATION,
    UVM_PHASE_START_OF_SIMULATION,
    UVM_PHASE_RUN,
    UVM_PHASE_EXTRACT,
    UVM_PHASE_CHECK,
    UVM_PHASE_REPORT,
    UVM_PHASE_FINAL
  } uvm_phase_type;

  // ===== GLOBAL VARIABLES =====

  uvm_verbosity global_verbosity = UVM_MEDIUM;

  // ===== BASE CLASSES =====

  virtual class uvm_void;
  endclass

  class uvm_object extends uvm_void;
    string m_name;  // Public for Verilator

    function new(string name = "uvm_object");
      m_name = name;
    endfunction

    virtual function string get_name();
      return m_name;
    endfunction

    virtual function string get_type_name();
      return "uvm_object";
    endfunction

    virtual function string get_full_name();
      return m_name;
    endfunction

    virtual function string sprint();
      string s;
      s = $sformatf("%s: %s", get_type_name(), get_name());
      return s;
    endfunction
  endclass

  // ===== PHASE =====

  class uvm_phase extends uvm_object;
    int m_objection_count;  // Public for Verilator

    function new(string name = "phase");
      super.new(name);
      m_objection_count = 0;
    endfunction

    task raise_objection(uvm_object obj, string description = "", int count = 1);
      m_objection_count += count;
      `uvm_info("OBJECTION", $sformatf("Raised by %s: count=%0d",
                obj != null ? obj.get_name() : "null", m_objection_count), UVM_MEDIUM)
    endtask

    task drop_objection(uvm_object obj, string description = "", int count = 1);
      m_objection_count -= count;
      `uvm_info("OBJECTION", $sformatf("Dropped by %s: count=%0d",
                obj != null ? obj.get_name() : "null", m_objection_count), UVM_MEDIUM)
      if (m_objection_count <= 0) begin
        #1ns;  // Allow time for final operations
      end
    endtask
  endclass

  // ===== COMPONENT HIERARCHY =====

  class uvm_component extends uvm_object;
    protected uvm_component m_parent;
    uvm_component m_children[$];  // Public for Verilator

    function new(string name, uvm_component parent = null);
      super.new(name);
      m_parent = parent;
      if (parent != null)
        parent.m_children.push_back(this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
    endfunction

    virtual function void start_of_simulation_phase(uvm_phase phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
    endtask

    virtual function void extract_phase(uvm_phase phase);
    endfunction

    virtual function void check_phase(uvm_phase phase);
    endfunction

    virtual function void report_phase(uvm_phase phase);
    endfunction

    virtual function void final_phase(uvm_phase phase);
    endfunction

    function uvm_component get_parent();
      return m_parent;
    endfunction

    virtual function string get_full_name();
      if (m_parent == null)
        return get_name();
      else
        return {m_parent.get_full_name(), ".", get_name()};
    endfunction

    function void print_topology();
      print_comp(this, 0);
    endfunction

    local function void print_comp(uvm_component comp, int indent);
      string spaces = "";
      for (int i = 0; i < indent; i++)  spaces = {spaces, "  "};
      $display("%s%s (%s)", spaces, comp.get_name(), comp.get_type_name());
      foreach (comp.m_children[i])
        print_comp(comp.m_children[i], indent + 1);
    endfunction
  endclass

  // ===== TRANSACTION CLASSES =====

  class uvm_sequence_item extends uvm_object;
    function new(string name = "uvm_sequence_item");
      super.new(name);
    endfunction
  endclass

  class uvm_sequence_base extends uvm_object;
    uvm_phase starting_phase;
    uvm_component m_sequencer;  // Base sequencer handle

    function new(string name = "uvm_sequence");
      super.new(name);
    endfunction

    virtual task pre_start();
      // Called before body, can be overridden
    endtask

    virtual task pre_body();
      if(starting_phase != null)
        starting_phase.raise_objection(this);
    endtask

    virtual task body();
    endtask

    virtual task post_body();
      if(starting_phase != null)
        starting_phase.drop_objection(this);
    endtask

    virtual task post_start();
      // Called after body, can be overridden
    endtask

    virtual task start(uvm_component sequencer);
      m_sequencer = sequencer;  // Store sequencer
      pre_start();
      pre_body();
      body();
      post_body();
      post_start();
    endtask
  endclass

  // ===== COMPONENT TYPES =====

  class uvm_sequencer_base extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  class uvm_driver_base extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  class uvm_monitor extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  class uvm_agent extends uvm_component;
    protected uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function uvm_active_passive_enum get_is_active();
      return is_active;
    endfunction

    function void set_is_active(uvm_active_passive_enum active);
      is_active = active;
    endfunction
  endclass

  class uvm_env extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  class uvm_test extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  class uvm_scoreboard extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  // ===== PARAMETERIZED TLM CLASSES =====

  `include "uvm_minimal_tlm.sv"

  // ===== RUN TEST INFRASTRUCTURE =====

  task run_phases(uvm_component comp, uvm_phase phase);
    uvm_component comp_queue[$];
    uvm_component current;

    // Build all components using queue (iterative instead of recursive)
    phase.m_name = "build";
    comp_queue.push_back(comp);
    while (comp_queue.size() > 0) begin
      current = comp_queue.pop_front();
      current.build_phase(phase);
      foreach (current.m_children[i])
        comp_queue.push_back(current.m_children[i]);
    end

    // Connect phase
    phase.m_name = "connect";
    comp.connect_phase(phase);

    // End of elaboration
    phase.m_name = "end_of_elaboration";
    comp.end_of_elaboration_phase(phase);

    // Start of simulation
    phase.m_name = "start_of_simulation";
    comp.start_of_simulation_phase(phase);

    // Run phase
    phase.m_name = "run";
    fork
      comp.run_phase(phase);
      foreach (comp.m_children[i])
        comp.m_children[i].run_phase(phase);
    join

    // Wait for objections
    wait (phase.m_objection_count <= 0);

    // Extract phase
    phase.m_name = "extract";
    comp.extract_phase(phase);

    // Check phase
    phase.m_name = "check";
    comp.check_phase(phase);

    // Report phase
    phase.m_name = "report";
    comp.report_phase(phase);

    // Final phase
    phase.m_name = "final";
    comp.final_phase(phase);
  endtask

  task run_test(string test_name = "");
    uvm_phase phase;
    uvm_component uvm_top_local;

    $display("========================================");
    $display("UVM Testbench (Verilator compatible)");
    if (test_name != "")
      $display("Test: %s", test_name);
    $display("========================================");

    // Create phase
    phase = new("uvm_phase");

    // Create test based on name (simplified factory)
    // The actual test creation happens in tb_top via axi_tb_pkg
    // This just creates a placeholder top component
    uvm_top_local = new("uvm_top", null);

    // Run all phases
    run_phases(uvm_top_local, phase);

    $display("========================================");
    $display("Test Complete");
    $display("========================================");
  endtask

endpackage

`endif
