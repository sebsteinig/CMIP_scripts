#!/bin/bash

set -x
set -e
set -a

# This script will do the following actions:
	# 1. create wget script for chosen $var and $experiment
	# 2. download data and check if all files have been downloaded
	# 3. sort model data into individual directories
	# 4. process model data with cdo 
	
	
if [ $(whoami) = "stein" ]; then            # check for system/user and adapt CMIP path  
    CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP"
    echo "user: stein"
elif [ $(whoami) = "smomw200" ]; then
    CMIP_dir="/gfs/scratch/smomw200/CMIP"
    echo "user: smomw200"
    module load cdo
fi
	
##########################################################################################

experiment="past1000"				# CMIP5 experiments: historical,rcp45
var="rlut"				# CMIP variable to process (e.g. tos,tas,pr,psl,...)
#var="tos"									# for full list see: http://cmip-pcmdi.llnl.gov/cmip5/docs/standard_output.pdf
observations="NCEP"					# HadISST HadSST3 CMAP GPCP HadSLP2 MLD ERSST HadCRUT4 CERES_EBAF NCEP
period=0851-1849					# time period for which the data gets processed
climatology_period=0851-1849
res=HadCRUT4						# HadCRUT4, ERSST
remap=remapbil
actions="1" 						# choose which sections of the script get executed; see list above

##########################################################################################	

# choose plots ( 0 = no / 1 = yes )
plot_means=0					# plot annual mean fields
plot_seasons=1					# plot seasonal mean fields				
plot_bias_ensemble=1			# plot bias against ensemble mean
plot_bias_observations=1		# plot bias against observations 	
plot_bias_KCM=0					# plot bias against KCM experiments
plot_change=0					# plot warming during 20th century
								# This has to be redone, since the file structure has changed!!! 

##########################################################################################

start_period=${period:0:4}						# calculate beginning of chosen period 
end_period=${period:5:9}						# calculate end of chosen period 

start_climatology=${climatology_period:0:4}		# calculate beginning of chosen climatological period 
end_climatology=${climatology_period:5:9}		# calculate end of chosen climatological period	

for actid in $actions ; do						# loop over all chosen actions
	
for variable in $var; do						# loop over all chosen variables

# select corresponding realm (atmosphere or ocean variable) for chosen variable
case $variable in                                                                   
            tos|zos|mlotst|zosga|zossga|zostoga|msftmyz)   
                realm=Omon; cmor_table=ocean                                                  				
                ;;
            tas|ta|psl|pr|rsut|rsutcs|rlut|rlutcs|ua|va|zg|rsdt)
				realm=Amon; cmor_table=atmos                 
				;;
            *)
            	echo unknown variable; break
esac

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

if [ $actid -eq 1 ];then # create wget script
	
    mkdir -p $CMIP_dir/data/CMIP5/$experiment/$realm/$variable; 

	url="http://esgf-data.dkrz.de/esg-search/wget?&latest=true&replica=false&facets=id&limit=2000&experiment_family=Paleo\
&ensemble=r1i1p1&experiment=$experiment&realm=$cmor_table&time_frequency=mon&cmor_table=$realm&variable=$variable"
	#url="http://esgf-data.dkrz.de/esg-search/wget?&latest=true&replica=false&facets=id&limit=2000\
#&ensemble=r1i1p1&experiment=$experiment&realm=$cmor_table&time_frequency=mon&cmor_table=$realm&variable=$variable"
	wget -O $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/wget.CMIP5.$realm.$experiment.mon.$variable.sh $url

##########################################################################################

download_all_files=1       # only set to 0 to delete lines from the wget file if you want to download only a subset of years
                           # e.g. to download only files which end after 1980 you can use the regular expression 
						   # '/.*19[0-7][0-9]..\.nc/d;/.*18....\.nc/d' to delete all other lines

