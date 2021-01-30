set_clock_tree_exceptions -stop_pins [get_pins "I_SDRAM_TOP/I_SDRAM_IF/sd_mux_*/S0"]
set_clock_tree_exceptions -dont_size_cells [get_cells "I_SDRAM_TOP/I_SDRAM_IF/sd_mux_*"]
set_clock_tree_exceptions -dont_size_cells [get_cells "I_CLOCKING/I_CLK_SOURCE*"]
set_clock_tree_exceptions -dont_size_cells [get_cells "I_CLOCKING/sys_clk_in_reg"]

