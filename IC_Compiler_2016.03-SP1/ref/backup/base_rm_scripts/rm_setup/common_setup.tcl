puts "RM-Info: Running script [info script]\n"

##########################################################################################
# Variables common to all reference methodology scripts
# Script: common_setup.tcl
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
##########################################################################################

set DESIGN_NAME                   "ORCA_TOP"  ;#  The name of the top-level design

# 
set WORKSHOP_REF_PATH             "../../../ref"
set ICC_INPUTS_PATH               "${WORKSHOP_REF_PATH}/design_data"
set LIBRARY_TOP_PATH              "${WORKSHOP_REF_PATH}/SAED32_2012-12-25"

set DESIGN_REF_PATH               "${LIBRARY_TOP_PATH}/lib"
set DESIGN_REF_TECH_PATH          "${LIBRARY_TOP_PATH}/tech"

#set DESIGN_REF_DATA_PATH          ""  ;#  Absolute path prefix variable for library/design data.
                                       #  Use this variable to prefix the common absolute path  
                                       #  to the common variables defined below.
                                       #  Absolute paths are mandatory for hierarchical 
                                       #  reference methodology flow.

##########################################################################################
# Hierarchical Flow Design Variables
##########################################################################################

set HIERARCHICAL_DESIGNS           "" ;# List of hierarchical block design names "DesignA DesignB" ...
set HIERARCHICAL_CELLS             "" ;# List of hierarchical block cell instance names "u_DesignA u_DesignB" ...

##########################################################################################
# Library Setup Variables
##########################################################################################

# For the following variables, use a blank space to separate multiple entries.
# Example: set TARGET_LIBRARY_FILES "lib1.db lib2.db lib3.db"

