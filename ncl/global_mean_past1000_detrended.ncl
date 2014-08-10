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

	gm_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/global_mean_decadal_mean_detrended/"
	gm_files = systemfunc ("ls "+gm_directory+"*.nc")
	gm_tmp=addfiles(gm_files,"r")
	ListSetType (gm_tmp, "join")

	gm_anomaly_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/global_mean_anomaly_decadal_mean_detrended/"
	gm_anomaly_files = systemfunc ("ls "+gm_anomaly_directory+"*.nc")
	gm_anomaly_tmp=addfiles(gm_anomaly_files,"r")
	ListSetType (gm_anomaly_tmp, "join")

	nh_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/NH_mean_decadal_mean_detrended/"
	nh_files = systemfunc ("ls "+nh_directory+"*.nc")
	nh_tmp=addfiles(nh_files,"r")
	ListSetType (nh_tmp, "join")

	nh_anomaly_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/NH_mean_anomaly_decadal_mean_detrended/"
	nh_anomaly_files = systemfunc ("ls "+nh_anomaly_directory+"*.nc")
	nh_anomaly_tmp=addfiles(nh_anomaly_files,"r")
	ListSetType (nh_anomaly_tmp, "join")

	proxy_gm_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_global_mean_0851-1849_decadal_mean.nc","r")
	proxy_gm_anomaly_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_global_mean_anomaly_0851-1849_decadal_mean.nc","r")
	proxy_nh_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_0851-1849_decadal_mean.nc","r")
	proxy_nh_anomaly_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_anomaly_0851-1849_decadal_mean.nc","r")

; decadal running mean

	gm_running_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/global_mean_decadal_running_mean_detrended/"
	gm_running_files = systemfunc ("ls "+gm_running_directory+"*.nc")
	gm_running_tmp=addfiles(gm_running_files,"r")
	ListSetType (gm_running_tmp, "join")

	gm_anomaly_running_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/global_mean_anomaly_decadal_running_mean_detrended/"
	gm_anomaly_running_files = systemfunc ("ls "+gm_anomaly_running_directory+"*.nc")
	gm_anomaly_running_tmp=addfiles(gm_anomaly_running_files,"r")
	ListSetType (gm_anomaly_running_tmp, "join")

	nh_running_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/NH_mean_decadal_running_mean_detrended/"
	nh_running_files = systemfunc ("ls "+nh_running_directory+"*.nc")
	nh_running_tmp=addfiles(nh_running_files,"r")
	ListSetType (nh_running_tmp, "join")

	nh_anomaly_running_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/NH_mean_anomaly_decadal_running_mean_detrended/"
	nh_anomaly_running_files = systemfunc ("ls "+nh_anomaly_running_directory+"*.nc")
	nh_anomaly_running_tmp=addfiles(nh_anomaly_running_files,"r")
	ListSetType (nh_anomaly_running_tmp, "join")

	proxy_gm_running_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_global_mean_0856-1845_decadal_running_mean.nc","r")
	proxy_gm_anomaly_running_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_global_mean_anomaly_0856-1845_decadal_running_mean.nc","r")
	proxy_nh_running_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_0856-1845_decadal_running_mean.nc","r")
	proxy_nh_anomaly_running_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_anomaly_0856-1845_decadal_running_mean.nc","r")


model_name=gm_anomaly_files
do nt = 0,(dimsizes(gm_anomaly_files)-1)
	strs=str_split(gm_anomaly_files(nt),"_")
	model_name(nt)=strs(10)
	delete(strs)
end do

names=array_append_record(model_name,"Mann et al. 2009 reconstruction",0)
time = ispan(864,1844,10)
time_running = ispan(856,1845,1)

gm=gm_tmp[:]->tas(:,:,0,0)
gm_anomaly=gm_anomaly_tmp[:]->tas(:,:,0,0)
nh=nh_tmp[:]->tas(:,:,0,0)
nh_anomaly=nh_anomaly_tmp[:]->tas(:,:,0,0)

gm_running=gm_running_tmp[:]->tas(:,:,0,0)
gm_anomaly_running=gm_anomaly_running_tmp[:]->tas(:,:,0,0)
nh_running=nh_running_tmp[:]->tas(:,:,0,0)
nh_anomaly_running=nh_anomaly_running_tmp[:]->tas(:,:,0,0)

proxy_gm=proxy_gm_tmp->tas(:,:,0)
proxy_gm_anomaly=proxy_gm_anomaly_tmp->tas(:,:,0)
proxy_nh=proxy_nh_tmp->tas(:,:,0)
proxy_nh_anomaly=proxy_nh_anomaly_tmp->tas(:,:,0)

proxy_gm_running=proxy_gm_running_tmp->tas(:,:,0)
proxy_gm_anomaly_running=proxy_gm_anomaly_running_tmp->tas(:,:,0)
proxy_nh_running=proxy_nh_running_tmp->tas(:,:,0)
proxy_nh_anomaly_running=proxy_nh_anomaly_running_tmp->tas(:,:,0)

proxy_gm!1="ncl_join"
proxy_gm_anomaly!1="ncl_join"
proxy_nh!1="ncl_join"
proxy_nh_anomaly!1="ncl_join"

proxy_gm_running!1="ncl_join"
proxy_gm_anomaly_running!1="ncl_join"
proxy_nh_running!1="ncl_join"
proxy_nh_anomaly_running!1="ncl_join"

all_fields_gm=array_append_record(gm,proxy_gm(ncl_join|:,time|:),0)
all_fields_gm_anomaly=array_append_record(gm_anomaly,proxy_gm_anomaly(ncl_join|:,time|:),0)
all_fields_nh=array_append_record(nh,proxy_nh(ncl_join|:,time|:),0)
all_fields_nh_anomaly=array_append_record(nh_anomaly,proxy_nh_anomaly(ncl_join|:,time|:),0)

