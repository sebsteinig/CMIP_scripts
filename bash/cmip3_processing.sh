#!/bin/bash
#set -x
set -e
# This script will do the following actions:
	# 1. PCMDI climatologies
	# 2. process data with cdo 

if [ $(whoami) = "stein" ]; then  
	CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP"
	echo "user: stein"
elif [ $(whoami) = "smomw200" ]; then
	CMIP_dir="/gfs/scratch/smomw200/CMIP"
	echo "user: smomw200"
	module load cdo
fi
	
##########################################################################################
 
experiment="20c3m"					# CMIP3 experiments: 20c3m
var="psl pr rlut rsut rlutcs rsutcs tos"
period=1900-1999 					# time period for which the data gets processed
climatology_period=1980-1999
remap=remapbil
res=HadCRUT4
actions="3"

##########################################################################################

start_period=${period:0:4}
end_period=${period:5:9}

start_climatology=${climatology_period:0:4}
end_climatology=${climatology_period:5:9}
	
for actid in $actions ; do		# loop over all chosen actions

for variable in $var; do		# loop over all chosen variable

export variable

case $variable in                                                                   
            tos|zos|mlotst|zosga|zossga|zostoga|msftmyz)   
                realm=ocn                                                				
                ;;
            tas|ta|psl|pr|rsut|rsutcs|rlut|rlutcs|ua|va|zg)
				realm=atm                
				;;
            *)
            	echo unknown variable; break
            esac
export realm

# select reference field to which the data should get remapped to
case $res in                                                                   
            HadCRUT4)   
                remap_reference=$CMIP_dir/data/observations/${res}/HadCRUT4_1870-2005.nc                                               				
                ;;
            ERSST)
				remap_reference=$CMIP_dir/data/observations/${res}/ERSST_1870-2005.nc            
				;;
            *)
            	echo unknown remap reference; break
esac
	

##########################################################################################

if [ $actid -eq 1 ];then # download data

    models="bccr_bcm2_0 cccma_cgcm3_1 cccma_cgcm3_1_t63 cnrm_cm3 csiro_mk3_0 csiro_mk3_5 gfdl_cm2_0 gfdl_cm2_1 giss_aom giss_model_e_h giss_model_e_r iap_fgoals1_0_g ingv_echam4 inmcm3_0 ipsl_cm4 miroc3_2_hires miroc3_2_medres mpi_echam5 mri_cgcm2_3_2a ncar_ccsm3_0 ncar_pcm1 ukmo_hadcm3 ukmo_hadgem1"
    mkdir -p $CMIP_dir/data/CMIP3/$experiment/$realm/$variable
	
    for exp in $models; do
	    wget --user=sebsteinig --password=seppel2482 -r --reject "index.html*" -P $CMIP_dir/data/CMIP3/$experiment/$realm/mo/$variable ftp://ftp-esg.ucllnl.org/ipcc/$experiment/$realm/mo/$variable/${exp}/run1/ 
    done

    mv $CMIP_dir/data/CMIP3/$experiment/$realm/mo/$variable/ftp-esg.ucllnl.org/ipcc/$experiment/$realm/mo/$variable/* $CMIP_dir/data/CMIP3/$experiment/$realm/$variable
	rm -r $CMIP_dir/data/CMIP3/$experiment/$realm/mo/
fi


##########################################################################################
    
if [ $actid -eq 2 ];then # merge data

	cd $CMIP_dir/data/CMIP3/$experiment/$realm/$variable       
		
	model_array=( $(find . -type d -maxdepth 1 -exec printf "{} " \;) )		# create array containing all model names

	for index in ${!model_array[*]}; do	                                                                                                        
        models[index]=${model_array[index]#./}					# remove "./" from the model names
		models_upper_case[index]=$(echo ${models[index]} | tr '[:lower:]' '[:upper:]')       
	done
	
	loop_length=$(expr ${#models[*]} - 1)									# loop over all folders

	while [[ $((++i)) -le ${loop_length} ]]; do                                  
    	cd ${models[i]}
        echo 'processing ' ${models_upper_case[i]}
		model=${PWD##*/}
		
		if [ "$variable" != "psl" ]; then
			cd run1
		fi
		
		count=$(find . -maxdepth 1 -name '*.nc' | wc -l)
		
		if [ $count -eq 1 ]; then
			mv *.nc dummy.nc
		else
			cdo mergetime *.nc dummy.nc
		fi
		
		cdo selyear,${start_period}/${end_period} dummy.nc $CMIP_dir/data/CMIP3/$experiment/$realm/$variable/${variable}_${realm}_${models_upper_case[i]}_${experiment}_CMIP3_r1i1p1_${start_period}-${end_period}.nc
		rm dummy.nc
		cd $CMIP_dir/data/CMIP3/$experiment/$realm/$variable
		rm -r ${models[i]}
	done
	unset i
