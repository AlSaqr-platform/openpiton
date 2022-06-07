`include "define.tmp.h"
`include "piton_system.vh"
`include "jtag.vh"
`include "mc_define.h"
`include "noc_axi4_bridge_define.vh"

`define PITON_NO_CHIP_BRIDGE
`define NO_SCAN
`define USE_FAKE_PLL_AND_CLKMUX
`define USE_FAKE_IOS
`define PITON_ARIANE
`define WT_DCACHE
`define NO_MRA_VAL
`define NO_SLAM_RANDOM
`define RTL_ARIANE0
`define NO_SLAM_RANDOM
`define NO_MRA_VAL

module cache_coherent_ariane (
  import ariane_axi_soc::*;

   // IO cell configs
   input                                        slew,
   input                                        impsel1,
   input                                        impsel2,

   // Input clocks
   input                                        core_ref_clk,
   input                                        io_clk,

   // Resets
   // reset is assumed to be asynchronous
   input                                        rst_n,

   input                                        pll_rst_n,

   // Chip-level clock enable
   input                                        clk_en,

   // PLL settings
   output                                       pll_lock,
   input                                        pll_bypass,
   input  [4:0]                                 pll_rangea,

   // Clock mux select (bypass PLL or not)
   // Double redundancy with pll_bypass
   input  [1:0]                                 clk_mux_sel,

   // JTAG
   input                                        jtag_clk,
   input                                        jtag_rst_l,
   input                                        jtag_modesel,
   input                                        jtag_datain,
   output                                       jtag_dataout,

   // Async FIFOs enable
   input                                        async_mux,

   // Debug
   input                                       ndmreset_i,    // non-debug module reset
   input   [`NUM_TILES-1:0]                    debug_req_i,   // async debug request
   output  [`NUM_TILES-1:0]                    unavailable_o, // communicate whether the hart is unavailable (e.g.: power down)
   input   wire [63:0]                         alsaqr_bootaddr,

   // CLINT
   input   [`NUM_TILES-1:0]                    timer_irq_i,   // Timer interrupts
   input   [`NUM_TILES-1:0]                    ipi_i,         // software interrupt (a.k.a inter-process-interrupt)

   // PLIC
   input   [`NUM_TILES*2-1:0]                  irq_i,          // level sensitive IR lines, mip & sip (async)

   // AXI interface
   // Address Write Channel
   output wire [`AXI4_ID_WIDTH     -1:0]    axi_awid,
   output wire [`AXI4_ADDR_WIDTH   -1:0]    axi_awaddr,
   output wire [`AXI4_LEN_WIDTH    -1:0]    axi_awlen,
   output wire [`AXI4_SIZE_WIDTH   -1:0]    axi_awsize,
   output wire [`AXI4_BURST_WIDTH  -1:0]    axi_awburst,
   output wire                              axi_awlock,
   output wire [`AXI4_CACHE_WIDTH  -1:0]    axi_awcache,
   output wire [`AXI4_PROT_WIDTH   -1:0]    axi_awprot,
   output wire [`AXI4_QOS_WIDTH    -1:0]    axi_awqos,
   output wire [`AXI4_REGION_WIDTH -1:0]    axi_awregion,
   output wire [`AXI4_USER_WIDTH   -1:0]    axi_awuser,
   output wire                              axi_awvalid,
   input  wire                              axi_awready,

   // Write Data Channel
   output wire  [`AXI4_ID_WIDTH     -1:0]    axi_wid,
   output wire  [`AXI4_DATA_WIDTH   -1:0]    axi_wdata,
   output wire  [`AXI4_STRB_WIDTH   -1:0]    axi_wstrb,
   output wire                               axi_wlast,
   output wire  [`AXI4_USER_WIDTH   -1:0]    axi_wuser,
   output wire                               axi_wvalid,
   input  wire                               axi_wready,

   // Address Read Channel
   output wire  [`AXI4_ID_WIDTH     -1:0]    axi_arid,
   output wire  [`AXI4_ADDR_WIDTH   -1:0]    axi_araddr,
   output wire  [`AXI4_LEN_WIDTH    -1:0]    axi_arlen,
   output wire  [`AXI4_SIZE_WIDTH   -1:0]    axi_arsize,
   output wire  [`AXI4_BURST_WIDTH  -1:0]    axi_arburst,
   output wire                               axi_arlock,
   output wire  [`AXI4_CACHE_WIDTH  -1:0]    axi_arcache,
   output wire  [`AXI4_PROT_WIDTH   -1:0]    axi_arprot,
   output wire  [`AXI4_QOS_WIDTH    -1:0]    axi_arqos,
   output wire  [`AXI4_REGION_WIDTH -1:0]    axi_arregion,
   output wire  [`AXI4_USER_WIDTH   -1:0]    axi_aruser,
   output wire                               axi_arvalid,
   input  wire                               axi_arready,

   // Read Data Channel
   input  wire  [`AXI4_ID_WIDTH     -1:0]    axi_rid,
   input  wire  [`AXI4_DATA_WIDTH   -1:0]    axi_rdata,
   input  wire  [`AXI4_RESP_WIDTH   -1:0]    axi_rresp,
   input  wire                               axi_rlast,
   input  wire  [`AXI4_USER_WIDTH   -1:0]    axi_ruser,
   input  wire                               axi_rvalid,
   output wire                               axi_rready,

   // Ack Channel
   input  wire  [`AXI4_ID_WIDTH     -1:0]    axi_bid,
   input  wire  [`AXI4_RESP_WIDTH   -1:0]    axi_bresp,
   input  wire  [`AXI4_USER_WIDTH   -1:0]    axi_buser,
   input  wire                               axi_bvalid,
   output wire                               axi_bready
);


