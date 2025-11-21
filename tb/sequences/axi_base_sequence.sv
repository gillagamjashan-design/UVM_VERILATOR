`ifndef AXI_BASE_SEQUENCE_SV
`define AXI_BASE_SEQUENCE_SV

// Base sequence for master
class axi_master_base_sequence extends uvm_sequence #(axi_transaction);

  `uvm_object_utils(axi_master_base_sequence)

  function new(string name = "axi_master_base_sequence");
    super.new(name);
  endfunction

endclass

// Simple write sequence
class axi_write_sequence extends axi_master_base_sequence;

  `uvm_object_utils(axi_write_sequence)

  rand bit [31:0] addr;
  rand bit [31:0] data;

  function new(string name = "axi_write_sequence");
    super.new(name);
  endfunction

  virtual task body();
    axi_transaction trans;
    trans = axi_transaction::create_object("trans");
    start_item(trans);
    // Simplified for Verilator - direct assignment instead of randomize
    trans.trans_type = axi_transaction::WRITE;
    trans.awaddr = addr;
    trans.wdata = data;
    trans.wstrb = 4'hF;  // All bytes valid
    trans.awprot = 0;
    finish_item(trans);
    `uvm_info(get_type_name(), $sformatf("Write sequence executed: addr=0x%0h data=0x%0h", addr, data), UVM_MEDIUM)
  endtask

endclass

// Simple read sequence
class axi_read_sequence extends axi_master_base_sequence;

  `uvm_object_utils(axi_read_sequence)

  rand bit [31:0] addr;
  bit [31:0] data;

  function new(string name = "axi_read_sequence");
    super.new(name);
  endfunction

  virtual task body();
    axi_transaction trans;
    trans = axi_transaction::create_object("trans");
    start_item(trans);
    // Simplified for Verilator - direct assignment instead of randomize
    trans.trans_type = axi_transaction::READ;
    trans.araddr = addr;
    trans.arprot = 0;
    finish_item(trans);
    // Simplified: skip response handling for Verilator
    data = $urandom();  // Dummy data
    `uvm_info(get_type_name(), $sformatf("Read sequence executed: addr=0x%0h", addr), UVM_MEDIUM)
  endtask

endclass

// Base sequence for slave
class axi_slave_base_sequence extends uvm_sequence #(axi_transaction);

  `uvm_object_utils(axi_slave_base_sequence)

  function new(string name = "axi_slave_base_sequence");
    super.new(name);
  endfunction

endclass

// Slave response sequence
class axi_slave_response_sequence extends axi_slave_base_sequence;

  `uvm_object_utils(axi_slave_response_sequence)

  function new(string name = "axi_slave_response_sequence");
    super.new(name);
  endfunction

  virtual task body();
    axi_transaction trans;
    forever begin
      trans = axi_transaction::create_object("trans");
      start_item(trans);
      // Simplified randomization for Verilator
      trans.rdata = $urandom();
      trans.bresp = 0;  // OKAY
      trans.rresp = 0;  // OKAY
      finish_item(trans);
    end
  endtask

endclass

`endif
