`ifndef TB_TOP_SV
`define TB_TOP_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import axi_tb_pkg::*;

module tb_top;

  // Simple test factory function
  function uvm_component create_test(string test_name);
    case (test_name)
      "axi_simple_test":     return axi_simple_test::create_object("test", null);
      "axi_burst_test":      return axi_burst_test::create_object("test", null);
      "axi_random_test":     return axi_random_test::create_object("test", null);
      "axi_multi_vseq_test": return axi_multi_vseq_test::create_object("test", null);
      default: begin
        $display("Warning: Unknown test '%s', using axi_simple_test", test_name);
        return axi_simple_test::create_object("test", null);
      end
    endcase
  endfunction

  // Clock and reset
  logic clk;
  logic rst_n;

  // Clock generation
  initial begin
    clk = 0;
    forever #5ns clk = ~clk;
  end

  // Reset generation
  initial begin
    rst_n = 0;
    #50ns;
    rst_n = 1;
  end

  // AXI Interface instantiation
  axi_interface axi_if(clk, rst_n);

  // DUT instantiation
  axi_passthrough dut (
    .clk(clk),
    .rst_n(rst_n),

    // Master side
    .m_awaddr(axi_if.m_awaddr),
    .m_awprot(axi_if.m_awprot),
    .m_awvalid(axi_if.m_awvalid),
    .m_awready(axi_if.m_awready),

    .m_wdata(axi_if.m_wdata),
    .m_wstrb(axi_if.m_wstrb),
    .m_wvalid(axi_if.m_wvalid),
    .m_wready(axi_if.m_wready),

    .m_bresp(axi_if.m_bresp),
    .m_bvalid(axi_if.m_bvalid),
    .m_bready(axi_if.m_bready),

    .m_araddr(axi_if.m_araddr),
    .m_arprot(axi_if.m_arprot),
    .m_arvalid(axi_if.m_arvalid),
    .m_arready(axi_if.m_arready),

    .m_rdata(axi_if.m_rdata),
    .m_rresp(axi_if.m_rresp),
    .m_rvalid(axi_if.m_rvalid),
    .m_rready(axi_if.m_rready),

    // Slave side
    .s_awaddr(axi_if.s_awaddr),
    .s_awprot(axi_if.s_awprot),
    .s_awvalid(axi_if.s_awvalid),
    .s_awready(axi_if.s_awready),

    .s_wdata(axi_if.s_wdata),
    .s_wstrb(axi_if.s_wstrb),
    .s_wvalid(axi_if.s_wvalid),
    .s_wready(axi_if.s_wready),

    .s_bresp(axi_if.s_bresp),
    .s_bvalid(axi_if.s_bvalid),
    .s_bready(axi_if.s_bready),

    .s_araddr(axi_if.s_araddr),
    .s_arprot(axi_if.s_arprot),
    .s_arvalid(axi_if.s_arvalid),
    .s_arready(axi_if.s_arready),

    .s_rdata(axi_if.s_rdata),
    .s_rresp(axi_if.s_rresp),
    .s_rvalid(axi_if.s_rvalid),
    .s_rready(axi_if.s_rready)
  );

  // UVM configuration and test start
  initial begin
    string test_name;
    uvm_component test_inst;
    uvm_phase phase;

    // Store the interface in config db
    uvm_config_db#(virtual axi_interface)::set(null, "*", "vif", axi_if);

    // Enable waveform dumping
    $dumpfile("axi_test.vcd");
    $dumpvars(0, tb_top);

    // Get test name from plusarg, default to axi_simple_test
    if (!$value$plusargs("TEST=%s", test_name)) begin
      test_name = "axi_simple_test";
    end

    $display("========================================");
    $display("UVM Testbench (Verilator compatible)");
    $display("Test: %s", test_name);
    $display("========================================");

    // Create the selected test
    test_inst = create_test(test_name);

    // Create phase and run
    phase = new("uvm_phase");
    run_phases(test_inst, phase);

    $display("========================================");
    $display("Test Complete");
    $display("========================================");
  end

  // Timeout watchdog
  initial begin
    #10ms;
    `uvm_fatal("TIMEOUT", "Test timeout!")
  end

endmodule

`endif
