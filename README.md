CMIP_scripts
============

Collection of bash and NCL scripts for CMIP3/5 data


CMIP3/CMIP5 Data Analysis - Documentation

Parts of the analysis:
============

- Download the data
- surface plots and biases against observations
- 20th century trends and significance testing
- scatter plots trends/pattern correlation
- Taylor-diagrams

Download the data
============

CMIP3:
============



CMIP5:
============

- Open “cmip5_processing.sh” under “scripts/“
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
