`ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

class axi_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(axi_scoreboard)

  uvm_analysis_imp_master #(axi_transaction, axi_scoreboard) master_export;
  uvm_analysis_imp_slave #(axi_transaction, axi_scoreboard) slave_export;

  axi_transaction master_queue[$];
  int match_count = 0;
  int mismatch_count = 0;

  function new(string name = "axi_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    master_export = new("master_export", this);
    slave_export = new("slave_export", this);
  endfunction

  virtual function void write_master(axi_transaction trans);
    master_queue.push_back(trans);
    `uvm_info(get_type_name(), $sformatf("Master transaction queued: type=%s addr=0x%0h",
              trans.trans_type.name(),
              trans.trans_type == axi_transaction::WRITE ? trans.awaddr : trans.araddr), UVM_HIGH)
  endfunction

  virtual function void write_slave(axi_transaction trans);
    axi_transaction master_trans;

    if(master_queue.size() == 0) begin
      `uvm_error(get_type_name(), "Slave transaction received but master queue is empty!")
      mismatch_count++;
      return;
    end

    master_trans = master_queue.pop_front();

    if(compare_transactions(master_trans, trans)) begin
      match_count++;
      `uvm_info(get_type_name(), $sformatf("MATCH: Transactions matched (Total: %0d)", match_count), UVM_MEDIUM)
    end else begin
      mismatch_count++;
      `uvm_error(get_type_name(), $sformatf("MISMATCH: Transactions did not match!\nMaster: %s\nSlave: %s",
                 master_trans.sprint(), trans.sprint()))
    end
  endfunction

  virtual function bit compare_transactions(axi_transaction master, axi_transaction slave);
    if(master.trans_type != slave.trans_type) return 0;

    if(master.trans_type == axi_transaction::WRITE) begin
      if(master.awaddr != slave.awaddr) begin
        `uvm_info(get_type_name(), $sformatf("Write address mismatch: M=0x%0h S=0x%0h",
                  master.awaddr, slave.awaddr), UVM_LOW)
        return 0;
      end
      if(master.wdata != slave.wdata) begin
        `uvm_info(get_type_name(), $sformatf("Write data mismatch: M=0x%0h S=0x%0h",
                  master.wdata, slave.wdata), UVM_LOW)
        return 0;
      end
    end else begin
      if(master.araddr != slave.araddr) begin
        `uvm_info(get_type_name(), $sformatf("Read address mismatch: M=0x%0h S=0x%0h",
                  master.araddr, slave.araddr), UVM_LOW)
        return 0;
      end
      if(master.rdata != slave.rdata) begin
        `uvm_info(get_type_name(), $sformatf("Read data mismatch: M=0x%0h S=0x%0h",
                  master.rdata, slave.rdata), UVM_LOW)
        return 0;
      end
    end

    return 1;
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("\n==== Scoreboard Report ====\nMatches: %0d\nMismatches: %0d\n===========================",
              match_count, mismatch_count), UVM_LOW)
    if(mismatch_count > 0)
      `uvm_error(get_type_name(), "Test FAILED - Mismatches detected")
    else if(match_count > 0)
      `uvm_info(get_type_name(), "Test PASSED - All transactions matched", UVM_LOW)
  endfunction

endclass

`uvm_analysis_imp_decl(_master)
`uvm_analysis_imp_decl(_slave)

`endif
