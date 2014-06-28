CMIP_scripts
============

Collection of bash and NCL scripts for CMIP3/5 data


CMIP3/CMIP5 Data Analysis - Documentation

Parts of the analysis:

- Download the data
- surface plots and biases against observations
- 20th century trends and significance testing
- scatter plots trends/pattern correlation
- Taylor-diagrams

Download the data

CMIP5:

- Open “cmip5_processing.sh” under “scripts/“
- sepcify: “experiment”, “var”, “actions” (1 and 2)
- if you only want to download a specific time range of the data, set “download_all_files” to 0 and adapt the regular expressions below
