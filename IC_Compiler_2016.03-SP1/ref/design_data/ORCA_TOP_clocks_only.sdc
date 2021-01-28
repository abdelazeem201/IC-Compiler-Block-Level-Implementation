###################################################################

# Created by write_sdc for scenario [leak] on Mon Mar 25 10:27:39 2013

###################################################################
set sdc_version 2.0

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
create_clock [get_ports pclk]  -name PCI_CLK  -period 7.5  -waveform {0 3.75}
create_clock -name v_PCI_CLK  -period 7.5  -waveform {0 3.75}
set_clock_latency 0.5 [get_clocks v_PCI_CLK]
create_clock [get_ports sys_2x_clk]  -name SYS_2x_CLK  -period 2.4  -waveform {0 1.2}
create_generated_clock [get_pins I_CLOCKING/sys_clk_in_reg/Q]  -name SYS_CLK  -source [get_ports sys_2x_clk]  -divide_by 2
create_clock [get_ports sdram_clk]  -name SDRAM_CLK  -period 4.1  -waveform {0 2.05}
create_clock -name v_SDRAM_CLK  -period 4.1  -waveform {0 2.05}
create_generated_clock [get_ports sd_CK] -name SD_DDR_CLK -source [get_ports sdram_clk] -combinational
create_generated_clock [get_ports sd_CKn] -name SD_DDR_CLKn -source [get_ports sdram_clk] -invert -combinational
set_clock_groups -asynchronous  -name func_async  -group [list [get_clocks SYS_2x_CLK] [get_clocks SYS_CLK]]  -group [list      \
[get_clocks PCI_CLK] [get_clocks v_PCI_CLK]]  -group [list [get_clocks         \
SDRAM_CLK] [get_clocks v_SDRAM_CLK] [get_clocks SD_DDR_CLK] [get_clocks        \
SD_DDR_CLKn]]

