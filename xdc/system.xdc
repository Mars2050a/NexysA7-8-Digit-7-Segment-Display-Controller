# =============================================================================
# Constraint file for Nexys A7-100T
# Project: 8-Digit 7-Segment Display Control via UART
# Board:    Digilent Nexys A7-100T
#
# Pin assignments:
#   CLK100MHZ   - 100 MHz system clock (pin E3)
#   CPU_RESETN  - CPU reset button, active low (pin C12)
#   UART_TXD_IN - UART receive from USB-UART bridge (pin C4)
#   UART_RXD_OUT - UART transmit to USB-UART bridge (pin D4)
#   seg[6:0]    - 7-segment segment lines {CA,CB,CC,CD,CE,CF,CG}
#   an[7:0]     - 7-segment anode lines (active low)
#   dp          - Decimal point (active low)
# =============================================================================

# ---------------------------------------------------------------------------
# System Clock: 100 MHz, period = 10.0 ns
# ---------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {CLK100MHZ}];

# ---------------------------------------------------------------------------
# CPU Reset Button (active low)
# ---------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { CPU_RESETN }];

# ---------------------------------------------------------------------------
# USB-UART Bridge (FTDI FT2232HQ)
# UART_TXD_IN: FTDI -> FPGA (FPGA receives data on this pin)
# UART_RXD_OUT: FPGA -> FTDI (FPGA transmits data on this pin, unused)
# ---------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { UART_TXD_IN }];
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { UART_RXD_OUT }];

# ---------------------------------------------------------------------------
# 7-Segment Display - Segment Lines (common anode, active low)
# seg = {CA, CB, CC, CD, CE, CF, CG} where CA = seg[6], CG = seg[0]
# ---------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { seg[6] }];  # CA
set_property -dict { PACKAGE_PIN R10   IOSTANDARD LVCMOS33 } [get_ports { seg[5] }];  # CB
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { seg[4] }];  # CC
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { seg[3] }];  # CD
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { seg[2] }];  # CE
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { seg[1] }];  # CF
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { seg[0] }];  # CG

# ---------------------------------------------------------------------------
# 7-Segment Display - Decimal Point (active low, tied to 1 in design)
# ---------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { dp }];

# ---------------------------------------------------------------------------
# 7-Segment Display - Anode Lines (common anode, active low)
# an[7] = leftmost digit, an[0] = rightmost digit
# ---------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { an[0] }];
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { an[1] }];
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { an[2] }];
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { an[3] }];
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { an[4] }];
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { an[5] }];
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { an[6] }];
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports { an[7] }];
