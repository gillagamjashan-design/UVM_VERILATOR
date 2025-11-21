`ifndef AXI_PASSTHROUGH_SV
`define AXI_PASSTHROUGH_SV

module axi_passthrough (
  input  logic        clk,
  input  logic        rst_n,

  // Master Interface (input from master)
  input  logic [31:0] m_awaddr,
  input  logic [2:0]  m_awprot,
  input  logic        m_awvalid,
  output logic        m_awready,

  input  logic [31:0] m_wdata,
  input  logic [3:0]  m_wstrb,
  input  logic        m_wvalid,
  output logic        m_wready,

  output logic [1:0]  m_bresp,
  output logic        m_bvalid,
  input  logic        m_bready,

  input  logic [31:0] m_araddr,
  input  logic [2:0]  m_arprot,
  input  logic        m_arvalid,
  output logic        m_arready,

  output logic [31:0] m_rdata,
  output logic [1:0]  m_rresp,
  output logic        m_rvalid,
  input  logic        m_rready,

  // Slave Interface (output to slave)
  output logic [31:0] s_awaddr,
  output logic [2:0]  s_awprot,
  output logic        s_awvalid,
  input  logic        s_awready,

  output logic [31:0] s_wdata,
  output logic [3:0]  s_wstrb,
  output logic        s_wvalid,
  input  logic        s_wready,

  input  logic [1:0]  s_bresp,
  input  logic        s_bvalid,
  output logic        s_bready,

  output logic [31:0] s_araddr,
  output logic [2:0]  s_arprot,
  output logic        s_arvalid,
  input  logic        s_arready,

  input  logic [31:0] s_rdata,
  input  logic [1:0]  s_rresp,
  input  logic        s_rvalid,
  output logic        s_rready
);

  // Registered pass-through to break combinational loops
  // This adds one clock cycle latency but avoids Verilator convergence issues

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_awaddr  <= '0;
      s_awprot  <= '0;
      s_awvalid <= '0;
      s_wdata   <= '0;
      s_wstrb   <= '0;
      s_wvalid  <= '0;
      s_bready  <= '0;
      s_araddr  <= '0;
      s_arprot  <= '0;
      s_arvalid <= '0;
      s_rready  <= '0;

      m_awready <= '0;
      m_wready  <= '0;
      m_bresp   <= '0;
      m_bvalid  <= '0;
      m_arready <= '0;
      m_rdata   <= '0;
      m_rresp   <= '0;
      m_rvalid  <= '0;
    end else begin
      // Forward master to slave
      s_awaddr  <= m_awaddr;
      s_awprot  <= m_awprot;
      s_awvalid <= m_awvalid;
      s_wdata   <= m_wdata;
      s_wstrb   <= m_wstrb;
      s_wvalid  <= m_wvalid;
      s_bready  <= m_bready;
      s_araddr  <= m_araddr;
      s_arprot  <= m_arprot;
      s_arvalid <= m_arvalid;
      s_rready  <= m_rready;

      // Forward slave to master
      m_awready <= s_awready;
      m_wready  <= s_wready;
      m_bresp   <= s_bresp;
      m_bvalid  <= s_bvalid;
      m_arready <= s_arready;
      m_rdata   <= s_rdata;
      m_rresp   <= s_rresp;
      m_rvalid  <= s_rvalid;
    end
  end

endmodule

`endif
