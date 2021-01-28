suppress_message MWUI-031
suppress_message MWUI-032

foreach_in_collection tie_cell [get_lib_cells -quiet */TIE*_HVT] {
	set_attribute $tie_cell dont_use false
	set_attribute $tie_cell dont_touch false
	set_attribute [get_lib_pins -of_objects $tie_cell] max_fanout 10 -type float
}

# Allow CTS to resize clock gates
remove_attribute  [get_lib_cells -quiet */CGL*] dont_use
remove_attribute  [get_lib_cells -quiet */CGL*] dont_touch


set_dont_use [get_lib_cells -quiet */RSDFF*]
set_dont_use [get_lib_cells -quiet */AOINV*]
set_dont_use [get_lib_cells -quiet */AOBUF*]
set_dont_use [get_lib_cells -quiet */PMT*]
set_dont_use [get_lib_cells -quiet */NMT*]

remove_attribute [get_lib_cells -quiet */SRAM*] dont_use

unsuppress_message MWUI-031
unsuppress_message MWUI-032

