// Minimal TLM and parameterized classes for Verilator

`ifndef UVM_MINIMAL_TLM_SV
`define UVM_MINIMAL_TLM_SV

// Analysis port - simplified without complex parameterization
class uvm_analysis_port #(type T = uvm_pkg::uvm_sequence_item) extends uvm_pkg::uvm_object;
  function new(string name, uvm_pkg::uvm_component parent = null);
    super.new(name);
  endfunction

  function void write(T trans);
    // Simplified - does nothing
  endfunction

  function void connect(uvm_pkg::uvm_object imp);
    // Simplified connection
  endfunction
endclass

// Analysis export
class uvm_analysis_export #(type T = uvm_pkg::uvm_sequence_item) extends uvm_pkg::uvm_object;
  function new(string name, uvm_pkg::uvm_component parent = null);
    super.new(name);
  endfunction
endclass

// Analysis imp base (for custom write functions)
class uvm_analysis_imp #(type T = uvm_pkg::uvm_sequence_item, type IMP = uvm_pkg::uvm_component) extends uvm_pkg::uvm_object;
  local IMP m_imp;

  function new(string name, IMP imp);
    super.new(name);
    m_imp = imp;
  endfunction

  function void write(T trans);
    // Call the imp's write function
    if (m_imp != null) begin
      // Simplified - would normally call m_imp.write(trans)
    end
  endfunction
endclass

// SEQ_ITEM_EXPORT for sequencer
class uvm_seq_item_pull_export #(type REQ = uvm_pkg::uvm_sequence_item, type RSP = REQ) extends uvm_pkg::uvm_object;
  function new(string name, uvm_pkg::uvm_component parent = null);
    super.new(name);
  endfunction
endclass

// SEQ_ITEM_PORT for driver-sequencer connection
class uvm_seq_item_pull_port #(type REQ = uvm_pkg::uvm_sequence_item, type RSP = REQ) extends uvm_pkg::uvm_object;
  function new(string name, uvm_pkg::uvm_component parent = null);
    super.new(name);
  endfunction

  task connect(uvm_pkg::uvm_object provider);
    // Simplified connection - avoid parameterized forward ref
  endtask

  task get_next_item(output REQ req);
    // Simplified - in real UVM this talks to sequencer
    #10ns;  // Dummy delay
  endtask

  function void item_done(RSP rsp = null);
    // Simplified
  endfunction
endclass

// Sequencer with parameterization
class uvm_sequencer #(type REQ = uvm_pkg::uvm_sequence_item, type RSP = REQ) extends uvm_pkg::uvm_sequencer_base;
  uvm_seq_item_pull_export#(REQ, RSP) seq_item_export;

  function new(string name, uvm_pkg::uvm_component parent = null);
    super.new(name, parent);
    seq_item_export = new("seq_item_export", this);
  endfunction
endclass

// Driver with parameterization
class uvm_driver #(type REQ = uvm_pkg::uvm_sequence_item, type RSP = REQ) extends uvm_pkg::uvm_driver_base;
  uvm_seq_item_pull_port#(REQ, RSP) seq_item_port;
  REQ req;
  RSP rsp;

  function new(string name, uvm_pkg::uvm_component parent = null);
    super.new(name, parent);
    seq_item_port = new("seq_item_port", this);
  endfunction
endclass

// Sequence with parameterization
class uvm_sequence #(type REQ = uvm_pkg::uvm_sequence_item, type RSP = REQ) extends uvm_pkg::uvm_sequence_base;
  REQ req;
  RSP rsp;

  function new(string name = "uvm_sequence");
    super.new(name);
  endfunction

  task start_item(REQ item);
    req = item;
  endtask

  task finish_item(REQ item);
    #10ns;  // Simplified timing
  endtask

  task get_response(output RSP response);
    response = rsp;
  endtask
endclass

// Config DB with parameterization simplified
// Uses output instead of ref for compatibility
class uvm_config_db #(type T = int);
  static T db[string];

  static function bit get(uvm_pkg::uvm_component cntxt, string inst_name, string field_name, output T value);
    string key = {inst_name, ".", field_name};

    // First try exact match
    if (db.exists(key)) begin
      value = db[key];
      return 1;
    end

    // Try wildcard match
    if (db.exists({"*.", field_name})) begin
      value = db[{"*.", field_name}];
      return 1;
    end

    // Try field_name only
    if (db.exists(field_name)) begin
      value = db[field_name];
      return 1;
    end

    return 0;
  endfunction

  static function void set(uvm_pkg::uvm_component cntxt, string inst_name, string field_name, T value);
    string key;
    if (inst_name == "")
      key = field_name;
    else
      key = {inst_name, ".", field_name};
    db[key] = value;
  endfunction
endclass

// Analysis imp variants (for scoreboard with multiple inputs)
// These replace the uvm_analysis_imp_decl macro
class uvm_analysis_imp_master #(type T = uvm_pkg::uvm_sequence_item, type IMP = uvm_pkg::uvm_component) extends uvm_pkg::uvm_object;
  local IMP m_imp;

  function new(string name, IMP imp);
    super.new(name);
    m_imp = imp;
  endfunction

  function void write(T trans);
    // Will call m_imp.write_master(trans)
  endfunction
endclass

class uvm_analysis_imp_slave #(type T = uvm_pkg::uvm_sequence_item, type IMP = uvm_pkg::uvm_component) extends uvm_pkg::uvm_object;
  local IMP m_imp;

  function new(string name, IMP imp);
    super.new(name);
    m_imp = imp;
  endfunction

  function void write(T trans);
    // Will call m_imp.write_slave(trans)
  endfunction
endclass

`endif