wire                                       valrdy_processor_offchip_noc2_valid;
wire [`NOC_DATA_WIDTH-1:0]                 valrdy_processor_offchip_noc2_data;
wire                                       valrdy_processor_offchip_noc2_ready;

wire                                       valrdy_offchip_processor_noc3_valid;
wire  [`NOC_DATA_WIDTH-1:0]                valrdy_offchip_processor_noc3_data;
wire                                       valrdy_offchip_processor_noc3_ready;


wire                                       processor_offchip_noc2_valid;
wire [`NOC_DATA_WIDTH-1:0]                 processor_offchip_noc2_data;
wire                                       processor_offchip_noc2_yummy;

wire                                       offchip_processor_noc3_valid;
wire  [`NOC_DATA_WIDTH-1:0]                offchip_processor_noc3_data;
wire                                       offchip_processor_noc3_yummy;

ariane_axi_soc::req_t    m_axi_ariane_req;
ariane_axi_soc::resp_t   m_axi_ariane_resp;

ariane_axi_soc::req_t    s_axi_ariane_req;
ariane_axi_soc::resp_t   s_axi_ariane_resp;

wire [4:0] dump_wid;
alsaqr_credit_to_valrdy req_credit_to_valrdy(
   .clk(core_ref_clk),
   .reset(rst_n),
   //credit based interface   
   .data_in(processor_offchip_noc2_data),
   .valid_in(processor_offchip_noc2_valid),
   .yummy_in(processor_offchip_noc2_yummy),
            
   //val/rdy interface
   .data_out(valrdy_processor_offchip_noc2_data),
   .valid_out(valrdy_processor_offchip_noc2_valid),
   .ready_out(valrdy_processor_offchip_noc2_ready)
);



valrdy_to_credit resp_valrdy_to_credit (
   .clk(core_ref_clk),
   .reset(rst_n),
                
   //val/rdy interface
   .data_in(valrdy_offchip_processor_noc3_data),
   .valid_in(valrdy_offchip_processor_noc3_valid),
   .ready_in(valrdy_offchip_processor_noc3_ready),

   //credit based interface   
   .data_out(offchip_processor_noc3_data),
   .valid_out(offchip_processor_noc3_valid),
   .yummy_out(offchip_processor_noc3_yummy)
);

