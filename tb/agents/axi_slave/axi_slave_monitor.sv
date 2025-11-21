`ifndef AXI_SLAVE_MONITOR_SV
`define AXI_SLAVE_MONITOR_SV

class axi_slave_monitor extends uvm_monitor;

  `uvm_component_utils(axi_slave_monitor)

  virtual axi_interface vif;
  uvm_analysis_port #(axi_transaction) item_collected_port;

  function new(string name = "axi_slave_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_collected_port = new("item_collected_port", this);
    if(!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for axi_slave_monitor")
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
      if(vif.s_awvalid && vif.s_awready) begin
        addr = vif.s_awaddr;

        // Capture write data
        fork
          begin
            while(!(vif.s_wvalid && vif.s_wready)) @(posedge vif.clk);
            data = vif.s_wdata;
            strb = vif.s_wstrb;
          end
        join_none

        // Wait for write response
        while(!(vif.s_bvalid && vif.s_bready)) @(posedge vif.clk);
        resp = vif.s_bresp;

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
      if(vif.s_arvalid && vif.s_arready) begin
        addr = vif.s_araddr;

        // Wait for read data
        while(!(vif.s_rvalid && vif.s_rready)) @(posedge vif.clk);
        data = vif.s_rdata;
        resp = vif.s_rresp;

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
