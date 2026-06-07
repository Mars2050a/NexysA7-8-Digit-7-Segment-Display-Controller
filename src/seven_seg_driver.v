// ============================================================================
// Module: seven_seg_driver
// Description: 8-digit 7-segment display driver with dynamic scanning.
//              Designed for Nexys A7 (common anode, active-low segments/anodes).
//              Drives one digit at a time with 1ms refresh per digit,
//              achieving ~125 Hz overall refresh rate (no visible flicker).
//
// Inputs:
//   digit0..digit7 - 4-bit values (0-9 valid, >9 shows blank)
//
// Outputs:
//   seg[6:0] - Segment outputs {CA, CB, CC, CD, CE, CF, CG} (active low)
//   an[7:0]  - Anode outputs (active low, one-hot per cycle)
// ============================================================================

module seven_seg_driver (
    input  wire       clk,        // 100 MHz system clock
    input  wire       rst_n,      // Active-low reset
    input  wire [3:0] digit0,     // Digit 0 value (0-9)
    input  wire [3:0] digit1,     // Digit 1 value (0-9)
    input  wire [3:0] digit2,     // Digit 2 value (0-9)
    input  wire [3:0] digit3,     // Digit 3 value (0-9)
    input  wire [3:0] digit4,     // Digit 4 value (0-9)
    input  wire [3:0] digit5,     // Digit 5 value (0-9)
    input  wire [3:0] digit6,     // Digit 6 value (0-9)
    input  wire [3:0] digit7,     // Digit 7 value (0-9)
    output reg  [6:0] seg,        // Segment: {CA,CB,CC,CD,CE,CF,CG} (active low)
    output reg  [7:0] an          // Anodes (active low)
);

    // -----------------------------------------------------------------------
    // Refresh timing: 1ms per digit
    // At 100 MHz: 100_000_000 cycles/sec * 0.001 sec = 100_000 cycles
    // Digit scan rate: 1/(8 * 1ms) = 125 Hz (no flicker)
    // -----------------------------------------------------------------------
    reg [16:0] cnt;           // Counter for 1ms timing
    reg [2:0]  digit_sel;     // Currently selected digit (0-7)

    // 1ms timer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 0;
        else if (cnt == 99_999)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end

    // Digit select (advance every 1ms)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            digit_sel <= 0;
        else if (cnt == 99_999)
            digit_sel <= digit_sel + 1;
    end

    // -----------------------------------------------------------------------
    // Multiplexer: select current digit value based on digit_sel
    // -----------------------------------------------------------------------
    reg [3:0] current_digit;
    always @(*) begin
        case (digit_sel)
            3'd0: current_digit = digit0;
            3'd1: current_digit = digit1;
            3'd2: current_digit = digit2;
            3'd3: current_digit = digit3;
            3'd4: current_digit = digit4;
            3'd5: current_digit = digit5;
            3'd6: current_digit = digit6;
            3'd7: current_digit = digit7;
            default: current_digit = 4'hF;
        endcase
    end

    // -----------------------------------------------------------------------
    // 7-segment decoder (common anode, active low)
    //
    // seg[6:0] = {CA, CB, CC, CD, CE, CF, CG}
    //   Bit:     6    5    4    3    2    1    0
    //          CA  CB  CC  CD  CE  CF  CG
    //
    //        A
    //      +---+
    //     F|   |B
    //      +-G-+
    //     E|   |C
    //      +---+
    //        D
    //
    // Active-low: 0 = segment ON, 1 = segment OFF
    // Common anode: anode ON when AN[x] = 0
    //
    // Encoding reference: https://en.wikipedia.org/wiki/Seven-segment_display
    // -----------------------------------------------------------------------
    always @(*) begin
        case (current_digit)
            //        CABC CCCD CECF CG     Segments ON
            4'd0: seg = 7'b0000_001;  // ABCDEF
            4'd1: seg = 7'b1001_111;  // BC
            4'd2: seg = 7'b0010_010;  // ABDEG
            4'd3: seg = 7'b0000_110;  // ABCDG
            4'd4: seg = 7'b1001_100;  // BCFG
            4'd5: seg = 7'b0100_100;  // ACDFG
            4'd6: seg = 7'b0100_000;  // ACDEFG
            4'd7: seg = 7'b0001_111;  // ABC
            4'd8: seg = 7'b0000_000;  // All segments
            4'd9: seg = 7'b0000_100;  // ABCDFG
            default: seg = 7'b1111_111; // All off (blank)
        endcase
    end

    // -----------------------------------------------------------------------
    // Anode decoder (active low)
    // Only one digit enabled at a time
    // -----------------------------------------------------------------------
    always @(*) begin
        case (digit_sel)
            3'd0: an = 8'b1111_1110;
            3'd1: an = 8'b1111_1101;
            3'd2: an = 8'b1111_1011;
            3'd3: an = 8'b1111_0111;
            3'd4: an = 8'b1110_1111;
            3'd5: an = 8'b1101_1111;
            3'd6: an = 8'b1011_1111;
            3'd7: an = 8'b0111_1111;
            default: an = 8'b1111_1111; // all off
        endcase
    end

endmodule