chip ariane_core_chip(

   //Memory Request
   .processor_offchip_noc2_valid(processor_offchip_noc2_valid),
   .processor_offchip_noc2_data(processor_offchip_noc2_data),
   .processor_offchip_noc2_yummy(processor_offchip_noc2_yummy),

   //Memory Response
   .offchip_processor_noc3_valid(offchip_processor_noc3_valid),
   .offchip_processor_noc3_data(offchip_processor_noc3_data),
   .offchip_processor_noc3_yummy(offchip_processor_noc3_yummy),

   // IO cell configs
   .slew(slew),
   .impsel1(impsel1),
   .impsel2(impsel2),

   // Input clocks
   .core_ref_clk(core_ref_clk),
   .io_clk(io_clk),

   // Resets
   // reset is assumed to be asynchronous
   .rst_n(rst_n),

   .pll_rst_n(pll_rst_n),

   // Chip-level clock enable
   .clk_en(clk_en),

   // PLL settings
   .pll_lock(pll_lock),
   .pll_bypass(pll_bypass),
   .pll_rangea(pll_rangea),

   // Clock mux select (bypass PLL or not)
   // Double redundancy with pll_bypass
   .clk_mux_sel(clk_mux_sel),

   // JTAG
   .jtag_clk(jtag_clk),
   .jtag_rst_l(jtag_rst_l),
   .jtag_modesel(jtag_modesel),
   .jtag_datain(jtag_datain),
   .jtag_dataout(jtag_dataout),

   // Async FIFOs enable
   .async_mux(async_mux),

   // Debug
   .ndmreset_i(ndmreset_i),    // non-debug module reset
   //.alsaqr_bootaddr(alsaqr_bootaddr),
   .debug_req_i(debug_req_i),   // async debug request
   .unavailable_o(unavailable_o), // communicate whether the hart is unavailable (e.g.: power down)
   // CLINT
   .timer_irq_i(timer_irq_i),   // Timer interrupts
   .ipi_i(ipi_i),         // software interrupt (a.k.a inter-process-interrupt)
   // PLIC
   .irq_i(irq_i)          // level sensitive IR lines, mip & sip (async)

);


