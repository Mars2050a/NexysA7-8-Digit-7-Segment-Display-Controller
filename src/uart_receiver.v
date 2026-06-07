// ============================================================================
// Module: uart_receiver
// Description: UART receiver module with 8N1 format (8 data bits, No parity,
//              1 stop bit). Samples the RX line at the middle of each bit
//              period for reliable data recovery.
//
// Parameters:
//   CLK_FREQ  - System clock frequency in Hz (default 100_000_000)
//   BAUD_RATE - Target baud rate (default 115200)
//
// Ports:
//   clk    - System clock input
//   rst_n  - Active-low asynchronous reset
//   rx     - UART receive line (serial data input)
//   data   - 8-bit received data byte (valid when valid == 1)
//   valid  - One-cycle pulse indicating new data available
// ============================================================================

module uart_receiver #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid
);

    // -----------------------------------------------------------------------
    // Baud rate timing constants
    // -----------------------------------------------------------------------
    // Bit period in clock cycles = CLK_FREQ / BAUD_RATE
    // Half-bit period used to sample at the center of each bit
    localparam BIT_CNT    = CLK_FREQ / BAUD_RATE;
    localparam HALF_BIT   = BIT_CNT / 2;

    // -----------------------------------------------------------------------
    // State machine encoding
    // -----------------------------------------------------------------------
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [1:0] next_state;

    reg [15:0] baud_counter;  // Counter for bit timing
    reg [15:0] next_baud_counter;
    reg [2:0]  bit_index;     // Which data bit we're sampling (0..7)
    reg [2:0]  next_bit_index;
    reg [7:0]  shift_reg;     // Shift register for incoming data bits
    reg [7:0]  next_shift_reg;

    // -----------------------------------------------------------------------
    // Sequential logic (state + data registers)
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            baud_counter <= 0;
            bit_index    <= 0;
            shift_reg    <= 0;
            data         <= 0;
            valid        <= 0;
        end else begin
            state        <= next_state;
            baud_counter <= next_baud_counter;
            bit_index    <= next_bit_index;
            shift_reg    <= next_shift_reg;
            data         <= (next_state == IDLE && state == STOP) ? shift_reg : data;
            valid        <= (next_state == IDLE && state == STOP);
        end
    end

    // -----------------------------------------------------------------------
    // Combinational logic (next-state and control)
    // -----------------------------------------------------------------------
    always @(*) begin
        next_state        = state;
        next_baud_counter = baud_counter + 1;
        next_bit_index    = bit_index;
        next_shift_reg    = shift_reg;

        case (state)
            // IDLE: wait for start bit (RX goes low)
            IDLE: begin
                next_baud_counter = 0;
                next_bit_index    = 0;
                if (!rx) begin
                    next_state = START;
                end
            end

            // START: wait half bit period, verify start bit is still low
            START: begin
                if (baud_counter == HALF_BIT - 1) begin
                    if (!rx) begin
                        // Valid start bit, begin data reception
                        next_state        = DATA;
                        next_baud_counter = 0;
                        next_bit_index    = 0;
                        next_shift_reg    = 0;
                    end else begin
                        // Glitch or noise, return to IDLE
                        next_state = IDLE;
                    end
                end
            end

            // DATA: sample 8 data bits (LSB first) at each bit center
            DATA: begin
                if (baud_counter == BIT_CNT - 1) begin
                    next_shift_reg[bit_index] = rx;
                    next_baud_counter         = 0;
                    if (bit_index == 7) begin
                        next_state = STOP;
                    end else begin
                        next_bit_index = bit_index + 1;
                    end
                end
            end

            // STOP: wait one bit period, then return to IDLE
            STOP: begin
                if (baud_counter == BIT_CNT - 1) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule
