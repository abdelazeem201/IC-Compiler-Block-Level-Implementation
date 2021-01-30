#****************************************
#Spare cells to be inserted right after place_opt step
#Library: saed32hvt_ss0p95v125c

insert_spare_cells \
	-lib_cell {AND2X1_HVT IBUFFX2_HVT INVX0_HVT NAND2X0_HVT NOR2X0_HVT OR2X1_HVT} \
	-num_instance 40 \
	-cell_name SPARE \
	-tie \
	-hier_cell I_SDRAM_TOP
set_attribute [all_spare_cells] is_soft_fixed true
                           
