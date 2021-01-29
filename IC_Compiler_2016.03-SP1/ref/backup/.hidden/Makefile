##ICC RM Makefile
##See README.* file for RM details


ICC_EXEC = icc_shell -64bit
LOGS_DIR     = ../logs
REPORTS_DIR = ../rpts
RESULTS_DIR = ../work
PNA_OUTPUT_DIR = ../work/pna_output

####Source Options
OPTIONS = 



##Optional: Specify design library if you want backup step and clean step to use it
##CAUTION: if added, the clean step will delete it
DESIGN_LIB = 


##########################################################################################################################
# Flat floorplanning script execution section
# Execute "make dp" to run ICC Design Planning RM based on your common_setup.tcl, icc_setup.tcl
##########################################################################################################################


init_design_icc: 
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/init_design_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_scripts/init_design_icc.tcl | tee -i $(LOGS_DIR)/init_design_icc/init_design_icc.log
	date > init_design_icc

flat_dp: init_design_icc
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/flat_dp
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_dp_scripts/flat_dp.tcl | tee -i $(LOGS_DIR)/flat_dp/flat_dp.log
	date > flat_dp

dp: flat_dp 
	date > dp


################################################################################################################
# ICC RM : netlist2gds script exection section
# Execute "make ic" to run IC Compiler based on your common_setup.tcl & icc_setup.tcl files
# If make dp has been run before, please pick one of the 8 created floorplans and fill that one in the 
# variable ICC_FLOORPLAN_CEL in the icc_setup.tcl file
################################################################################################################


place_opt_icc: init_design_icc
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/place_opt_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_scripts/place_opt_icc.tcl |tee -i $(LOGS_DIR)/place_opt_icc/place_opt_icc.log
	date > place_opt_icc

clock_opt_cts_icc: place_opt_icc
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/clock_opt_cts_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_scripts/clock_opt_cts_icc.tcl |tee -i $(LOGS_DIR)/clock_opt_cts_icc/clock_opt_cts_icc.log
	date > clock_opt_cts_icc

clock_opt_psyn_icc: clock_opt_cts_icc
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/clock_opt_psyn_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_zrt_scripts/clock_opt_psyn_icc.tcl |tee -i $(LOGS_DIR)/clock_opt_psyn_icc/clock_opt_psyn_icc.log
	date > clock_opt_psyn_icc

clock_opt_route_icc: clock_opt_psyn_icc
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/clock_opt_route_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_zrt_scripts/clock_opt_route_icc.tcl |tee -i $(LOGS_DIR)/clock_opt_route_icc/clock_opt_route_icc.log
	date > clock_opt_route_icc

route_icc: clock_opt_route_icc
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/route_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_zrt_scripts/route_icc.tcl |tee -i $(LOGS_DIR)/route_icc/route_icc.log
	date > route_icc

route_opt_icc: route_icc
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/route_opt_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_zrt_scripts/route_opt_icc.tcl |tee -i $(LOGS_DIR)/route_opt_icc/route_opt_icc.log
	date > route_opt_icc

chip_finish_icc: route_opt_icc
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/chip_finish_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_zrt_scripts/chip_finish_icc.tcl |tee -i $(LOGS_DIR)/chip_finish_icc/chip_finish_icc.log
	date > chip_finish_icc

metal_fill_icc: chip_finish_icc
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/metal_fill_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_zrt_scripts/metal_fill_icc.tcl |tee -i $(LOGS_DIR)/metal_fill_icc/metal_fill_icc.log
	date > metal_fill_icc

signoff_drc_icc: metal_fill_icc
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/signoff_drc_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_zrt_scripts/signoff_drc_icc.tcl |tee -i $(LOGS_DIR)/signoff_drc_icc/signoff_drc_icc.log
	date > signoff_drc_icc

outputs_icc: signoff_drc_icc
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/outputs_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_zrt_scripts/outputs_icc.tcl |tee -i $(LOGS_DIR)/outputs_icc/outputs_icc.log
	date > outputs_icc

ic: outputs_icc
	date > ic

################################################################################################################
# ICC RM : Eco flow
################################################################################################################
eco_icc: 
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/eco_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_zrt_scripts/eco_icc.tcl |tee -i $(LOGS_DIR)/eco_icc/eco_icc.log
	date > eco_icc

eco: eco_icc
	date > eco

################################################################################################################
# ICC RM : Focal_opt flow
################################################################################################################
focal_opt_icc:
	mkdir -p $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR)/focal_opt_icc
	$(ICC_EXEC) $(OPTIONS) -f ../../scripts_block/rm_icc_zrt_scripts/focal_opt_icc.tcl |tee -i $(LOGS_DIR)/focal_opt_icc/focal_opt_icc.log
	date > focal_opt_icc

focal_opt: focal_opt_icc
	date > focal_opt


