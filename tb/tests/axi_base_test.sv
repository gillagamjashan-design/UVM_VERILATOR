`ifndef AXI_BASE_TEST_SV
`define AXI_BASE_TEST_SV

class axi_base_test extends uvm_test;

  `uvm_component_utils(axi_base_test)

  axi_env env;

  function new(string name = "axi_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi_env::create_object("env", this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    this.print_topology();
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this, "Starting test");
    `uvm_info(get_type_name(), "Test running...", UVM_LOW)
    #1us;
    phase.drop_objection(this, "Ending test");
  endtask

endclass

// Test using simple virtual sequence
class axi_simple_test extends axi_base_test;

  `uvm_component_utils(axi_simple_test)

  function new(string name = "axi_simple_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    axi_simple_vseq vseq;
    vseq = axi_simple_vseq::create_object("vseq");
    vseq.starting_phase = phase;
    vseq.start(env.virtual_sequencer);
  endtask

endclass

// Test using burst virtual sequence
class axi_burst_test extends axi_base_test;

  `uvm_component_utils(axi_burst_test)

  function new(string name = "axi_burst_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    axi_burst_vseq vseq;
    vseq = axi_burst_vseq::create_object("vseq");
    vseq.starting_phase = phase;
    vseq.start(env.virtual_sequencer);
  endtask

endclass

// Test using random virtual sequence
class axi_random_test extends axi_base_test;

  `uvm_component_utils(axi_random_test)

  function new(string name = "axi_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    axi_random_vseq vseq;
    vseq = axi_random_vseq::create_object("vseq");
    vseq.starting_phase = phase;
    vseq.start(env.virtual_sequencer);
  endtask

endclass

// Test running multiple virtual sequences sequentially
class axi_multi_vseq_test extends axi_base_test;

  `uvm_component_utils(axi_multi_vseq_test)

  function new(string name = "axi_multi_vseq_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    axi_simple_vseq simple_vseq;
    axi_burst_vseq burst_vseq;
    axi_random_vseq random_vseq;

    phase.raise_objection(this, "Starting multi-vseq test");

    `uvm_info(get_type_name(), "Running Simple Virtual Sequence", UVM_LOW)
    simple_vseq = axi_simple_vseq::create_object("simple_vseq");
    simple_vseq.start(env.virtual_sequencer);

    `uvm_info(get_type_name(), "Running Burst Virtual Sequence", UVM_LOW)
    burst_vseq = axi_burst_vseq::create_object("burst_vseq");
    burst_vseq.start(env.virtual_sequencer);

    `uvm_info(get_type_name(), "Running Random Virtual Sequence", UVM_LOW)
    random_vseq = axi_random_vseq::create_object("random_vseq");
    random_vseq.start(env.virtual_sequencer);

    #500ns;
    phase.drop_objection(this, "Ending multi-vseq test");
  endtask

endclass

`endif
