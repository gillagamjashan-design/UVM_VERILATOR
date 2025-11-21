`ifndef AXI_SLAVE_AGENT_SV
`define AXI_SLAVE_AGENT_SV

class axi_slave_agent extends uvm_agent;

  `uvm_component_utils(axi_slave_agent)

  axi_slave_driver driver;
  axi_slave_monitor monitor;
  axi_slave_sequencer sequencer;

  uvm_analysis_port #(axi_transaction) item_collected_port;

  function new(string name = "axi_slave_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    monitor = axi_slave_monitor::create_object("monitor", this);

    if(get_is_active() == UVM_ACTIVE) begin
      driver = axi_slave_driver::create_object("driver", this);
      sequencer = axi_slave_sequencer::create_object("sequencer", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
    item_collected_port = monitor.item_collected_port;
  endfunction

endclass

`endif
