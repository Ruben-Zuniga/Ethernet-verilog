/*
    Testbench del generador de MII
*/

module signal_generator_tb();
    // Parameters
    parameter                           DATA_WIDTH              = 64                ;   // Must be a multiple of 8 bits (octets)
    parameter                           CTRL_WIDTH              = DATA_WIDTH / 8    ;   // 
    parameter int                       DATA_CHAR_PROBABILITY   = 50                ;   // Probability in percentage (0-100)
    parameter       [7:0]               DATA_CHAR_PATTERN       = 8'hAA             ;   // Data character pattern
    parameter       [7:0]               CTRL_CHAR_PATTERN       = 8'h55             ;   // Control character pattern
    parameter                           NUM_CYCLES              = 1000              ;   // Testbench clock cycles
    parameter                           LOGGING_ENABLED         = 1                 ;   // Optional logging

    // Testbench signals
    logic                               clk                                         ;
    logic                               rst                                         ;
    logic           [DATA_WIDTH-1:0]    o_data                                      ;
    logic           [CTRL_WIDTH-1:0]    o_ctrl                                      ;

    // Declare variables used in logging
    int                                 rand_num                                    ;
    
    // MII codes
    localparam TXD_IDLE = 8'h07;
    localparam TXD_SEQUENCE = 8'h9C;
    localparam TXD_START = 8'hFB;
    localparam TXD_TERMINATE = 8'hFD;
    localparam TXD_ERROR = 8'hFE;

    // Inter-frame function
    function logic [DATA_WIDTH-1:0] inter_frame;
        inter_frame = {8{TXD_IDLE}};
    endfunction

    // Clock generation
    always #5 clk = ~clk; // 100MHz clock

    always @(posedge clk) begin
        if (LOGGING_ENABLED) begin
            // Log summary in a single line
            $display("Time: %0t | Data Char: %0d | Control Char: %0d",
                     $time,         o_data,         o_ctrl);
        end
    end

    // Simulation control
    initial begin
        // VCD dump
        $dumpfile("signal_generator_tb.vcd");
        $dumpvars(0, signal_generator_tb);

        // Initialize signals
        clk = 0;
        rst = 1;

        #20;
        @(posedge clk);
        rst = 0;

        // Run simulation for NUM_CYCLES
        repeat (NUM_CYCLES) @(posedge clk);

        // Finish simulation
        $display("Simulation finished after %0d cycles.", NUM_CYCLES);

        $finish;
    end

    // Instantiate generator and checker modules
    signal_generator #(
        .DATA_WIDTH             (DATA_WIDTH             ),
        .CTRL_WIDTH             (CTRL_WIDTH             ),
        .DATA_CHAR_PROBABILITY  (DATA_CHAR_PROBABILITY  ),
        .DATA_CHAR_PATTERN      (DATA_CHAR_PATTERN      ),
        .CTRL_CHAR_PATTERN      (CTRL_CHAR_PATTERN      )
    ) u_generator (
        .clk                    (clk                    ),
        .rst                    (rst                    ),
        .o_data                 (o_data                 ),
        .o_ctrl                 (o_ctrl                 )
    );

endmodule
