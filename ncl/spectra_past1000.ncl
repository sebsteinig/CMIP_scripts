;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

; load data

CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP/"

; non-overlapping decades

	gm_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/global_mean_decadal_mean/"
	gm_files = systemfunc ("ls "+gm_directory+"*.nc")
	gm_tmp=addfiles(gm_files,"r")
	ListSetType (gm_tmp, "join")

	gm_anomaly_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/global_mean_anomaly_decadal_mean/"
	gm_anomaly_files = systemfunc ("ls "+gm_anomaly_directory+"*.nc")
	gm_anomaly_tmp=addfiles(gm_anomaly_files,"r")
	ListSetType (gm_anomaly_tmp, "join")

	nh_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/NH_mean_decadal_mean/"
	nh_files = systemfunc ("ls "+nh_directory+"*.nc")
	nh_tmp=addfiles(nh_files,"r")
	ListSetType (nh_tmp, "join")

	nh_anomaly_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/NH_mean_anomaly_decadal_mean/"
	nh_anomaly_files = systemfunc ("ls "+nh_anomaly_directory+"*.nc")
	nh_anomaly_tmp=addfiles(nh_anomaly_files,"r")
	ListSetType (nh_anomaly_tmp, "join")

	proxy_gm_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_global_mean_0851-1849_decadal_mean.nc","r")
	proxy_gm_anomaly_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_global_mean_anomaly_0851-1849_decadal_mean.nc","r")
	proxy_nh_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_0851-1849_decadal_mean.nc","r")
	proxy_nh_anomaly_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_anomaly_0851-1849_decadal_mean.nc","r")

