`ifndef AXI_ENV_SV
`define AXI_ENV_SV

class axi_env extends uvm_env;

  `uvm_component_utils(axi_env)

  axi_master_agent master_agent;
  axi_slave_agent slave_agent;
  axi_scoreboard scoreboard;
  axi_virtual_sequencer virtual_sequencer;

  function new(string name = "axi_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    master_agent = axi_master_agent::create_object("master_agent", this);
    slave_agent = axi_slave_agent::create_object("slave_agent", this);
    scoreboard = axi_scoreboard::create_object("scoreboard", this);
    virtual_sequencer = axi_virtual_sequencer::create_object("virtual_sequencer", this);

    // Set master as active, slave as active (for response generation)
    uvm_config_db#(uvm_active_passive_enum)::set(this, "master_agent", "is_active", UVM_ACTIVE);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "slave_agent", "is_active", UVM_ACTIVE);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect agents to scoreboard
    master_agent.item_collected_port.connect(scoreboard.master_export);
    slave_agent.item_collected_port.connect(scoreboard.slave_export);

    // Connect sequencers to virtual sequencer
    virtual_sequencer.master_sequencer = master_agent.sequencer;
    virtual_sequencer.slave_sequencer = slave_agent.sequencer;
  endfunction

endclass

`endif
