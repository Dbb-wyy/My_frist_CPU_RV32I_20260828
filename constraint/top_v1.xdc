set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN V4 [get_ports clk]
create_clock -period 20.000 -name sys_clk [get_ports clk]

set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property DRIVE 12 [get_ports uart_tx]
set_property PACKAGE_PIN W21 [get_ports uart_tx]

set_property PACKAGE_PIN U7 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

set_property PULLTYPE PULLUP [get_ports rst_n]
set_property PULLTYPE PULLUP [get_ports uart_tx]
