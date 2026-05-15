##############################################################################
# Constraints File: rv32i_top_p10_zybo_z7_10.xdc
# Target Board   : Digilent Zybo Z7-10  (xc7z010clg400-1)
# Top Module     : rv32i_top_p10
#
# IMPORTANT NOTES for Zybo Z7-10:
#   - PMOD JB is connected to PS MIO pins — cannot be used as PL GPIO
#   - PMOD JA, JC, JD are PL I/O (Bank 35 / Bank 34 — all 3.3V on this board)
#   - Only 4 LEDs + 24 PMOD pins available; alu_out[31:24] mapped via ILA
#
# Port Mapping Summary:
#   clk            -> K17  (125 MHz on-board clock)
#   rst            -> K18  (BTN0, active-HIGH)
#   alu_out[3:0]   -> LD0-LD3  (on-board LEDs)
#   alu_out[11:4]  -> PMOD JA  (Bank 35, LVCMOS33)
#   alu_out[19:12] -> PMOD JC  (Bank 35, LVCMOS33)
#   alu_out[23:20] -> PMOD JD pins 1-4
#   pc_out[3:0]    -> PMOD JD pins 7-10
#   alu_out[31:24] -> Use Xilinx ILA IP for visibility (no pins left)
#   pc_out[31:4]   -> Use Xilinx ILA IP for visibility
##############################################################################


##############################################################################
# CLOCK – 125 MHz on-board clock  (Bank 35, LVCMOS33)
##############################################################################
set_property -dict { PACKAGE_PIN K17  IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 8.000 -waveform {0 4} [get_ports clk]


##############################################################################
# RESET – BTN0  (Bank 35, LVCMOS33, active-HIGH)
##############################################################################
set_property -dict { PACKAGE_PIN K18  IOSTANDARD LVCMOS33 } [get_ports rst]


##############################################################################
# LEDs LD0–LD3  (Bank 35, LVCMOS33) — alu_out[3:0]
##############################################################################
set_property -dict { PACKAGE_PIN M14  IOSTANDARD LVCMOS33 } [get_ports {alu_out[0]}]
set_property -dict { PACKAGE_PIN M15  IOSTANDARD LVCMOS33 } [get_ports {alu_out[1]}]
set_property -dict { PACKAGE_PIN G14  IOSTANDARD LVCMOS33 } [get_ports {alu_out[2]}]
set_property -dict { PACKAGE_PIN D18  IOSTANDARD LVCMOS33 } [get_ports {alu_out[3]}]


##############################################################################
# PMOD JA  (Bank 35, LVCMOS33) — alu_out[11:4]
# Header J2: top row = JA1..JA4, bottom row = JA7..JA10
##############################################################################
set_property -dict { PACKAGE_PIN N15  IOSTANDARD LVCMOS33 } [get_ports {alu_out[4]}]
set_property -dict { PACKAGE_PIN L14  IOSTANDARD LVCMOS33 } [get_ports {alu_out[5]}]
set_property -dict { PACKAGE_PIN K16  IOSTANDARD LVCMOS33 } [get_ports {alu_out[6]}]
set_property -dict { PACKAGE_PIN K14  IOSTANDARD LVCMOS33 } [get_ports {alu_out[7]}]
set_property -dict { PACKAGE_PIN N16  IOSTANDARD LVCMOS33 } [get_ports {alu_out[8]}]
set_property -dict { PACKAGE_PIN L15  IOSTANDARD LVCMOS33 } [get_ports {alu_out[9]}]
set_property -dict { PACKAGE_PIN J16  IOSTANDARD LVCMOS33 } [get_ports {alu_out[10]}]
set_property -dict { PACKAGE_PIN J14  IOSTANDARD LVCMOS33 } [get_ports {alu_out[11]}]


##############################################################################
# PMOD JC  (Bank 35, LVCMOS33) — alu_out[19:12]
# Header J4: JC1=V15, JC2=W15, JC3=T11, JC4=T10, JC7=W14, JC8=Y14, JC9=T12, JC10=U12
##############################################################################
set_property -dict { PACKAGE_PIN V15  IOSTANDARD LVCMOS33 } [get_ports {alu_out[12]}]
set_property -dict { PACKAGE_PIN W15  IOSTANDARD LVCMOS33 } [get_ports {alu_out[13]}]
set_property -dict { PACKAGE_PIN T11  IOSTANDARD LVCMOS33 } [get_ports {alu_out[14]}]
set_property -dict { PACKAGE_PIN T10  IOSTANDARD LVCMOS33 } [get_ports {alu_out[15]}]
set_property -dict { PACKAGE_PIN W14  IOSTANDARD LVCMOS33 } [get_ports {alu_out[16]}]
set_property -dict { PACKAGE_PIN Y14  IOSTANDARD LVCMOS33 } [get_ports {alu_out[17]}]
set_property -dict { PACKAGE_PIN T12  IOSTANDARD LVCMOS33 } [get_ports {alu_out[18]}]
set_property -dict { PACKAGE_PIN U12  IOSTANDARD LVCMOS33 } [get_ports {alu_out[19]}]


##############################################################################
# PMOD JD top row (pins 1-4) — alu_out[23:20]
# JD1=V12, JD2=W13, JD3=T14, JD4=T15
##############################################################################
set_property -dict { PACKAGE_PIN V12  IOSTANDARD LVCMOS33 } [get_ports {alu_out[20]}]
set_property -dict { PACKAGE_PIN W13  IOSTANDARD LVCMOS33 } [get_ports {alu_out[21]}]
set_property -dict { PACKAGE_PIN T14  IOSTANDARD LVCMOS33 } [get_ports {alu_out[22]}]
set_property -dict { PACKAGE_PIN T15  IOSTANDARD LVCMOS33 } [get_ports {alu_out[23]}]

# alu_out[31:24] — connect via Xilinx ILA IP core in Vivado for full visibility


##############################################################################
# PMOD JD bottom row (pins 7-10) — pc_out[3:0]
# JD7=V13, JD8=U13, JD9=U14, JD10=T13
##############################################################################
set_property -dict { PACKAGE_PIN V13  IOSTANDARD LVCMOS33 } [get_ports {pc_out[0]}]
set_property -dict { PACKAGE_PIN U13  IOSTANDARD LVCMOS33 } [get_ports {pc_out[1]}]
set_property -dict { PACKAGE_PIN U14  IOSTANDARD LVCMOS33 } [get_ports {pc_out[2]}]
set_property -dict { PACKAGE_PIN T13  IOSTANDARD LVCMOS33 } [get_ports {pc_out[3]}]

# pc_out[31:4] — connect via Xilinx ILA IP core in Vivado for full visibility


##############################################################################
# Timing — relax I/O paths (LEDs and PMOD are not timing-critical)
##############################################################################
set_false_path -from [get_ports rst]
set_false_path -to   [get_ports {alu_out[*]}]
set_false_path -to   [get_ports {pc_out[*]}]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