noc_axi4_bridge noc_axi_bridge(
   // Clock + Reset
   .clk(core_ref_clk),
   .rst_n(rst_n),
   .uart_boot_en(0),
   .phy_init_done(rst_n),

   // Noc interface
   .src_bridge_vr_noc2_val(valrdy_processor_offchip_noc2_valid),
   .src_bridge_vr_noc2_dat(valrdy_processor_offchip_noc2_data),
   .src_bridge_vr_noc2_rdy(valrdy_processor_offchip_noc2_ready),
   .bridge_dst_vr_noc3_val(valrdy_offchip_processor_noc3_valid),
   .bridge_dst_vr_noc3_dat(valrdy_offchip_processor_noc3_data),
   .bridge_dst_vr_noc3_rdy(valrdy_offchip_processor_noc3_ready),

  // AXI interface
  .m_axi_awid(m_axi_ariane_req.aw.id),
  .m_axi_awaddr(m_axi_ariane_req.aw.addr),
  .m_axi_awlen(m_axi_ariane_req.aw.len),
  .m_axi_awsize(m_axi_ariane_req.aw.size),
  .m_axi_awburst(m_axi_ariane_req.aw.burst),
  .m_axi_awlock(m_axi_ariane_req.aw.lock ),
  .m_axi_awcache(m_axi_ariane_req.aw.cache),
  .m_axi_awprot(m_axi_ariane_req.aw.prot),
  .m_axi_awqos(m_axi_ariane_req.aw.qos ),
  .m_axi_awregion(m_axi_ariane_req.aw.region),
  .m_axi_awuser(m_axi_ariane_req.aw.user),
  .m_axi_awvalid(m_axi_ariane_req.aw_valid),
  .m_axi_awready(m_axi_ariane_resp.aw_ready),

  .m_axi_wid(dump_wid),
  .m_axi_wdata(m_axi_ariane_req.w.data),
  .m_axi_wstrb(m_axi_ariane_req.w.strb),
  .m_axi_wlast(m_axi_ariane_req.w.last),
  .m_axi_wuser(m_axi_ariane_req.w.user),
  .m_axi_wvalid(m_axi_ariane_req.w_valid),
  .m_axi_wready(m_axi_ariane_resp.w_ready),

  .m_axi_arid(m_axi_ariane_req.ar.id),
  .m_axi_araddr(m_axi_ariane_req.ar.addr),
  .m_axi_arlen(m_axi_ariane_req.ar.len),
  .m_axi_arsize(m_axi_ariane_req.ar.size ),
  .m_axi_arburst(m_axi_ariane_req.ar.burst),
  .m_axi_arlock(m_axi_ariane_req.ar.lock),
  .m_axi_arcache(m_axi_ariane_req.ar.cache),
  .m_axi_arprot(m_axi_ariane_req.ar.prot),
  .m_axi_arqos(m_axi_ariane_req.ar.qos),
  .m_axi_arregion(m_axi_ariane_req.ar.region),
  .m_axi_aruser(m_axi_ariane_req.ar.user),
  .m_axi_arvalid(m_axi_ariane_req.ar_valid),
  .m_axi_arready(m_axi_ariane_resp.ar_ready),

  .m_axi_rid(m_axi_ariane_resp.r.id),
  .m_axi_rdata(m_axi_ariane_resp.r.data),
  .m_axi_rresp(m_axi_ariane_resp.r.resp),
  .m_axi_rlast(m_axi_ariane_resp.r.last),
  .m_axi_ruser(m_axi_ariane_resp.r.user),
  .m_axi_rvalid(m_axi_ariane_resp.r_valid),
  .m_axi_rready(m_axi_ariane_req.r_ready),

  .m_axi_bid(m_axi_ariane_resp.b.id),
  .m_axi_bresp(m_axi_ariane_resp.b.resp),
  .m_axi_buser(m_axi_ariane_resp.b.user),
  .m_axi_bvalid(m_axi_ariane_resp.b_valid),
  .m_axi_bready(m_axi_ariane_req.b_ready)

);




axi_dw_converter size_converter#(
    AxiMaxReads         = 1    , // Number of outstanding reads
    AxiSlvPortDataWidth = 64    , // Data width of the slv port
    AxiMstPortDataWidth = 512    , // Data width of the mst port
    AxiAddrWidth        = 64    , // Address width
    AxiIdWidth          = 5    , // ID width
    aw_chan_t                   = ariane_axi_soc::aw_chan_t, // AW Channel Type
    mst_w_chan_t                = ariane_axi_soc::w_chan_t, //  W Channel Type for the mst port
    slv_w_chan_t                = ariane_axi_soc::w_chan_t, //  W Channel Type for the slv port
    b_chan_t                    = ariane_axi_soc::b_chan_t, //  B Channel Type
    ar_chan_t                   = ariane_axi_soc::ar_chan_t, // AR Channel Type
    mst_r_chan_t                = ariane_axi_soc::r_chan_t, //  R Channel Type for the mst port
    slv_r_chan_t                = ariane_axi_soc::r_chan_t, //  R Channel Type for the slv port
    axi_mst_req_t               = ariane_axi_soc::req_t, // AXI Request Type for mst ports
    axi_mst_resp_t              = ariane_axi_soc::resp_t, // AXI Response Type for mst ports
    axi_slv_req_t               = ariane_axi_soc::req_t, // AXI Request Type for slv ports
    axi_slv_resp_t              = ariane_axi_soc::resp_t  // AXI Response Type for slv ports
  ) (
    .clk_i(core_ref_clk),
    .rst_ni(rst_n),
    // Slave interface
    .slv_req_i(s_axi_ariane_req),
    .slv_resp_o(s_axi_ariane_resp),
    // Master interface
    .mst_req_o(m_axi_ariane_req),
    .mst_resp_i(m_axi_ariane_resp)
);


endmodule