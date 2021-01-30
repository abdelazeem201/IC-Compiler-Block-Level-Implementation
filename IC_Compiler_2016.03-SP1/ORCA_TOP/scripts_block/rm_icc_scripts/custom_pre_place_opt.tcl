# Protect the SDRAM muxes from being sized, and don't allow any cells
# to be inserted between the muxes and the output ports:
set_dont_touch [get_nets "sd_DQ_out[*] sd_CK*"]
set_dont_touch [get_cells "I_SDRAM_TOP/I_SDRAM_IF/sd_mux_*"]

# Enable the following for magnet placement and bounds:
if 1 {
	# Put the clocking logic into a bound, right next to the clock ports
	create_bounds -name bound_clk -coordinate {425.561 606.470 477.082 707.451} -type hard {I_CLOCKING snps_OCC_controller}

	# Use magnet placement to pull the SDRAM muxes right next to their ports
	magnet_placement -mark_fixed [get_ports "sd_DQ_out[*] sd_CK*"]
}

# The following command is being applied because there is a problem with the dynamic power characterization
# information in our libraries. Under certain circumstances, NEGATIVE dynamic "internal" power numbers are reported. 
# The command below is being used to override the library internal power data, to prevent negative power numbers:
set_cell_internal_power [get_pins -of_objects [get_flat_cells *_RAM*]] 1 uW
