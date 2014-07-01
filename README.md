CMIP_scripts
============

Collection of bash and NCL scripts for CMIP3/5 data


CMIP3/CMIP5 Data Analysis - Documentation

Parts of the analysis:
============

- Download the data
- surface plots and biases against observations and ensemble mean
- 20th century trends and significance testing
- scatter plots trends/pattern correlation
- Taylor-diagrams
- KCM comparison

Download the data
============

CMIP3:
============

- Open “cmip3_processing.sh” under “CMIP_scripts/bash/“
- sepcify: “experiment”, “var”, “actions” (1)

CMIP5:
============

- Open “cmip5_processing.sh” under “CMIP_scripts/bash/“
- sepcify: “experiment”, “var”, “actions” (1 and 2)
- if you only want to download a specific time range of the data, set “download_all_files” to 0 and adapt the regular expressions below
- run “cmip5_processing.sh”
- if asked provide the following credentials:
	- openID: https://pcmdi9.llnl.gov/esgf-idp/openid/steinigsebastian
	- password: ho2djz&4ByJG
	
	please note: there are problems with retrieving the needed credentials on the nesh-fe servers
				 in this case retrieve the credentials on another machine and copy the ~/.esg/certificates
				 to your nesh-fe home directory
- the download should start now and the script will echo in the end whether all files have been downloaded or not
- if not, rerun wget script and/or add "--no-check-certificate" to the wget command
- to update the data just rerun actions 1 and 2, the script won't redownload already present data

Process the data
============

CMIP3:
============

- Open “cmip3_processing.sh” under “CMIP_scripts/bash/“
- sepcify: “experiment”, “var”, “actions” (3), "period", "climatology_period", "remap" and "res"
- run the script, it will result in the following structure under $CMIP_dir/processed/CMIP3/experiment/realm/variable/:
	- rmeapped_to_$res (model field remapped to an observational grid; ERSST or HadCRUT4)
	- original_resolution (model field on its original resolution
	- climatologies (climatological fields for the period specified in $climatology_period; needed for the PCMDI metrics table)

CMIP5:
============

- Open “cmip5_processing.sh” under “CMIP_scripts/bash/“
- sepcify: “experiment”, “var”, “actions” (3 and 4), "period", "climatology_period", "remap" and "res"
- run the script, it will result in the following structure under $CMIP_dir/processed/CMIP5/experiment/realm/variable/:
	- rmeapped_to_$res (model field remapped to an observational grid; ERSST or HadCRUT4)
	- original_resolution (model field on its original resolution
	- climatologies (climatological fields for the period specified in $climatology_period; needed for the PCMDI metrics table)


Surface Plots
============

- Open “cmip5_processing.sh” under “CMIP_scripts/bash/“
- sepcify: “experiment”, “var”, “actions” (8), "period" and "res"
- specifiy the plot mods just below to choose which fields should be plotted
  (please note: don't set plot_means and plot_seasons both to 1, ths will result in an ncl error at the moment)


