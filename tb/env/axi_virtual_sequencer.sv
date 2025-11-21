`ifndef AXI_VIRTUAL_SEQUENCER_SV
`define AXI_VIRTUAL_SEQUENCER_SV

class axi_virtual_sequencer extends uvm_sequencer;

  `uvm_component_utils(axi_virtual_sequencer)

  axi_master_sequencer master_sequencer;
  axi_slave_sequencer slave_sequencer;

  function new(string name = "axi_virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass

`endif