#############################################################################################################################
# Utilities Section
#
#############################################################################################################################


##Backup
BACKUP  = BACKUP.`date "+%m_%d_%H_%M"`
backup:
	rm -rf $(BACKUP)
	mkdir -p $(BACKUP)
	cp -rf ../../scripts_block/rm_icc_scripts ../../scripts_block/rm_icc_zrt_scripts ../../scripts_block/rm_icc_dp_scripts ../../scripts_block/rm_setup $(DESIGN_LIB) $(REPORTS_DIR) $(RESULTS_DIR) $(LOGS_DIR) $(PNA_OUTPUT_DIR) $(BACKUP)


##Clean

clean_all:
	rm  -f init_design_icc flat_dp dp init_design_icc_dp place_opt_icc clock_opt_cts_icc clock_opt_psyn_icc clock_opt_route_icc route_icc route_opt_icc chip_finish_icc metal_fill_icc signoff_drc_icc outputs_icc ic
	rm -rf $(DESIGN_LIB) $(LOGS_DIR)/* $(RESULTS_DIR)/*sbpf* legalizer_debug_plots *.tf_checker $(RESULTS_DIR)/*.def $(RESULTS_DIR)/*pg*  $(REPORTS_DIR)/place* $(REPORTS_DIR)/clock* $(REPORTS_DIR)/route* $(REPORTS_DIR)/sign* $(REPORTS_DIR)/chip*  *_map\.* \
               net.acts *.attr .zr* Milkyway.cmd.*_*_*_* Milkyway.log.*_*_*_* \.vers* port_mapping.* pna_output icc_shell.cmd.* icc_shell.log.* cpd_pre_* \
               filenames_*.log icc_output.txt net.gcts split.gcts buffer.gcts output_heatmap check_scenarios_* *.LOG *.log
	##ICC_RM-Info: "make clean" does not remove the design library unless you have specified it with the DESIGN_LIB variable in Makefile"

clean: clean_all



###############################################################
# CES IC Compiler 1 workshop - lab support targets
# Everything below this is not part of the LCRM scripts
###############################################################


CES_SCRIPTS = ../../scripts_block/ces_scripts
setup load load_init load_placed load_cts load_psyn load_clock_route load_route load_route_opt load_dfm:
	$(ICC_EXEC) $(OPTIONS) -f $(CES_SCRIPTS)/$@.tcl 

DIFF = diff -wB
LABBACKUP = ../../../ref/backup
SCRIPTS_BLOCK = ../../scripts_block

.PHONY : clean_current_lab clean_all restore_base_rm

# @find -maxdepth 1 | grep -v "Makefile\|snapshot\|\.$$" | xargs rm -rf

clean_current_lab:
	@echo "Cleaning current lab..."
	@find -maxdepth 1 -name . -o -name Makefile -o -name snapshot -prune -o -exec rm -rf {} \;
	@rm -rf ../work ../logs ../rpts
	@mkdir ../work ../logs ../rpts
	@ln -s ../../scripts_block/rm_setup
	@ln -s ../../scripts_block/rm_icc_scripts
	@ln -s ../../scripts_block/rm_icc_zrt_scripts

restore_base_rm:
	@echo "Restoring scripts_block to defaults..."
	@tar xzf $(LABBACKUP)/base_rm_scripts/rm_setup.tgz -C $(SCRIPTS_BLOCK)
	@tar xzf $(LABBACKUP)/base_rm_scripts/rm_icc_scripts.tgz -C $(SCRIPTS_BLOCK)
	@tar xzf $(LABBACKUP)/base_rm_scripts/rm_icc_zrt_scripts.tgz -C $(SCRIPTS_BLOCK)
	@tar xzf $(LABBACKUP)/base_rm_scripts/rm_icc_dp_scripts.tgz -C $(SCRIPTS_BLOCK)
	

restore_lab0: clean_current_lab restore_base_rm
	@echo "Restoring clean setup for lab 0..."
	@tar xzf $(LABBACKUP)/lab0_gui/initial/rm_icc/work/ORCA_TOP_LIB.tgz -C ../work
	@cp $(LABBACKUP)/lab0_gui/initial/rm_icc/tmp/.synopsys_dc.setup .
	@touch .lab0_restored


restore_lab1: clean_current_lab restore_base_rm
	@echo "Restoring clean setup for lab 1..."
	@cp $(LABBACKUP)/lab1_init_design/initial/scripts_block/rm_setup/common_setup.tcl $(SCRIPTS_BLOCK)/rm_setup
	@cp $(LABBACKUP)/lab1_init_design/initial/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup
	@cp $(LABBACKUP)/lab1_init_design/initial/scripts_block/rm_icc_scripts/init_design_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@cp $(LABBACKUP)/lab1_init_design/initial/scripts_block/rm_icc_scripts/mcmm.scenarios.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@touch .lab1_restored

final_lab1:
	@echo "Creating final setup for lab 1..."
	cp $(LABBACKUP)/lab1_init_design/final/scripts_block/rm_setup/common_setup.tcl $(SCRIPTS_BLOCK)/rm_setup
	cp $(LABBACKUP)/lab1_init_design/final/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup
	cp $(LABBACKUP)/lab1_init_design/final/scripts_block/rm_icc_scripts/init_design_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	cp $(LABBACKUP)/lab1_init_design/final/scripts_block/rm_icc_scripts/common_optimization_settings_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	cp $(LABBACKUP)/lab1_init_design/final/scripts_block/rm_icc_scripts/mcmm.scenarios.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts

diff_lab1:
	@echo "Comparing against final setup for lab 1..."
	-$(DIFF) $(LABBACKUP)/lab1_init_design/final/scripts_block/rm_setup/common_setup.tcl $(SCRIPTS_BLOCK)/rm_setup || true
	-$(DIFF) $(LABBACKUP)/lab1_init_design/final/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup || true
	-$(DIFF) $(LABBACKUP)/lab1_init_design/final/scripts_block/rm_icc_scripts/init_design_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts || true
	-$(DIFF) $(LABBACKUP)/lab1_init_design/final/scripts_block/rm_icc_scripts/common_optimization_settings_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts || true
	-$(DIFF) $(LABBACKUP)/lab1_init_design/final/scripts_block/rm_icc_scripts/mcmm.scenarios.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts || true


restore_lab2: clean_current_lab restore_base_rm
	@echo "Restoring clean setup for lab 2..."
	@tar xzf $(LABBACKUP)/lab2_dp/initial/rm_icc/work/ORCA_TOP_LIB.tgz -C ../work
	@cp $(LABBACKUP)/lab2_dp/initial/rm_icc/tmp/macro_constraints.tcl .
	@cp $(LABBACKUP)/lab2_dp/initial/rm_icc/tmp/macros.def .
	@cp $(LABBACKUP)/lab2_dp/initial/rm_icc/tmp/tpns_mv.tcl .
	@cp $(LABBACKUP)/lab2_dp/initial/rm_icc/tmp/pg_mesh.tpl .
	@cp $(LABBACKUP)/lab2_dp/initial/rm_icc/tmp/create_fp.tcl .
	@cp $(LABBACKUP)/lab2_dp/initial/scripts_block/rm_icc_scripts/common_optimization_settings_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@touch .lab2_restored


restore_lab3: clean_current_lab restore_base_rm
	@echo "Restoring clean setup for lab 3..."
	@\cp $(LABBACKUP)/lab3_place_opt/initial/scripts_block/rm_icc_scripts/common_optimization_settings_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@\cp $(LABBACKUP)/lab3_place_opt/initial/scripts_block/rm_icc_scripts/mcmm.scenarios.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@\cp $(LABBACKUP)/lab3_place_opt/initial/scripts_block/rm_icc_scripts/custom_pre_place_opt.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@\cp $(LABBACKUP)/lab3_place_opt/initial/scripts_block/rm_icc_scripts/custom_post_place_opt.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@\cp $(LABBACKUP)/lab3_place_opt/initial/scripts_block/rm_icc_scripts/spare_cells.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@tar xzf $(LABBACKUP)/lab3_place_opt/initial/rm_icc/work/ORCA_TOP_LIB.tgz -C ../work
	@touch init_design_icc
	@touch .lab3_restored

final_lab3:
	@echo "Creating final setup for lab 3..."
	cp $(LABBACKUP)/lab3_place_opt/final/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup
	cp $(LABBACKUP)/lab3_place_opt/final/scripts_block/rm_icc_scripts/custom_pre_place_opt.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts/

diff_lab3:
	@echo "Comparing against final setup for lab 3..."
	-$(DIFF) $(LABBACKUP)/lab3_place_opt/final/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup || true
	-$(DIFF) $(LABBACKUP)/lab3_place_opt/final/scripts_block/rm_icc_scripts/custom_pre_place_opt.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts/ || true


restore_lab4: clean_current_lab restore_base_rm
	@echo "Restoring clean setup for lab 4..."
	@\cp $(LABBACKUP)/lab4_clock_opt/initial/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup
	@\cp $(LABBACKUP)/lab3_place_opt/initial/scripts_block/rm_icc_scripts/common_optimization_settings_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@\cp $(LABBACKUP)/lab3_place_opt/initial/scripts_block/rm_icc_scripts/mcmm.scenarios.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@\cp $(LABBACKUP)/lab4_clock_opt/initial/scripts_block/rm_icc_scripts/custom_pre_clock_opt.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts/
	@\cp $(LABBACKUP)/lab4_clock_opt/initial/scripts_block/rm_icc_scripts/common_cts_settings_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@\cp $(LABBACKUP)/lab4_clock_opt/initial/scripts_block/rm_icc_scripts/clock_opt_cts_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@\cp $(LABBACKUP)/lab4_clock_opt/initial/scripts_block/rm_icc_zrt_scripts/common_route_si_settings_zrt_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_zrt_scripts
	@tar xzf $(LABBACKUP)/lab4_clock_opt/initial/rm_icc/work/ORCA_TOP_LIB.tgz -C ../work
	@tar xzf $(LABBACKUP)/lab4_clock_opt/initial/rm_icc/logs/init_place_logs.tgz -C ../logs
	@touch init_design_icc place_opt_icc
	@touch .lab4_restored


final_lab4:
	@echo "Creating final setup for lab 4..."
	cp $(LABBACKUP)/lab4_clock_opt/final/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup
	cp $(LABBACKUP)/lab4_clock_opt/final/scripts_block/rm_icc_scripts/common_cts_settings_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	cp $(LABBACKUP)/lab4_clock_opt/final/scripts_block/rm_icc_scripts/custom_pre_clock_opt.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts

diff_lab4:
	@echo "Compare against final setup for lab 4..."
	-$(DIFF) $(LABBACKUP)/lab4_clock_opt/final/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup || true
	-$(DIFF) $(LABBACKUP)/lab4_clock_opt/final/scripts_block/rm_icc_scripts/common_cts_settings_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts/ || true
	-$(DIFF) $(LABBACKUP)/lab4_clock_opt/final/scripts_block/rm_icc_scripts/custom_pre_clock_opt.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts/ || true


restore_lab5: clean_current_lab restore_base_rm
	@echo "Restoring clean setup for lab 5..."
	@cp $(LABBACKUP)/lab5_route_opt/initial/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup
	@cp $(LABBACKUP)/lab5_route_opt/initial/scripts_block/rm_icc_scripts/common_optimization_settings_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@cp $(LABBACKUP)/lab5_route_opt/initial/scripts_block/rm_icc_scripts/common_cts_settings_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@cp $(LABBACKUP)/lab5_route_opt/initial/scripts_block/rm_icc_scripts/mcmm.hold_scenarios.tcl $(SCRIPTS_BLOCK)/rm_icc_scripts
	@cp $(LABBACKUP)/lab5_route_opt/initial/scripts_block/rm_icc_zrt_scripts/common_route_si_settings_zrt_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_zrt_scripts
	@cp $(LABBACKUP)/lab5_route_opt/initial/scripts_block/rm_icc_zrt_scripts/route_opt_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_zrt_scripts
	@tar xzf $(LABBACKUP)/lab5_route_opt/initial/rm_icc/work/ORCA_TOP_LIB.tgz -C ../work
	@touch init_design_icc place_opt_icc clock_opt_cts_icc clock_opt_psyn_icc
	@touch .lab5_restored

final_lab5:
	@echo "Creating final setup for lab 5..."
	@cp $(LABBACKUP)/lab5_route_opt/final/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup
	@cp $(LABBACKUP)/lab5_route_opt/final/scripts_block/rm_icc_zrt_scripts/common_route_si_settings_zrt_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_zrt_scripts
	@cp $(LABBACKUP)/lab5_route_opt/final/scripts_block/rm_icc_zrt_scripts/route_opt_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_zrt_scripts

diff_lab5:
	@echo "Compare against final setup for lab 5..."
	-$(DIFF) $(LABBACKUP)/lab5_route_opt/final/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup || true
	-$(DIFF) $(LABBACKUP)/lab5_route_opt/final/scripts_block/rm_icc_zrt_scripts/common_route_si_settings_zrt_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_zrt_scripts || true
	-$(DIFF) $(LABBACKUP)/lab5_route_opt/final/scripts_block/rm_icc_zrt_scripts/route_opt_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_zrt_scripts || true


restore_lab6: clean_current_lab restore_base_rm
	@echo "Restoring clean setup for lab 6..."
	@cp $(LABBACKUP)/lab6_dfm/initial/scripts_block/rm_setup/icc_setup.tcl $(SCRIPTS_BLOCK)/rm_setup
	@cp $(LABBACKUP)/lab6_dfm/initial/scripts_block/rm_icc_zrt_scripts/common_route_si_settings_zrt_icc.tcl $(SCRIPTS_BLOCK)/rm_icc_zrt_scripts
	@tar xzf $(LABBACKUP)/lab6_dfm/initial/rm_icc/work/ORCA_TOP_LIB.tgz -C ../work
	@touch init_design_icc place_opt_icc clock_opt_cts_icc clock_opt_psyn_icc clock_opt_route_icc route_icc route_opt_icc
	@touch .lab6_restored
