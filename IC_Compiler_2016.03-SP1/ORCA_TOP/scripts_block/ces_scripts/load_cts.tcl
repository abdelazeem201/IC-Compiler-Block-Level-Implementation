##########################################################################################
# CES IC Compiler 1 Workshop
# Copyright (C) 2007-2012 Synopsys, Inc. All rights reserved.
##########################################################################################

set TEV(num_cores) 1
set SEV(script_file) [info script]
set SEV(src) clock_opt_cts_icc
set SEV(dst) clock_opt_cts_icc

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 

open_mw_lib $MW_DESIGN_LIBRARY
open_mw_cel $SEV(dst)

link -f



## Optimization Common Session options - set in all sessions
source -echo common_optimization_settings_icc.tcl 
source -echo common_placement_settings_icc.tcl 

## Source CTS Options
source -echo common_cts_settings_icc.tcl
source -echo common_post_cts_timing_settings.tcl

