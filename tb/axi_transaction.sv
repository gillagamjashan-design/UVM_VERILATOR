`ifndef AXI_TRANSACTION_SV
`define AXI_TRANSACTION_SV

class axi_transaction extends uvm_sequence_item;

  // AXI LITE signals
  rand bit [31:0] awaddr;   // Write address
  rand bit [2:0]  awprot;   // Write protection
  rand bit        awvalid;  // Write address valid
  bit             awready;  // Write address ready

  rand bit [31:0] wdata;    // Write data
  rand bit [3:0]  wstrb;    // Write strobe
  rand bit        wvalid;   // Write valid
  bit             wready;   // Write ready

  bit [1:0]       bresp;    // Write response
  bit             bvalid;   // Write response valid
  rand bit        bready;   // Write response ready

  rand bit [31:0] araddr;   // Read address
  rand bit [2:0]  arprot;   // Read protection
  rand bit        arvalid;  // Read address valid
  bit             arready;  // Read address ready

  bit [31:0]      rdata;    // Read data
  bit [1:0]       rresp;    // Read response
  bit             rvalid;   // Read valid
  rand bit        rready;   // Read ready

  // Transaction type
  typedef enum {WRITE, READ} trans_type_e;
  rand trans_type_e trans_type;

  // UVM Macros
  `uvm_object_utils_begin(axi_transaction)
    `uvm_field_int(awaddr, UVM_ALL_ON)
    `uvm_field_int(awprot, UVM_ALL_ON)
    `uvm_field_int(wdata, UVM_ALL_ON)
    `uvm_field_int(wstrb, UVM_ALL_ON)
    `uvm_field_int(bresp, UVM_ALL_ON)
    `uvm_field_int(araddr, UVM_ALL_ON)
    `uvm_field_int(arprot, UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_field_int(rresp, UVM_ALL_ON)
    `uvm_field_enum(trans_type_e, trans_type, UVM_ALL_ON)
  `uvm_object_utils_end

  // Constructor
  function new(string name = "axi_transaction");
    super.new(name);
  endfunction

  // Constraints
  constraint c_wstrb { wstrb inside {4'b0001, 4'b0011, 4'b1111}; }
  constraint c_addr_align {
    if(trans_type == WRITE) awaddr[1:0] == 2'b00;
    if(trans_type == READ) araddr[1:0] == 2'b00;
  }

endclass

`endif
