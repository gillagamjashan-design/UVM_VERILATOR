`ifndef AXI_INTERFACE_SV
`define AXI_INTERFACE_SV

interface axi_interface(input logic clk, input logic rst_n);

  // Master signals
  logic [31:0] m_awaddr  = '0;
  logic [2:0]  m_awprot  = '0;
  logic        m_awvalid = '0;
  logic        m_awready = '0;

  logic [31:0] m_wdata  = '0;
  logic [3:0]  m_wstrb  = '0;
  logic        m_wvalid = '0;
  logic        m_wready = '0;

  logic [1:0]  m_bresp  = '0;
  logic        m_bvalid = '0;
  logic        m_bready = '0;

  logic [31:0] m_araddr  = '0;
  logic [2:0]  m_arprot  = '0;
  logic        m_arvalid = '0;
  logic        m_arready = '0;

  logic [31:0] m_rdata  = '0;
  logic [1:0]  m_rresp  = '0;
  logic        m_rvalid = '0;
  logic        m_rready = '0;

  // Slave signals
  logic [31:0] s_awaddr  = '0;
  logic [2:0]  s_awprot  = '0;
  logic        s_awvalid = '0;
  logic        s_awready = '0;

  logic [31:0] s_wdata  = '0;
  logic [3:0]  s_wstrb  = '0;
  logic        s_wvalid = '0;
  logic        s_wready = '0;

  logic [1:0]  s_bresp  = '0;
  logic        s_bvalid = '0;
  logic        s_bready = '0;

  logic [31:0] s_araddr  = '0;
  logic [2:0]  s_arprot  = '0;
  logic        s_arvalid = '0;
  logic        s_arready = '0;

  logic [31:0] s_rdata  = '0;
  logic [1:0]  s_rresp  = '0;
  logic        s_rvalid = '0;
  logic        s_rready = '0;

  // Modports for master side (driver perspective)
  modport master_mp (
    output m_awaddr, m_awprot, m_awvalid,
    input  m_awready,
    output m_wdata, m_wstrb, m_wvalid,
    input  m_wready,
    input  m_bresp, m_bvalid,
    output m_bready,
    output m_araddr, m_arprot, m_arvalid,
    input  m_arready,
    input  m_rdata, m_rresp, m_rvalid,
    output m_rready,
    input  clk, rst_n
  );

  // Modports for slave side (driver perspective)
  modport slave_mp (
    input  s_awaddr, s_awprot, s_awvalid,
    output s_awready,
    input  s_wdata, s_wstrb, s_wvalid,
    output s_wready,
    output s_bresp, s_bvalid,
    input  s_bready,
    input  s_araddr, s_arprot, s_arvalid,
    output s_arready,
    output s_rdata, s_rresp, s_rvalid,
    input  s_rready,
    input  clk, rst_n
  );

endinterface

`endif
