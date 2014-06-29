models="bccr_bcm2_0 cccma_cgcm3_1 cccma_cgcm3_1_t63 cnrm_cm3 csiro_mk3_0 csiro_mk3_5 gfdl_cm2_0 gfdl_cm2_1 giss_aom giss_model_e_h giss_model_e_r iap_fgoals1_0_g ingv_echam4 inmcm3_0 ipsl_cm4 miroc3_2_hires miroc3_2_medres mpi_echam5 mri_cgcm2_3_2a ncar_ccsm3_0 ncar_pcm1 ukmo_hadcm3 ukmo_hadgem1"

for exp in $models; do

	#wget --user=sebsteinig --password=seppel2482 -r --reject "index.html*" -P $SCRATCH/CMIP/data/CMIP3 ftp://ftp-esg.ucllnl.org/ipcc/20c3m/atm/mo/ta/${exp}/run1/ 
	wget --user=sebsteinig --password=seppel2482 -r --reject "index.html*" -P /Volumes/HiWi_data/CMIP_test/data/CMIP3 ftp://ftp-esg.ucllnl.org/ipcc/20c3m/ocn/mo/tos/${exp}/run1/ 


done


