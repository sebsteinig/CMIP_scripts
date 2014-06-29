#!/bin/bash

set -x
set -e
set -a

# This script will do the following actions:
	# 1. create wget script for chosen $var and $experiment
	# 2. download data and check if all files have been downloaded
	# 3. sort model data into individual directories
	# 4. process model data with cdo 
	# 5. create PCMDI climatologies (i.e. 1980-2005 climatologies on T42 grid)
	# 6. download and process observation data
	# 7. process KCM data
	# 8. calculate global means and correlations
	# 9. make plots with ncl
	# 10. make trend plots with ncl
	# 11. make correlation plots with ncl
    # 12. make PCMDI metric plots with ncl
	# 13. rotate plots 90° to the left
	
	
if [ $(whoami) = "stein" ]; then            # check for system/user and adapt CMIP path  
    CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP"
    echo "user: stein"
elif [ $(whoami) = "smomw200" ]; then
    CMIP_dir="/gfs/scratch/smomw200/CMIP"
    echo "user: smomw200"
    module load cdo
fi
	
##########################################################################################

experiment="historical"         # CMIP5 experiments: historical,rcp45; CMIP3 experiments: 20c3m
var="tas"                       # CMIP variable to process (e.g. tos,tas,pr,psl,...)
                                # for full list see: http://cmip-pcmdi.llnl.gov/cmip5/docs/standard_output.pdf
observations="HadCRUT4"         # HadISST HadSST3 CMAP GPCP HadSLP2 MLD ERSST HadCRUT4 CERES_EBAF NCEP
period_1=1870-2005              # time period for which the data gets processed
res=HadCRUT4                    # ERSST, r180x89, r360x180
remap=remapbil
actions="3 4"                     # choose which sections of the script get executed; see list above

##########################################################################################	
# choose plots ( 0 = no / 1 = yes )

plot_seasons=0
plot_means=1
plot_bias_ensemble=0
plot_bias_observations=0
plot_bias_KCM=0
plot_change=0

##########################################################################################

start_1=${period_1:0:4}
end_1=${period_1:5:9}
	
for variable in $var; do		# loop over all chosen variables

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

for actid in $actions ; do		# loop over all chosen actions

##########################################################################################