if [ ${download_all_files} -eq 0 ]; then	
    if [[ $OSTYPE == "darwin"* ]]; then 	 
        sed -i '' '/.*19[0-7][0-9]..\.nc/d;/.*18....\.nc/d' $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/wget.CMIP5.$realm.$experiment.mon.$variable.sh
	# count the new number of files to download 
		new_file_count=$(sed -n '/download_files="$(cat <<EOF--dataset.file.url.chksum_type.chksum/,/EOF--dataset.file.url.chksum_type.chksum/ p' $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/wget.CMIP5.$realm.$experiment.mon.$variable.sh | wc -l)
	# remove spaces in front of the number
		new_file_count=$(sed -e 's/^[[:space:]]*//' <<<"$new_file_count")
	# replace number of files in wget scrip 
		sed -i '' "s/^Script created for.*/Script created for $new_file_count file(s)/" $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/wget.CMIP5.$realm.$experiment.mon.$variable.sh

	elif [[ $OSTYPE == "linux-gnu" ]]; then	
		sed -i '/.*19[0-7][0-9]..\.nc/d;/.*18....\.nc/d' $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/wget.CMIP5.$realm.$experiment.mon.$variable.sh
	# count the new number of files to download 
		new_file_count=$(sed -n '/download_files="$(cat <<EOF--dataset.file.url.chksum_type.chksum/,/EOF--dataset.file.url.chksum_type.chksum/ p' $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/wget.CMIP5.$realm.$experiment.mon.$variable.sh | wc -l)
	# remove spaces in front of the number
		new_file_count=$(sed -e 's/^[[:space:]]*//' <<<"$new_file_count")
	# replace number of files in wget scrip 
		sed -i "s/^Script created for.*/Script created for $new_file_count file(s)/" $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/wget.CMIP5.$realm.$experiment.mon.$variable.sh
	fi		
fi
##########################################################################################

	chmod u+x $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/wget.CMIP5.$realm.$experiment.mon.$variable.sh
fi
	
##########################################################################################

if [ $actid -eq 2 ];then # download data
	
	cd $CMIP_dir/data/CMIP5/$experiment/$realm/$variable
	./wget.CMIP5.$realm.$experiment.mon.$variable.sh

	find . -size 0 -type f -delete # remove empty downloads (failed downloads)
	
	files_expected=$(awk '/Script created for / {print $4}' wget.CMIP5.$realm.$experiment.mon.$variable.sh)
	files_downloaded=$(find . -maxdepth 1 -type f -name '*.nc' -print| wc -l)
	
	echo $files_downloaded of $files_expected were downloaded
	
	if [ $files_expected == $files_downloaded ]; then 
		echo all files have been downloaded; 
	else 
		echo not all files have been downloaded;  
	fi

fi

##########################################################################################

