// Minimal UVM-like package for Verilator compatibility
// This provides basic UVM functionality without problematic features

`ifndef UVM_MINIMAL_PKG_SV
`define UVM_MINIMAL_PKG_SV

package uvm_pkg;

  // Verbosity levels
  typedef enum {
    UVM_NONE = 0,
    UVM_LOW = 100,
    UVM_MEDIUM = 200,
    UVM_HIGH = 300,
    UVM_FULL = 400,
    UVM_DEBUG = 500
  } uvm_verbosity;

  // Severity levels
  typedef enum {
    UVM_INFO,
    UVM_WARNING,
    UVM_ERROR,
    UVM_FATAL
  } uvm_severity;

  // Action types
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

  // Active/Passive enum
  typedef enum bit {
    UVM_PASSIVE = 0,
    UVM_ACTIVE = 1
  } uvm_active_passive_enum;

  // Phase types (simplified)
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

  // Global verbosity
  uvm_verbosity global_verbosity = UVM_MEDIUM;

  // Simple reporting
  function void uvm_report_info(string id, string message, int verbosity = UVM_MEDIUM);
    if (verbosity <= global_verbosity) begin
      $display("[INFO] @%0t: %s: %s", $time, id, message);
    end
  endfunction

  function void uvm_report_warning(string id, string message);
    $display("[WARNING] @%0t: %s: %s", $time, id, message);
  endfunction

  function void uvm_report_error(string id, string message);
    $display("[ERROR] @%0t: %s: %s", $time, id, message);
  endfunction

  function void uvm_report_fatal(string id, string message);
    $display("[FATAL] @%0t: %s: %s", $time, id, message);
    $finish;
  endfunction

  // Base uvm_void (simplest base)
  virtual class uvm_void;
  endclass

  // Base uvm_object
  class uvm_object extends uvm_void;
    protected string m_name;

    function new(string name = "uvm_object");
      m_name = name;
    endfunction

    virtual function string get_name();
      return m_name;
    endfunction

    virtual function string get_type_name();
      return "uvm_object";
    endfunction

    virtual function uvm_object clone();
      return null;  // Simplified
    endfunction

    virtual function void do_print();
      $display("%s", get_name());
    endfunction

    virtual function string sprint();
      return get_name();
    endfunction
  endclass

  // Phase object (simplified)
  class uvm_phase extends uvm_object;
    uvm_phase_type phase_type;

    function new(string name = "phase");
      super.new(name);
    endfunction

    task raise_objection(uvm_object obj, string description = "", int count = 1);
      // Simplified - just log
    endtask

    task drop_objection(uvm_object obj, string description = "", int count = 1);
      // Simplified - just log
    endtask
  endclass

  // Component base
  class uvm_component extends uvm_object;
    protected uvm_component m_parent;

    function new(string name, uvm_component parent = null);
      super.new(name);
      m_parent = parent;
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
  endclass

  // Simplified transaction/sequence_item
  class uvm_sequence_item extends uvm_object;
    function new(string name = "uvm_sequence_item");
      super.new(name);
    endfunction
  endclass

  // Simplified sequencer
  class uvm_sequencer_base extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  // Simplified driver base
  class uvm_driver_base extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  // Simplified monitor
  class uvm_monitor extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  // Simplified agent
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

  // Simplified environment
  class uvm_env extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  // Simplified test
  class uvm_test extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  // Simplified scoreboard
  class uvm_scoreboard extends uvm_component;
    function new(string name, uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  // Simplified sequence
  class uvm_sequence_base extends uvm_object;
    uvm_phase starting_phase;

    function new(string name = "uvm_sequence");
      super.new(name);
    endfunction

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
  endclass

  // Global run_test task
  uvm_component uvm_top;

  task run_test(string test_name = "");
    // Simplified - just display
    $display("UVM Minimal: run_test called with test=%s", test_name);
  endtask

  // Config DB (simplified with no parameterization)
  class uvm_config_db_base;
    static function bit get_string(uvm_component cntxt, string inst_name, string field_name, ref string value);
      return 0;
    endfunction

    static function void set_string(uvm_component cntxt, string inst_name, string field_name, string value);
    endfunction
  endclass

endpackage

`endif
