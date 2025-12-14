`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE-Illinois
// Engineer: Zuofu Cheng
// 
// Create Date: 06/08/2023 12:21:05 PM
// Design Name: 
// Module Name: hdmi_text_controller_v1_0_AXI
// Project Name: ECE 385 - hdmi_text_controller
// Target Devices: 
// Tool Versions: 
// Description: 
// This is a modified version of the Vivado template for an AXI4-Lite peripheral,
// rewritten into SystemVerilog for use with ECE 385.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - File modified to be more consistent with generated template
// Revision 11/18 - Made comments less confusing
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1 ns / 1 ps

module hdmi_text_controller_v1_0_AXI #
(

    // Parameters of Axi Slave Bus Interface S_AXI
    // Modify parameters as necessary for access of full VRAM range

    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH	= 16
)
(
    // Users to add ports here
    output logic [C_S_AXI_DATA_WIDTH-1:0] control_reg_out,
    output logic [C_S_AXI_DATA_WIDTH-1:0] palette_out [8],

    input logic [C_S_AXI_DATA_WIDTH-1:0] frame_count_in,
    input logic [C_S_AXI_DATA_WIDTH-1:0] drawx_in,
    input logic [C_S_AXI_DATA_WIDTH-1:0] drawy_in,

    output logic bram_ena,
    output logic [3:0] bram_wea,
    output logic [10:0] bram_addra,
    output logic [31:0] bram_dina,
    input logic [31:0] bram_douta,
    // User ports ends

    // Global Clock Signal
    input logic  S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input logic  S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
        // privilege and security level of the transaction, and whether
        // the transaction is a data access or an instruction access.
    input logic [2 : 0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
        // valid write address and control information.
    input logic  S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
        // to accept an address and associated control signals.
    output logic  S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
    input logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
        // valid data. There is one write strobe bit for each eight
        // bits of the write data bus.    
    input logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
        // data and strobes are available.
    input logic  S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
        // can accept the write data.
    output logic  S_AXI_WREADY,
    // Write response. This signal indicates the status
        // of the write transaction.
    output logic [1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
        // is signaling a valid write response.
    output logic  S_AXI_BVALID,
    // Response ready. This signal indicates that the master
        // can accept a write response.
    input logic  S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
        // and security level of the transaction, and whether the
        // transaction is a data access or an instruction access.
    input logic [2 : 0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
        // is signaling valid read address and control information.
    input logic  S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
        // ready to accept an address and associated control signals.
    output logic  S_AXI_ARREADY,
    // Read data (issued by slave)
    output logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
        // read transfer.
    output logic [1 : 0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
        // signaling the required read data.
    output logic  S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
        // accept the read data and response information.
    input logic  S_AXI_RREADY
);

// AXI4LITE signals
logic  [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
logic  axi_awready;
logic  axi_wready;
logic  [1 : 0] 	axi_bresp;
logic  axi_bvalid;
logic  [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
logic  axi_arready;
logic  [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
logic  [1 : 0] 	axi_rresp;
logic  	axi_rvalid;

// Example-specific design signals
// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
// ADDR_LSB is used for addressing 32/64 bit registers/memories
// ADDR_LSB = 2 for 32 bits (n downto 2)
// ADDR_LSB = 3 for 64 bits (n downto 3)
localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
localparam integer OPT_MEM_ADDR_BITS = 13;  // 11 or larger
//----------------------------------------------
//-- Signals for user logic register space example
//------------------------------------------------
//-- Number of Slave Registers 4
//logic [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
//logic [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
//logic [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
//logic [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
//
//Note: the provided Verilog template had the registered declared as above, but in order to give 
//students a hint we have replaced the 4 individual registers with an unpacked array of packed logic. 
//Note that you as the student will still need to extend this to the full register set needed for the lab.

// week 2 changes:
logic [C_S_AXI_DATA_WIDTH-1:0] slv_regs[1];
logic [C_S_AXI_DATA_WIDTH-1:0] palette_regs[8];
logic [1:0] bram_read_wait; // wait states for BRAM read. We set 0 to be idle, and 1,2,3 to be wait states
logic [C_S_AXI_DATA_WIDTH-1:0] axi_araddr_latched; // latched read address for wait state
// week 2 changes end
logic [C_S_AXI_DATA_WIDTH-1:0] read_only_regs[3];
logic	 slv_reg_rden;
logic	 slv_reg_wren;
logic [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
integer	 byte_index;
logic	 aw_en;

// I/O Connections assignments

assign S_AXI_AWREADY	= axi_awready;
assign S_AXI_WREADY	= axi_wready;
assign S_AXI_BRESP	= axi_bresp;
assign S_AXI_BVALID	= axi_bvalid;
assign S_AXI_ARREADY = axi_arready;
assign S_AXI_RDATA	= axi_rdata;
assign S_AXI_RRESP	= axi_rresp;
assign S_AXI_RVALID	= axi_rvalid;
// Implement axi_awready generation
// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
// de-asserted when reset is low.

always_ff @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_awready <= 1'b0;
      aw_en <= 1'b1;
    end 
  else
    begin    
      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
          // slave is ready to accept write address when 
          // there is a valid write address and write data
          // on the write address and data bus. This design 
          // expects no outstanding transactions. 
          axi_awready <= 1'b1;
          aw_en <= 1'b0;
        end
        else if (S_AXI_BREADY && axi_bvalid)
            begin
              aw_en <= 1'b1;
              axi_awready <= 1'b0;
            end
      else           
        begin
          axi_awready <= 1'b0;
        end
    end 
end       

// Implement axi_awaddr latching
// This process is used to latch the address when both 
// S_AXI_AWVALID and S_AXI_WVALID are valid. 

always_ff @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_awaddr <= 0;
    end 
  else
    begin    
      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
          // Write Address latching 
          axi_awaddr <= S_AXI_AWADDR;
        end
    end 
end       

// Implement axi_wready generation
// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
// de-asserted when reset is low. 

always_ff @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_wready <= 1'b0;
    end 
  else
    begin    
      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
        begin
          // slave is ready to accept write data when 
          // there is a valid write address and write data
          // on the write address and data bus. This design 
          // expects no outstanding transactions. 
          axi_wready <= 1'b1;
        end
      else
        begin
          axi_wready <= 1'b0;
        end
    end 
end       

// Implement memory mapped register select and write logic generation
// The write data is accepted and written to memory mapped registers when
// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
// select byte enables of slave registers while writing.
// These registers are cleared when reset (active low) is applied.
// Slave register write enable is asserted when valid address and data are available
// and the slave is ready to accept the write address and write data.
assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

// Notion: WSTRB is byte enable signal, we use this to indicate which bytes of the 32-bit word are being written to.
// Fix the write logic, refer to LAB 5 code for help.
always_ff @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
        slv_regs[0] <= 0;
        palette_regs[0] <= 32'h0000A000;  // C1=blue, C0=black
        palette_regs[1] <= 32'h00AA00A0;  // C3=cyan, C2=green
        palette_regs[2] <= 32'h000AA00A;  // C5=magenta, C4=red
        palette_regs[3] <= 32'h0AAA0A50;  // C7=lt gray, C6=brown
        palette_regs[4] <= 32'h055F5555;  // C9=lt blue, C8=dk gray
        palette_regs[5] <= 32'h05FF55F5;  // C11=lt cyan, C10=lt green
        palette_regs[6] <= 32'h0F5FF555;  // C13=lt magenta, C12=lt red
        palette_regs[7] <= 32'h0FFFFF55;  // C15=white, C14=yellow
    end
  else begin
    if (slv_reg_wren)
      begin
        if(axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] >= 2048 &&
            axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 2056)
            begin
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                palette_regs[axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] - 2048][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          end
        end
     end
end

always_ff @(posedge S_AXI_ACLK) begin
    if (~S_AXI_ARESETN) begin
        bram_ena <= 1'b0;
        bram_wea <= 4'b0;
        bram_addra <= 11'b0;
        bram_dina <= 32'b0;
    end else if (slv_reg_wren && axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 1200) begin
        bram_ena <= 1'b1;
        bram_wea <= S_AXI_WSTRB;
        bram_addra <= axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
        bram_dina <= S_AXI_WDATA;
    end else if (slv_reg_rden && axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 1200) begin
        bram_ena <= 1'b1;
        bram_wea <= 4'b0;
        bram_addra <= axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
        bram_dina <= 32'b0;
    end else if (bram_read_wait != 0 && axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 1200) begin
        bram_ena <= 1'b1;
        bram_wea <= 4'b0;
        bram_addra <= axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
        bram_dina <= 32'b0;
    end else begin
        bram_ena <= 1'b0;
        bram_wea <= 4'b0;
        bram_addra <= 11'b0;
        bram_dina <= 32'b0;
    end
end

// Implement write response logic generation
// The write response and response valid signals are asserted by the slave 
// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
// This marks the acceptance of address and indicates the status of 
// write transaction.

always_ff @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_bvalid  <= 0;
      axi_bresp   <= 2'b0;
    end 
  else
    begin    
      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
        begin
          // indicates a valid write response is available
          axi_bvalid <= 1'b1;
          axi_bresp  <= 2'b0; // 'OKAY' response 
        end                   // work error responses in future
      else
        begin
          if (S_AXI_BREADY && axi_bvalid) 
            //check if bready is asserted while bvalid is high) 
            //(there is a possibility that bready is always asserted high)   
            begin
              axi_bvalid <= 1'b0; 
            end  
        end
    end
end   

// Implement axi_arready generation
// axi_arready is asserted for one S_AXI_ACLK clock cycle when
// S_AXI_ARVALID is asserted. axi_awready is 
// de-asserted when reset (active low) is asserted. 
// The read address is also latched when S_AXI_ARVALID is 
// asserted. axi_araddr is reset to zero on reset assertion.

always_ff @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_arready <= 1'b0;
      axi_araddr  <= 32'b0;
    end 
  else
    begin    
      if (~axi_arready && S_AXI_ARVALID)
        begin
          // indicates that the slave has acceped the valid read address
          axi_arready <= 1'b1;
          // Read address latching
          axi_araddr  <= S_AXI_ARADDR;
        end
      else
        begin
          axi_arready <= 1'b0;
        end
    end 
end       

// Implement axi_arvalid generation
// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
// data are available on the axi_rdata bus at this instance. The 
// assertion of axi_rvalid marks the validity of read data on the 
// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
// is deasserted on reset (active low). axi_rresp and axi_rdata are 
// cleared to zero on reset (active low).  

// We add wait state logic for reading from BRAM here; This deals with address decoding and wait states.
// week 2 changes begin:
always_ff @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_rvalid <= 0;
      axi_rresp  <= 0;
      bram_read_wait <= 0; // wk2
      axi_araddr_latched <= 0; // wk2
    end 
  else
    begin    
      // Begin wait state logic for BRAM read.
      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid && bram_read_wait == 2'b00)
        begin
          // Valid read data is available at the read data bus
          axi_araddr_latched <= axi_araddr; // latch the read address
          bram_read_wait <= 1; // move to wait state 1
          axi_rvalid <= 0; // not valid yet
          axi_rresp  <= 2'b0; // 'OKAY' response
        end   
      else if (bram_read_wait == 2'b01)
        begin
          bram_read_wait <= 2'b10; // move to wait state 2
          axi_rvalid <= 0; // not valid yet
        end
      else if (bram_read_wait == 2)
        begin
          bram_read_wait <= 0; // back to idle
          axi_rvalid <= 1; // now data is valid
          axi_rresp  <= 2'b0; // 'OKAY' response
        end
      else if (axi_rvalid && S_AXI_RREADY)
        begin
          // Read data is accepted by the master
          axi_rvalid <= 1'b0;
        end                
    end
end    
// week 2 changes end

// Implement memory mapped register select and read logic generation
// Slave register read enable is asserted when valid address is available
// and the slave is ready to accept the read address.
assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

always_comb
begin
    if (axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 1200)
        begin
            reg_data_out = bram_douta;
        end
//    else if (axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 600) 
//        begin
//            reg_data_out = slv_regs[0];
//        end
    // Turned to color palette
    else if (axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] >= 2048 && axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 2056) 
        begin
            reg_data_out = palette_regs[axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] - 2048];
        end
     // Reserved for control regs
    else if (axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] >= 2056 && axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] <= 2058) 
        begin
            reg_data_out = read_only_regs[axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] - 2056];
        end
      // Address decoding for reading registers
    else 
        begin
            reg_data_out = 0;
        end
      // Week 2 changes end
end

// Output register or memory read data
always_ff @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_rdata  <= 0;
    end 
  else
    begin    
      // When there is a valid read address (S_AXI_ARVALID) with 
      // acceptance of read address by the slave (axi_arready), 
      // output the read data 
      if (bram_read_wait == 2'b10)
        begin
          axi_rdata <= reg_data_out;     // register read data
        end   
    end
end       

// Add user logic here
assign control_reg_out = slv_regs[0];
assign palette_out = palette_regs;
assign read_only_regs[0] = frame_count_in;
assign read_only_regs[1] = drawx_in;
assign read_only_regs[2] = drawy_in;
// User logic ends

endmodule

