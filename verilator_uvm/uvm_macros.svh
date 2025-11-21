// Minimal UVM-like macros for Verilator compatibility

`ifndef UVM_MINIMAL_MACROS_SVH
`define UVM_MINIMAL_MACROS_SVH

// Info/Warning/Error macros
`define uvm_info(ID, MSG, VERBOSITY) \
  begin \
    if (VERBOSITY <= uvm_pkg::global_verbosity) \
      $display("[INFO] @%0t [%s] %s", $time, ID, MSG); \
  end

`define uvm_warning(ID, MSG) \
  begin \
    $display("[WARNING] @%0t [%s] %s", $time, ID, MSG); \
  end

`define uvm_error(ID, MSG) \
  begin \
    $display("[ERROR] @%0t [%s] %s", $time, ID, MSG); \
  end

`define uvm_fatal(ID, MSG) \
  begin \
    $display("[FATAL] @%0t [%s] %s", $time, ID, MSG); \
    $finish; \
  end

// Object utils simplified for Verilator
// type_id is a typedef with create_object function
`define uvm_object_utils(T) \
  virtual function string get_type_name(); \
    return `"T`"; \
  endfunction \
  \
  typedef T type_id; \
  \
  static function T create_object(string name = "obj"); \
    T obj = new(name); \
    return obj; \
  endfunction

// Workaround for type_id::create syntax
`define type_id_create(TYPE, NAME) TYPE::create_object(NAME)

// Object utils with field automation (very simplified)
`define uvm_object_utils_begin(T) \
  `uvm_object_utils(T)

`define uvm_object_utils_end

// Field macros (do nothing in simplified version)
`define uvm_field_int(ARG, FLAG)
`define uvm_field_enum(T, ARG, FLAG)

// Component utils (simplified)
`define uvm_component_utils(T) \
  virtual function string get_type_name(); \
    return `"T`"; \
  endfunction \
  \
  typedef T type_id; \
  \
  static function T create_object(string name, uvm_pkg::uvm_component parent); \
    T obj = new(name, parent); \
    return obj; \
  endfunction

// Component utils begin/end
`define uvm_component_utils_begin(T) \
  `uvm_component_utils(T)

`define uvm_component_utils_end

// Analysis imp macros (for multiple analysis ports)
// Simplified to work with Verilator
`define uvm_analysis_imp_decl(SUFFIX)

// We'll use a simpler approach without macros for analysis_imp

// Declare p_sequencer and add pre_start to cast m_sequencer
`define uvm_declare_p_sequencer(SEQUENCER) \
  SEQUENCER p_sequencer; \
  \
  virtual task pre_start(); \
    super.pre_start(); \
    if (m_sequencer != null) begin \
      if (!$cast(p_sequencer, m_sequencer)) begin \
        `uvm_fatal(get_type_name(), "Failed to cast m_sequencer to p_sequencer") \
      end \
    end else begin \
      `uvm_fatal(get_type_name(), "m_sequencer is null") \
    end \
  endtask

`endif
