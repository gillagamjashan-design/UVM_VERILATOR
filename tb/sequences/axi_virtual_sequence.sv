`ifndef AXI_VIRTUAL_SEQUENCE_SV
`define AXI_VIRTUAL_SEQUENCE_SV

// Base virtual sequence
class axi_base_virtual_sequence extends uvm_sequence;

  `uvm_object_utils(axi_base_virtual_sequence)
  `uvm_declare_p_sequencer(axi_virtual_sequencer)

  function new(string name = "axi_base_virtual_sequence");
    super.new(name);
  endfunction

  virtual task pre_body();
    if(starting_phase != null)
      starting_phase.raise_objection(this, "Starting virtual sequence");
  endtask

  virtual task post_body();
    if(starting_phase != null)
      starting_phase.drop_objection(this, "Ending virtual sequence");
  endtask

endclass

// Virtual sequence 1: Simple write and read test
class axi_simple_vseq extends axi_base_virtual_sequence;

  `uvm_object_utils(axi_simple_vseq)

  function new(string name = "axi_simple_vseq");
    super.new(name);
  endfunction

  virtual task body();
    axi_write_sequence wr_seq;
    axi_read_sequence rd_seq;
    axi_slave_response_sequence slave_seq;

    `uvm_info(get_type_name(), "Starting Simple Virtual Sequence", UVM_LOW)

    // Start slave response sequence in background
    fork
      begin
        slave_seq = axi_slave_response_sequence::create_object("slave_seq");
        slave_seq.start(p_sequencer.slave_sequencer);
      end
    join_none

    // Perform some writes
    repeat(5) begin
      wr_seq = axi_write_sequence::create_object("wr_seq");
      // Simple values for Verilator (randomize not fully supported)
      wr_seq.addr = $urandom_range(32'h1000, 32'h1FFF);
      wr_seq.data = $urandom();
      wr_seq.start(p_sequencer.master_sequencer);
    end

    // Perform some reads
    repeat(5) begin
      rd_seq = axi_read_sequence::create_object("rd_seq");
      // Simple values for Verilator
      rd_seq.addr = $urandom_range(32'h1000, 32'h1FFF);
      rd_seq.start(p_sequencer.master_sequencer);
    end

    #100ns;
    `uvm_info(get_type_name(), "Completed Simple Virtual Sequence", UVM_LOW)
  endtask

endclass

// Virtual sequence 2: Burst write-read test
class axi_burst_vseq extends axi_base_virtual_sequence;

  `uvm_object_utils(axi_burst_vseq)

  function new(string name = "axi_burst_vseq");
    super.new(name);
  endfunction

  virtual task body();
    axi_write_sequence wr_seq;
    axi_read_sequence rd_seq;
    axi_slave_response_sequence slave_seq;
    bit [31:0] addr_array[10];
    bit [31:0] data_array[10];

    `uvm_info(get_type_name(), "Starting Burst Virtual Sequence", UVM_LOW)

    // Start slave response sequence in background
    fork
      begin
        slave_seq = axi_slave_response_sequence::create_object("slave_seq");
        slave_seq.start(p_sequencer.slave_sequencer);
      end
    join_none

    // Write to sequential addresses
    for(int i = 0; i < 10; i++) begin
      addr_array[i] = 32'h1000 + (i * 4);
      data_array[i] = 32'hDEAD_0000 + i;

      wr_seq = axi_write_sequence::create_object("wr_seq");
      wr_seq.addr = addr_array[i];
      wr_seq.data = data_array[i];
      wr_seq.start(p_sequencer.master_sequencer);
    end

    // Read back from same addresses
    for(int i = 0; i < 10; i++) begin
      rd_seq = axi_read_sequence::create_object("rd_seq");
      rd_seq.addr = addr_array[i];
      rd_seq.start(p_sequencer.master_sequencer);
      `uvm_info(get_type_name(), $sformatf("Burst Read %0d: addr=0x%0h expected=0x%0h got=0x%0h",
                i, addr_array[i], data_array[i], rd_seq.data), UVM_MEDIUM)
    end

    #100ns;
    `uvm_info(get_type_name(), "Completed Burst Virtual Sequence", UVM_LOW)
  endtask

endclass

// Virtual sequence 3: Random interleaved transactions
class axi_random_vseq extends axi_base_virtual_sequence;

  `uvm_object_utils(axi_random_vseq)

  rand int num_transactions;

  constraint c_num_trans { num_transactions inside {[10:20]}; }

  function new(string name = "axi_random_vseq");
    super.new(name);
  endfunction

  virtual task body();
    axi_write_sequence wr_seq;
    axi_read_sequence rd_seq;
    axi_slave_response_sequence slave_seq;

    `uvm_info(get_type_name(), $sformatf("Starting Random Virtual Sequence with %0d transactions", num_transactions), UVM_LOW)

    // Start slave response sequence in background
    fork
      begin
        slave_seq = axi_slave_response_sequence::create_object("slave_seq");
        slave_seq.start(p_sequencer.slave_sequencer);
      end
    join_none

    // Random mix of reads and writes
    repeat(num_transactions) begin
      if($urandom_range(0, 1)) begin
        wr_seq = axi_write_sequence::create_object("wr_seq");
        // Simple values for Verilator
        wr_seq.addr = $urandom_range(32'h1000, 32'h1FFF);
        wr_seq.data = $urandom();
        wr_seq.start(p_sequencer.master_sequencer);
      end else begin
        rd_seq = axi_read_sequence::create_object("rd_seq");
        // Simple values for Verilator
        rd_seq.addr = $urandom_range(32'h1000, 32'h1FFF);
        rd_seq.start(p_sequencer.master_sequencer);
      end
    end

    #100ns;
    `uvm_info(get_type_name(), "Completed Random Virtual Sequence", UVM_LOW)
  endtask

endclass

`endif