fi

##########################################################################################
    
if [ $actid -eq 3 ];then # process data with cdo 

    cd $CMIP_dir/data/CMIP3/$experiment/$realm/$variable       
	
    mkdir -p $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/original_resolution
    mkdir -p $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/remapped_to_${res}
    mkdir -p $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/climatologies
	rm -f $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/original_resolution/*      # remove old data
	rm -f $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/remapped_to_${res}/*       # remove old data
	rm -f $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/climatologies/*       # remove old data
	
	
	model_array=( $(find . -type d -maxdepth 1 -exec printf "{} " \;) )		# create array containing all model names

	for index in ${!model_array[*]}; do                                                                                                        
        models[index]=${model_array[index]#./}								# remove "./" from the model names      
	done
	
	loop_length=$(expr ${#models[*]} - 1)									

	while [[ $((++i)) -le ${loop_length} ]]; do                            # loop over all folders
	
		if [ "$variable" != "psl" ]; then
    		cd ${models[i]}/run1
		else
			cd ${models[i]}
		fi
		
        echo 'processing ' ${models[i]}
        model=${models[i]}

        if [ -d processed ]; then rm -r processed; fi 			           # remove old data
        mkdir processed
		
		count=$(find . -maxdepth 1 -name '*.nc' | wc -l)                   # check whether model data is split into multiple files
		
		# if there is only 1 file, then link it to the processed folder
		if [ $count -eq 1 ]; then
			ln *.nc processed/${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc
		# else merge individual files together 
		else
			cdo mergetime *.nc processed/${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc
			cp -p processed/${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/original_resolution/${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_${first_model_year}-${last_model_year}_original_resolution.nc
		fi
		
		cd processed
	
		# further proceeding is dependent of the variable
        case $variable in 
            msftmyz) # MOC streamfunction -> no vertical interpolation between model grids
				if [ $first_model_year -le ${start_period} ]; then
 				    cdo  -selyear,${start_period}/${end_period} -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_${start_period}-${end_period}.nc
				fi
				
				rm ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc
				
                ;;
            zosga|zossga|zostoga) # global average times eries of sea level change -> no remapping needed 
            	if [ $first_model_year -le 1861 ]; then
				    cdo selyear,1861/1999 ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_1861-2005.nc
				    rm ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc			
				fi
                ;;
            *)
            	ensemble_mean_flag=1 # calculate a multi model ensemble mean in the end
            
            	if [ "$variable" == "psl" ]; then # divide pressure values by 100 (Pa -> hPa)    	 
            	    mv ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc
            	    cdo divc,100 ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc
            	    rm ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc         	
            	fi
            	
            	if [ "$variable" == "tas" ] || [ "$variable" == "ta" ]; then # convert °K to °C
            	    mv ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc
            	    cdo -chunit,K,°C -addc,-273.15 ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc
            	    rm ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc
			    fi
            	
            	if [ "$variable" == "pr" ]; then # convert to mm/day
            	    mv ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc
            	    cdo mulc,86400 ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc
            	    rm ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc
            	fi
            	
            	if [ "$model" != "GFDL-CM2p1" ] && [ "$variable" == "tos" ]; then # convert all to °C, except GFDL-CM2p1  model (already has °C unit)
					mv ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc
            	    cdo -chunit,K,C -addc,-273.15 -setctomiss,0 ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc
            	    rm ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_temp.nc
            	fi
				
				# remap to T42 grid and calculate ${start_climatology}-${end_climatology} climatologies, according to the PCMDI metrics (see IPCC, figure 9.7)
				if [ "$variable" == "zg" ]; then
					# don't calculate ensemble mean for 4D variable, since they don't get processed (see below)
					ensemble_mean_flag=0
					# only consider geopotential height at 500 hPa
					cdo -${remap},t42grid -ymonmean -selyear,${start_climatology}/${end_climatology} -sellevel,50000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/climatologies/${variable}_500_${realm}_${model}_${experiment}_CMIP3_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc
				elif [ "$variable" == "ua" ] || [ "$variable" == "va" ] || [ "$variable" == "ta" ]; then 
					# don't calculate ensemble mean for 4D variable, since they don't get processed (see below
					ensemble_mean_flag=0
					# only consider values at 200 and 850 hPa
					cdo -${remap},t42grid -ymonmean -selyear,${start_climatology}/${end_climatology} -sellevel,85000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/climatologies/${variable}_850_${realm}_${model}_${experiment}_CMIP3_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc
					cdo -${remap},t42grid -ymonmean -selyear,${start_climatology}/${end_climatology} -sellevel,20000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/climatologies/${variable}_200_${realm}_${model}_${experiment}_CMIP3_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc
				else
					cdo -${remap},t42grid -ymonmean -selyear,${start_climatology}/${end_climatology} -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/climatologies/${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc
				fi			
            	
				# process model data only if it starts before selected period and is not a 4D-variable
            	if [ "$variable" != "zg" ]  ||  [ "$variable" != "ta" ] || \
					[ "$variable" != "ua" ] || [ "$variable" != "va" ] ; then 
					# remap model field to observational data set for comparability; also cut time period selected in the beginning (period)
					cdo -${remap},${remap_reference} -selyear,${start_period}/${end_period} -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc
           		fi
				
           		rm ${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1.nc # delete temporal data
            esac
		
		if [ "$variable" != "psl" ]; then
			cd ../../..
		else
			cd ../../
		fi

		# if model data got processed, move it from data to processed directory
		if [ -f $CMIP_dir/data/CMIP3/$experiment/$realm/$variable/$model/run1/processed/${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc ] ; then 
			mv ${model}/run1/processed/*.nc $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/remapped_to_${res}; 
		fi
		
		if [ -f $CMIP_dir/data/CMIP3/$experiment/$realm/$variable/$model/processed/${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc ] ; then 
			mv ${model}/processed/*.nc $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/remapped_to_${res}; 
		fi
		
		
		if [ "$variable" != "psl" ]; then
			rm -r $CMIP_dir/data/CMIP3/$experiment/$realm/$variable/${model}/run1/processed
		else
			rm -r $CMIP_dir/data/CMIP3/$experiment/$realm/$variable/${model}/processed
		fi
			
		
		cd $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/original_resolution
		# if original data consists only of 1 file (1850-2005), create relative symbolic link to it in the original resolution folder to save disk space
		if [ $count -eq 1 ]; then
			if [ "$variable" != "psl" ]; then
				ln -s $(ls ../../../../../../data/CMIP3/$experiment/$realm/$variable/$model/run1/*.nc) $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/original_resolution/${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_${first_model_year}-${last_model_year}_original_resolution.nc
			else
				ln -s $(ls ../../../../../../data/CMIP3/$experiment/$realm/$variable/$model/*.nc) $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/original_resolution/${variable}_${realm}_${model}_${experiment}_CMIP3_r1i1p1_${first_model_year}-${last_model_year}_original_resolution.nc
			fi
	    fi
		cd $CMIP_dir/data/CMIP3/$experiment/$realm/$variable
		unset models[i]		
	done
	
	unset i
	
	if [ ${ensemble_mean_flag} -eq 1 ]; then # remove old ensemble mean and calculate new one
	    cd $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/remapped_to_${res}/
	    rm -f ${variable}*mmm*${period}*${res}*
		# HadGEM models get excluded, since they only provide data until 200511 -> different number of timesteps than other models
	    if [ "$variable" == "rlutcs" ] || [ "$variable" == "rsutcs" ] || [ "$variable" == "rsut" ] || [ "$variable" == "rlut" ]; then
			cdo ensmean $(ls ${variable}*${period}*${res}* |grep -vi "HadGEM" |grep -vi "CMCC-CESM" |grep -vi "CMCC-CM") ${variable}_${realm}_mmm_${experiment}_CMIP3_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc
		else
			cdo ensmean $(ls ${variable}*${period}*${res}* |grep -vi "csiro_mk3_5") ${variable}_${realm}_mmm_${experiment}_CMIP3_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc
		fi
		cd $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/climatologies
		rm -f ${variable}*mmm*${start_climatology}-${end_climatology}*
		if [ "$variable" == "zg" ]; then 
			cdo ensmean ${variable}*500*${start_climatology}-${end_climatology}*T42* ${variable}_500_${realm}_mmm_${experiment}_CMIP3_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
		elif [ "$variable" == "ua" ] || [ "$variable" == "va" ] || [ "$variable" == "ta" ]; then 
			cdo ensmean ${variable}*850*${start_climatology}-${end_climatology}*T42* ${variable}_850_${realm}_mmm_${experiment}_CMIP3_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
			cdo ensmean ${variable}*200*${start_climatology}-${end_climatology}*T42* ${variable}_200_${realm}_mmm_${experiment}_CMIP3_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
		else
			cdo ensmean ${variable}*${start_climatology}-${end_climatology}*T42* ${variable}_${realm}_mmm_${experiment}_CMIP3_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
		fi
		
	fi
		
    # calculate shortwave cloud radiative feedback fields if data for clear-sky and all-sky SW radiation is available
	if [ -d $CMIP_dir/processed/CMIP3/$experiment/Amon/rsut/climatologies ] && [ -d cd $CMIP_dir/processed/CMIP3/$experiment/Amon/rsutcs/climatologies ] && ( [ "$variable" == "rsut" ] || [ "$variable" == "rsutcs" ] ); then 		
	    # create folders for new sw_cre variable or delete old data
	    mkdir -p $CMIP_dir/processed/CMIP3/$experiment/Amon/sw_cre/climatologies
		mkdir -p $CMIP_dir/processed/CMIP3/$experiment/Amon/sw_cre/original_resolution
		mkdir -p $CMIP_dir/processed/CMIP3/$experiment/Amon/sw_cre/remapped_to_${res}	
		rm -f $CMIP_dir/processed/CMIP3/$experiment/Amon/sw_cre/climatologies/*
		rm -f $CMIP_dir/processed/CMIP3/$experiment/Amon/sw_cre/original_resolution/*
		rm -f $CMIP_dir/processed/CMIP3/$experiment/Amon/sw_cre/remapped_to_${res}/*
	
	    # go the climatologies and subtract rsut from rsutcs for each model
		cd $CMIP_dir/processed/CMIP3/$experiment/Amon/rsutcs/climatologies		
		for i in *${start_climatology}-${end_climatology}*.nc; do
			j=`echo $i | sed 's/rsutcs/rsut/'`
			k=`echo $i | sed 's/rsutcs/sw_cre/'`
			cdo -chname,rsutcs,sw_cre -sub $i $CMIP_dir/processed/CMIP3/$experiment/Amon/rsut/climatologies/$j $CMIP_dir/processed/CMIP3/$experiment/Amon/sw_cre/climatologies/$k
		done
	
	    # do the same for the fields with original resolution
		cd $CMIP_dir/processed/CMIP3/$experiment/Amon/rsutcs/original_resolution		
		for i in *.nc; do
			j=`echo $i | sed 's/rsutcs/rsut/'`
			k=`echo $i | sed 's/rsutcs/sw_cre/'`
			cdo -chname,rsutcs,sw_cre -sub $i $CMIP_dir/processed/CMIP3/$experiment/Amon/rsut/original_resolution/$j $CMIP_dir/processed/CMIP3/$experiment/Amon/sw_cre/original_resolution/$k
		done
	
	    # do the same for the remapped fields
		cd $CMIP_dir/processed/CMIP3/$experiment/Amon/rsutcs/remapped_to_${res}		
		for i in *${period}*.nc; do
			j=`echo $i | sed 's/rsutcs/rsut/'`
			k=`echo $i | sed 's/rsutcs/sw_cre/'`
			cdo -chname,rsutcs,sw_cre -sub $i $CMIP_dir/processed/CMIP3/$experiment/Amon/rsut/remapped_to_${res}/$j $CMIP_dir/processed/CMIP3/$experiment/Amon/sw_cre/remapped_to_${res}/$k
		done
	
	    # calculate ensemble mean for the climatologies
		cd $CMIP_dir/processed/CMIP3/$experiment/Amon/sw_cre/climatologies/
		rm -f *mmm*${start_climatology}-${end_climatology}*		
		cdo ensmean *${start_climatology}-${end_climatology}*T42* sw_cre_${realm}_mmm_${experiment}_CMIP3_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
	
	    # calculate ensemble mean for the remapped fields
		cd $CMIP_dir/processed/CMIP3/$experiment/Amon/sw_cre/remapped_to_${res}/
		rm -f *mmm*${period}*		
		cdo ensmean *${period}*${res}* sw_cre_${realm}_mmm_${experiment}_CMIP3_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc	
    fi	
		
    # do the same as above, but for the long wave cloud radiative effect
	if [ -d $CMIP_dir/processed/CMIP3/$experiment/Amon/rlut/climatologies ] && [ -d cd $CMIP_dir/processed/CMIP3/$experiment/Amon/rlutcs/climatologies ] && ( [ "$variable" == "rlut" ] || [ "$variable" == "rlutcs" ] ); then 	
	    # create folders for new sw_cre variable or delete old data
	    mkdir -p $CMIP_dir/processed/CMIP3/$experiment/Amon/lw_cre/climatologies
		mkdir -p $CMIP_dir/processed/CMIP3/$experiment/Amon/lw_cre/original_resolution
		mkdir -p $CMIP_dir/processed/CMIP3/$experiment/Amon/lw_cre/remapped_to_${res}	
		rm -f $CMIP_dir/processed/CMIP3/$experiment/Amon/lw_cre/climatologies/*
		rm -f $CMIP_dir/processed/CMIP3/$experiment/Amon/lw_cre/original_resolution/*
		rm -f $CMIP_dir/processed/CMIP3/$experiment/Amon/lw_cre/remapped_to_${res}/*
	
	    # go the climatologies and subtract rlut from rlutcs for each model
		cd $CMIP_dir/processed/CMIP3/$experiment/Amon/rlutcs/climatologies		
		for i in *${start_climatology}-${end_climatology}*.nc; do
			j=`echo $i | sed 's/rlutcs/rlut/'`
			k=`echo $i | sed 's/rlutcs/lw_cre/'`
			cdo -chname,rlutcs,lw_cre -sub $i $CMIP_dir/processed/CMIP3/$experiment/Amon/rlut/climatologies/$j $CMIP_dir/processed/CMIP3/$experiment/Amon/lw_cre/climatologies/$k
		done
	
	    # do the same for the fields with original resolution
		cd $CMIP_dir/processed/CMIP3/$experiment/Amon/rlutcs/original_resolution		
		for i in *.nc; do
			j=`echo $i | sed 's/rlutcs/rlut/'`
			k=`echo $i | sed 's/rlutcs/lw_cre/'`
			cdo -chname,rlutcs,lw_cre -sub $i $CMIP_dir/processed/CMIP3/$experiment/Amon/rlut/original_resolution/$j $CMIP_dir/processed/CMIP3/$experiment/Amon/lw_cre/original_resolution/$k
		done
	
	    # do the same for the remapped fields
		cd $CMIP_dir/processed/CMIP3/$experiment/Amon/rlutcs/remapped_to_${res}		
		for i in *${period}*.nc; do
			j=`echo $i | sed 's/rlutcs/rlut/'`
			k=`echo $i | sed 's/rlutcs/lw_cre/'`
			cdo -chname,rlutcs,lw_cre -sub $i $CMIP_dir/processed/CMIP3/$experiment/Amon/rlut/remapped_to_${res}/$j $CMIP_dir/processed/CMIP3/$experiment/Amon/lw_cre/remapped_to_${res}/$k
		done
	
	    # calculate ensemble mean for the climatologies
		cd $CMIP_dir/processed/CMIP3/$experiment/Amon/lw_cre/climatologies/
		rm -f *mmm*${start_climatology}-${end_climatology}*		
		cdo ensmean *${start_climatology}-${end_climatology}*T42* lw_cre_${realm}_mmm_${experiment}_CMIP3_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
	
	    # calculate ensemble mean for the remapped fields
		cd $CMIP_dir/processed/CMIP3/$experiment/Amon/lw_cre/remapped_to_${res}/
		rm -f *mmm*${period}*		
		cdo ensmean *${period}*${res}* lw_cre_${realm}_mmm_${experiment}_CMIP3_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc	
    fi

fi

##########################################################################################

done
done