if [ $actid -eq 1 ];then # create wget script
	
    mkdir -p $CMIP_dir/data/CMIP5/$experiment/$realm/$variable; 

	url="http://esgf-data.dkrz.de/esg-search/wget?&latest=true&replica=false&facets=id&limit=2000&project=CMIP5\
&ensemble=r1i1p1&experiment=$experiment&realm=$cmor_table&time_frequency=mon&cmor_table=$realm&variable=$variable"
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
    mkdir -p $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}
    mkdir -p $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/original_resolution/*      # remove old data
	rm -f $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}/*       # remove old data
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
				if [ $first_model_year -le ${start_1} ]; then
 				    cdo  -selyear,${start_1}/${end_1} -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_1}-${end_1}.nc
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
				
				# remap to T42 grid and calculate 1980-1999 climatologies, according to the PCMDI metrics (see IPCC, figure 9.7)
				if [ "$variable" == "zg" ]; then
					# don't calculate ensemble mean for 4D variable, since they don't get processed (see below)
					ensemble_mean_flag=0
					# only consider geopotential height at 500 hPa
					cdo -${remap},t42grid -ymonmean -selyear,1980/1999 -sellevel,50000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies/${variable}_500_${realm}_${model}_${experiment}_CMIP5_r1i1p1_1980-1999_clim_${remap}_T42.nc
				elif [ "$variable" == "ua" ] || [ "$variable" == "va" ] || [ "$variable" == "ta" ]; then 
					# don't calculate ensemble mean for 4D variable, since they don't get processed (see below
					ensemble_mean_flag=0
					# only consider values at 200 and 850 hPa
					cdo -${remap},t42grid -ymonmean -selyear,1980/1999 -sellevel,85000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies/${variable}_850_${realm}_${model}_${experiment}_CMIP5_r1i1p1_1980-1999_clim_${remap}_T42.nc
					cdo -${remap},t42grid -ymonmean -selyear,1980/1999 -sellevel,20000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies/${variable}_200_${realm}_${model}_${experiment}_CMIP5_r1i1p1_1980-1999_clim_${remap}_T42.nc
				else
					cdo -${remap},t42grid -ymonmean -selyear,1980/1999 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_1980-1999_clim_${remap}_T42.nc
				fi			
            	
				# process model data only if it starts before selected period and is not a 4D-variable
            	if [ $first_model_year -le ${start_1} ] && ( [ "$variable" != "zg" ]  ||  [ "$variable" != "ta" ] || \
					[ "$variable" != "ua" ] || [ "$variable" != "va" ] ); then 
					cdo -${remap},$CMIP_dir/data/observations/${res}/HadCRUT4_1870-2005.nc -selyear,${start_1}/${end_1} -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_1}-${end_1}_${remap}_${res}.nc
           		fi
				
           		rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc # delete temporal data
            esac
		
		cd ../..
		# if model data got processed, move it from data to processed directory
		if [ -f $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/$model/processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${start_1}-${end_1}_${remap}_${res}.nc ]; then 
			mv ${model}/processed/*.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}; 
		fi
		rm -r ${model}/processed
		# remove the individual model folders -> change to file list as obtained by the wget script
		mv $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/$model/*.nc $CMIP_dir/data/CMIP5/$experiment/$realm/$variable
		rm -r $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/$model/
		cd $CMIP_dir/data/CMIP5/$experiment/$realm/$variable
		# if original data consists only of 1 file (1850-2005), create symbolic link to it in the original resolution folder to save disk space
		if [ $count -eq 1 ]; then
			ln -s $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/*${model}*.nc $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/original_resolution/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_${first_model_year}-${last_model_year}_original_resolution.nc
	    fi
		unset models[i]		
	done
	
	if [ ${ensemble_mean_flag} -eq 1 ]; then # remove old ensemble mean and calculate new one
	    cd $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/remapped_to_${res}/
	    rm -f ${variable}*mmm*${period_1}*${res}*
		# HadGEM models get excluded, since they only provide data until 200511 -> different number of timesteps than other models
	    cdo ensmean $(ls ${variable}*${period_1}*${res}* |grep -vi "HadGEM") ${variable}_${realm}_mmm_${experiment}_CMIP5_r1i1p1_${start_1}-${end_1}_${remap}_${res}.nc
		
		cd $CMIP_dir/processed/CMIP5/$experiment/$realm/$variable/climatologies
		rm -f ${variable}*mmm*1980-1999*
		if [ "$variable" == "zg" ]; then 
			cdo ensmean ${variable}*500*1980-1999*T42* ${variable}_500_${realm}_mmm_${experiment}_CMIP5_r1i1p1_1980-1999_clim_${remap}_T42.nc	
		elif [ "$variable" == "ua" ] || [ "$variable" == "va" ] || [ "$variable" == "ta" ]; then 
			cdo ensmean ${variable}*850*1980-1999*T42* ${variable}_850_${realm}_mmm_${experiment}_CMIP5_r1i1p1_1980-1999_clim_${remap}_T42.nc	
			cdo ensmean ${variable}*200*1980-1999*T42* ${variable}_200_${realm}_mmm_${experiment}_CMIP5_r1i1p1_1980-1999_clim_${remap}_T42.nc	
		else
			cdo ensmean ${variable}*1980-1999*T42* ${variable}_${realm}_mmm_${experiment}_CMIP5_r1i1p1_1980-1999_clim_${remap}_T42.nc	
		fi
		
	fi	

fi

##########################################################################################
    
 if [ $actid -eq 5 ];then # create PCMDI climatologies 

	cd $CMIP_dir/data/CMIP5/$experiment/$realm/$variable       
	
    mkdir -p $CMIP_dir/processed/$experiment/$realm/$variable
	
	model_array=( $(find . -type d -maxdepth 1 -exec printf "{} " \;) )		# create array containing all model names

	for index in ${!model_array[*]}; do
	                                                                                                        
        models[index]=${model_array[index]#./}								# remove "./" from the model names
        
	done
	
	loop_length=$(expr ${#models[*]} - 1)									# loop over all folders without "processed"

	while [[ $((++i)) -le ${loop_length} ]]; do                            
       
    	cd ${models[i]}
        echo 'processing ' ${models[i]}
        file=`ls *.nc |tail -n1`
		last_model_year=`echo $file | rev | cut -c 6-9 | rev`
		file_1=`ls *.nc |head -n1`
		first_model_year=`echo $file_1 | rev | cut -c 13-16 | rev`
        model=${PWD##*/}

        if [ -d processed ]; then rm -r processed; fi 			# remove old data
        mkdir processed
		
		count=$(find . -maxdepth 1 -name '*.nc' | wc -l)
		
		if [ $count -eq 1 ]; then
			ln *.nc processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
		else
			cdo mergetime *.nc processed/${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
		fi
		
		cd processed
	
    	ensemble_mean_flag=1
    
    	if [ "$variable" == "psl" ]; then
    	 
    	mv ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
    	cdo divc,100 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
    	rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
    	
    	fi
    	
    	if [ "$variable" == "tas" ] || [ "$variable" == "ta" ]; then
    	 
    	mv ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
    	cdo -chunit,K,°C -addc,-273.15 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
    	rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
    	
    	fi
    	
    	if [ "$variable" == "pr" ]; then
    	 
    	mv ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
    	cdo mulc,86400 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
    	rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
    	
    	fi
    	
    	if [ "$model" != "GFDL-CM2p1" ] && [ "$variable" == "tos" ]; then 
    	
    	mv ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
    	cdo -chunit,K,C -addc,-273.15 -setctomiss,0 ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
    	rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_temp.nc
    	
    	fi
    	
		if [ "$variable" == "zg" ]; then 
			cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -sellevel,50000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_500_${realm}_${model}_${experiment}_CMIP5_r1i1p1_1980-2000_clim_${remap}_T42.nc
		elif [ "$variable" == "ua" ] || [ "$variable" == "va" ] || [ "$variable" == "ta" ]; then 
			cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -sellevel,85000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_850_${realm}_${model}_${experiment}_CMIP5_r1i1p1_1980-2000_clim_${remap}_T42.nc
			cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -sellevel,20000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_200_${realm}_${model}_${experiment}_CMIP5_r1i1p1_1980-2000_clim_${remap}_T42.nc
		else
			cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -selvar,${variable} ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1_1980-2000_clim_${remap}_T42.nc
		fi
		
		rm ${variable}_${realm}_${model}_${experiment}_CMIP5_r1i1p1.nc
           		
						
		cd ../..
		
		mv ${model}/processed/*.nc $CMIP_dir/processed/$experiment/$realm/$variable; 
		
		rm -r ${model}/processed
		mv $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/$model/*.nc $CMIP_dir/data/CMIP5/$experiment/$realm/$variable
		rm -r $CMIP_dir/data/CMIP5/$experiment/$realm/$variable/$model/
		unset models[i]
		cd $CMIP_dir/data/CMIP5/$experiment/$realm/$variable
		
	done
	
	if [ ${ensemble_mean_flag} -eq 1 ]; then
	
	cd $CMIP_dir/processed/$experiment/$realm/$variable/
	
	rm -f *mmm*1980-2000*
	
	if [ "$variable" == "zg" ]; then 
		cdo ensmean ${variable}*500*1980-2000*T42* ${variable}_500_${realm}_mmm_${experiment}_CMIP5_r1i1p1_1980-2000_clim_${remap}_T42.nc	
	elif [ "$variable" == "ua" ] || [ "$variable" == "va" ] || [ "$variable" == "ta" ]; then 
		cdo ensmean ${variable}*850*1980-2000*T42* ${variable}_850_${realm}_mmm_${experiment}_CMIP5_r1i1p1_1980-2000_clim_${remap}_T42.nc	
		cdo ensmean ${variable}*200*1980-2000*T42* ${variable}_200_${realm}_mmm_${experiment}_CMIP5_r1i1p1_1980-2000_clim_${remap}_T42.nc	
	else
		cdo ensmean ${variable}*1980-2000*T42* ${variable}_${realm}_mmm_${experiment}_CMIP5_r1i1p1_1980-2000_clim_${remap}_T42.nc	
	fi
			
	fi
	
	cre=0 	# 1 = calculate LW/SW cloud radiative effects
	      	# 0 = do not calculate LW/SW cloud radiative effects
		
	if [ ${cre} -eq 1 ]; then
		mkdir -p $CMIP_dir/processed/$experiment/Amon/sw_cre
		mkdir -p $CMIP_dir/processed/$experiment/Amon/lw_cre
		
		cd $CMIP_dir/processed/$experiment/Amon/rsutcs/	
		
		for i in *.nc; do
			j=`echo $i | sed 's/rsutcs/rsut/'`
			k=`echo $i | sed 's/rsutcs/sw_cre/'`
			cdo -chname,rsutcs,sw_cre -sub $i $CMIP_dir/processed/$experiment/Amon/rsut/$j $CMIP_dir/processed/$experiment/Amon/sw_cre/$k
		done
		
		cd $CMIP_dir/processed/$experiment/Amon/sw_cre/
		rm -f *mmm*1980-2000*
		
		cdo ensmean *1980-2000*T42* sw_cre_${realm}_mmm_${experiment}_CMIP5_r1i1p1_1980-2000_clim_${remap}_T42.nc	
		
		
		cd $CMIP_dir/processed/$experiment/Amon/rlutcs/	
		
		for i in *.nc; do
			j=`echo $i | sed 's/rlutcs/rlut/'`
			k=`echo $i | sed 's/rlutcs/lw_cre/'`
			cdo -chname,rlutcs,lw_cre -sub $i $CMIP_dir/processed/$experiment/Amon/rlut/$j $CMIP_dir/processed/$experiment/Amon/lw_cre/$k
		done
		
		cd $CMIP_dir/processed/$experiment/Amon/lw_cre/
		rm -f *mmm*1980-2000*
		
		cdo ensmean *1980-2000*T42* lw_cre_${realm}_mmm_${experiment}_CMIP5_r1i1p1_1980-2000_clim_${remap}_T42.nc	
		
		
	fi
			
		  
	 
fi

##########################################################################################
    
if [ $actid -eq 6 ];then # download and process observation data

	for obs in $observations; do
	
   		mkdir -p $CMIP_dir/data/observations/${obs}
   		cd $CMIP_dir/data/observations/${obs}

	case $obs in                                                                   
            HadISST) 
                wget -N http://www.metoffice.gov.uk/hadobs/hadisst/data/HadISST_sst.nc.gz --header="accept-encoding: gzip"
                gunzip HadISST_sst.nc.gz
                cdo -setvals,-1000,-1.8 -selgrid,2 HadISST_sst.nc HadISST_sst_grid2.nc
                data="HadISST_sst_grid2.nc"
                cut_flag=1                                            				
                ;;
            HadSST3) 
                wget -N http://www.metoffice.gov.uk/hadobs/hadsst3/data/HadSST.3.1.0.0/netcdf/HadSST.3.1.0.0.median_netcdf.zip --header="accept-encoding: gzip"
                unzip HadSST.3.1.0.0.median_netcdf.zip
                cdo selgrid,2 HadSST.3.1.0.0.median.nc HadSST.3.1.0.0.median_grid_2.nc
                data="HadSST.3.1.0.0.median_grid_2.nc"
                cut_flag=1                                            				
                ;;              
            CMAP)
				wget -N -O CMAP.pr.mon.mean.nc ftp://ftp.cdc.noaa.gov/Datasets/cmap/enh/precip.mon.mean.nc
			    cdo -${remap},t42grid -ymonmean -selyear,1980/2005 -selvar,precip CMAP.pr.mon.mean.nc CMAP.pr.mon.mean.1980-2005_clim_${remap}_T42.nc   
				data="CMAP.pr.mon.mean.nc"
				cut_flag=2      
				;;
            GPCP)
				wget -N -O GPCP.pr.mon.mean.nc ftp://ftp.cdc.noaa.gov/Datasets/gpcp/precip.mon.mean.nc  
			    cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -selvar,precip GPCP.pr.mon.mean.nc GPCP.pr.mon.mean.1980-2000_clim_${remap}_T42.nc  
				;;
            HadSLP2)
            	wget -N ftp://ftp.cdc.noaa.gov/Datasets.other/hadslp2/slp.mnmean.real.nc
            	data="slp.mnmean.real.nc"
            	cut_flag=1 
            	;;
            MLD)
            	wget -N http://www.ifremer.fr/cerweb/deboyer/data/mld_DT02_c1m_reg2.0.nc 
            	data="mld_DT02_c1m_reg2.0.nc"
            	cut_flag=3
            	;;
            ERSST)
            	wget -N ftp://ftp.cdc.noaa.gov/Datasets/noaa.ersst/sst.mnmean.nc
            	cdo -selgrid,2 sst.mnmean.nc ersstv3b.mnmean.nc
            	data="ersstv3b.mnmean.nc"
            	cut_flag=1
            	;;
	        CERES_EBAF) # download data from: http://ceres.larc.nasa.gov/products.php?product=EBAF-TOA
            	cdo -${remap},t42grid -ymonmean -shifttime,-2mon CERES_EBAF-TOA_Ed2.8_Subset_200003-201312.nc CERES_EBAF_clim_T42.nc
				cdo selvar,toa_sw_all_mon CERES_EBAF_clim_T42.nc rsut_CERES_EBAF_clim_T42.nc
				cdo selvar,toa_lw_all_mon CERES_EBAF_clim_T42.nc rlut_CERES_EBAF_clim_T42.nc
				cdo selvar,toa_cre_sw_mon CERES_EBAF_clim_T42.nc sw_cre_CERES_EBAF_clim_T42.nc
				cdo selvar,toa_cre_lw_mon CERES_EBAF_clim_T42.nc lw_cre_CERES_EBAF_clim_T42.nc
            	;;
            NCEP)			
				download_again=1 # set to 1 to download or update the files again
				
				if [ ${download_again} -eq 1 ]; then
					
            	wget -N -O NCEP.tas.mon.mean.nc ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/surface/air.mon.mean.nc #tas
				wget -N -O NCEP.ta.mon.mean.nc ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/pressure/air.mon.mean.nc #ta
				wget -N -O NCEP.zg.mon.mean.nc ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/pressure/hgt.mon.mean.nc #zg
				wget -N -O NCEP.ua.mon.mean.nc ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/pressure/uwnd.mon.mean.nc #ua
				wget -N -O NCEP.va.mon.mean.nc ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/pressure/vwnd.mon.mean.nc #va
				wget -N -O NCEP.shtfl.mon.mean.nc ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/surface_gauss/shtfl.sfc.mon.mean.nc #shtfl
				wget -N -O NCEP.lhtfl.mon.mean.nc ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/surface_gauss/lhtfl.sfc.mon.mean.nc #lhtfl
				
				fi
				
				cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -selvar,air NCEP.tas.mon.mean.nc NCEP.tas.mon.mean.1980-2000_clim_${remap}_T42.nc
				cdo -${remap},t42grid -timmean -selyear,1980/2000 -selvar,air NCEP.tas.mon.mean.nc NCEP_clim.tas.T42.nc
				cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -sellevel,850 -selvar,air NCEP.ta.mon.mean.nc NCEP.ta_850.mon.mean.1980-2000_clim_${remap}_T42.nc
				cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -sellevel,200 -selvar,air NCEP.ta.mon.mean.nc NCEP.ta_200.mon.mean.1980-2000_clim_${remap}_T42.nc
				cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -sellevel,850 -selvar,uwnd NCEP.ua.mon.mean.nc NCEP.ua_850.mon.mean.1980-2000_clim_${remap}_T42.nc
				cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -sellevel,200 -selvar,uwnd NCEP.ua.mon.mean.nc NCEP.ua_200.mon.mean.1980-2000_clim_${remap}_T42.nc
				cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -sellevel,850 -selvar,vwnd NCEP.va.mon.mean.nc NCEP.va_850.mon.mean.1980-2000_clim_${remap}_T42.nc
				cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -sellevel,200 -selvar,vwnd NCEP.va.mon.mean.nc NCEP.va_200.mon.mean.1980-2000_clim_${remap}_T42.nc
				cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -sellevel,500 -selvar,hgt NCEP.zg.mon.mean.nc NCEP.zg_500.mon.mean.1980-2000_clim_${remap}_T42.nc
				cdo -${remap},t42grid -timmean -selyear,1980/2000 -sellevel,500 -selvar,hgt NCEP.zg.mon.mean.nc NCEP_clim.zg_500.T42.nc			
				cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -selvar,shtfl NCEP.shtfl.mon.mean.nc NCEP.shtfl.mon.mean.1980-2000_clim_${remap}_T42.nc
				cdo -${remap},t42grid -timmean -selyear,1980/2000 -selvar,shtfl NCEP.shtfl.mon.mean.nc NCEP_clim.shtfl.T42.nc
				cdo -${remap},t42grid -ymonmean -selyear,1980/2000 -selvar,lhtfl NCEP.lhtfl.mon.mean.nc NCEP.lhtfl.mon.mean.1980-2000_clim_${remap}_T42.nc
				cdo -${remap},t42grid -timmean -selyear,1980/2000 -selvar,lhtfl NCEP.lhtfl.mon.mean.nc NCEP_clim.lhtfl.T42.nc

            	;;
             HadCRUT4)
            	wget -N http://www.cru.uea.ac.uk/cru/data/temperature/HadCRUT.4.2.0.0.median.nc 
            	data="HadCRUT.4.2.0.0.median.nc"
            	cut_flag=1     	
            esac

	if [ ${cut_flag} -eq 1 ]; then

	cdo -selyear,${start_1}/${end_1} -selgrid,1 $data ${obs}_${start_1}-${end_1}.nc
	
		if [ "${obs}" == "HadISST" ]; then
			
		cdo -${remap},$CMIP_dir/data/observations/${res}/ersstv3b.mnmean.nc ${obs}_${start_1}-${end_1}.nc ${obs}_${start_1}-${end_1}_${remap}_${res}.nc
			
		fi

	fi

	if [ ${cut_flag} -eq 2 ]; then

	cdo -${remap},$CMIP_dir/data/observations/${res}/ersstv3b.mnmean.nc -selyear,1979/${end_1} -selgrid,1 $data ${obs}_1979-${end_1}_${remap}_${res}.nc
	
	fi
	
	if [ ${cut_flag} -eq 3 ]; then
	
	cdo -${remap},$CMIP_dir/data/observations/${res}/ersstv3b.mnmean.nc $data ${obs}_climatology_${remap}_${res}.nc
	
	fi	
	
	unset data
	unset cut_flag
	
	done

fi

##########################################################################################
    
if [ $actid -eq 7 ];then # process KCM data

cd $CMIP_dir/data/KCM

process_all=0 # set to 1 to execute statement below

if [process_all -eq 1]; then

exp="P14 P16"
var="pr temp2 tsw sosstsst"

for jj in $exp; do
	for kk in $var; do

	if [ "${kk}" == "precip" ]; then
		cdo -${remap},${res} -setunit,mm/day -mulc,86400 -setrtomiss,273,274 -selyear,0300/0199 ${jj}_mm_0100-0399.${kk}.nc KCM_${jj}_0300-0399_${remap}_${res}.${kk}.nc
	elif [ "${kk}" == "sosstsst" ]; then
		cdo -${remap},${res} -setctomiss,0 -selyear,0300/0399 ${jj}_mm_0300-0399.${kk}.nc KCM_${jj}_0300-0399_${remap}_${res}.${kk}.nc
	else
		cdo -${remap},${res} -setunit,C -addc,-273.15 -setrtomiss,273,274 -selyear,0300/0399 ${jj}_mm_0300-0399.${kk}.nc KCM_${jj}_0300-0399_${remap}_${res}.${kk}.nc
	fi
	
	done
done

exp="W03 W04"
var="precip temp2 tsw sosstsst"

for jj in $exp; do
	for kk in $var; do

	if [ "${kk}" == "precip" ]; then
		cdo -${remap},${res} -setunit,mm/day -mulc,86400 -setrtomiss,273,274 -selyear,0900/0999 ${jj}_mm_0700-0999.${kk}.nc KCM_${jj}_0900-0999_${remap}_${res}.${kk}.nc
	elif [ "${kk}" == "sosstsst" ]; then
		cdo -${remap},${res} -setctomiss,0 -selyear,0900/0999 ${jj}_mm_0900-0999.${kk}.nc KCM_${jj}_0900-0999_${remap}_${res}.${kk}.nc
	else
		cdo -${remap},${res} -setunit,C -addc,-273.15 -setrtomiss,273,274 -selyear,0900/0999 ${jj}_mm_0700-0999.${kk}.nc KCM_${jj}_0900-0999_${remap}_${res}.${kk}.nc
	fi
	
	done
done

fi

exp="W03 W04 P12 P14"

for ii in $exp; do
	
	cdo -${remap},t42grid -mulc,86400 -setunit,mm/day -ymonmean -selvar,precip ${ii}_mm_metrics.pr.nc ${ii}_pr_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -setunit,C -addc,-273.15 -ymonmean -selvar,temp2 ${ii}_mm_metrics.temp2.nc ${ii}_tas_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -setunit,C -addc,-273.15 -ymonmean -sellevel,85000 -selvar,t ${ii}_mm_metrics.ta.nc ${ii}_ta_850_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -setunit,C -addc,-273.15 -ymonmean -sellevel,20000 -selvar,t ${ii}_mm_metrics.ta.nc ${ii}_ta_200_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -ymonmean -sellevel,85000 -selvar,u ${ii}_mm_metrics.ua.nc ${ii}_ua_850_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -ymonmean -sellevel,20000 -selvar,u ${ii}_mm_metrics.ua.nc ${ii}_ua_200_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -ymonmean -sellevel,85000 -selvar,v ${ii}_mm_metrics.va.nc ${ii}_va_850_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -ymonmean -sellevel,20000 -selvar,v ${ii}_mm_metrics.va.nc ${ii}_va_200_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -ymonmean -sellevel,50000 -selvar,geopoth ${ii}_mm_metrics.zg.nc ${ii}_zg_500_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -ymonmean -selvar,srad0u ${ii}_mm_metrics.rsut.nc ${ii}_rsut_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -ymonmean -selvar,trad0 ${ii}_mm_metrics.rlut.nc ${ii}_rlut_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -ymonmean -selvar,sw_cre ${ii}_mm_metrics.sw_cre.nc ${ii}_sw_cre_mm_clim_${remap}_T42.nc
	cdo -${remap},t42grid -ymonmean -selvar,lw_cre ${ii}_mm_metrics.lw_cre.nc ${ii}_lw_cre_mm_clim_${remap}_T42.nc
	
done

fi

##########################################################################################
    
if [ $actid -eq 8 ];then # calculate global means and correlations
	
number_of_years=$((end_1 - start_1))
number_of_decades=$((number_of_years/10))

if [ $((number_of_decades*10)) == $((number_of_years)) ]; then # check if number of years is a multiple of 10
	echo ${number_of_decades}
else
	years_last_period=$((number_of_years-(number_of_decades*10)))
	number_of_decades=$((number_of_decades+1))
	echo ${number_of_decades}
fi	

cd ${CMIP_dir}/processed/$experiment/$realm/$variable

if [ ! -e gm ]; then mkdir -p gm; fi 
if [ ! -e gm_removed ]; then mkdir -p gm_removed; fi
if [ ! -e correlations ]; then mkdir -p correlations; fi
if [ ! -e trends ]; then mkdir -p trends; fi

if [ "$variable" == "tos" ]; then # process tos observations
	
	cdo fldmean $CMIP_dir/data/observations/ERSST/ERSST_${start_1}-${end_1}.nc gm/ERSST_gm_${start_1}-${end_1}.nc
	cdo fldmean $CMIP_dir/data/observations/HadISST/HadISST_${start_1}-${end_1}.nc gm/HadISST_gm_${start_1}-${end_1}.nc
	cdo sub $CMIP_dir/data/observations/ERSST/ERSST_${start_1}-${end_1}.nc -enlarge,$CMIP_dir/data/observations/ERSST/ERSST_${start_1}-${end_1}.nc gm/ERSST_gm_${start_1}-${end_1}.nc gm_removed/ERSST_gm_removed_${start_1}-${end_1}.nc
	cdo sub $CMIP_dir/data/observations/HadISST/HadISST_${start_1}-${end_1}_${remap}_${res}.nc -enlarge,$CMIP_dir/data/observations/HadISST/HadISST_${start_1}-${end_1}_${remap}_${res}.nc gm/HadISST_gm_${start_1}-${end_1}.nc gm_removed/HadISST_gm_removed_${start_1}-${end_1}.nc
	cdo ymonmean gm_removed/ERSST_gm_removed_${start_1}-${end_1}.nc gm_removed/ERSST_climatology_${start_1}-${end_1}.nc
	cdo ymonmean gm_removed/HadISST_gm_removed_${start_1}-${end_1}.nc gm_removed/HadISST_climatology_${start_1}-${end_1}.nc
	
	decade=1
	while [ $decade -le ${number_of_decades} ]; do
		echo $decade
		first_year=$((start_1 + (decade-1)*10))
		if [ $decade -lt ${number_of_decades} ]; then
			last_year=$((first_year + 9))
		else
			last_year=$((first_year + years_last_period))
		fi
		echo ${first_year}
		echo ${last_year}
		
		obs_data="ERSST HadISST" # ERSST HadISST
			
		for data_set in ${obs_data} ; do
		
			if [ $decade -eq 1 ]; then
				cdo -trend -yearmean -selyear,${first_year}/${end_1} -selvar,sst gm/${data_set}_gm_${start_1}-${end_1}.nc a.nc trends/${data_set}_gm_decadal_trends_${start_1}-${end_1}.nc
				rm a.nc
			else
				cdo -trend -yearmean -selyear,${first_year}/${end_1} -selvar,sst gm/${data_set}_gm_${start_1}-${end_1}.nc a.nc trends/${data_set}_gm_trends_${first_year}-${end_1}.nc
				cdo cat trends/${data_set}_gm_trends_${first_year}-${end_1}.nc trends/${data_set}_gm_decadal_trends_${start_1}-${end_1}.nc
				rm a.nc
				rm trends/${data_set}_gm_trends_${first_year}-${end_1}.nc
			fi
		
		done
		
		decade=$(( $decade + 1 ))
		
	done

	
fi
	
	
for data_set in ${obs_data} ; do
	
	for model_file in *${remap}_${res}.nc; do 
		model_name=$(echo "${model_file}" | cut -d'_' -f3)
	
		if [ "$variable" == "tas" ]; then # express tas fields as anomalies to 1961-1990 to compare with HadCRUT4
		
			mv ${model_file} ${model_file}_temp
			cdo sub ${model_file}_temp -timmean -selyear,1961/1990 ${model_file}_temp ${model_file}
		
		fi
	
		cdo fldmean ${model_file} gm/${variable}_gm_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc
		cdo sub ${model_file} -enlarge,${model_file} gm/${variable}_gm_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc gm_removed/${variable}_gm_removed_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc
		cdo ymonmean gm_removed/${variable}_gm_removed_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc gm_removed/${variable}_climatology_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc
	
		decade=1
		while [ $decade -le ${number_of_decades} ]; do
			echo $decade
			first_year=$((start_1 + (decade-1)*10))
			if [ $decade -lt ${number_of_decades} ]; then
				last_year=$((first_year + 9))
			else
				last_year=$((first_year + years_last_period))
			fi
			echo ${first_year}
			echo ${last_year}
		
			if [ $decade -eq 1 ]; then
				cdo -trend -yearmean -selyear,${first_year}/${end_1} -selvar,${variable} gm/${variable}_gm_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc a.nc trends/${variable}_gm_decadal_trends_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc
				rm a.nc
				
				cdo -timmean -ymonsub -selyear,${first_year}/${last_year} gm_removed/${data_set}_gm_removed_${start_1}-${end_1}.nc gm_removed/${data_set}_climatology_${start_1}-${end_1}.nc gm_removed/${data_set}_gm_removed_${start_1}-${end_1}_decadal_patterns.nc 
				cdo -timmean -ymonsub -selyear,${first_year}/${last_year} gm_removed/${variable}_gm_removed_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc gm_removed/${variable}_climatology_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc gm_removed/${variable}_gm_removed_${start_1}-${end_1}_decadal_patterns_${model_name}_${remap}_${res}.nc 
			
				cdo -f nc -fldcor gm_removed/${data_set}_gm_removed_${start_1}-${end_1}_decadal_patterns.nc gm_removed/${variable}_gm_removed_${start_1}-${end_1}_decadal_patterns_${model_name}_${remap}_${res}.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_1}-${end_1}_${model_name}_${remap}_${res}_90.nc
				cdo -f nc -fldcor -sellonlatbox,0,360,-70,70 gm_removed/${data_set}_gm_removed_${start_1}-${end_1}_decadal_patterns.nc -sellonlatbox,0,360,-70,70 gm_removed/${variable}_gm_removed_${start_1}-${end_1}_decadal_patterns_${model_name}_${remap}_${res}.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_1}-${end_1}_${model_name}_${remap}_${res}_70.nc
				cdo -f nc -fldcor -sellonlatbox,0,360,0,90 gm_removed/${data_set}_gm_removed_${start_1}-${end_1}_decadal_patterns.nc -sellonlatbox,0,360,0,90 gm_removed/${variable}_gm_removed_${start_1}-${end_1}_decadal_patterns_${model_name}_${remap}_${res}.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_1}-${end_1}_${model_name}_${remap}_${res}_NH.nc
				cdo -f nc -fldcor -sellonlatbox,0,360,-90,0 gm_removed/${data_set}_gm_removed_${start_1}-${end_1}_decadal_patterns.nc -sellonlatbox,0,360,-90,0 gm_removed/${variable}_gm_removed_${start_1}-${end_1}_decadal_patterns_${model_name}_${remap}_${res}.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_1}-${end_1}_${model_name}_${remap}_${res}_SH.nc
			
			else
				cdo -trend -yearmean -selyear,${first_year}/${end_1} -selvar,${variable} gm/${variable}_gm_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc a.nc trends/${variable}_gm_trends_${first_year}-${end_1}_${model_name}_${remap}_${res}.nc
									
				cdo -timmean -ymonsub -selyear,${first_year}/${last_year} gm_removed/${data_set}_gm_removed_${start_1}-${end_1}.nc gm_removed/${data_set}_climatology_${start_1}-${end_1}.nc gm_removed/${data_set}_gm_removed_${first_year}-${last_year}_decadal_patterns.nc 
				cdo -timmean -ymonsub -selyear,${first_year}/${last_year} gm_removed/${variable}_gm_removed_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc gm_removed/${variable}_climatology_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc gm_removed/${variable}_gm_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc 
			
				cdo -f nc -fldcor gm_removed/${data_set}_gm_removed_${first_year}-${last_year}_decadal_patterns.nc gm_removed/${variable}_gm_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_90.nc
				cdo -f nc -fldcor -sellonlatbox,0,360,-70,70 gm_removed/${data_set}_gm_removed_${first_year}-${last_year}_decadal_patterns.nc -sellonlatbox,0,360,-70,70 gm_removed/${variable}_gm_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_70.nc
				cdo -f nc -fldcor -sellonlatbox,0,360,-0,90 gm_removed/${data_set}_gm_removed_${first_year}-${last_year}_decadal_patterns.nc -sellonlatbox,0,360,0,90 gm_removed/${variable}_gm_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_NH.nc
				cdo -f nc -fldcor -sellonlatbox,0,360,-90,0 gm_removed/${data_set}_gm_removed_${first_year}-${last_year}_decadal_patterns.nc -sellonlatbox,0,360,-90,0 gm_removed/${variable}_gm_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_SH.nc

				cdo cat trends/${variable}_gm_trends_${first_year}-${end_1}_${model_name}_${remap}_${res}.nc trends/${variable}_gm_decadal_trends_${start_1}-${end_1}_${model_name}_${remap}_${res}.nc
				cdo cat gm_removed/${data_set}_gm_removed_${first_year}-${last_year}_decadal_patterns.nc gm_removed/${data_set}_gm_removed_${start_1}-${end_1}_decadal_patterns.nc 
				cdo cat gm_removed/${variable}_gm_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc gm_removed/${variable}_gm_removed_${start_1}-${end_1}_decadal_patterns_${model_name}_${remap}_${res}.nc 			
				cdo cat correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_70.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_1}-${end_1}_${model_name}_${remap}_${res}_70.nc
				cdo cat correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_90.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_1}-${end_1}_${model_name}_${remap}_${res}_90.nc
				cdo cat correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_NH.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_1}-${end_1}_${model_name}_${remap}_${res}_NH.nc
				cdo cat correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_SH.nc correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${start_1}-${end_1}_${model_name}_${remap}_${res}_SH.nc
		
				rm a.nc
				rm trends/${variable}_gm_trends_${first_year}-${end_1}_${model_name}_${remap}_${res}.nc
				rm gm_removed/${data_set}_gm_removed_${first_year}-${last_year}_decadal_patterns.nc 
				rm gm_removed/${variable}_gm_removed_${first_year}-${last_year}_decadal_patterns_${model_name}_${remap}_${res}.nc 
				rm correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_70.nc
				rm correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_90.nc
				rm correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_NH.nc
				rm correlations/${variable}_decadal_pattern_correlation_to_${data_set}_${first_year}-${last_year}_${model_name}_${remap}_${res}_SH.nc
				
			
			fi
		
			decade=$(( $decade + 1 ))
		
		done
	
		if [ "$variable" == "tas" ]; then # express tas fields as anomalies to 1961-1990 to compare with HadCRUT4
		
			mv ${model_file}_temp ${model_file}
			
		fi
		
	done

done


fi

##########################################################################################
    
if [ $actid -eq 9 ];then # make plots with ncl

mkdir -p $CMIP_dir/plots/surface_fields/${variable}

export plot_dir=$CMIP_dir/plots/surface_fields/${variable}
export CMIP_dir
export experiment

ncl $CMIP_dir/scripts/ncl/surface_plots.ncl

fi

##########################################################################################
    
if [ $actid -eq 10 ];then # make plots with ncl

mkdir -p $CMIP_dir/plots/${variable}/trends

export plot_dir=$CMIP_dir/plots/${variable}/trends
export CMIP_dir
export experiment

ncl $CMIP_dir/scripts/trend_plots.ncl

fi

##########################################################################################
    
if [ $actid -eq 11 ];then # make global mean and correlation plots

mkdir -p $CMIP_dir/plots/${variable}/correlations

export plot_dir=$CMIP_dir/plots/${variable}/correlations
export CMIP_dir
export experiment

ncl $CMIP_dir/scripts/correlation_plots.ncl

fi

##########################################################################################
    
if [ $actid -eq 12 ];then # make PCMDI metric plots

mkdir -p $CMIP_dir/plots/${variable}/PCMDI_metrics

export plot_dir=$CMIP_dir/plots/${variable}/PCMDI_metrics
export CMIP_dir
export experiment

#ncl $CMIP_dir/scripts/PCMDI_metrics.ncl
#ncl $CMIP_dir/scripts/PCMDI_metrics_against_P14.ncl
#ncl $CMIP_dir/scripts/PCMDI_metrics_3.0.ncl
#ncl $CMIP_dir/scripts/PCMDI_metrics_3.5.ncl
ncl $CMIP_dir/scripts/PCMDI_metrics_4.0.ncl

fi

##########################################################################################

if [ $actid -eq 13 ];then # rotate plots 90° to the left

cd $CMIP_dir/plots/${variable}/trends
for i in *.pdf; do pdftk $i cat 1left output rot_${i}; rm ${i}; mv rot_${i} ${i}; done

fi
##########################################################################################
done
done                                                                                         
