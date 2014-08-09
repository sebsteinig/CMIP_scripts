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
    CMIP_dir="/Volumes/HiWi_data/CMIP"
    echo "user: stein"
elif [ $(whoami) = "smomw200" ]; then
    CMIP_dir="/gfs/scratch/smomw200/CMIP"
    echo "user: smomw200"
    module load cdo
fi
	
##########################################################################################

experiment="past1000"				# CMIP5 experiments: historical,rcp45
var="tas"				# CMIP variable to process (e.g. tos,tas,pr,psl,...)
#var="tos"									# for full list see: http://cmip-pcmdi.llnl.gov/cmip5/docs/standard_output.pdf
observations="NCEP"					# HadISST HadSST3 CMAP GPCP HadSLP2 MLD ERSST HadCRUT4 CERES_EBAF NCEP
period=0851-1849					# time period for which the data gets processed
climatology_period=0851-1849
res=HadCRUT4						# HadCRUT4, ERSST
remap=remapbil
actions="3 4" 						# choose which sections of the script get executed; see list above

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
            tas|ta|psl|pr|rsut|rsutcs|rlut|rlutcs|ua|va|zg)
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
    mkdir -p $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/original_resolution/*      # remove old data
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}/*       # remove old data
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_monthly_mean/*       # remove old data
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_annual_mean/*       # remove old data
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_decadal_mean/*       # remove old data
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies/*       # remove old data
	
	
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
				
				# remap to T42 grid and calculate ${start_climatology}-${end_climatology} climatologies, according to the PCMDI metrics (see IPCC, figure 9.7)
				if [ "$variable" == "zg" ]; then
					# don't calculate ensemble mean for 4D variable, since they don't get processed (see below)
					ensemble_mean_flag=0
					# only consider geopotential height at 500 hPa
					cdo -${remap},t42grid -ymonmean -selyear,${start_climatology}/${end_climatology} -sellevel,50000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies/${variable}_500_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc
				elif [ "$variable" == "ua" ] || [ "$variable" == "va" ] || [ "$variable" == "ta" ]; then 
					# don't calculate ensemble mean for 4D variable, since they don't get processed (see below
					ensemble_mean_flag=0
					# only consider values at 200 and 850 hPa
					cdo -${remap},t42grid -ymonmean -selyear,${start_climatology}/${end_climatology} -sellevel,85000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies/${variable}_850_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc
					cdo -${remap},t42grid -ymonmean -selyear,${start_climatology}/${end_climatology} -sellevel,20000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies/${variable}_200_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc
				else
					cdo -${remap},t42grid -ymonmean -selyear,${start_climatology}/${end_climatology} -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc
				fi			
            	
				# process model data only if it starts before selected period and is not a 4D-variable
            	if [ $first_model_year -le ${start_period} ] && ( [ "$variable" != "zg" ]  ||  [ "$variable" != "ta" ] || \
					[ "$variable" != "ua" ] || [ "$variable" != "va" ] ); then 
					# remap model field to observational data set for comparability; also cut time period selected in the beginning (period)
					cdo -${remap},${remap_reference} -selyear,${start_period}/${end_period} -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc
           			cdo yearmean ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_annual_mean.nc
					cdo runmean,10 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_annual_mean.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_decadal_mean.nc
				fi
				
           		rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc # delete temporal data
            esac
		
		cd ../..
		# if model data got processed, move it from data to processed directory
		if [ -f $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/$model/processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}:monthly_mean.nc ]; then 
			mv ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_monthly_mean.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_monthly_mean
			mv ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_annual_mean.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_annual_mean
			mv ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}_decadal_mean.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}_decadal_mean
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
	    cd $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}/
	    rm -f ${variable}*mmm*${period}*${res}*
		# HadGEM models get excluded, since they only provide data until 200511 -> different number of timesteps than other models
	    if [ "$variable" == "rlutcs" ] || [ "$variable" == "rsutcs" ] || [ "$variable" == "rsut" ] || [ "$variable" == "rlut" ]; then
			cdo ensmean $(ls ${variable}*${period}*${res}* |grep -vi "HadGEM" |grep -vi "CMCC-CESM" |grep -vi "CMCC-CM") ${variable}_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc
		else
			cdo ensmean $(ls ${variable}*${period}*${res}* |grep -vi "HadGEM") ${variable}_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc
		fi
		cd $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies
		rm -f ${variable}*mmm*${start_climatology}-${end_climatology}*
		if [ "$variable" == "zg" ]; then 
			cdo ensmean ${variable}*500*${start_climatology}-${end_climatology}*T42* ${variable}_500_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
		elif [ "$variable" == "ua" ] || [ "$variable" == "va" ] || [ "$variable" == "ta" ]; then 
			cdo ensmean ${variable}*850*${start_climatology}-${end_climatology}*T42* ${variable}_850_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
			cdo ensmean ${variable}*200*${start_climatology}-${end_climatology}*T42* ${variable}_200_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
		else
			cdo ensmean ${variable}*${start_climatology}-${end_climatology}*T42* ${variable}_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
		fi
		
	fi
		
    # calculate shortwave cloud radiative feedback fields if data for clear-sky and all-sky SW radiation is available
	if [ -d $CMIP_dir/processed/CMIP5/$experiment/Amon/rsut/climatologies ] && [ -d $CMIP_dir/processed/CMIP5/$experiment/Amon/rsutcs/climatologies ] && ( [ "$variable" == "rsut" ] || [ "$variable" == "rsutcs" ] ); then 		
	    # create folders for new sw_cre variable or delete old data
	    mkdir -p $CMIP_dir/processed/CMIP5/$experiment/Amon/sw_cre/climatologies
		mkdir -p $CMIP_dir/processed/CMIP5/$experiment/Amon/sw_cre/original_resolution
		mkdir -p $CMIP_dir/processed/CMIP5/$experiment/Amon/sw_cre/remapped_to_${res}	
		rm -f $CMIP_dir/processed/CMIP5/$experiment/Amon/sw_cre/climatologies/*
		rm -f $CMIP_dir/processed/CMIP5/$experiment/Amon/sw_cre/original_resolution/*
		rm -f $CMIP_dir/processed/CMIP5/$experiment/Amon/sw_cre/remapped_to_${res}/*
	
	    # go the climatologies and subtract rsut from rsutcs for each model
		cd $CMIP_dir/processed/CMIP5/$experiment/Amon/rsutcs/climatologies		
		for i in *${start_climatology}-${end_climatology}*.nc; do
			j=`echo $i | sed 's/rsutcs/rsut/'`
			k=`echo $i | sed 's/rsutcs/sw_cre/'`
			cdo -chname,rsutcs,sw_cre -sub $i $CMIP_dir/processed/CMIP5/$experiment/Amon/rsut/climatologies/$j $CMIP_dir/processed/CMIP5/$experiment/Amon/sw_cre/climatologies/$k
		done
	
	    # do the same for the fields with original resolution
		cd $CMIP_dir/processed/CMIP5/$experiment/Amon/rsutcs/original_resolution		
		for i in *.nc; do
			j=`echo $i | sed 's/rsutcs/rsut/'`
			k=`echo $i | sed 's/rsutcs/sw_cre/'`
			cdo -chname,rsutcs,sw_cre -sub $i $CMIP_dir/processed/CMIP5/$experiment/Amon/rsut/original_resolution/$j $CMIP_dir/processed/CMIP5/$experiment/Amon/sw_cre/original_resolution/$k
		done
	
	    # do the same for the remapped fields
		cd $CMIP_dir/processed/CMIP5/$experiment/Amon/rsutcs/remapped_to_${res}		
		for i in *${period}*.nc; do
			j=`echo $i | sed 's/rsutcs/rsut/'`
			k=`echo $i | sed 's/rsutcs/sw_cre/'`
			cdo -chname,rsutcs,sw_cre -sub $i $CMIP_dir/processed/CMIP5/$experiment/Amon/rsut/remapped_to_${res}/$j $CMIP_dir/processed/CMIP5/$experiment/Amon/sw_cre/remapped_to_${res}/$k
		done
	
	    # calculate ensemble mean for the climatologies
		cd $CMIP_dir/processed/CMIP5/$experiment/Amon/sw_cre/climatologies/
		rm -f *mmm*${start_climatology}-${end_climatology}*		
		cdo ensmean *${start_climatology}-${end_climatology}*T42* sw_cre_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
	
	    # calculate ensemble mean for the remapped fields
		cd $CMIP_dir/processed/CMIP5/$experiment/Amon/sw_cre/remapped_to_${res}/
		rm -f *mmm*${period}*		
		cdo ensmean *${period}*${res}* sw_cre_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc	
    fi	
		
    # do the same as above, but for the long wave cloud radiative effect
	if [ -d $CMIP_dir/processed/CMIP5/$experiment/Amon/rlut/climatologies ] && [ -d $CMIP_dir/processed/CMIP5/$experiment/Amon/rlutcs/climatologies ] && ( [ "$variable" == "rlut" ] || [ "$variable" == "rlutcs" ] ); then 	
	    # create folders for new sw_cre variable or delete old data
	    mkdir -p $CMIP_dir/processed/CMIP5/$experiment/Amon/lw_cre/climatologies
		mkdir -p $CMIP_dir/processed/CMIP5/$experiment/Amon/lw_cre/original_resolution
		mkdir -p $CMIP_dir/processed/CMIP5/$experiment/Amon/lw_cre/remapped_to_${res}	
		rm -f $CMIP_dir/processed/CMIP5/$experiment/Amon/lw_cre/climatologies/*
		rm -f $CMIP_dir/processed/CMIP5/$experiment/Amon/lw_cre/original_resolution/*
		rm -f $CMIP_dir/processed/CMIP5/$experiment/Amon/lw_cre/remapped_to_${res}/*
	
	    # go the climatologies and subtract rlut from rlutcs for each model
		cd $CMIP_dir/processed/CMIP5/$experiment/Amon/rlutcs/climatologies		
		for i in *${start_climatology}-${end_climatology}*.nc; do
			j=`echo $i | sed 's/rlutcs/rlut/'`
			k=`echo $i | sed 's/rlutcs/lw_cre/'`
			cdo -chname,rlutcs,lw_cre -sub $i $CMIP_dir/processed/CMIP5/$experiment/Amon/rlut/climatologies/$j $CMIP_dir/processed/CMIP5/$experiment/Amon/lw_cre/climatologies/$k
		done
	
	    # do the same for the fields with original resolution
		cd $CMIP_dir/processed/CMIP5/$experiment/Amon/rlutcs/original_resolution		
		for i in *.nc; do
			j=`echo $i | sed 's/rlutcs/rlut/'`
			k=`echo $i | sed 's/rlutcs/lw_cre/'`
			cdo -chname,rlutcs,lw_cre -sub $i $CMIP_dir/processed/CMIP5/$experiment/Amon/rlut/original_resolution/$j $CMIP_dir/processed/CMIP5/$experiment/Amon/lw_cre/original_resolution/$k
		done
	
	    # do the same for the remapped fields
		cd $CMIP_dir/processed/CMIP5/$experiment/Amon/rlutcs/remapped_to_${res}		
		for i in *${period}*.nc; do
			j=`echo $i | sed 's/rlutcs/rlut/'`
			k=`echo $i | sed 's/rlutcs/lw_cre/'`
			cdo -chname,rlutcs,lw_cre -sub $i $CMIP_dir/processed/CMIP5/$experiment/Amon/rlut/remapped_to_${res}/$j $CMIP_dir/processed/CMIP5/$experiment/Amon/lw_cre/remapped_to_${res}/$k
		done
	
	    # calculate ensemble mean for the climatologies
		cd $CMIP_dir/processed/CMIP5/$experiment/Amon/lw_cre/climatologies/
		rm -f *mmm*${start_climatology}-${end_climatology}*		
		cdo ensmean *${start_climatology}-${end_climatology}*T42* lw_cre_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_climatology}-${end_climatology}_clim_${remap}_T42.nc	
	
	    # calculate ensemble mean for the remapped fields
		cd $CMIP_dir/processed/CMIP5/$experiment/Amon/lw_cre/remapped_to_${res}/
		rm -f *mmm*${period}*		
		cdo ensmean *${period}*${res}* lw_cre_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_period}-${end_period}_${remap}_${res}.nc	
    fi

fi

##########################################################################################
    
if [ $actid -eq 5 ];then # calculate global means and correlations
	
	unset start_period end_period

	period_new=${period:1:9}					# time period for which the data gets processed	
	start_period=${period_new:0:3}						# calculate beginning of chosen period 
	end_period=${period_new:4:8}						# calculate end of chosen period 
	
	
	#calculate number of decades in the specified period
    number_of_years=$((end_period - start_period))
    number_of_decades=$((number_of_years/10))

	# check if number of years is a multiple of 10
    if [ $((number_of_decades*10)) == $((number_of_years)) ]; then 
	    echo ${number_of_decades}
	# if it is not evenly dividable by 10 add one decade for the last years 
    else
	    years_last_period=$((number_of_years-(number_of_decades*10)))
	    number_of_decades=$((number_of_decades+1))
	    echo ${number_of_decades}
    fi	

    cd ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/
	mkdir -p global_mean
	mkdir -p global_mean_removed
	#mkdir -p correlations
	mkdir -p trends
	cd remapped_to_${res}
	
	# specifiy observational data set to which the pattern correlation should be calculated
	obs_data="ERSST" # ERSST HadISST

	if [ "$variable" == "tos" ]; then # process tos observations
		# select specified period
		#cdo -selyear,${start_period}/${end_period} -selgrid,1 $CMIP_dir/data/observations/ERSST/ersstv3b.mnmean.nc $CMIP_dir/data/observations/ERSST/ERSST_${start_period}-${end_period}.nc
		# calculate global mean
		#cdo fldmean $CMIP_dir/data/observations/ERSST/ERSST_${start_period}-${end_period}.nc ../global_mean/ERSST_global_mean_${start_period}-${end_period}.nc
		# subtract global mean for each timestep
		#cdo sub $CMIP_dir/data/observations/ERSST/ERSST_${start_period}-${end_period}.nc -enlarge,$CMIP_dir/data/observations/ERSST/ERSST_${start_period}-${end_period}.nc ../global_mean/ERSST_global_mean_${start_period}-${end_period}.nc ../global_mean_removed/ERSST_global_mean_removed_${start_period}-${end_period}.nc
		# calculate climatology of anomaly fields
		#cdo ymonmean ../global_mean_removed/ERSST_global_mean_removed_${start_period}-${end_period}.nc ../global_mean_removed/ERSST_climatology_${start_period}-${end_period}.nc
		
		# repeat the following steps for each decade
		decade=1
		while [ $decade -le ${number_of_decades} ]; do
			echo $decade
			first_year=$((start_period + (decade-1)*10))
			if [ $decade -lt ${number_of_decades} ]; then
				last_year=$((first_year + 9))
			else
				last_year=$((first_year + years_last_period))
			fi
			echo ${first_year}
			echo ${last_year}
		
			for data_set in ${obs_data} ; do	
				if [ $decade -eq 1 ]; then
					# calculate trends of the annual mean fields
					cdo -trend -yearmean -selyear,${first_year}/${end_period} -selvar,sst ../global_mean/${data_set}_global_mean_${start_period}-${end_period}.nc a.nc ../trends/${data_set}_global_mean_decadal_trends_${start_period}-${end_period}.nc
					rm a.nc
				else
					# calculate trends of the annual mean fields
					cdo -trend -yearmean -selyear,${first_year}/${end_period} -selvar,sst ../global_mean/${data_set}_global_mean_${start_period}-${end_period}.nc a.nc ../trends/${data_set}_global_mean_trends_${first_year}-${end_period}.nc
					# starting with the second period, the trends will be added to the above created file to store all decadal values in 1 file
					cdo cat ../trends/${data_set}_global_mean_trends_${first_year}-${end_period}.nc ../trends/${data_set}_global_mean_decadal_trends_${start_period}-${end_period}.nc
					rm a.nc
					rm ../trends/${data_set}_global_mean_trends_${first_year}-${end_period}.nc
				fi	
			done		
			decade=$(( $decade + 1 ))		
		done	
	fi
	
	# in general repeat the above calculations for each model
	for data_set in ${obs_data} ; do
		for model_file in *${remap}_${res}.nc; do 
			model_name=$(echo "${model_file}" | cut -d'_' -f3)
	
			# express tas fields as anomalies to 1961-1990 to compare with HadCRUT4	
			#if [ "$variable" == "tas" ]; then 
				#mv ${model_file} ${model_file}_temp
				#cdo sub ${model_file}_temp -timmean -selyear,1961/1990 ${model_file}_temp ${model_file}	
				#fi
	
			# again calculate anomalies and anomaly-climatologies
			cdo fldmean ${model_file} ../global_mean/${variable}_global_mean_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc
			cdo sub ${model_file} -enlarge,${model_file} ../global_mean/${variable}_global_mean_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc ../global_mean_removed/${variable}_global_mean_removed_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc
			cdo ymonmean ../global_mean_removed/${variable}_global_mean_removed_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc ../global_mean_removed/${variable}_climatology_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc
	
			decade=1
			while [ $decade -le ${number_of_decades} ]; do
				echo $decade
				first_year=$((start_period + (decade-1)*10))
				if [ $decade -lt ${number_of_decades} ]; then
					last_year=$((first_year + 9))
				else
					last_year=$((first_year + years_last_period))
				fi
				echo ${first_year}
				echo ${last_year}
		
				# calculate trends, anomaly patterns for each decade and pattern correlation for different regions
				if [ $decade -eq 1 ]; then
					cdo -trend -yearmean -selyear,${first_year}/${end_period} -selvar,${variable} ../global_mean/${variable}_global_mean_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc a.nc ../trends/${variable}_global_mean_decadal_trends_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc
					rm a.nc
				
					#cdo -timmean -ymonsub -selyear,${first_year}/${last_year} ../global_mean_removed/${data_set}_global_mean_removed_${start_period}-${end_period}.nc ../global_mean_removed/${data_set}_climatology_${start_period}-${end_period}.nc ../global_mean_removed/${data_set}_global_mean_removed_${start_period}-${end_period}_decadal_patterns.nc 
					cdo -timmean -ymonsub -selyear,${first_year}/${last_year} ../global_mean_removed/${variable}_global_mean_removed_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc ../global_mean_removed/${variable}_climatology_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc ../global_mean_removed/${variable}_global_mean_removed_${start_period}-${end_period}_decadal_patterns_${model_name}_${remap}_${res}.nc 
			
					#cdo -f nc -fldcor ../global_mean_removed/${data_set}_global_mean_removed_${start_period}-${end_period}_decadal_patterns.nc ../global_mean_removed/${variable}_global_mean_removed_${start_period}-${end_period}_decadal_patterns_${model_name}_${remap}_${res}.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_period}-${end_period}_${model_name}_${remap}_${res}_90.nc
					#cdo -f nc -fldcor -sellonlatbox,0,360,-70,70 ../global_mean_removed/${data_set}_global_mean_removed_${start_period}-${end_period}_decadal_patterns.nc -sellonlatbox,0,360,-70,70 ../global_mean_removed/${variable}_global_mean_removed_${start_period}-${end_period}_decadal_patterns_${model_name}_${remap}_${res}.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_period}-${end_period}_${model_name}_${remap}_${res}_70.nc
					#cdo -f nc -fldcor -sellonlatbox,0,360,0,90 ../global_mean_removed/${data_set}_global_mean_removed_${start_period}-${end_period}_decadal_patterns.nc -sellonlatbox,0,360,0,90 ../global_mean_removed/${variable}_global_mean_removed_${start_period}-${end_period}_decadal_patterns_${model_name}_${remap}_${res}.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_period}-${end_period}_${model_name}_${remap}_${res}_NH.nc
					#cdo -f nc -fldcor -sellonlatbox,0,360,-90,0 ../global_mean_removed/${data_set}_global_mean_removed_${start_period}-${end_period}_decadal_patterns.nc -sellonlatbox,0,360,-90,0 ../global_mean_removed/${variable}_global_mean_removed_${start_period}-${end_period}_decadal_patterns_${model_name}_${remap}_${res}.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_period}-${end_period}_${model_name}_${remap}_${res}_SH.nc		
				
				# repeat the above steps for the other decades and cat them to the file create for the first decade
				else
					cdo -trend -yearmean -selyear,${first_year}/${end_period} -selvar,${variable} ../global_mean/${variable}_global_mean_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc a.nc ../trends/${variable}_global_mean_trends_${first_year}-${end_period}_${model_name}_${remap}_${res}.nc
									
					#cdo -timmean -ymonsub -selyear,${first_year}/${last_year} ../global_mean_removed/${data_set}_global_mean_removed_${start_period}-${end_period}.nc ../global_mean_removed/${data_set}_climatology_${start_period}-${end_period}.nc ../global_mean_removed/${data_set}_global_mean_removed_${first_year}-${last_year}_decadal_patterns.nc 
					cdo -timmean -ymonsub -selyear,${first_year}/${last_year} ../global_mean_removed/${variable}_global_mean_removed_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc ../global_mean_removed/${variable}_climatology_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc ../global_mean_removed/${variable}_global_mean_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc 
			
					#cdo -f nc -fldcor ../global_mean_removed/${data_set}_global_mean_removed_${first_year}-${last_year}_decadal_patterns.nc ../global_mean_removed/${variable}_global_mean_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_90.nc
					#cdo -f nc -fldcor -sellonlatbox,0,360,-70,70 ../global_mean_removed/${data_set}_global_mean_removed_${first_year}-${last_year}_decadal_patterns.nc -sellonlatbox,0,360,-70,70 ../global_mean_removed/${variable}_global_mean_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_70.nc
					#cdo -f nc -fldcor -sellonlatbox,0,360,-0,90 ../global_mean_removed/${data_set}_global_mean_removed_${first_year}-${last_year}_decadal_patterns.nc -sellonlatbox,0,360,0,90 ../global_mean_removed/${variable}_global_mean_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_NH.nc
					#cdo -f nc -fldcor -sellonlatbox,0,360,-90,0 ../global_mean_removed/${data_set}_global_mean_removed_${first_year}-${last_year}_decadal_patterns.nc -sellonlatbox,0,360,-90,0 ../global_mean_removed/${variable}_global_mean_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_SH.nc

					cdo cat ../trends/${variable}_global_mean_trends_${first_year}-${end_period}_${model_name}_${remap}_${res}.nc ../trends/${variable}_global_mean_decadal_trends_${start_period}-${end_period}_${model_name}_${remap}_${res}.nc
					#cdo cat ../global_mean_removed/${data_set}_global_mean_removed_${first_year}-${last_year}_decadal_patterns.nc ../global_mean_removed/${data_set}_global_mean_removed_${start_period}-${end_period}_decadal_patterns.nc 
					cdo cat ../global_mean_removed/${variable}_global_mean_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc ../global_mean_removed/${variable}_global_mean_removed_${start_period}-${end_period}_decadal_patterns_${model_name}_${remap}_${res}.nc 			
					#cdo cat ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_70.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_period}-${end_period}_${model_name}_${remap}_${res}_70.nc
					#cdo cat ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_90.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_period}-${end_period}_${model_name}_${remap}_${res}_90.nc
					#cdo cat ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_NH.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_period}-${end_period}_${model_name}_${remap}_${res}_NH.nc
					#cdo cat ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_SH.nc ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_period}-${end_period}_${model_name}_${remap}_${res}_SH.nc
					
					# clean up
					rm a.nc
					rm ../trends/${variable}_global_mean_trends_${first_year}-${end_period}_${model_name}_${remap}_${res}.nc
					#rm ../global_mean_removed/${data_set}_global_mean_removed_${first_year}-${last_year}_decadal_patterns.nc 
					rm ../global_mean_removed/${variable}_global_mean_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc 
					#rm ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_70.nc
					#rm ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_90.nc
					#rm ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_NH.nc
					#rm ../correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_SH.nc
				fi	
				decade=$(( $decade + 1 ))	
			done
	
			# undo temporal renaming for tas models
			#if [ "$variable" == "tas" ]; then 	
				#mv ${model_file}_temp ${model_file}		
				#fi	
		done
	done
fi


##########################################################################################

if [ $actid -eq 6 ];then # combine past1000 and historical experiments
	
	cd ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/
    rm -r -d extended_to_2000
	rm -r -d zonal_means
	mkdir -p extended_to_2000
	mkdir -p zonal_means
	cd original_resolution
		
	for i in *.nc; do
		j=`echo $i | sed 's/0850-1850_original_resolution.nc/1850-2005_original_resolution.nc/;s/past1000/historical/'`
		k=`echo $i | sed 's/0850-1850_original_resolution.nc/1850-2000_remapped.nc/;s/past1000/historical/'`
		cdo -r remapbil,${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}/tas_Amon_mmm_past1000_CMIP5_r1i1p1_0851-1849_remapbil_HadCRUT4.nc -chunit,K,°C -addc,-273.15 -selyear,1850/2000 -yearmean ${CMIP_dir}/processed/CMIP5/historical/$realm/$variable/original_resolution/$j ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$k		
	done
	
	cd ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000
	
	rm -f *mmm*
	cdo -r ensmean *remapped.nc tas_Amon_mmm_historical_CMIP5_r1i1p1_1850-2000_remapped.nc
	
	cd ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}
	
	for i in *.nc; do
		j=`echo $i | sed 's/0851-1849/0851-2000/'`
		k=`echo $i | sed 's/past1000/historical/;s/remapbil_HadCRUT4.nc/remapped.nc/;s/0851-1849/1850-2000/'`
		l=`echo $j | sed 's/.nc/_anomaly.nc/'`
		m=`echo $j | sed 's/.nc/_anomaly_gm_removed.nc/'`
		n=`echo $j | sed 's/Amon/global_mean/'`
		o=`echo $l | sed 's/_anomaly.nc/_zonal_mean_anomaly.nc/'`
		p=`echo $m | sed 's/_anomaly_gm_removed.nc/_zonal_mean_anomaly_gm_subtracted.nc/'`
		
		cdo -r -mergetime -yearmean $i ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$k ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$j
		cdo -r -sub ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$j -timmean -selyear,1961/1990 ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$j ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$l
		cdo -r -sub ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$l -enlarge,${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$l -fldmean ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$l ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$m
	    cdo -r -fldmean ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$l ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/global_mean/$n
		cdo -r -zonmean -ymonsub ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$j -ymonmean ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000/$j ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/zonal_means/$o
		cdo -r -sub ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/zonal_means/$o -enlarge,${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/zonal_means/$o -fldmean ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/zonal_means/$o ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/zonal_means/$p

	done
	
	#cd ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/extended_to_2000
		#for i in *0851-2000*HadCRUT4*.nc; do
			#j=`echo $i | sed 's/0851-1849/0851-2000.nc/'`
	
		
fi

##########################################################################################

if [ $actid -eq 7 ];then # calculate zonal means for Hovmöller diagrams
	
	cd ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/
	rm -r -d zonal_means
	mkdir -p zonal_means
	cd remapped_to_${res}
		
	for i in *${period}*${res}.nc; do
		j=`echo $i | sed 's/.nc/_clim_subtracted.nc/'`
		k=`echo $i | sed 's/.nc/_zonal_mean_anomaly.nc/'`
		l=`echo $i | sed 's/.nc/_zonal_mean_anomaly_gm_subtracted.nc/'`
		
		cdo -r -ymonsub $i -ymonmean $i $j
		cdo -r zonmean $j ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/zonal_means/$k 
		cdo -r -sub $i -enlarge,$i -fldmean $i gm_removed_tmp.nc
		cdo -r -ymonsub gm_removed_tmp.nc -ymonmean gm_removed_tmp.nc gm_clim_removed_tmp.nc
		cdo -r zonmean gm_clim_removed_tmp.nc ${CMIP_dir}/processed/CMIP5/$experiment/$realm/$variable/zonal_means/$l
		rm -f *tmp*
	done
	
	rm -f  *subtracted*
fi

##########################################################################################

done
done                                                                                         
