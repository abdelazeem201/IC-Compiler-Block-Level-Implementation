###################################################################################
# Synopsys(R) IC Compiler(TM) Reference Methodology 
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
###################################################################################

Features
========

*  Provides self-documenting reference methodology scripts for place and route 
   using IC Compiler

*  Provides the baseline flow from netlist to GDS out

*  Includes the IC Compiler Design Planning Reference Methodology, which allows 
   you to explore different floorplans

*  Includes parallel flows for multivoltage and multicorner-multimode

*  Includes the IC Compiler Hierarchical Reference Methodology

*  Includes design-for-test (DFT) and power optimization

*  Designed to work with the Synopsys Design Compiler(R) Reference Methodology 
   as the first step

*  Includes a Synopsys Formality(R) reference methodology script to perform 
   verification of the netlist read into the IC Compiler tool versus the Verilog 
   netlist created by the tool


Description
===========

The IC Compiler Reference Methodology provides a set of reference scripts that you 
can use as a recommended guideline for developing IC Compiler scripts. 

You can run the scripts "out of the box" to get a fully optimized and routed 
design right away. In addition to the baseline flow, which includes the 
IC Compiler Design Planning Reference Methodology and sign-off-driven optimization, 
the scripts also provide the following parallel flows: 

*  Feasibility flow
*  Concurrent clock and data optimization flow
*  Two-pass place_opt flow
*  IEEE 1801-based multivoltage flows: golden UPF and UPF-prime
   IEEE 1801 is also known as Unified Power Format (UPF).
*  Multicorner-multimode flow
*  Physical guidance flow
*  Flip-chip flow
*  Zroute flow
*  Design-for-test (DFT) scan chain reordering flow
*  Power optimization flow
*  Chip-finishing flow steps 
*  Signoff metal fill and signoff design rule checking (DRC) flows
*  Engineering change order (ECO) flow
*  Formality flow

The IC Compiler Reference Methodology can also include the Synopsys MVRC Static 
Verification Reference Methodology scripts and the Synopsys Verification
Compiler(TM) Low Power Static Signoff Reference Methodology scripts for static 
verification of multivoltage designs. These scripts are included only when you 
select TRUE for the Multivoltage or Multisupply option in RMgen.


Contents
========

The IC Compiler Reference Methodology includes the following files:

RMgen Option Settings
---------------------

*  ICC-RMsettings.txt        

   This file contains reference methodology option settings that were selected when 
   the scripts were generated.

README and Release Note Files
-----------------------------

*  README.ICC-RM.txt

   This file contains information and instructions for setting up and running the 
   IC Compiler Reference Methodology scripts.

*  Release_Notes.ICC-RM.txt

   This file contains release notes for the IC Compiler Reference Methodology 
   scripts listing the incremental changes in each new version of the scripts.

Setup Scripts
-------------

The setup scripts are located in the rm_setup directory.

*  common_setup.tcl

   This file contains common design setup variables for the reference 
   methodologies. 

*  icc_setup.tcl

   This file contains IC Compiler-specific design setup variables used by all 
   IC Compiler reference methodologies. 

Constraint and Optimization Scripts
-----------------------------------

*  rm_icc_scripts/init_design_icc.tcl 

   This script reads the logic design netlist and constraints, creates the 
   floorplan or reads the floorplan from a Design Exchange Format (DEF) file, 
   and generates a zero-interconnect timing report.

*  rm_icc_scripts/place_opt_icc.tcl

   This script runs placement and placement-based optimization.

*  rm_icc_scripts/clock_opt_cts_icc.tcl 

   This script runs clock tree synthesis and optimization.

*  rm_icc_zrt_scripts/clock_opt_psyn_icc.tcl

   This script runs post-clock-tree-synthesis optimization.

*  rm_icc_zrt_scripts/clock_opt_ccd_icc.tcl

   This script runs concurrent clock and data optimization.

*  rm_icc_zrt_scripts/clock_opt_route_icc.tcl

   This script routes the clocks with the specified nondefault routing rules.

*  rm_icc_zrt_scripts/route_icc.tcl

   This script runs routing with crosstalk delta delay enabled by default. 

*  rm_icc_zrt_scripts/route_opt_icc.tcl

   This script runs postroute optimization with crosstalk delta delay enabled by 
   default.

