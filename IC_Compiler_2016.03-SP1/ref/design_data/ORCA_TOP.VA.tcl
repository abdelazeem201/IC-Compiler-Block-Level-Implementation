set bbox [join [get_attribute [get_voltage_area DEFAULT_VA] bbox]]
set lly [lindex $bbox 1]
set urx [lindex $bbox 2]
create_voltage_area -coordinate [list [expr $urx - 420.28] $lly $urx [expr $lly + 180.576]] -power_domain PD_RISC_CORE \
	-cycle_color -guard_band_x 10 -guard_band_y 10

