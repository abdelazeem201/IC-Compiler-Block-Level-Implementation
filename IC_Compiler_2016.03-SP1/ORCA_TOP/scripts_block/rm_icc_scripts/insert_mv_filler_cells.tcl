##########################################################################################
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
##########################################################################################

puts "RM-Info: Running script [info script]\n"

  if {$FILLER_CELL_METAL != ""} {insert_stdcell_filler -cell_with_metal $FILLER_CELL_METAL -voltage_area DEFAULT_VA -connect_to_power $MW_POWER_NET -connect_to_ground $MW_GROUND_NET}
  if {$FILLER_CELL != ""} {insert_stdcell_filler -cell_without_metal $FILLER_CELL -voltage_area DEFAULT_VA -connect_to_power $MW_POWER_NET -connect_to_ground $MW_GROUND_NET}

  if {$PD1 != "" } {
     if {$FILLER_CELL_METAL != ""} {insert_stdcell_filler -cell_with_metal $FILLER_CELL_METAL -voltage_area $PD1 -connect_to_power $MW_POWER_NET1 -connect_to_ground $MW_GROUND_NET}
     if {$FILLER_CELL != ""} {insert_stdcell_filler -cell_without_metal $FILLER_CELL -voltage_area $PD1 -connect_to_power $MW_POWER_NET1 -connect_to_ground $MW_GROUND_NET}
  }
  if {$PD2 != "" } {
     if {$FILLER_CELL_METAL != ""} {insert_stdcell_filler -cell_with_metal $FILLER_CELL_METAL -voltage_area $PD2 -connect_to_power $MW_POWER_NET2 -connect_to_ground $MW_GROUND_NET}
     if {$FILLER_CELL != ""} {insert_stdcell_filler -cell_without_metal $FILLER_CELL -voltage_area $PD2 -connect_to_power $MW_POWER_NET2 -connect_to_ground $MW_GROUND_NET}
  }
  if {$PD3 != "" } {
     if {$FILLER_CELL_METAL != ""} {insert_stdcell_filler -cell_with_metal $FILLER_CELL_METAL -voltage_area $PD3 -connect_to_power $MW_POWER_NET3 -connect_to_ground $MW_GROUND_NET}
     if {$FILLER_CELL != ""} {insert_stdcell_filler -cell_without_metal $FILLER_CELL -voltage_area $PD3 -connect_to_power $MW_POWER_NET3 -connect_to_ground $MW_GROUND_NET}
  }
  if {$PD4 != "" } {
     if {$FILLER_CELL_METAL != ""} {insert_stdcell_filler -cell_with_metal $FILLER_CELL_METAL -voltage_area $PD4 -connect_to_power $MW_POWER_NET4 -connect_to_ground $MW_GROUND_NET}
     if {$FILLER_CELL != ""} {insert_stdcell_filler -cell_without_metal $FILLER_CELL -voltage_area $PD4 -connect_to_power $MW_POWER_NET4 -connect_to_ground $MW_GROUND_NET}
  }

puts "RM-Info: Completed script [info script]\n"
