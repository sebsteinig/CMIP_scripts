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
var="ua"
period=1900-1999 					# time period for which the data gets processed
climatology_period=1980-1999
remap=remapbil
res=HadCRUT4
actions="1"

##########################################################################################

start_period=${period:0:4}
end_period=${period:5:9}

start_climatology=${climatology_period:0:4}
end_climatology=${climatology_period:5:9}
	
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

for actid in $actions ; do		# loop over all chosen actions

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
		cd run1
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
fi


##########################################################################################

 if [ $actid -eq 3 ];then # create PCMDI climatologies 

	cd $CMIP_dir/data/CMIP3/$experiment/$realm/mo/$variable       
	
    mkdir -p $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable
	
	model_array=( $(find . -type d -maxdepth 1 -exec printf "{} " \;) )		# create array containing all model names

	for index in ${!model_array[*]}; do
	                                                                                                        
        models[index]=${model_array[index]#./}					# remove "./" from the model names
		models_upper_case[index]=$(echo ${models[index]} | tr '[:lower:]' '[:upper:]')
        
	done
	
	loop_length=$(expr ${#models[*]} - 1)									# loop over all folders without "processed"

	while [[ $((++i)) -le ${loop_length} ]]; do                            
       
    	cd ${models[i]}
        echo 'processing ' ${models_upper_case[i]}
		model=${PWD##*/}
		cd run1
		mkdir -p processed
		count=$(find . -maxdepth 1 -name '*.nc' | wc -l)
		
		if [ $count -eq 1 ]; then
			ln *.nc processed/${variable}_${realm}_${model}_${experiment}_CMIP3.nc
		else
			cdo mergetime *.nc processed/${variable}_${realm}_${model}_${experiment}_CMIP3.nc
		fi
		
		cd processed
		
    	if [ "$variable" == "tas" ] || [ "$variable" == "ta" ]; then
    	 
    		mv ${variable}_${realm}_${model}_${experiment}_CMIP3.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
    		cdo -chunit,K,°C -addc,-273.15 ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP3.nc
    		rm ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
    	
    	fi
    	
    	if [ "$variable" == "pr" ]; then
    	 
    		mv ${variable}_${realm}_${model}_${experiment}_CMIP3.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
    		cdo mulc,86400 ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP3.nc
    		rm ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
    	
		fi
		
    	if [ "$variable" == "tos" ]; then 
    	
    		mv ${variable}_${realm}_${model}_${experiment}_CMIP3.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
    		cdo -chunit,K,C -addc,-273.15 ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP3.nc
    		rm ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
			
		fi
		
    	   	
		if [ "$variable" == "zg" ]; then 
			cdo -${remap},t42grid -ymonmean -selyear,1980/1999 -sellevel,50000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP3.nc ${variable}_500_${realm}_${models_upper_case[i]}_${experiment}_CMIP3_1980-1999_clim_${remap}_T42.nc
		elif [ "$variable" == "ua" ] || [ "$variable" == "va" ] || [ "$variable" == "ta" ]; then 
			cdo -${remap},t42grid -ymonmean -selyear,1980/1999 -sellevel,85000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP3.nc ${variable}_850_${realm}_${models_upper_case[i]}_${experiment}_CMIP3_1980-1999_clim_${remap}_T42.nc
			cdo -${remap},t42grid -ymonmean -selyear,1980/1999 -sellevel,20000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP3.nc ${variable}_200_${realm}_${models_upper_case[i]}_${experiment}_CMIP3_1980-1999_clim_${remap}_T42.nc
		else
			cdo -${remap},t42grid -ymonmean -selyear,1870/1999 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP3.nc ${variable}_${realm}_${models_upper_case[i]}_${experiment}_CMIP3_1980-1999_clim_${remap}_T42.nc
		fi
				
		rm ${variable}_${realm}_${model}_${experiment}_CMIP3.nc
           		
		cd ../../..
		
		pwd
		echo $model
		mv ${model}/run1/processed/*.nc $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable; 
		
		rm -r $CMIP_dir/data/CMIP3/$experiment/$realm/mo/$variable/$model/run1/processed
		unset models[i]
		cd $CMIP_dir/data/CMIP3/$experiment/$realm/mo/$variable
		
	done
	
	cd $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/
	
	rm -f *mmm*1980-1999*
	
	if [ "$variable" == "zg" ]; then 
		cdo ensmean ${variable}*500*1980-1999*T42* ${variable}_500_${realm}_mmm_${experiment}_CMIP3_1980-1999_clim_${remap}_T42.nc	
	elif [ "$variable" == "ua" ] || [ "$variable" == "va" ] || [ "$variable" == "ta" ]; then 
		cdo ensmean ${variable}*850*1980-1999*T42* ${variable}_850_${realm}_mmm_${experiment}_CMIP3_1980-1999_clim_${remap}_T42.nc	
		cdo ensmean ${variable}*200*1980-1999*T42* ${variable}_200_${realm}_mmm_${experiment}_CMIP3_1980-1999_clim_${remap}_T42.nc	
	else
		cdo ensmean ${variable}*1980-1999*T42* ${variable}_${realm}_mmm_${experiment}_CMIP3_1980-1999_clim_${remap}_T42.nc	
	fi
	

	cre=0 	# 1 = calculate LW/SW cloud radiative effects
	      	# 0 = do not calculate LW/SW cloud radiative effects
		
	if [ ${cre} -eq 1 ]; then
		mkdir -p $CMIP_dir/processed/CMIP3/$experiment/$realm/sw_cre
		mkdir -p $CMIP_dir/processed/CMIP3/$experiment/$realm/lw_cre
		
		cd $CMIP_dir/processed/CMIP3/$experiment/$realm/rsutcs/	
		
		for i in *.nc; do
			j=`echo $i | sed 's/rsutcs/rsut/'`
			k=`echo $i | sed 's/rsutcs/sw_cre/'`
			cdo -chname,rsutcs,sw_cre -sub $i $CMIP_dir/processed/CMIP3/$experiment/$realm/rsut/$j $CMIP_dir/processed/CMIP3/$experiment/$realm/sw_cre/$k
		done
		
		cd $CMIP_dir/processed/CMIP3/$experiment/$realm/sw_cre/
		rm -f *mmm*1980-1999*
		
		cdo ensmean *1980-1999*T42* sw_cre_${realm}_mmm_${experiment}_CMIP3_1980-1999_clim_${remap}_T42.nc	
		
		
		cd $CMIP_dir/processed/CMIP3/$experiment/$realm/rlutcs/	
		
		for i in *.nc; do
			j=`echo $i | sed 's/rlutcs/rlut/'`
			k=`echo $i | sed 's/rlutcs/lw_cre/'`
			cdo -chname,rlutcs,lw_cre -sub $i $CMIP_dir/processed/CMIP3/$experiment/$realm/rlut/$j $CMIP_dir/processed/CMIP3/$experiment/$realm/lw_cre/$k
		done
		
		cd $CMIP_dir/processed/CMIP3/$experiment/$realm/lw_cre/
		rm -f *mmm*1980-1999*
		
		cdo ensmean *1980-1999*T42* lw_cre_${realm}_mmm_${experiment}_CMIP3_1980-1999_clim_${remap}_T42.nc	
		
		
	fi



	
fi

##########################################################################################
    
 if [ $actid -eq 4 ];then # process data with cdo 

	cd $CMIP_dir/data/CMIP3/$experiment/$realm/mo/$variable       
	
    mkdir -p $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable
	
	model_array=( $(find . -type d -maxdepth 1 -exec printf "{} " \;) )		# create array containing all model names

	for index in ${!model_array[*]}; do
	                                                                                                        
        models[index]=${model_array[index]#./}					# remove "./" from the model names
		models_upper_case[index]=$(echo ${models[index]} | tr '[:lower:]' '[:upper:]')
        
	done
	
	loop_length=$(expr ${#models[*]} - 1)									# loop over all folders without "processed"

	while [[ $((++i)) -le ${loop_length} ]]; do                            
       
    	cd ${models[i]}
        echo 'processing ' ${models_upper_case[i]}
		model=${PWD##*/}
		cd run1
		mkdir -p processed
		count=$(find . -maxdepth 1 -name '*.nc' | wc -l)
		
		if [ $count -eq 1 ]; then
			ln *.nc processed/${variable}_${realm}_${model}_${experiment}_CMIP3.nc
		else
			cdo mergetime *.nc processed/${variable}_${realm}_${model}_${experiment}_CMIP3.nc
		fi
		
		cd processed
		
    	if [ "$variable" == "tas" ] || [ "$variable" == "ta" ]; then
    	 
    		mv ${variable}_${realm}_${model}_${experiment}_CMIP3.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
    		cdo -chunit,K,°C -addc,-273.15 ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP3.nc
    		rm ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
    	
    	fi
    	
    	if [ "$variable" == "pr" ]; then
    	 
    		mv ${variable}_${realm}_${model}_${experiment}_CMIP3.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
    		cdo mulc,86400 ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP3.nc
    		rm ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
    	
		fi
		
    	if [ "$variable" == "tos" ]; then 
    	
    		mv ${variable}_${realm}_${model}_${experiment}_CMIP3.nc ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
    		cdo -chunit,K,C -addc,-273.15 ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP3.nc
    		rm ${variable}_${realm}_${model}_${experiment}_CMIP3_temp.nc
			
		fi
		
    	cdo selyear,1870/1999 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP3.nc ${variable}_${realm}_${models_upper_case[i]}_${experiment}_CMIP3_1870-1999_original_resolution.nc
		cdo -${remap},$CMIP_dir/data/observations/${res}/ersstv3b.mnmean.nc ${variable}_${realm}_${models_upper_case[i]}_${experiment}_CMIP3_1870-1999_original_resolution.nc ${variable}_${realm}_${models_upper_case[i]}_${experiment}_CMIP3_1870-1999_${remap}_${res}.nc
		
		keep_resolution=1
		
		if [ $keep_resolution -ne 1 ]; then 
			rm -f ${variable}_${realm}_${models_upper_case[i]}_${experiment}_CMIP3_1870-1999_original_resolution.nc
		fi
				
		rm ${variable}_${realm}_${model}_${experiment}_CMIP3.nc
           		
		cd ../../..
		
		pwd
		echo $model
		mv ${model}/run1/processed/*.nc $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable; 
		
		rm -r $CMIP_dir/data/CMIP3/$experiment/$realm/mo/$variable/$model/run1/processed
		unset models[i]
		cd $CMIP_dir/data/CMIP3/$experiment/$realm/mo/$variable
		
	done
	
	cd $CMIP_dir/processed/CMIP3/$experiment/$realm/$variable/
	
	rm -f *mmm*1870-1999*
	
	cdo ensmean ${variable}*1870-1999*ERSST* ${variable}_${realm}_mmm_${experiment}_CMIP3_1870-1999_${remap}_ERSST.nc						
	
fi

##########################################################################################

done
done
