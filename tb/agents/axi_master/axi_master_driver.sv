`ifndef AXI_MASTER_DRIVER_SV
`define AXI_MASTER_DRIVER_SV

class axi_master_driver extends uvm_driver #(axi_transaction);

  `uvm_component_utils(axi_master_driver)

  virtual axi_interface vif;

  function new(string name = "axi_master_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for axi_master_driver")
  endfunction

  virtual task run_phase(uvm_phase phase);
    reset_signals();
    forever begin
      seq_item_port.get_next_item(req);
      drive_transaction(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task reset_signals();
    vif.m_awaddr  <= 0;
    vif.m_awprot  <= 0;
    vif.m_awvalid <= 0;
    vif.m_wdata   <= 0;
    vif.m_wstrb   <= 0;
    vif.m_wvalid  <= 0;
    vif.m_bready  <= 0;
    vif.m_araddr  <= 0;
    vif.m_arprot  <= 0;
    vif.m_arvalid <= 0;
    vif.m_rready  <= 0;
  endtask

  virtual task drive_transaction(axi_transaction trans);
    if(trans.trans_type == axi_transaction::WRITE) begin
      drive_write(trans);
    end else begin
      drive_read(trans);
    end
  endtask

  virtual task drive_write(axi_transaction trans);
    fork
      // Write address channel
      begin
        @(posedge vif.clk);
        vif.m_awaddr  <= trans.awaddr;
        vif.m_awprot  <= trans.awprot;
        vif.m_awvalid <= 1'b1;
        wait(vif.m_awready);
        @(posedge vif.clk);
        vif.m_awvalid <= 1'b0;
      end
      // Write data channel
      begin
        @(posedge vif.clk);
        vif.m_wdata  <= trans.wdata;
        vif.m_wstrb  <= trans.wstrb;
        vif.m_wvalid <= 1'b1;
        wait(vif.m_wready);
        @(posedge vif.clk);
        vif.m_wvalid <= 1'b0;
      end
    join
    // Write response channel
    vif.m_bready <= 1'b1;
    wait(vif.m_bvalid);
    trans.bresp = vif.m_bresp;
    @(posedge vif.clk);
    vif.m_bready <= 1'b0;
    `uvm_info(get_type_name(), $sformatf("Write: addr=0x%0h data=0x%0h resp=%0d",
              trans.awaddr, trans.wdata, trans.bresp), UVM_MEDIUM)
  endtask

  virtual task drive_read(axi_transaction trans);
    // Read address channel
    @(posedge vif.clk);
    vif.m_araddr  <= trans.araddr;
    vif.m_arprot  <= trans.arprot;
    vif.m_arvalid <= 1'b1;
    wait(vif.m_arready);
    @(posedge vif.clk);
    vif.m_arvalid <= 1'b0;

    // Read data channel
    vif.m_rready <= 1'b1;
    wait(vif.m_rvalid);
    trans.rdata = vif.m_rdata;
    trans.rresp = vif.m_rresp;
    @(posedge vif.clk);
    vif.m_rready <= 1'b0;
    `uvm_info(get_type_name(), $sformatf("Read: addr=0x%0h data=0x%0h resp=%0d",
              trans.araddr, trans.rdata, trans.rresp), UVM_MEDIUM)
  endtask

endclass

`endif
