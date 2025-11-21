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
  $display("[WARNING] @%0t [%s] %s", $time, ID, MSG)

`define uvm_error(ID, MSG) \
  $display("[ERROR] @%0t [%s] %s", $time, ID, MSG)

`define uvm_fatal(ID, MSG) \
  begin \
    $display("[FATAL] @%0t [%s] %s", $time, ID, MSG); \
    $finish; \
  end

// Object utils (simplified - no factory)
`define uvm_object_utils(T) \
  virtual function string get_type_name(); \
    return `"T`"; \
  endfunction \
  \
  static function T type_id_create(string name); \
    T obj = new(name); \
    return obj; \
  endfunction

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
  static function T type_id_create(string name, uvm_pkg::uvm_component parent); \
    T obj = new(name, parent); \
    return obj; \
  endfunction

// Component utils begin/end
`define uvm_component_utils_begin(T) \
  `uvm_component_utils(T)

`define uvm_component_utils_end

// Analysis imp macros (for multiple analysis ports)
`define uvm_analysis_imp_decl(SUFFIX) \
  class uvm_analysis_imp``SUFFIX extends uvm_pkg::uvm_object; \
    function new(string name, uvm_pkg::uvm_component parent); \
      super.new(name); \
    endfunction \
    \
    function void write``SUFFIX(uvm_pkg::uvm_object trans); \
    endfunction \
  endclass

// Declare p_sequencer
`define uvm_declare_p_sequencer(SEQUENCER) \
  SEQUENCER p_sequencer;

`endif