all_fields_gm_running=array_append_record(gm_running,proxy_gm_running(ncl_join|:,time|:),0)
all_fields_gm_anomaly_running=array_append_record(gm_anomaly_running,proxy_gm_anomaly_running(ncl_join|:,time|:),0)
all_fields_nh_running=array_append_record(nh_running,proxy_nh_running(ncl_join|:,time|:),0)
all_fields_nh_anomaly_running=array_append_record(nh_anomaly_running,proxy_nh_anomaly_running(ncl_join|:,time|:),0)

; define resources constant for all 4 plots

res                     		= True             
res@vpHeightF 	 				= 0.4              	
res@vpWidthF 	        		= 0.7
res@gsnMaximize     			= True              
res@tmYMajorGrid				= "True"
res@tmYMajorGridLineColor		= "grey"
res@tmYMajorGridLineDashPattern	= 16
res@tmYMajorGridThicknessF		= 1.0
res@pmLegendDisplayMode    		= "Always"   		
res@xyExplicitLegendLabels 		= names         	
res@pmLegendWidthF         		= 0.30              
res@pmLegendHeightF        		= 0.15              
res@xyLineColors       			= (/"coral3","cyan","gold","blue","darkorchid2","darkseagreen4","grey","darkorange1","green","firebrick2","black"/) ; colors chosen
res@xyLineThicknesses   		= (/2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,5.0,5.0/) 
res@xyDashPattern      			= 0
res@tiYAxisString	 			= "[~S~o~N~C]"     	    	
res@tiXAxisString	 			= "Year"      		 
res@tmYRLabelsOn 				= True
 
 
 
; define variable resources

res@gsnCenterString 			= "decadal surface air temperature detrended"
res@trXMinF	         			= 864             	
res@trXMaxF	       	  			= 1844

; global mean plot
 
	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_0851-1849_past1000_global_mean_decadal_detrended")            

	res@trYMinF	            		= 11.2          ; set x-axis minimum
	res@trYMaxF	            		= 15.5
	res@tiMainString				= "global mean" 

	model_plot = gsn_csm_xy (wks,time,all_fields_gm(ncl_join|0:dimsizes(gm_files)-1,time|:),res)     
	
; NH mean plot
 
	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_0851-1849_past1000_NH_mean_decadal_detrended")       

	res@trYMinF	            		= 11.2          ; set x-axis minimum
	res@trYMaxF	            		= 15.5
	res@tiMainString				= "NH mean" 

	model_plot = gsn_csm_xy (wks,time,all_fields_nh(ncl_join|0:dimsizes(gm_files)-1,time|:),res)     
	
; global mean anomaly plot
 
	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_0851-1849_past1000_global_mean_anomaly_decadal_detrended")            

	res@trYMinF	            		= -0.9          ; set x-axis minimum
	res@trYMaxF	            		= 0.9
	res@tiMainString				= "global mean anomaly" 

	model_plot = gsn_csm_xy (wks,time,all_fields_gm_anomaly(ncl_join|0:dimsizes(gm_files),time|:),res)      

; NH mean anomaly plot

	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_0851-1849_past1000_NH_mean_anomaly_decadal_detrended")              

	res@trYMinF	            		= -0.9          ; set x-axis minimum
	res@trYMaxF	            		= 0.9
	res@tiMainString				= "NH mean anomaly" 

	model_plot = gsn_csm_xy (wks,time,all_fields_nh_anomaly(ncl_join|0:dimsizes(gm_files),time|:),res)     


; define variable resources

res@gsnCenterString 			= "decadal running mean surface air temperature detrended"
res@trXMinF	         			= 856             	
res@trXMaxF	       	  			= 1845

; global mean plot
 
	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_0851-1849_past1000_global_mean_decadal_running_detrended")            

	res@trYMinF	            		= 11.2          ; set x-axis minimum
	res@trYMaxF	            		= 15.5
	res@tiMainString				= "global mean" 

	model_plot = gsn_csm_xy (wks,time_running,all_fields_gm_running(ncl_join|0:dimsizes(gm_files)-1,time|:),res)       

; NH mean plot
 
	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_0851-1849_past1000_NH_mean_decadal_running_detrended")              

	res@trYMinF	            		= 11.2          ; set x-axis minimum
	res@trYMaxF	            		= 15.5
	res@tiMainString				= "NH mean" 

	model_plot = gsn_csm_xy (wks,time_running,all_fields_nh_running(ncl_join|0:dimsizes(gm_files)-1,time|:),res)       
	
; global mean anomaly plot
 
	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_0851-1849_past1000_global_mean_anomaly_decadal_running_detrended")              

	res@trYMinF	            		= -0.9          ; set x-axis minimum
	res@trYMaxF	            		= 0.9
	res@tiMainString				= "global mean anomaly" 

	model_plot = gsn_csm_xy (wks,time_running,all_fields_gm_anomaly_running(ncl_join|0:dimsizes(gm_files),time|:),res)       

; NH mean anomaly plot

	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_0851-1849_past1000_NH_mean_anomaly_decadal_running_detrended")               

	res@trYMinF	            		= -0.9          ; set x-axis minimum
	res@trYMaxF	            		= 0.9
	res@tiMainString				= "NH mean anomaly" 

	model_plot = gsn_csm_xy (wks,time_running,all_fields_nh_anomaly_running(ncl_join|0:dimsizes(gm_files),time|:),res)      

end

