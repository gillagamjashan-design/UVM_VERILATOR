`ifndef AXI_SLAVE_DRIVER_SV
`define AXI_SLAVE_DRIVER_SV

class axi_slave_driver extends uvm_driver #(axi_transaction);

  `uvm_component_utils(axi_slave_driver)

  virtual axi_interface vif;

  function new(string name = "axi_slave_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for axi_slave_driver")
  endfunction

  virtual task run_phase(uvm_phase phase);
    reset_signals();
    forever begin
      seq_item_port.get_next_item(req);
      drive_response(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task reset_signals();
    vif.s_awready <= 0;
    vif.s_wready  <= 0;
    vif.s_bresp   <= 0;
    vif.s_bvalid  <= 0;
    vif.s_arready <= 0;
    vif.s_rdata   <= 0;
    vif.s_rresp   <= 0;
    vif.s_rvalid  <= 0;
  endtask

  virtual task drive_response(axi_transaction trans);
    if(trans.trans_type == axi_transaction::WRITE) begin
      drive_write_response(trans);
    end else begin
      drive_read_response(trans);
    end
  endtask

  virtual task drive_write_response(axi_transaction trans);
    fork
      // Accept write address
      begin
        @(posedge vif.clk);
        vif.s_awready <= 1'b1;
        wait(vif.s_awvalid);
        @(posedge vif.clk);
        vif.s_awready <= 1'b0;
      end
      // Accept write data
      begin
        @(posedge vif.clk);
        vif.s_wready <= 1'b1;
        wait(vif.s_wvalid);
        @(posedge vif.clk);
        vif.s_wready <= 1'b0;
      end
    join

    // Send write response
    repeat(2) @(posedge vif.clk); // Add some delay
    vif.s_bresp  <= 2'b00; // OKAY response
    vif.s_bvalid <= 1'b1;
    wait(vif.s_bready);
    @(posedge vif.clk);
    vif.s_bvalid <= 1'b0;
    `uvm_info(get_type_name(), "Slave responded to write", UVM_HIGH)
  endtask

  virtual task drive_read_response(axi_transaction trans);
    // Accept read address
    @(posedge vif.clk);
    vif.s_arready <= 1'b1;
    wait(vif.s_arvalid);
    @(posedge vif.clk);
    vif.s_arready <= 1'b0;

    // Send read data
    repeat(2) @(posedge vif.clk); // Add some delay
    vif.s_rdata  <= trans.rdata;
    vif.s_rresp  <= 2'b00; // OKAY response
    vif.s_rvalid <= 1'b1;
    wait(vif.s_rready);
    @(posedge vif.clk);
    vif.s_rvalid <= 1'b0;
    `uvm_info(get_type_name(), $sformatf("Slave responded to read with data=0x%0h", trans.rdata), UVM_HIGH)
  endtask

endclass

`endif
