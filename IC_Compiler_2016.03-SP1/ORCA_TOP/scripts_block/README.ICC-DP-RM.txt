####################################################################################
# Synopsys(R) IC Compiler(TM) Design Planning Reference Methodology 
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
####################################################################################
 
A reference methodology provides a set of reference scripts that serve as a good 
starting point for running a tool. These scripts are not designed to run in their 
current form. You should use them as a reference and adapt them for use in your 
design environment.

The IC Compiler Design Planning Reference Methodology is focused primarily on the 
following tasks:

*  For feasibility analysis, it runs through the entire flow: design creation, 
   floorplan creation, virtual flat placement, power network synthesis and 
   analysis, in-place optimization, global routing, reporting, and writing out 
   the floorplan.

*  For floorplan exploration, it can run automatically through the same flow 
   multiple times, each time with different combinations of settings.
   
   The results are presented in an HTML table.

The IC Compiler Design Planning Reference Methodology consists of a set of 
ready-to-use scripts and makes the best use of the design planning features 
within the context of the flow.

*  The flat, straightforward structure includes setup files, makefiles, and scripts.

*  The scripts contain detailed comments for command sequence and usage.

The IC Compiler Design Planning Reference Methodology generates the following 
output:

*  Floorplanned CEL views and floorplan files that you can use to continue detailed 
   implementation with the IC Compiler Reference Methodology
 
*  Floorplan exploration results summarized in an HTML file that you can view by 
   using a Web browser


Files Included With the IC Compiler Design Planning Reference Methodology
=========================================================================

------------------------------------------------------------------------------------
File                            Description
------------------------------------------------------------------------------------

ICC-RMsettings.txt              Reference methodology option settings used to 
                                generate the scripts

README.ICC-DP-RM.txt            Information and instructions for setting up and 
                                running the IC Compiler Design Planning Reference 
                                Methodology

Release_Notes.ICC-DP-RM.txt     Release notes for the IC Compiler Design Planning 
                                Reference Methodology scripts listing the 
                                incremental changes in each new version of the 
                                scripts

rm_setup/Makefile and 
rm_setup/Makefile_zrt           Makefiles for both the IC Compiler Design Planning 
                                Reference Methodology and the IC Compiler Reference 
                                Methodology scripts

rm_setup/common_setup.tcl       Common design setup variables for the reference 
                                methodologies. 

rm_setup/icc_setup.tcl          IC Compiler-specific design setup variables used by 
                                all IC Compiler reference methodologies 

rm_icc_scripts/
init_design_icc.tcl             Script that reads the logic design netlist and 
                                constraints, and either creates the floorplan or 
                                reads the floorplan from a Design Exchange 
                                Format (DEF) file or a floorplan file

rm_icc_dp_scripts/flat_dp.tcl   Script that runs the flat design planning flow to 
                                show the routeability, timing, and voltage (IR) drop 
                                of the design

                                The two modes, baseline and explore, are controlled 
                                by the ICC_DP_EXPLORE_MODE variable in 
                                icc_setup.tcl:

                                o  Baseline mode runs through the flow and generates 
                                   one result. 

                                   Basically, this is like a template or set of 
                                   self-documented scripts. 

                                o  Explore mode performs multiple runs, generates 
                                   multiple results, and at the end generates an 
                                   HTML file that aggregates the results in a table. 

                                   Explore mode is configurable through 
                                   macro_placement_exploration_dp.tcl. 

                                Baseline mode sources 
                                rm_icc_dp_scripts/baseline.tcl.

                                Explore mode sources 
                                rm_icc_dp_scripts/macro_placement_exploration_dp.tcl.

rm_icc_dp_scripts/
macro_placement_exploration_dp.tcl	
                                Explore mode instructions that describe the 
                                combinations for each run

                                You can configure explore mode in this file, for 
                                example, by adding or removing runs or by changing 
                                the settings for a particular run. A procedure is 
                                called in the file to execute the instructions for 
                                each run. This procedure is defined in 
                                proc_explore.tcl.

Supportive Scripts
------------------

rm_icc_dp_scripts/
proc_explore.tcl                Script containing a procedure that is required to 
                                perform explore mode

rm_icc_dp_scripts/gen_explore_table.pl and
rm_icc_dp_scripts/gen_explore_table	
                                Scripts that parse the log file and the reports 
                                from explore mode runs and generate an HTML table

rm_setup/icc_scripts/
common_optimization_settings_icc.tcl	
                                Script containing common optimization settings
------------------------------------------------------------------------------------


Instructions for Using the IC Compiler Design Planning Reference Methodology
============================================================================

To run the IC Compiler Design Planning Reference Methodology scripts in baseline 
mode for a standard reference methodology flow,

1. Set ICC_DP_EXPLORE_MODE to false in rm_setup/icc_setup.tcl,

2. Enter

   % make -f rm_setup/Makefile dp

3. Check the logs/* and reports/* files.

To run the IC Compiler Design Planning Reference Methodology scripts in explore mode
for a standard reference methodology flow,

1. Enter 

   % make -f rm_setup/Makefile dp

2. Open ${DESIGN_NAME}_explore.html in your Web browser, using the design name you 
   specified in rm_setup/common_setup.tcl.

To run the IC Compiler Design Planning Reference Methodology scripts in baseline 
mode for a Lynx-compatible reference methodology flow,

1. Set ICC_DP_EXPLORE_MODE to false in rm_setup/icc_setup.tcl,
  
2. Enter

   % cd rm_icc/tmp
   % make -f ../../scripts_block/rm_setup/Makefile dp

3. Check the rm_icc/logs/* and rm_icc/rpts/* files.

To run the IC Compiler Design Planning Reference Methodology scripts in explore mode
for a Lynx-compatible reference methodology flow,

1. Enter 

   % cd rm_icc/tmp
   % make -f ../../scripts_block/rm_setup/Makefile dp

2. Open ${DESIGN_NAME}_explore.html in your Web browser, using the design name you 
   specified in scripts_block/rm_setup/common_setup.tcl.
