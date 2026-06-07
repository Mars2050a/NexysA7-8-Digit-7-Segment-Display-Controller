// ============================================================================
// Module: top
// Description: Top-level module for Nexys A7 8-digit 7-segment display
//              control via UART.
//
// Protocol:
//   Host sends exactly 8 bytes over UART (115200 8N1):
//     Byte 0 -> Digit 0 (rightmost)
//     Byte 1 -> Digit 1
//     ...
//     Byte 7 -> Digit 7 (leftmost)
//   Each byte should be 0x00-0x09 representing digits 0-9.
//   The lower 4 bits of each byte are used as the digit value.
//   After 8 bytes, the counter wraps and a new sequence can begin.
//
// Port mapping (Nexys A7):
//   CLK100MHZ  - 100 MHz system clock (pin E3)
//   CPU_RESETN - Active-low reset button (pin C12)
//   UART_TXD_IN - UART receive from USB-UART bridge (pin C4)
//   UART_RXD_OUT - UART transmit to USB-UART bridge (pin D4, unused)
//   seg[6:0]  - 7-segment cathodes {CA,CB,CC,CD,CE,CF,CG}
//   an[7:0]   - 7-segment anodes (active low)
//   dp        - Decimal point (always off)
// ============================================================================

module top (
    input  wire       CLK100MHZ,     // 100 MHz system clock
    input  wire       CPU_RESETN,    // Active-low reset
    input  wire       UART_TXD_IN,   // UART RX (data from FTDI to FPGA)
    output wire       UART_RXD_OUT,  // UART TX (data from FPGA to FTDI, unused)
    output wire [6:0] seg,           // 7-segment segments {CA,CB,CC,CD,CE,CF,CG}
    output wire [7:0] an,            // 7-segment anodes (active low)
    output wire       dp             // Decimal point (active low, always off)
);

    // -----------------------------------------------------------------------
    // Internal signals
    // -----------------------------------------------------------------------
    wire [7:0] rx_data;      // Data byte from UART receiver
    wire       rx_valid;     // Valid pulse when new byte received

    // Digit value registers (4-bit each, 0-9 valid)
    reg [3:0] digit0;
    reg [3:0] digit1;
    reg [3:0] digit2;
    reg [3:0] digit3;
    reg [3:0] digit4;
    reg [3:0] digit5;
    reg [3:0] digit6;
    reg [3:0] digit7;

    reg [3:0] byte_count;   // Counts received bytes (0-7)

    // -----------------------------------------------------------------------
    // UART Receiver instantiation
    // -----------------------------------------------------------------------
    uart_receiver #(
        .CLK_FREQ (100_000_000),
        .BAUD_RATE(115200)
    ) uart_inst (
        .clk  (CLK100MHZ),
        .rst_n(CPU_RESETN),
        .rx   (UART_TXD_IN),
        .data (rx_data),
        .valid(rx_valid)
    );

    // -----------------------------------------------------------------------
    // UART data processing: receive 8 bytes, update digit registers
    //
    // On each rx_valid pulse, store the lower nibble of the received byte
    // into the corresponding digit register, then advance the counter.
    // After byte 7, the counter wraps to 0 on the next valid byte,
    // allowing continuous updates.
    // -----------------------------------------------------------------------
    always @(posedge CLK100MHZ or negedge CPU_RESETN) begin
        if (!CPU_RESETN) begin
            byte_count <= 0;
            digit0     <= 0;
            digit1     <= 0;
            digit2     <= 0;
            digit3     <= 0;
            digit4     <= 0;
            digit5     <= 0;
            digit6     <= 0;
            digit7     <= 0;
        end else if (rx_valid) begin
            // Store the digit value (use lower nibble, range 0-15)
            case (byte_count)
                4'd0: digit0 <= rx_data[3:0];
                4'd1: digit1 <= rx_data[3:0];
                4'd2: digit2 <= rx_data[3:0];
                4'd3: digit3 <= rx_data[3:0];
                4'd4: digit4 <= rx_data[3:0];
                4'd5: digit5 <= rx_data[3:0];
                4'd6: digit6 <= rx_data[3:0];
                4'd7: digit7 <= rx_data[3:0];
                default: ;
            endcase

            // Advance byte counter, wrap after 8 bytes
            if (byte_count == 4'd7)
                byte_count <= 0;
            else
                byte_count <= byte_count + 1;
        end
    end

    // -----------------------------------------------------------------------
    // 7-Segment Display Driver instantiation
    // -----------------------------------------------------------------------
    seven_seg_driver seg_driver (
        .clk    (CLK100MHZ),
        .rst_n  (CPU_RESETN),
        .digit0 (digit0),
        .digit1 (digit1),
        .digit2 (digit2),
        .digit3 (digit3),
        .digit4 (digit4),
        .digit5 (digit5),
        .digit6 (digit6),
        .digit7 (digit7),
        .seg    (seg),
        .an     (an)
    );

    // -----------------------------------------------------------------------
    // Unused outputs
    // -----------------------------------------------------------------------
    assign dp          = 1'b1;          // Decimal point always off (active low)
    assign UART_RXD_OUT = 1'b1;         // UART TX idle high (not used)

endmodule
