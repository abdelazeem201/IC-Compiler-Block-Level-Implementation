####################################################################################
# Synopsys(R) IC Compiler(TM) Hierarchical Reference Methodology 
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
####################################################################################

There are three stages in the IC Compiler Hierarchical Reference Methodology flow:

1. Hierarchical design planning based on the virtual flat flow

2. Block-level implementation

3. Top-level integration

Use the following instructions to run the IC Compiler Hierarchical Reference 
Methodology:

Step 1. Setup: 
Edit common_setup.tcl, icc_setup.tcl, and the makefiles in the rm_setup directory
---------------------------------------------------------------------------------

The common_setup.tcl file contains reference methodology library and technology 
variables that are common to all the product reference methodologies.

*  Make sure the path to your reference library and inputs are absolute paths.

   The reference methodology sets up subdirectories for your blocks and top-level 
   design. Absolute paths are required for the subdirectories to work.

*  You can use a variable named $DESIGN_REF_DATA_PATH to manage the 
   absolute paths to design data if they share a common root.

   For example:
   set DESIGN_REF_DATA_PATH 	"/user/design_data"
   set MW_REFERENCE_LIB_DIRS 	"$DESIGN_REF_DATA_PATH/lib/library"
   set TECH_FILE		"$DESIGN_REF_DATA_PATH/tech/techfile"	

The icc_setup.tcl file contains IC Compiler Hierarchical Reference Methodology 
specific variables. The most important variables are

ICC_DP_PLAN_GROUPS:       Provides the module instance names for the plan groups 
                          to be created (future physical blocks) 

                          The IC Compiler tool automatically uses this variable to 
                          create and arrange the locations for the plan groups.

ICC_DP_PLANGROUP_FILE:    Specifies the plan group dump file if you want to skip the 
                          automatic creation of plan groups

                          This file should be generated from your existing floorplan 
                          by the write_floorplan command.

If you do not provide information about which modules to use for block creation, 
the IC Compiler tool does not have sufficient information and the hierarchical flow 
does not work.

The makefiles run the scripts. Edit ICC_EXEC in the makefiles. 


Step 2. Hierarchical design planning: 
Run Makefile_hier from the working directory: 
make -f rm_setup/Makefile_hier hier_dp &
----------------------------------------

This makefile performs hierarchical partitioning all the way from reading netlist 
to commit. At the end, it prepares the block and top subdirectories.

*  When the makefile finishes, it prepares subdirectories for your blocks and 
   top-level design.

   These preparations include 

   o  Creating subdirectories, copying scripts and other necessary files, moving 
      libraries, and setting up icc_setup.tcl and common_setup.tcl.

   o  Creating preliminary block abstractions, creating the FRAM view for 
      each block (before detailed block-level implementation), and linking them to 
      the top-level design.

      This allows an early timing check of the top-level CEL view.
      
      Note:
         You should always finish block-level implementation to get accurate block 
         abstractions and FRAM views.

*  Now you should see subdirectories for all your blocks and the top-level design.
  
   Proceed to each block for detailed implementation.

*  See the "Using RMgen and Reference Methodology Scripts
   Application Note" for more details on the flow and data structure.


Step 3. Block-Level implementation: 
Run Makefile from each of the block directories: make -f rm_setup/Makefile_zrt ic &
-----------------------------------------------------------------------------------

This makefile runs the IC Compiler Reference Methodology for block-level 
implementation. At the end, it generates the block abstraction and 
the FRAM view for the block.

*  When you have completed block-level implementation for all the blocks, 
   you can move on to top-level integration.

Note:
   If you selected FALSE for the Zroute option in RMgen,
   replace Makefile_zrt with Makefile in the invocation command.


Step 4. Top-level integration: 
Run Makefile from the top directory: make -f rm_setup/Makefile_zrt ic &
-----------------------------------------------------------------------

*  This makefile runs the IC Compiler Reference Methodology for top-level 
   integration.

*  The makefile is already set up to reference the block libraries for block 
   abstractions and the FRAM view (initial or after detailed block 
   implementation).

   Typically, you run this step after completing step 3. However, you can run this 
   step after step 2 if you want to perform some early checks.  

Note:
   If you selected FALSE for the Zroute option in RMgen, replace Makefile_zrt with 
   Makefile in the invocation command.


Note for the Lynx-Compatible Reference Methodology Flow
-------------------------------------------------------
When using the standalone Lynx-compatible IC Compiler Hierarchical Reference 
Methodology flow, you must set up the top and block directories parallel to the 
current working directory, where you run hierarchical design planning. Name the 
block directory with the module master name of the desired block partition. Name 
the top directory with the top-level design name.

For more information about how to set up your current working directory, see the 
"Using the Reference Methodology Scripts Within Lynx" section in 
README.LynxCompatible-RM_Start.txt.