if [ $actid -eq 3 ];then # sort model data into individual directories
	
	cd $CMIP_dir/data/CMIP5/$experiment/$realm/$variable
	
	length_beginning=$(expr ${#realm} + ${#variable} + 2)     # calculate characters in front of model name
	
	for fileid in *.nc; do                                    # loop over each .nc file

		file_name=`ls *.nc |tail -n1`                         # read first file
		model_temp=${file_name%%\_$experiment*}               # cut off string after model name
		model=${model_temp:$length_beginning}                 # cut off string in front of model name 

        mkdir -p $model       
		mv $file_name $model;                                 # move file to respective folder
		
	done
	
fi

##########################################################################################
    
if [ $actid -eq 4 ];then # process data with cdo 

    cd $CMIP_dir/data/CMIP5/$experiment/$realm/$variable       
	
    mkdir -p $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/original_resolution
    mkdir -p $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_monthly_mean
	mkdir -p $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_annual_mean
    mkdir -p $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_decadal_mean
    mkdir -p $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_decadal_running_mean
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/original_resolution/*      # remove old data
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}/*       # remove old data
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_monthly_mean/*       # remove old data
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_annual_mean/*       # remove old data
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_decadal_mean/*       # remove old data
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_decadal_running_mean/*       # remove old data
	
	
	
	model_array=( $(find . -type d -maxdepth 1 -exec printf "{} " \;) )		# create array containing all model names

	for index in ${!model_array[*]}; do                                                                                                        
        models[index]=${model_array[index]#./}								# remove "./" from the model names      
	done
	
	loop_length=$(expr ${#models[*]} - 1)									

	while [[ $((++i)) -le ${loop_length} ]]; do                            # loop over all folders
    	cd ${models[i]}
        echo 'processing ' ${models[i]}
        file=`ls *.nc |tail -n1`                                           
		last_model_year=`echo $file | rev | cut -c 6-9 | rev`              # find last model year
		file_1=`ls *.nc |head -n1`
		first_model_year=`echo $file_1 | rev | cut -c 13-16 | rev`         # find first model year
        model=${PWD##*/}

        if [ -d processed ]; then rm -r processed; fi 			           # remove old data
        mkdir processed
		
		count=$(find . -maxdepth 1 -name '*.nc' | wc -l)                   # check whether model data is split into multiple files
		
		# if there is only 1 file, then link it to the processed folder
		if [ $count -eq 1 ]; then
			ln *.nc processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
		# else merge individual files together 
		else
			cdo mergetime *.nc processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
			cp -p processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/original_resolution/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${first_model_year}-${last_model_year}_original_resolution.nc
		fi
		
		cd processed
	
		# further proceeding is dependent of the variable
        case $variable in 
            msftmyz) # MOC streamfunction -> no vertical interpolation between model grids
				if [ $first_model_year -le ${start_period} ]; then
 				    cdo  -selyear,${start_period}/${end_period} -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}.nc
				fi
				
				rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
				
                ;;
            zosga|zossga|zostoga) # global average times eries of sea level change -> no remapping needed 
            	if [ $first_model_year -le 1861 ]; then
				    cdo selyear,1861/2005 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_1861-2005.nc
				    rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc			
				fi
                ;;
            *)
            	ensemble_mean_flag=1 # calculate a multi model ensemble mean in the end
            
            	if [ "$variable" == "psl" ]; then # divide pressure values by 100 (Pa -> hPa)    	 
            	    mv ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
            	    cdo divc,100 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
            	    rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc         	
            	fi
            	
            	if [ "$variable" == "tas" ] || [ "$variable" == "ta" ]; then # convert °K to °C
            	    mv ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
            	    cdo -chunit,K,°C -addc,-273.15 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
            	    rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
			    fi
            	
            	if [ "$variable" == "pr" ]; then # convert to mm/day
            	    mv ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
            	    cdo mulc,86400 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
            	    rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
            	fi
            	
            	if [ "$model" != "GFDL-CM2p1" ] && [ "$variable" == "tos" ]; then # convert all to °C, except GFDL-CM2p1  model (already has °C unit)
					mv ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
            	    cdo -chunit,K,C -addc,-273.15 -setctomiss,0 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
            	    rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
            	fi
				# process model data only if it starts before selected period and is not a 4D-variable
            	if [ $first_model_year -le ${start_period} ] && ( [ "$variable" != "zg" ]  ||  [ "$variable" != "ta" ] || \
					[ "$variable" != "ua" ] || [ "$variable" != "va" ] ); then 
					# remap model field to observational data set for comparability; also cut time period selected in the beginning (period)
					cdo -${remap},${remap_reference} -selyear,${start_period}/${end_period} -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc
           			cdo yearmean ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_annual_mean.nc
					cdo runmean,10 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_annual_mean.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_decadal_running_mean.nc
					# calculate non-overlapping decadal means and skip first 9 years since time series starts at 851 (incomplete decade)
					cdo timselmean,10,9 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_annual_mean.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_decadal_mean.nc
				fi
				
           		rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc # delete temporal data
            esac
		
		cd ../..
		# if model data got processed, move it from data to processed directory
		if [ -f $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/$model/processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc ]; then 
			mv ${model}/processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_monthly_mean
			mv ${model}/processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_annual_mean.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_annual_mean
			mv ${model}/processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_decadal_running_mean.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_decadal_running_mean
			mv ${model}/processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_decadal_mean.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_decadal_mean
		fi
		rm -r ${model}/processed
		# remove the individual model folders -> change to file list as obtained by the wget script
		mv $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/$model/*.nc $CMIP_dir/data/CMIP5/$experiment/$realm/$variable
		rm -r $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/$model/
		cd $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/original_resolution
		# if original data consists only of 1 file (1850-2005), create relative symbolic link to it in the original resolution folder to save disk space
		if [ $count -eq 1 ]; then
			ln -s $(ls ../../../../../../data/CMIP5/$experiment/$realm/$variable/*${model}*.nc) $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/original_resolution/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${first_model_year}-${last_model_year}_original_resolution.nc	
	    fi
		cd $CMIP_dir/data/CMIP5/$experiment/$realm/$variable
		unset models[i]		
	done
	
	unset i
	
	if [ ${ensemble_mean_flag} -eq 1 ]; then # remove old ensemble mean and calculate new one
		
		dir_list="monthly_mean annual_mean decadal_mean decadal_running_mean"
		
		for dir in $dir_list; do
	    	cd $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_${dir}/
	    	rm -f ${variable}*mmm*${period}*${res}*
			
			if [ "$dir" == "monthly_mean" ]; then
				cdo ensmean $(ls ${variable}*${period}*${res}*) ${variable}_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc
			else
				cdo ensmean $(ls ${variable}*${period}*${res}*) ${variable}_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_${dir}.nc
			fi
		done
	fi	
fi

##########################################################################################
    
if [ $actid -eq 5 ];then # calculate spatial means and anomalies for past1000 experiment
	
    cd ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/
	
	mean_list="annual_mean annual_mean_detrended decadal_mean decadal_mean_detrended decadal_running_mean decadal_running_mean_detrended"
	
	for mean in ${mean_list}; do	
		mkdir -p global_mean_${mean}
		mkdir -p global_mean_anomaly_${mean}
		mkdir -p NH_mean_${mean}
		mkdir -p NH_mean_anomaly_${mean}
		mkdir -p MCA_anomaly_${mean}
		mkdir -p LIA_anomaly_${mean}
		
		cd remapped_to_${res}_${mean}
	
		for model_file in *${remap}_${res}_${mean}.nc; do 
			model_name=$(echo "${model_file}" | cut -d'_' -f3)
			j=`echo ${model_file} | sed 's/.nc/_MCA_anomaly.nc/'`
			k=`echo ${model_file} | sed 's/.nc/_LIA_anomaly.nc/'`
			# again calculate anomalies and anomaly-climatologies
			cdo fldmean ${model_file} ../global_mean_${mean}/${variable}_global_mean_${start_period}-${end_period}_${model_name}_${remap}_${res}_${mean}.nc
			cdo fldmean -sellonlatbox,-180,180,0,90 ${model_file} ../NH_mean_${mean}/${variable}_NH_mean_${start_period}-${end_period}_${model_name}_${remap}_${res}_${mean}.nc
			cdo sub ../global_mean_${mean}/${variable}_global_mean_${start_period}-${end_period}_${model_name}_${remap}_${res}_${mean}.nc -timmean ../global_mean_${mean}/${variable}_global_mean_${start_period}-${end_period}_${model_name}_${remap}_${res}_${mean}.nc ../global_mean_anomaly_${mean}/${variable}_global_mean_anomaly_${start_period}-${end_period}_${model_name}_${remap}_${res}_${mean}.nc
			cdo sub ../NH_mean_${mean}/${variable}_NH_mean_${start_period}-${end_period}_${model_name}_${remap}_${res}_${mean}.nc -timmean ../NH_mean_${mean}/${variable}_NH_mean_${start_period}-${end_period}_${model_name}_${remap}_${res}_${mean}.nc ../NH_mean_anomaly_${mean}/${variable}_NH_mean_anomaly_${start_period}-${end_period}_${model_name}_${remap}_${res}_${mean}.nc
			cdo timmean -selyear,950/1250 -sub ${model_file} -timmean ${model_file} ../MCA_anomaly_${mean}/$j
			cdo timmean -selyear,1400/1700 -sub ${model_file} -timmean ${model_file} ../LIA_anomaly_${mean}/$k
	
		done
		cd ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/
	done
fi

##########################################################################################
    
if [ $actid -eq 6 ];then # calculate corresponding piControl time series
	
    cd ${CMIP_dir}/processed/CMIP5/piControl/$realm/$variable/
    mkdir -p remapped_to_${res}_monthly_mean
	mkdir -p remapped_to_${res}_annual_mean
    mkdir -p remapped_to_${res}_decadal_mean
    mkdir -p remapped_to_${res}_decadal_running_mean
    mkdir -p remapped_to_${res}_decadal_running_mean_detrended
	
	
	
	cd ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/
	cd remapped_to_${res}_decadal_mean
	
	for i in *${remap}_${res}_decadal_mean.nc; do
		if [ "$i" != "tas_Amon_mmm_past1000_CMIP5_r1i1p1_0851-1849_remapbil_HadCRUT4_decadal_mean.nc" ]; then
			j=`echo $i | sed 's/_past1000/_piControl/;s/_CMIP5_r1i1p1_0851-1849_remapbil_HadCRUT4_decadal_mean.nc//'`
			cp ${CMIP_dir}/processed/CMIP5/piControl/$realm/$variable/remapped_to_HadCRUT4/$j* ${CMIP_dir}/processed/CMIP5/piControl/$realm/$variable/remapped_to_${res}_monthly_mean
		fi
	done
	
	cd ${CMIP_dir}/processed/CMIP5/piControl/$realm/$variable/remapped_to_${res}_monthly_mean
	
	for i in *.nc; do
		j=`echo $i | sed 's/_HadCRUT4.nc/_HadCRUT4_annual_mean.nc/'`
		k=`echo $i | sed 's/_HadCRUT4.nc/_HadCRUT4_decadal_mean.nc/'`
		l=`echo $i | sed 's/_HadCRUT4.nc/_HadCRUT4_decadal_running_mean.nc/'`
		m=`echo $i | sed 's/_HadCRUT4.nc/_HadCRUT4_annual_mean_detrended.nc/'`
		n=`echo $i | sed 's/_HadCRUT4.nc/_HadCRUT4_decadal_running_mean_detrended.nc/'`
		
		
		cdo yearmean $i ../remapped_to_${res}_annual_mean/$j
		cdo timselmean,10,9 ../remapped_to_${res}_annual_mean/$j ../remapped_to_${res}_decadal_mean/$k
		cdo runmean,10 ../remapped_to_${res}_annual_mean/$j ../remapped_to_${res}_decadal_running_mean/$l
		cdo runmean,10 ../remapped_to_${res}_annual_mean_detrended/$m ../remapped_to_${res}_decadal_running_mean_detrended/$n
		
	done
		
    cd ${CMIP_dir}/processed/CMIP5/piControl/$realm/$variable/
	
	mean_list="annual_mean annual_mean_detrended decadal_mean decadal_running_mean decadal_running_mean_detrended"
	
	for mean in ${mean_list}; do	
		mkdir -p global_mean_${mean}
		mkdir -p global_mean_anomaly_${mean}
		mkdir -p NH_mean_${mean}
		mkdir -p NH_mean_anomaly_${mean}
		cd remapped_to_${res}_${mean}
	
		for model_file in *${remap}_${res}_${mean}.nc; do 
			model_name=$(echo "${model_file}" | cut -d'_' -f3)
			# again calculate anomalies and anomaly-climatologies
			cdo -r fldmean ${model_file} ../global_mean_${mean}/${variable}_global_mean_${model_name}_${remap}_${res}_${mean}.nc
			cdo -r fldmean -sellonlatbox,-180,180,0,90 ${model_file} ../NH_mean_${mean}/${variable}_NH_mean_${model_name}_${remap}_${res}_${mean}.nc
			cdo -r sub ../global_mean_${mean}/${variable}_global_mean_${model_name}_${remap}_${res}_${mean}.nc -timmean ../global_mean_${mean}/${variable}_global_mean_${model_name}_${remap}_${res}_${mean}.nc ../global_mean_anomaly_${mean}/${variable}_global_mean_anomaly_${model_name}_${remap}_${res}_${mean}.nc
			cdo -r sub ../NH_mean_${mean}/${variable}_NH_mean_${model_name}_${remap}_${res}_${mean}.nc -timmean ../NH_mean_${mean}/${variable}_NH_mean_${model_name}_${remap}_${res}_${mean}.nc ../NH_mean_anomaly_${mean}/${variable}_NH_mean_anomaly_${model_name}_${remap}_${res}_${mean}.nc
		done
		cd ${CMIP_dir}/processed/CMIP5/piControl/$realm/$variable/
	done	
	
fi

##########################################################################################
    
if [ $actid -eq 7 ];then # ccalculate model drift from piControl and detrend the simulations
	
    cd ${CMIP_dir}/processed/CMIP5/piControl/$realm/$variable/
    mkdir -p trends
	mkdir -p offsets
	
	cd remapped_to_${res}_annual_mean
	
	for i in *${remap}_${res}_annual_mean.nc; do
		j=`echo $i | sed 's/annual_mean/offset/'`
		k=`echo $i | sed 's/annual_mean/annual_trend/'`
		l=`echo $i | sed 's/annual_mean/annual_mean_detrended/'`

		cdo trend $i ../offsets/$j.tmp ../trends/$k
		cdo setmisstoc,0 -setrtomiss,-9999,9999 ../offsets/$j.tmp ../offsets/$j
		rm ../offsets/$j.tmp
		cdo subtrend $i ../offsets/$j ../trends/$k ../remapped_to_${res}_annual_mean_detrended/$l
	done		
	
fi

##########################################################################################
    
if [ $actid -eq 8 ];then # detrend the past1000 simulations with piControl trends
	
    cd ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/
	mkdir -p remapped_to_${res}_annual_mean_detrended
	mkdir -p remapped_to_${res}_decadal_mean_detrended
	mkdir -p remapped_to_${res}_decadal_running_mean_detrended
	cd remapped_to_${res}_annual_mean
	
	for i in *${remap}_${res}_annual_mean.nc; do
		if [ "$i" != "tas_Amon_mmm_past1000_CMIP5_r1i1p1_0851-1849_remapbil_HadCRUT4_annual_mean.nc" ]; then
			j=`echo $i | sed 's/_past1000/_piControl/;s/_CMIP5_r1i1p1_0851-1849_remapbil_HadCRUT4_annual_mean.nc//'`
			k=$(ls ${CMIP_dir}/processed/CMIP5/piControl/$realm/$variable/offsets/$j*)
			l=$(ls ${CMIP_dir}/processed/CMIP5/piControl/$realm/$variable/trends/$j*)
			m=`echo $i | sed 's/annual_mean/annual_mean_detrended/'`
			
			cdo subtrend $i $k $l ../remapped_to_${res}_annual_mean_detrended/$m
			rm -f ../remapped_to_${res}_annual_mean_detrended/*mmm*
			cdo ensmean ../remapped_to_${res}_annual_mean_detrended/*.nc ../remapped_to_${res}_annual_mean_detrended/tas_Amon_mmm_past1000_CMIP5_r1i1p1_0851-1849_remapbil_HadCRUT4_annual_mean_detrended.nc
		fi
	done
	
	cd 	../remapped_to_${res}_annual_mean_detrended
	
	for i in *${remap}_${res}_annual_mean_detrended.nc; do
		j=`echo $i | sed 's/annual/decadal_running/'`
		k=`echo $i | sed 's/annual/decadal/'`
		cdo runmean,10 $i ../remapped_to_${res}_decadal_running_mean_detrended/$j
		cdo timselmean,10,9 $i ../remapped_to_${res}_decadal_mean_detrended/$k
	done
	
	
fi


##########################################################################################

if [ $actid -eq 9 ];then # convert Mann et al data set from ascii to netcdf
	
	#ncl $CMIP_dir/CMIP_scripts/ncl/convert_mann_et_al.ncl
	
	cd $CMIP_dir/data/observations/Mann_et_al_2009
	cdo setctomiss,1e36 mann2009_reconstruction_0851-2000.nc mann2009_reconstruction_0851-2000.tmp.nc
	rm mann2009_reconstruction_0851-2000.nc
	mv mann2009_reconstruction_0851-2000.tmp.nc mann2009_reconstruction_0851-2000.nc
	cdo selyear,851/1849 mann2009_reconstruction_0851-2000.nc mann2009_reconstruction_0851-1849.nc
	cdo selyear,856/1845 mann2009_reconstruction_0851-2000.nc mann2009_reconstruction_0856-1845_decadal_mean.nc
	cdo timselmean,1,13,9 mann2009_reconstruction_0851-1849.nc mann2009_reconstruction_0851-1849_decadal_mean.nc
	cdo fldmean mann2009_reconstruction_0851-1849_decadal_mean.nc mann2009_reconstruction_global_mean_0851-1849_decadal_mean.nc
	cdo fldmean mann2009_reconstruction_0856-1845_decadal_mean.nc mann2009_reconstruction_global_mean_0856-1845_decadal_running_mean.nc
	cdo fldmean -sellonlatbox,-180,180,0,90 mann2009_reconstruction_0851-1849_decadal_mean.nc mann2009_reconstruction_NH_mean_0851-1849_decadal_mean.nc
	cdo fldmean -sellonlatbox,-180,180,0,90 mann2009_reconstruction_0856-1845_decadal_mean.nc mann2009_reconstruction_NH_mean_0856-1845_decadal_running_mean.nc
	cdo sub mann2009_reconstruction_global_mean_0851-1849_decadal_mean.nc -timmean mann2009_reconstruction_global_mean_0851-1849_decadal_mean.nc mann2009_reconstruction_global_mean_anomaly_0851-1849_decadal_mean.nc
	cdo sub mann2009_reconstruction_global_mean_0856-1845_decadal_running_mean.nc -timmean mann2009_reconstruction_global_mean_0856-1845_decadal_running_mean.nc mann2009_reconstruction_global_mean_anomaly_0856-1845_decadal_running_mean.nc
	cdo sub mann2009_reconstruction_NH_mean_0851-1849_decadal_mean.nc -timmean mann2009_reconstruction_NH_mean_0851-1849_decadal_mean.nc mann2009_reconstruction_NH_mean_anomaly_0851-1849_decadal_mean.nc
	cdo sub mann2009_reconstruction_NH_mean_0856-1845_decadal_running_mean.nc -timmean mann2009_reconstruction_NH_mean_0856-1845_decadal_running_mean.nc mann2009_reconstruction_NH_mean_anomaly_0856-1845_decadal_running_mean.nc
	
		
fi

##########################################################################################

if [ $actid -eq 10 ];then # calculate zonal means for Hovmöller diagrams
		
	mean_list="annual_mean annual_mean_detrended decadal_mean decadal_mean_detrended decadal_running_mean decadal_running_mean"
		
	for i in ${mean_list}; do	
		cd ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/	
		mkdir -p zonal_mean_${i}
		mkdir -p zonal_mean_anomaly_${i}
		cd remapped_to_${res}_${i}		
		for j in *.nc; do
			k=`echo $j | sed "s/${i}/${i}_zonal_mean/"`
			l=`echo $j | sed "s/${i}/${i}_zonal_mean_anomaly/"`
			#m=`echo $i | sed 's/.nc/_zonal_mean_anomaly_gm_subtracted.nc/'`
		
			cdo -r zonmean $j ../zonal_mean_${i}/$k
			cdo -r sub ../zonal_mean_${i}/$k -timmean ../zonal_mean_${i}/$k ../zonal_mean_anomaly_${i}/$l
		done
	done
		
		cd ${CMIP_dir}/data/observations/Mann_et_al_2009
		cdo -r zonmean mann2009_reconstruction_0851-1849_decadal_mean.nc mann2009_reconstruction_0851-1849_decadal_mean_zonal_mean.nc
		cdo -r sub mann2009_reconstruction_0851-1849_decadal_mean_zonal_mean.nc -timmean mann2009_reconstruction_0851-1849_decadal_mean_zonal_mean.nc mann2009_reconstruction_0851-1849_decadal_mean_zonal_mean_anomaly.nc
fi

##########################################################################################

done
done                                                                                         
