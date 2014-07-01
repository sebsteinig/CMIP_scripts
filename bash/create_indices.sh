if [ $(whoami) = "stein" ]; then  
	CMIP_dir="/Volumes/HiWi_data/CMIP_test"
	echo "user: stein"
elif [ $(whoami) = "smomw200" ]; then
	CMIP_dir="/gfs/scratch/smomw200/CMIP"
	echo "user: smomw200"
	module load cdo
fi

nino3=0

if [ ${nino3} -eq 1 ]; then
	
	cd $CMIP_dir/processed/CMIP5/historical/Omon/tos
	mkdir -p nino3

	for i in *1870-1999_original_resolution.nc; do
		
		j=`echo $i | sed 's/original_resolution/nino3_area/'`
		k=`echo $i | sed 's/original_resolution/nino3_index/'`
		l=`echo $i | sed 's/original_resolution/remapbil_ERSST/'`

		
		#cdo sellonlatbox,-150,-90,-5,5 $l nino3/$j
		cdo fldmean -ymonsub -sellonlatbox,-150,-90,-5,5 $i -ymonmean -sellonlatbox,-150,-90,-5,5 $i nino3/$k
		
	done
	
	#cdo sellonlatbox,-150,-90,-5,5 tos_Omon_mmm_historical_CMIP5_r1i1p1_1870-1999_remapbil_ERSST.nc nino3/tos_Omon_mmm_historical_CMIP5_r1i1p1_1870-1999_nino3_area.nc
	cdo fldmean -ymonsub -sellonlatbox,-150,-90,-5,5 tos_Omon_mmm_historical_CMIP5_r1i1p1_1870-1999_remapbil_ERSST.nc -ymonmean -sellonlatbox,-150,-90,-5,5 tos_Omon_mmm_historical_CMIP5_r1i1p1_1870-1999_remapbil_ERSST.nc nino3/tos_Omon_mmm_historical_CMIP5_r1i1p1_1870-1999_nino3_index.nc

	cd $CMIP_dir/processed/CMIP3/20c3m/ocn/tos
	mkdir -p nino3

	for i in *1870-1999_original_resolution.nc; do
		
		j=`echo $i | sed 's/original_resolution/nino3_area/'`
		k=`echo $i | sed 's/original_resolution/nino3_index/'`
		l=`echo $i | sed 's/original_resolution/remapbil_ERSST/'`

		#cdo sub -sellonlatbox,-150,-90,-5,5 $l -fldmean -sellonlatbox,-150,-90,-5,5 $l nino3/$j
		cdo fldmean -ymonsub -sellonlatbox,-150,-90,-5,5 $i -ymonmean -sellonlatbox,-150,-90,-5,5 $i nino3/$k
				
	done
	
	cdo fldmean -ymonsub -sellonlatbox,-150,-90,-5,5 tos_ocn_mmm_20c3m_CMIP3_1870-1999_remapbil_ERSST.nc -ymonmean -sellonlatbox,-150,-90,-5,5 tos_ocn_mmm_20c3m_CMIP3_1870-1999_remapbil_ERSST.nc nino3/tos_ocn_mmm_20c3m_CMIP3_1870-1999_nino3_index.nc
	
	cd $CMIP_dir/data/observations/ERSST/
	
	#cdo sellonlatbox,-150,-90,-5,5 -selyear,1870/1999 ersstv3b.mnmean.nc ERSST_1870-1999_nino3_area.nc
	#cdo fldmean ERSST_1870-1999_nino3_area.nc ERSST_1870-1999_nino3_index.nc
	
	cdo fldmean -ymonsub -sellonlatbox,-150,-90,-5,5 -selyear,1870/1999 ersstv3b.mnmean.nc -ymonmean -sellonlatbox,-150,-90,-5,5 -selyear,1870/1999 ersstv3b.mnmean.nc ERSST_1870-1999_nino3_index.nc
	
fi

global_temp2=0

if [ ${global_temp2} -eq 1 ]; then
	
	cd $CMIP_dir/processed/CMIP5/historical/Amon/tas
	mkdir -p gm

	for i in *1870-1999_original_resolution.nc; do
	
		k=`echo $i | sed 's/original_resolution/gm/;s/1870-1999/1948-1999/'`

		cdo fldmean -ymonsub -selyear,1948/1999 $i -ymonmean -selyear,1948/1999 $i gm/$k
		
	done
	
	cdo fldmean -ymonsub -selyear,1948/1999 tas_Amon_mmm_historical_CMIP5_r1i1p1_1870-1999_remapbil_ERSST.nc -ymonmean -selyear,1948/1999 tas_Amon_mmm_historical_CMIP5_r1i1p1_1870-1999_remapbil_ERSST.nc gm/tas_Amon_mmm_historical_CMIP5_r1i1p1_1948-1999_gm.nc
	
	cd $CMIP_dir/processed/CMIP3/20c3m/atm/tas
	mkdir -p gm

	for i in *1870-1999_original_resolution.nc; do
		
		k=`echo $i | sed 's/original_resolution/gm/;s/1870-1999/1948-1999/'`

		cdo fldmean -ymonsub -selyear,1948/1999 $i -ymonmean -selyear,1948/1999 $i gm/$k
		
	done
	
	cdo fldmean -ymonsub -selyear,1948/1999 tas_atm_mmm_20c3m_CMIP3_1870-1999_remapbil_ERSST.nc -ymonmean -selyear,1948/1999 tas_atm_mmm_20c3m_CMIP3_1870-1999_remapbil_ERSST.nc gm/tas_atm_mmm_20c3m_CMIP3_1948-1999_gm.nc
	
	cd $CMIP_dir/data/observations/NCEP/
	
	cdo fldmean -ymonsub -selyear,1948/1999 NCEP.tas.mon.mean.nc -ymonmean -selyear,1948/1999 NCEP.tas.mon.mean.nc NCEP_tas_1948-1999_gm.nc
	
	
fi

pr=1

if [ ${pr} -eq 1 ]; then
	
	cd $CMIP_dir/processed/CMIP5/historical/Amon/pr
	mkdir -p pacific_mean

	for i in *1980-1999_original_resolution.nc; do
	
		k=`echo $i | sed 's/original_resolution/pacific_mean/'`

		cdo fldmean -ymonsub -sellonlatbox,110,-140,-30,30 $i -ymonmean -sellonlatbox,110,-140,-30,30 $i pacific_mean/$k
		
	done
	
	cdo fldmean -ymonsub -sellonlatbox,110,-140,-30,30 pr_Amon_mmm_historical_CMIP5_r1i1p1_1870-1999_remapbil_ERSST.nc -ymonmean -sellonlatbox,110,-140,-30,30 pr_Amon_mmm_historical_CMIP5_r1i1p1_1870-1999_remapbil_ERSST.nc pacific_mean/tas_Amon_mmm_historical_CMIP5_r1i1p1_1948-1999_pacific_mean.nc
	
	
	cd $CMIP_dir/data/observations/GPCP/
	
	cdo fldmean -ymonsub -sellonlatbox,110,-140,-30,30 -selyear,1980/1999 GPCP.pr.mon.mean.nc -ymonmean -sellonlatbox,110,-140,-30,30 -selyear,1980/1999 GPCP.pr.mon.mean.nc GPCP_pr_1980-1999_pacific_mean.nc
	
	
fi


