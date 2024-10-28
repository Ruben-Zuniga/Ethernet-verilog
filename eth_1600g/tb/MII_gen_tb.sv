module EthernetFrameGenerator_tb;
    /*
    *---------CYCLES---------
    */
    parameter int IDLE_CYCLES = 12          ,   //! Idle length
    parameter int PREAMBLE_CYCLES = 6       ,   //! Preamble length
    parameter int SFD_CYCLES = 1            ,   //! SFD length
    parameter int DATA_CYCLES = 46          ,   //! Data length
    /*
    *---------CODES---------
    */
    parameter [7:0] IDLE_CODE = 8'h07       ,
    parameter [7:0] START_CODE = 8'hFB      ,
    parameter [7:0] PREAMBLE_CODE = 8'h55   ,
    parameter [7:0] SFD_CODE = 8'hD5        ,
    parameter [7:0] TERMINATE_CODE = 8'hFD  ,        

    input  logic        clk                 ,   //! Clock input
    input  logic        i_rst               ,   //! Asynchronous reset
    input  logic        i_start                 //! Signal to start frame transmission
    input  logic [7:0]  i_interrupt         ,   //! Interrupt the frame into different scenarios
    output logic [7:0]  o_tx_data           ,   //! Transmitted data (8 bits per cycle)
    output logic [7:0]  o_tx_ctrl           ,   //! Transmit control signal (indicates valid data)

    // Inputs
    logic clk;
    logic i_rst;
    logic i_interrupt;
    logic i_start;

    // Outputs from the EthernetFrameGenerator
    logic [7:0] o_tx_data;
    logic [7:0] o_tx_ctrl;

    // Instantiate the EthernetFrameGenerator
    EthernetFrameGenerator 
    #(
        .IDLE_CYCLES(IDLE_CYCLES),
        .PREAMBLE_CYCLES(PREAMBLE_CYCLES),
        .SFD_CYCLES(SFD_CYCLES),
        .DATA_CYCLES(DATA_CYCLES),
        .IDLE_CODE(IDLE_CODE),
        .PREAMBLE_CODE(PREAMBLE_CODE),
        .SFD_CODE(SFD_CODE),
        .EOF_CODE(EOF_CODE)
    
    )dut (
        .clk(clk),
        .i_rst(i_rst),
        .i_start(i_start),
        .i_interrupt(i_interrupt),
        .o_tx_data(o_tx_data),
        .o_tx_ctrl(o_tx_ctrl)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Test sequence
    initial begin
        i_rst = 1;
        i_start = 0;
        #20 i_rst = 0;
        #20 i_start = 1;
        #200 i_start = 0;
        #1000 ;

        // Monitor outputs
        $display(Out: %h, o_tx_data);
        $monitor("Time: %0t, o_tx_data: %h, o_tx_ctrl: %b, tx_clk: %b", $time, o_tx_data, o_tx_ctrl, tx_clk);

        $finish;
    end
endmodule