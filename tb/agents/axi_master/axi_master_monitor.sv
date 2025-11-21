`ifndef AXI_MASTER_MONITOR_SV
`define AXI_MASTER_MONITOR_SV

class axi_master_monitor extends uvm_monitor;

  `uvm_component_utils(axi_master_monitor)

  virtual axi_interface vif;
  uvm_analysis_port #(axi_transaction) item_collected_port;

  function new(string name = "axi_master_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_collected_port = new("item_collected_port", this);
    if(!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for axi_master_monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      collect_write_transactions();
      collect_read_transactions();
    join
  endtask

  virtual task collect_write_transactions();
    axi_transaction trans;
    bit [31:0] addr, data;
    bit [3:0] strb;
    bit [1:0] resp;

    forever begin
      // Wait for write address valid
      @(posedge vif.clk);
      if(vif.m_awvalid && vif.m_awready) begin
        addr = vif.m_awaddr;

        // Capture write data (could be same cycle or later)
        fork
          begin
            while(!(vif.m_wvalid && vif.m_wready)) @(posedge vif.clk);
            data = vif.m_wdata;
            strb = vif.m_wstrb;
          end
        join_none

        // Wait for write response
        while(!(vif.m_bvalid && vif.m_bready)) @(posedge vif.clk);
        resp = vif.m_bresp;

        trans = axi_transaction::create_object("trans");
        trans.trans_type = axi_transaction::WRITE;
        trans.awaddr = addr;
        trans.wdata = data;
        trans.wstrb = strb;
        trans.bresp = resp;

        item_collected_port.write(trans);
        `uvm_info(get_type_name(), $sformatf("Monitored Write: addr=0x%0h data=0x%0h",
                  addr, data), UVM_HIGH)
      end
    end
  endtask

  virtual task collect_read_transactions();
    axi_transaction trans;
    bit [31:0] addr, data;
    bit [1:0] resp;

    forever begin
      // Wait for read address valid
      @(posedge vif.clk);
      if(vif.m_arvalid && vif.m_arready) begin
        addr = vif.m_araddr;

        // Wait for read data
        while(!(vif.m_rvalid && vif.m_rready)) @(posedge vif.clk);
        data = vif.m_rdata;
        resp = vif.m_rresp;

        trans = axi_transaction::create_object("trans");
        trans.trans_type = axi_transaction::READ;
        trans.araddr = addr;
        trans.rdata = data;
        trans.rresp = resp;

        item_collected_port.write(trans);
        `uvm_info(get_type_name(), $sformatf("Monitored Read: addr=0x%0h data=0x%0h",
                  addr, data), UVM_HIGH)
      end
    end
  endtask

endclass

`endif
