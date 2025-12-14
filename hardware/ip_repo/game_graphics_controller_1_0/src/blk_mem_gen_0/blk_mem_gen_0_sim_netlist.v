// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Thu Nov  6 15:14:10 2025
// Host        : LAPTOP-GN38KN49 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim {c:/Users/Ziheng
//               Qi/Desktop/ip_repo/hdmi_text_controller_1_0/src/blk_mem_gen_0/blk_mem_gen_0_sim_netlist.v}
// Design      : blk_mem_gen_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7s50csga324-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_0,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_0
   (clka,
    ena,
    wea,
    addra,
    dina,
    douta,
    clkb,
    enb,
    web,
    addrb,
    dinb,
    doutb);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [3:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [10:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [31:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [31:0]douta;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTB, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clkb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB EN" *) input enb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB WE" *) input [3:0]web;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *) input [10:0]addrb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DIN" *) input [31:0]dinb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *) output [31:0]doutb;

  wire [10:0]addra;
  wire [10:0]addrb;
  wire clka;
  wire clkb;
  wire [31:0]dina;
  wire [31:0]dinb;
  wire [31:0]douta;
  wire [31:0]doutb;
  wire ena;
  wire enb;
  wire [3:0]wea;
  wire [3:0]web;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rsta_busy_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [10:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [10:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "11" *) 
  (* C_ADDRB_WIDTH = "11" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "8" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "0" *) 
  (* C_COUNT_36K_BRAM = "2" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     10.7492 mW" *) 
  (* C_FAMILY = "spartan7" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "1" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "1" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "1" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "blk_mem_gen_0.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "2" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "1200" *) 
  (* C_READ_DEPTH_B = "1200" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "32" *) 
  (* C_READ_WIDTH_B = "32" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "1" *) 
  (* C_USE_BYTE_WEB = "1" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "4" *) 
  (* C_WEB_WIDTH = "4" *) 
  (* C_WRITE_DEPTH_A = "1200" *) 
  (* C_WRITE_DEPTH_B = "1200" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "32" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "spartan7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_0_blk_mem_gen_v8_4_5 U0
       (.addra(addra),
        .addrb(addrb),
        .clka(clka),
        .clkb(clkb),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb(dinb),
        .douta(douta),
        .doutb(doutb),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(enb),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[10:0]),
        .regcea(1'b0),
        .regceb(1'b0),
        .rsta(1'b0),
        .rsta_busy(NLW_U0_rsta_busy_UNCONNECTED),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[10:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[31:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(wea),
        .web(web));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2022.2"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
VHPlDkoDlWlBfBMvPBmGYmaek3s9hXXhjF28kllYPnaNm3TSnzzpXHWHc8Ye9/2L2yiQfJ1hTWou
Ia/zeQ8h9/dtr6QB5YkyW4wlb/LbMgXb+DGIXPSllNl0IMsRQIcQDbcQm1bO/nlhb+2pjxiuaQrl
DbvxoDwPs7z3LunRxsg=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
lmIhoX8hXuc7tNV1sXY1K2/gXL7Y7Hq73qQF7+x03UWWTRd3uhGmVQtOMVbhIW+66UkWUHiD26zL
fzqGor8bgSNGpSFyS11k4TwLQT4OfAMGO8C9Qmmh4+VENBnpS9TW+wHzCv8oUwht7xYtYRZvOvYK
F3fMppz2sBkUd1lciw98ZE/UmNkhqBuMfIYF43j45DEJ55PBhOZNg91Ls4v3qBHyBAaYPFFoMry3
d5Fw1PZyFQSEOSSpwgyds2aN0g6oIwl7zm0LJrM9VDAOxBUE50hk+oHr4jj8J8UhHQJnlEHm1Idm
rvxKygNKRvfSpa90NYxZJFYgqnrMYg+19+9aZA==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
VkyCjO2onoeZWEoYQ/4ue7X5mkHyTYVW9xjdoTsGS4GdP/Q64VaCZL/jr6R8DVDXPMnH7tRMrDpo
jpYBnyzSgOkfgqM+96ioC2fDyAaG4gYgGLmrBR6qK3/mxXwAZZX+GJ9R/eWXkc9h8xN+gsSSX6/M
jIQCgeT6q7PB4dWT6KY=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Iub91V+TnhVlZCSLu6iKmFjix71y6/l83OPTs8uewWvkE7WcqYxEKi9fonXEkzAtWzuKwEUqnOlN
VBsNJqPUdKcd22q523mrdt89mpdosWD+hvZdO7ELhJniY5u9h49FFkubpN2JiUTcIcKEYxVNlds4
wyvaYUqbPVH5v2ooJwDdimS4GVn9HerCOgPwfshvQDNlMTxLcYju4v8BHMc5Rub9Q/ihvpQU74v2
ouZ9XIwA+C6pBLwvaqS8jE7HXOokgqJilaX/W/t+KEgiFry/txRTMU9WMD7tCN7lcfjCydmS3Lq+
3u6Hsr0S8BwNjcaDpZDnBTygUJd4JSqREnk33w==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
U46EWFmKmpZGaWfyL+dokyQtJtaOYsa7HCW/+fdtw9/yHKTWFpmqKBZngBj5rPkNhtTDDCJkqsYj
tUXg1j4tgIBaCQn9B0q/aG+B3gPLrudp9hLL25mVbsfiTzdekiV2hJMmhuMoavKKPJHC6zyW7kZi
80er82OQy8h+Df/fe6TRjH9xEt3/b80tRKUMbxkLfnnkAyyf1KfOhB6/uyI4mwXuQR+DsAbzybKR
YtXpOiW72tGrXTFlzcwbHamWZefqsilVpBw6V5dh33vYKGx50xwWpj76maAkpQrOpB7zufeldJe4
W1UOEN84AZdRTLkVSxamWo/wp8nP9fiGS/ItRw==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2021_07", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
qczgIJYpE/SzErzK7eWJBGcDFEzDLm8cKbwJbPXuM6YnJxx44W+E60R3war7K2QGFAkOoCDUtDC7
SghJGF32btaDLzeKm0tQ669sBtQmMIaBrlt7I9QBkNM8zN9GL92qxNC9o3UVWMOYy5BmH8nUPgcE
O6lRubeltlrTuDe7UJQ2nEPHcXjpUJJ8dxktyW+LovBy1OxW8g4GRAsmEJsoOEg0HuDdWcc4IshJ
PvwPJ7LblELAKsdkSt65y9VaklaEm7MlH4ImlgIa74TgRmutLUbWxM1QYhGE5rAzFhGU5i3RJOdx
L3N7GGGvLMW2z9NSHbIFX+/eNII9fNJ9nZbgLA==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Ti1NUgDv8YPk90APMwfu/mRr38QYwAxZfv0T6zQ89YS55t2EquEGVqrEafYX6rTydLOw8le1Oucv
f2oERpSSSTih/ScZneSZmuPE/Zh2BU1Ajv0j+/+0uEWXU+5lLPbDJjnapTmJXih1MYPf0SHpZZmE
BKj2IEBI9MPZlh6bxpa5BWJnyPdAvHf+UNaMXU9+pmbtrzUVebql4mFJu45Z3+ehmFY4FBW3zXMF
44C4TlHACLwL3vHVMCVfeKhgdVDbpE+/IFhTStz7mZ9h9RKGanQcs6YDVM1R+2RKA1QT1fX4FiQc
1V+FGmrm1ujxmFGXwpfNKByVlfCY0oWhRJCYYQ==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
HuEXFK0NXt09xU2yxxjng1OLsT+ZEM4EhqBgpr9D2ljw2vDaMBrqEsRQTc2B9soDq3ewDduHJXBd
OGYxkPnoN6LhjULtB2nTgjcH6NxA4puZ1ZNcndDndVBo8rTW5W1OqHq6InAG0CqPpTIkuqz3ECPl
EysI++MCDfH6tIzlekxJFIJ1McJsTq5rFuLzMMcrmkBxgcayDpOcCFuzZzCczxmt/cCCIKmDybwT
OQXmOcLJoYLP4sFu6R9c6xO8i6p++crv2N3eIxZHKbek9xBBZqQM9EYuEtsbkqAs9XZpa16i5njR
BDFxTKcP6r7JgFALJE89AZhBbate5JXWp0v4ECZD18aEL17CipwcWPutNMdG1apzSPP5y59n7rMG
yxBPz1gKHc3Emkl4WcO0hjICxqmO6dMXoY8JvBSf6ry2l0sH9Ihr3Bq5WWmlhPHnoaNr5jl//vNe
KfToWtn97eoVSt1LnmXXnSpdigbHr0UIg8AdkpdkuNRaWdVicDdgSo49

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
mokwst2bn6UxD6V9UdIgCIG1QQ/d0FiJqYGOTI2eHPV6YElaLjnJ8DnQmZnGS95o3x93FDOoa58C
RwYsX1fVoVtXkj1LuZq0k7q9vEe4T8xMjpkeYtIHY9k0Xhy1Lq/xRlfzGAf9fvf9e+f4r7aR/Sb/
uCZxxugG5niTwLENY1n3NthYL0jvo8Fmdw4Qg0nTCGWlVCws+09K0g9/lx6I9EcuHHemcHO3fOZG
lMc4NaPNozKwnyDMoWUkwiVxyFEPFaQLNYqzjvR+CqrWfhFLo96JWhL+eaDoNuZoBVYQtNH5ZwBL
BoO27Pw10lgcReGlZBz3BLO7T4ddynCx0+eSnw==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
PiP7AjOQqqouyQMoBQqgWIDhUSViq94rIvGiIJ/UKMDspM/yXw1caE8AhWHTjYckC4yLpPAz5P6s
1Z6flzDPrzVwg4e59X2cc4IMCHhedna0rDO804njcc6amRDTeLsMLTkWfvomB4xwszm2AgT+PRnB
WHd09ZUDVFjiBXT+Oa9AicgGJHrX3w823yBPuAa704kje/SzgtiDpcTU1eLmLhLW7LpEd9KIHd9s
ER7Uk9Orws0Kq9PMTqMX4hMn5K5mFakOeOURiEbUjdv5RiIJ2g/PlQXSItM8fHsBTQa6fOaJwQTI
vHwK3a8ZBHpfT1YH+n7wNiNUZwD4SFXm1QVx4g==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Ul5ZfTHJwMctaNhYRortUZizYMPYRef7uYqPSuMkxsArnxI/cjGh+KRMwzV86hyp/6TXSJIjm5ec
2wX2UONdPN+DOJ84jYC4JbgJQrPnTj7ioD8uLX/WlyPcQzyF5keqFgj5eR5s13FskVWCuAWf5m9w
mhFEKFjVXDAr7gVgAJh/hL8P6Psrnf+LGfiM8JhnDepsHEYykGlpD3fzru2BGgqHWqPqFMcnyVGl
vysaIXiJz/eYKvO8RGcgd3DJAM/wPm9A0m/DWcmSnczOgTjoqkHcBg2H5uJMLvufzmjImi6LYEqq
v04ESDEN31cSUzqUYcayvMFOnI/WNsWbFIa5+Q==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 48176)
`pragma protect data_block
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
KGAzKYyC0nC6GXY=
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
