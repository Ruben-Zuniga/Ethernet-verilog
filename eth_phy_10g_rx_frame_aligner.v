// Language: Verilog 2001

`resetall
`timescale 1us / 100ns
`default_nettype none

/*
 * 10G Ethernet PHY frame aligner
 */
module eth_phy_10g_rx_frame_aligner #
(
    parameter DATA_WIDTH            = 64,
    parameter HDR_WIDTH             = 2,
    parameter RX_WIDTH              = DATA_WIDTH+HDR_WIDTH,
    parameter BITSLIP_HIGH_CYCLES   = 1,
    parameter BITSLIP_LOW_CYCLES    = 8
)
(
    input  wire                         clk,
    input  wire                         rst,

    /*
     * SERDES interface
     */
    input  wire [RX_WIDTH-1:0]          serdes_rx,          // Senial de entrada de 66 bits
    input  wire                         serdes_rx_bitslip,
    output wire [DATA_WIDTH-1:0]        serdes_rx_data,
    output wire [HDR_WIDTH-1:0]         serdes_rx_hdr
);

// bus width assertions
initial begin
    if (DATA_WIDTH != 64) begin
        $error("Error: Interface width must be 64");
        $finish;
    end

    if (HDR_WIDTH != 2) begin
        $error("Error: HDR_WIDTH must be 2");
        $finish;
    end
end

// POR AHORA NO SE USAN LOS LOCALPARAM
localparam BITSLIP_MAX_CYCLES    = BITSLIP_HIGH_CYCLES > BITSLIP_LOW_CYCLES ? BITSLIP_HIGH_CYCLES : BITSLIP_LOW_CYCLES;
localparam BITSLIP_COUNT_WIDTH   = $clog2(BITSLIP_MAX_CYCLES);
localparam SH_POS_WIDTH          = $clog2(RX_WIDTH);

reg         [SH_POS_WIDTH-1:0]          sh_pos                  = 0;

//reg         [BITSLIP_COUNT_WIDTH-1:0]   bitslip_count_reg       = {BITSLIP_COUNT_WIDTH{1'b0}};
//reg                                     bitslip_count_next;

reg         [RX_WIDTH-1:0]              serdes_rx_reg           = {RX_WIDTH{1'b0}};
reg         [2*RX_WIDTH-1:0]            serdes_rx_concat_reg    = {2*RX_WIDTH{1'b0}};
reg         [2*RX_WIDTH-1:0]            serdes_rx_concat_next;

//reg                                     serdes_rx_bitslip_reg   = 1'b0;
//reg                                     serdes_rx_bitslip_next;

reg         [HDR_WIDTH-1:0]             serdes_rx_hdr_reg       = {HDR_WIDTH{1'b0}};
reg         [HDR_WIDTH-1:0]             serdes_rx_hdr_next;
reg         [DATA_WIDTH-1:0]            serdes_rx_data_reg      = {DATA_WIDTH{1'b0}};
reg         [DATA_WIDTH-1:0]            serdes_rx_data_next;

always @(*) begin

    //serdes_rx_bitslip_next          = serdes_rx_bitslip_reg;

    /*  ej: sh_pos = 0 y DATA_WIDTH = 2     ej: sh_pos = 3 y DATA_WIDTH = 2
        concat  = [11111111] (7:0)          concat  = [00011111] (7:0)
        hdr     = [00000011] (1:0)          hdr     = [00000011] (4:3)
        data    = [00001100] (3:2)          data    = [00001100] (6:5)
    */
    serdes_rx_concat_next           = serdes_rx_concat_reg >> sh_pos;
    serdes_rx_hdr_next              = serdes_rx_concat_next[HDR_WIDTH-1:0];
    serdes_rx_data_next             = serdes_rx_concat_next[RX_WIDTH-1:2];

end

always @(posedge clk) begin

    serdes_rx_concat_reg            <= {serdes_rx_concat_reg[RX_WIDTH-1:0], serdes_rx};
    serdes_rx_hdr_reg               <= serdes_rx_hdr_next;
    serdes_rx_data_reg              <= serdes_rx_data_next;
    
    if (serdes_rx_bitslip) begin            // if( !(bitslip_count_reg == {BITSLIP_COUNT_WIDTH{1'b0}}) )

        //serdes_rx_bitslip_next      = 1'b0;

        if(sh_pos == RX_WIDTH)
            sh_pos                  = {SH_POS_WIDTH{1'b0}};
        else
            sh_pos                  = sh_pos+1;

    end
    /*
    if (rst) begin
        bitslip_count_reg           <= 0;
        serdes_rx_bitslip_reg       <= 1'b0;
        
    end else begin
        bitslip_count_reg           <= bitslip_count_next;
        serdes_rx_bitslip_reg       <= serdes_rx_bitslip_next;
    end
    */
end

assign                                  serdes_rx_hdr           = serdes_rx_hdr_reg;
assign                                  serdes_rx_data          = serdes_rx_data_reg;

endmodule

`resetall