set ADDITIONAL_SEARCH_PATH        [join "
	${DESIGN_REF_PATH}/stdcell_lvt/db_nldm
	${DESIGN_REF_PATH}/stdcell_hvt/db_nldm
	${DESIGN_REF_PATH}/sram_lp/db_nldm
	${ICC_INPUTS_PATH}
	"]

set TARGET_LIBRARY_FILES     [join "
	saed32lvt_ss0p75vn40c.db
	saed32lvt_ss0p95vn40c.db
	saed32lvt_ulvl_ss0p95vn40c_i0p75v.db
	saed32lvt_dlvl_ss0p75vn40c_i0p95v.db
	saed32hvt_ss0p75vn40c.db
	saed32hvt_ss0p95vn40c.db
	saed32hvt_ulvl_ss0p95vn40c_i0p75v.db
	saed32hvt_dlvl_ss0p75vn40c_i0p95v.db

		saed32lvt_ff0p95vn40c.db
		saed32lvt_ff1p16vn40c.db
		saed32lvt_ulvl_ff1p16vn40c_i0p95v.db
		saed32lvt_dlvl_ff0p95vn40c_i1p16v.db
		saed32hvt_ff0p95vn40c.db
		saed32hvt_ff1p16vn40c.db
		saed32hvt_ulvl_ff1p16vn40c_i0p95v.db
		saed32hvt_dlvl_ff0p95vn40c_i1p16v.db

			saed32lvt_ff0p95v125c.db
			saed32lvt_ff1p16v125c.db
			saed32lvt_ulvl_ff1p16v125c_i0p95v.db
			saed32lvt_dlvl_ff0p95v125c_i1p16v.db
			saed32hvt_ff0p95v125c.db
			saed32hvt_ff1p16v125c.db
			saed32hvt_ulvl_ff1p16v125c_i0p95v.db
			saed32hvt_dlvl_ff0p95v125c_i1p16v.db

	saed32lvt_ss0p75v125c.db
	saed32lvt_ss0p95v125c.db
	saed32lvt_ulvl_ss0p95v125c_i0p75v.db
	saed32lvt_dlvl_ss0p75v125c_i0p95v.db
	saed32hvt_ss0p75v125c.db
	saed32hvt_ss0p95v125c.db
	saed32hvt_ulvl_ss0p95v125c_i0p75v.db
	saed32hvt_dlvl_ss0p75v125c_i0p95v.db

	"]

set ADDITIONAL_LINK_LIB_FILES     [join "
	saed32sramlp_ss0p75vn40c_i0p75v.db
	saed32sramlp_ss0p95vn40c_i0p95v.db
		saed32sramlp_ff0p95vn40c_i0p95v.db
		saed32sramlp_ff1p16vn40c_i1p16v.db
			saed32sramlp_ff0p95v125c_i0p95v.db
			saed32sramlp_ff1p16v125c_i1p16v.db
	saed32sramlp_ss0p75v125c_i0p75v.db
	saed32sramlp_ss0p95v125c_i0p95v.db
"]

set MIN_LIBRARY_FILES             ""  ;#  List of max min library pairs "max1 min1 max2 min2 max3 min3"...

set MW_REFERENCE_LIB_DIRS         [join "
	${DESIGN_REF_PATH}/stdcell_lvt/milkyway/saed32nm_lvt_1p9m
	${DESIGN_REF_PATH}/stdcell_hvt/milkyway/saed32nm_hvt_1p9m
	${DESIGN_REF_PATH}/sram_lp/milkyway/saed32sram_lp
	"]

set MW_REFERENCE_CONTROL_FILE     ""  ;#  Reference Control file to define the Milkyway reference libs

set TECH_FILE                     "${DESIGN_REF_TECH_PATH}/milkyway/saed32nm_1p9m_mw.tf"  ;#  Milkyway technology file
set MAP_FILE                      "${DESIGN_REF_TECH_PATH}/star_rc/saed32nm_tf_itf_tluplus.map"  ;#  Mapping file for TLUplus
set TLUPLUS_MAX_FILE              "${DESIGN_REF_TECH_PATH}/star_rc/saed32nm_1p9m_Cmax.tluplus"  ;#  Max TLUplus file
set TLUPLUS_MIN_FILE              "${DESIGN_REF_TECH_PATH}/star_rc/saed32nm_1p9m_Cmin.tluplus"  ;#  Min TLUplus file


set MW_POWER_NET                "VDD" ;#
set MW_POWER_PORT               "VDD" ;#
set MW_GROUND_NET               "VSS" ;#
set MW_GROUND_PORT              "VSS" ;#

set MIN_ROUTING_LAYER            "M1"   ;# Min routing layer
set MAX_ROUTING_LAYER            "M5"   ;# Max routing layer

set LIBRARY_DONT_USE_FILE        "saed32_dont_use.tcl"   ;# Tcl file with library modifications for dont_use


##########################################################################################
# Multivoltage Common Variables
#
# Define the following multivoltage common variables for the reference methodology scripts 
# for multivoltage flows. 
# Use as few or as many of the following definitions as needed by your design.
##########################################################################################

set PD1                          ""           ;# Name of power domain/voltage area  1
set VA1_COORDINATES              {}           ;# Coordinates for voltage area 1
set MW_POWER_NET1                "VDD1"       ;# Power net for voltage area 1

set PD2                          ""           ;# Name of power domain/voltage area  2
set VA2_COORDINATES              {}           ;# Coordinates for voltage area 2
set MW_POWER_NET2                "VDD2"       ;# Power net for voltage area 2

set PD3                          ""           ;# Name of power domain/voltage area  3
set VA3_COORDINATES              {}           ;# Coordinates for voltage area 3
set MW_POWER_NET3                "VDD3"       ;# Power net for voltage area 3

set PD4                          ""           ;# Name of power domain/voltage area  4
set VA4_COORDINATES              {}           ;# Coordinates for voltage area 4
set MW_POWER_NET4                "VDD4"       ;# Power net for voltage area 4

puts "RM-Info: Completed script [info script]\n"

