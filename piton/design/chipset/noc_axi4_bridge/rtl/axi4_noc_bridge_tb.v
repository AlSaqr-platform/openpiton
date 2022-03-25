`include "mc_define.h"
`include "define.tmp.h"
`include "noc_axi4_bridge_define.vh"

module axi4_noc_bridge_tb;
   
// Clock + Reset
reg                                   clk;
reg                                   rst_n;
reg                                   uart_boot_en;
reg                                   phy_init_done; 

// Noc interface
reg                                    src_bridge_vr_noc2_val;
reg [`NOC_DATA_WIDTH-1:0]              src_bridge_vr_noc2_dat;
wire                                   src_bridge_vr_noc2_rdy;
wire                                   bridge_dst_vr_noc3_val;
wire [`NOC_DATA_WIDTH-1:0]             bridge_dst_vr_noc3_dat;
reg                                    bridge_dst_vr_noc3_rdy;

// AXI interface
wire [`AXI4_ID_WIDTH     -1:0]     m_axi_awid;
wire [`AXI4_ADDR_WIDTH   -1:0]     m_axi_awaddr;
wire [`AXI4_LEN_WIDTH    -1:0]     m_axi_awlen;
wire [`AXI4_SIZE_WIDTH   -1:0]     m_axi_awsize;
wire [`AXI4_BURST_WIDTH  -1:0]     m_axi_awburst;
wire                               m_axi_awlock;
wire [`AXI4_CACHE_WIDTH  -1:0]     m_axi_awcache;
wire [`AXI4_PROT_WIDTH   -1:0]     m_axi_awprot;
wire [`AXI4_QOS_WIDTH    -1:0]     m_axi_awqos;
wire [`AXI4_REGION_WIDTH -1:0]     m_axi_awregion;
wire [`AXI4_USER_WIDTH   -1:0]     m_axi_awuser;
wire                               m_axi_awvalid;
reg                                m_axi_awready;

wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_wid;
wire  [`AXI4_DATA_WIDTH   -1:0]    m_axi_wdata;
wire  [`AXI4_STRB_WIDTH   -1:0]    m_axi_wstrb;
wire                               m_axi_wlast;
wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_wuser;
wire                               m_axi_wvalid;
reg                                m_axi_wready;

wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_arid;
wire  [`AXI4_ADDR_WIDTH   -1:0]    m_axi_araddr;
wire  [`AXI4_LEN_WIDTH    -1:0]    m_axi_arlen;
wire  [`AXI4_SIZE_WIDTH   -1:0]    m_axi_arsize;
wire  [`AXI4_BURST_WIDTH  -1:0]    m_axi_arburst;
wire                               m_axi_arlock;
wire  [`AXI4_CACHE_WIDTH  -1:0]    m_axi_arcache;
wire  [`AXI4_PROT_WIDTH   -1:0]    m_axi_arprot;
wire  [`AXI4_QOS_WIDTH    -1:0]    m_axi_arqos;
wire  [`AXI4_REGION_WIDTH -1:0]    m_axi_arregion;
wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_aruser;
wire                               m_axi_arvalid;
reg                                m_axi_arready;

reg  [`AXI4_ID_WIDTH     -1:0]     m_axi_rid;
reg  [`AXI4_DATA_WIDTH   -1:0]     m_axi_rdata;
reg  [`AXI4_RESP_WIDTH   -1:0]     m_axi_rresp;
reg                                m_axi_rlast;
reg  [`AXI4_USER_WIDTH   -1:0]     m_axi_ruser;
reg                                m_axi_rvalid;
wire                               m_axi_rready;

reg  [`AXI4_ID_WIDTH     -1:0]     m_axi_bid;
reg  [`AXI4_RESP_WIDTH   -1:0]     m_axi_bresp;
reg  [`AXI4_USER_WIDTH   -1:0]     m_axi_buser;
reg                                m_axi_bvalid;
wire                               m_axi_bread;


always
begin
clk = 0;
#10;
clk = 1;
#10;
end


initial
begin 
rst_n = 0;
uart_boot_en = 0;
phy_init_done = 1; 
src_bridge_vr_noc2_dat = 0;
src_bridge_vr_noc2_val = 0;
bridge_dst_vr_noc3_rdy= 0;
m_axi_awready = 1;
m_axi_wready = 1;
m_axi_wready = 1;
m_axi_arready = 1;
m_axi_rid = 0;
m_axi_rdata = 0;
m_axi_rresp = 0;
m_axi_rlast = 0;
m_axi_ruser =0;
m_axi_rvalid = 0;
m_axi_bid = 0;
m_axi_bresp = 0;
m_axi_buser = 0;
m_axi_bvalid = 0;

#10000

rst_n = 1;
#10
repeat(1)@(posedge clk);
src_bridge_vr_noc2_dat = 64'h800000008084c008;
src_bridge_vr_noc2_val = 1;
repeat(1)@(posedge clk);
src_bridge_vr_noc2_dat = 64'h00fff10100000300;
src_bridge_vr_noc2_val = 1;
repeat(1)@(posedge clk);
src_bridge_vr_noc2_dat = 64'h0;
src_bridge_vr_noc2_val= 1;
repeat(1)@(posedge clk);
src_bridge_vr_noc2_val= 0;




end

noc_axi4_bridge test (
    // Clock + Reset
    .clk(clk),
    .rst_n(rst_n),
    .uart_boot_en(uart_boot_en),
    .phy_init_done(phy_init_done), 

    // Noc interface
    .src_bridge_vr_noc2_val(src_bridge_vr_noc2_val),
    .src_bridge_vr_noc2_dat(src_bridge_vr_noc2_dat),
    .src_bridge_vr_noc2_rdy(src_bridge_vr_noc2_rdy),
    .bridge_dst_vr_noc3_val(bridge_dst_vr_noc3_val),
    .bridge_dst_vr_noc3_dat(bridge_dst_vr_noc3_dat),
    .bridge_dst_vr_noc3_rdy(bridge_dst_vr_noc3_rdy),

    // AXI interface
    .m_axi_awid(m_axi_awid),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awlen(m_axi_awlen),
    .m_axi_awsize(m_axi_awsize),
    .m_axi_awburst(m_axi_awburst),
    .m_axi_awlock(m_axi_awlock),
    .m_axi_awcache(m_axi_awcache),
    .m_axi_awprot(m_axi_awprot),
    .m_axi_awqos(m_axi_awqos),
    .m_axi_awregion(m_axi_awregion),
    .m_axi_awuser(m_axi_awuser),
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),

    .m_axi_wid(m_axi_wid),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wstrb(m_axi_wstrb),
    .m_axi_wlast(m_axi_wlast),
    .m_axi_wuser(m_axi_wuser),
    .m_axi_wvalid(m_axi_wvalid),
    .m_axi_wready(m_axi_wready),

    .m_axi_arid(m_axi_arid),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst),
    .m_axi_arlock(m_axi_arlock),
    .m_axi_arcache(m_axi_arcache),
    .m_axi_arprot(m_axi_arprot),
    .m_axi_arqos(m_axi_arqos),
    .m_axi_arregion(m_axi_arregion),
    .m_axi_aruser(m_axi_aruser),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),

    .m_axi_rid(m_axi_rid),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rlast(m_axi_rlast),
    .m_axi_ruser(m_axi_ruser),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready),

    .m_axi_bid(m_axi_bid),
    .m_axi_bresp(m_axi_bresp),
    .m_axi_buser(m_axi_buser),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_bready(m_axi_bready)
);
endmodule // axi4_noc_bridge_tb