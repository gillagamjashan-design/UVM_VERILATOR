`ifndef AXI_TB_PKG_SV
`define AXI_TB_PKG_SV

package axi_tb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Transaction
  `include "axi_transaction.sv"

  // Master Agent
  `include "agents/axi_master/axi_master_sequencer.sv"
  `include "agents/axi_master/axi_master_driver.sv"
  `include "agents/axi_master/axi_master_monitor.sv"
  `include "agents/axi_master/axi_master_agent.sv"

  // Slave Agent
  `include "agents/axi_slave/axi_slave_sequencer.sv"
  `include "agents/axi_slave/axi_slave_driver.sv"
  `include "agents/axi_slave/axi_slave_monitor.sv"
  `include "agents/axi_slave/axi_slave_agent.sv"

  // Scoreboard
  `include "env/axi_scoreboard.sv"

  // Virtual Sequencer
  `include "env/axi_virtual_sequencer.sv"

  // Environment
  `include "env/axi_env.sv"

  // Sequences
  `include "sequences/axi_base_sequence.sv"
  `include "sequences/axi_virtual_sequence.sv"

  // Tests
  `include "tests/axi_base_test.sv"

endpackage

`endif