*  rm_icc_zrt_scripts/chipfinish_icc.tcl: 

   This script runs several chip finishing steps, such as timing-driven metal fill, 
   detail route wire spreading to reduce the critical area, and antenna fixing. 

*  rm_icc_zrt_scripts/outputs_icc.tcl

   This script creates several output files, such as Verilog, Design Exchange 
   Format (DEF), Standard Parasitic Exchange Format (SPEF), GDS, and others.

*  rm_icc_zrt_scripts/eco_icc.tcl

   This script runs the engineering change order (ECO) flow.

*  rm_icc_zrt_scripts/focal_opt_icc.tcl

   This script runs postroute optimization to fix setup, hold, or logic
   design rule checking (DRC) violations on the design by using focal_opt.

*  rm_icc_scripts/fm.tcl

   This script runs the Formality tool after the outputs_icc step has been 
   completed. To run this script, enter the following command:

   % fm_shell -f rm_icc_scripts/fm.tcl | tee logs_zrt/fm.log (or log/fm.log)	

Note: 
   If you select FALSE for the Zroute option in RMgen, all the scripts described 
   in this section are located in the rm_icc_scripts directory.

The flat and hierarchical floorplanning scripts are located in the 
rm_icc_dp_scripts directory. 

MVRC Static Verification Reference Methodology Files
----------------------------------------------------

*  README.MVRC-RM.txt

   This file contains information and instructions for setting up and running the 
   MVRC Static Verification Reference Methodology scripts.

*  Release_Notes.MVRC-RM.txt

   This file contains release notes for the MVRC Static Verification Reference 
   Methodology scripts listing the incremental changes in each new version of 
   the scripts.

*  rm_icc_scripts/mvrc.tcl

   This file contains the MVRC Static Verification Reference Methodology script 
   used to perform static verification of multivoltage designs for top-down 
   place and route or for block-level place and route in a hierarchical flow.

Verification Compiler Low Power Static Signoff Reference Methodology Files
--------------------------------------------------------------------------

*  README.VCLP-RM.txt
    
   This file contains information and instructions for setting up and running the 
   Verification Compiler Low Power Static Signoff Reference Methodology scripts.

*  Release_Notes.VCLP-RM.txt

   This file contains release notes for the Verification Compiler Low Power Static 
   Signoff Reference Methodology scripts. The release notes list the incremental 
   changes in each new version of the scripts.

*  rm_icc_scripts/vc_lp.tcl

   This file contains the Verification Compiler Low Power Static Signoff Reference 
   Methodology script used to perform static verification of multivoltage designs 
   for top-down place and route or for block-level place and route in a 
   hierarchical flow.


Usage
=====

For the standard reference methodology flow, use the following commands. 

*  To run the reference methodology scripts, enter the following command:

   % make -f rm_setup/Makefile_zrt ic

*  To run the ECO flow, enter the following command:

   % make -f rm_setup/Makefile_zrt eco

*  To run the focal_opt flow, enter the following command:

   % make -f rm_setup/Makefile_zrt focal_opt

Note: 
   This usage is based on Zroute. If you select FALSE for the Zroute option in RMgen,  
   replace Makefile_zrt with Makefile in the invocation commands. 

For the Lynx-compatible reference methodology flow, run the tool from the 
working directory, rm_icc/tmp. Make sure that the working directory exists 
before you run the tool.

  *  To run the reference methodology scripts, enter the following command:
  
     % mkdir -p rm_icc/tmp
     % cd rm_icc/tmp
     % make -f ../../scripts_block/rm_setup/Makefile_zrt ic
  
  *  To run the ECO flow, enter the following command:
  
     % mkdir -p rm_icc/tmp
     % cd rm_icc/tmp
     % make -f ../../scripts_block/rm_setup/Makefile_zrt eco
  
  *  To run the focal_opt flow, enter the following command:
  
     % mkdir -p rm_icc/tmp
     % cd rm_icc/tmp
     % make -f ../../scripts_block/rm_setup/Makefile_zrt focal_opt

Note: 
   This usage is based on Zroute. If you select FALSE for the Zroute option in 
   RMgen, replace Makefile_zrt with Makefile in the invocation commands.
