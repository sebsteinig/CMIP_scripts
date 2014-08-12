;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

; load data

CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP/"

; decadal running mean

	gm_anomaly_running_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/global_mean_anomaly_decadal_running_mean_detrended/"
	gm_anomaly_running_files = systemfunc ("ls "+gm_anomaly_running_directory+"*.nc")
	gm_anomaly_running_tmp=addfiles(gm_anomaly_running_files,"r")
	ListSetType (gm_anomaly_running_tmp, "join")

	nh_anomaly_running_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/NH_mean_anomaly_decadal_running_mean_detrended/"
	nh_anomaly_running_files = systemfunc ("ls "+nh_anomaly_running_directory+"*.nc")
	nh_anomaly_running_tmp=addfiles(nh_anomaly_running_files,"r")
	ListSetType (nh_anomaly_running_tmp, "join")

	proxy_gm_running_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_global_mean_0856-1845_decadal_running_mean.nc","r")
	proxy_gm_anomaly_running_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_global_mean_anomaly_0856-1845_decadal_running_mean.nc","r")
	proxy_nh_running_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_0856-1845_decadal_running_mean.nc","r")
	proxy_nh_anomaly_running_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_anomaly_0856-1845_decadal_running_mean.nc","r")


model_name=gm_anomaly_running_files
do nt = 0,(dimsizes(gm_anomaly_running_files)-1)
	strs=str_split(gm_anomaly_running_files(nt),"_")
	model_name(nt)=strs(10)
	delete(strs)
end do


names=array_append_record(model_name,"Mann et al. 2009 reconstruction",0)
time = ispan(864,1844,10)
time_running = ispan(856,1845,1)

print(names)

gm_anomaly_running=gm_anomaly_running_tmp[:]->tas(:,:,0,0)
nh_anomaly_running=nh_anomaly_running_tmp[:]->tas(:,:,0,0)

proxy_gm_running=proxy_gm_running_tmp->tas(:,:,0)
proxy_gm_anomaly_running=proxy_gm_anomaly_running_tmp->tas(:,:,0)
proxy_nh_running=proxy_nh_running_tmp->tas(:,:,0)
proxy_nh_anomaly_running=proxy_nh_anomaly_running_tmp->tas(:,:,0)

proxy_gm_running!1="ncl_join"
proxy_gm_anomaly_running!1="ncl_join"
proxy_nh_running!1="ncl_join"
proxy_nh_anomaly_running!1="ncl_join"

all_fields_gm_anomaly_running=array_append_record(gm_anomaly_running,proxy_gm_anomaly_running(ncl_join|:,time|:),0)
all_fields_nh_anomaly_running=array_append_record(nh_anomaly_running,proxy_nh_anomaly_running(ncl_join|:,time|:),0)


mmm_gm_std=dim_stddev_n_Wrap(all_fields_gm_anomaly_running(0:8,:),0)
mmm_nh_std=dim_stddev_n_Wrap(all_fields_nh_anomaly_running(0:8,:),0)

gm_bnd=all_fields_gm_anomaly_running(0:1,:)
nh_bnd=all_fields_gm_anomaly_running(0:1,:)

gm_bnd(0,:)=all_fields_gm_anomaly_running(9,:)-2*mmm_gm_std
gm_bnd(1,:)=all_fields_gm_anomaly_running(9,:)+2*mmm_gm_std
nh_bnd(0,:)=all_fields_nh_anomaly_running(9,:)-2*mmm_nh_std
nh_bnd(1,:)=all_fields_nh_anomaly_running(9,:)+2*mmm_nh_std

printVarSummary(gm_bnd)


; define resources constant for all 4 plots

res                     		= True   
res@gsnDraw = False ; don't draw yet 
res@gsnFrame = False ; don't advance frame yet           
res@vpHeightF 	 				= 0.4              	
res@vpWidthF 	        		= 0.7
res@gsnMaximize     			= True              
res@tmYMajorGrid				= "True"
res@tmYMajorGridLineColor		= "grey"
res@tmYMajorGridLineDashPattern	= 16
res@tmYMajorGridThicknessF		= 1.0
;res@pmLegendDisplayMode    		= "Always"   		
res@xyExplicitLegendLabels 		= names         	
res@pmLegendWidthF         		= 0.30              
res@pmLegendHeightF        		= 0.15              
;res@xyLineColors       			= (/"coral3","cyan","gold","blue","darkorchid2","darkseagreen4","grey","darkorange1","green","firebrick2","black"/) ; colors chosen
;res@xyLineColors       			= (/"black"/) ; colors chosen
res@xyLineThicknesses   		= (/2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,5.0,5.0/) 
res@xyDashPattern      			= 0
res@tiYAxisString	 			= "[~S~o~N~C]"     	    	
res@tiXAxisString	 			= "Year"      		 
res@tmYRLabelsOn 				= True

res2                     		= True 
res2@xyLineColors       			= (/"black"/) ; colors chosen
res2@gsnDraw = False ; don't draw yet 
res2@gsnFrame = False ; don't advance frame yet
res2@vpHeightF 	 				= 0.4              	
res2@vpWidthF 	        		= 0.7
res2@gsnMaximize     			= True              
res2@tmYMajorGrid				= "True"
res2@tmYMajorGridLineColor		= "grey"
res2@tmYMajorGridLineDashPattern	= 16
res2@tmYMajorGridThicknessF		= 1.0
;res2@pmLegendDisplayMode    		= "Always"   		
res2@xyExplicitLegendLabels 		= names         	
res2@pmLegendWidthF         		= 0.30              
res2@pmLegendHeightF        		= 0.15              
;re2s@xyLineColors       			= (/"coral3","cyan","gold","blue","darkorchid2","darkseagreen4","grey","darkorange1","green","firebrick2","black"/) ; colors chosen
;res2@xyLineColors       			= (/"black"/) ; colors chosen
res2@xyLineThicknesses   		= (/5.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,5.0,5.0/) 
res2@xyDashPattern      			= 0
res2@tiYAxisString	 			= "[~S~o~N~C]"     	    	
res2@tiXAxisString	 			= "Year"      		 
res2@tmYRLabelsOn 				= True



resP                     		= True 

            


; define variable resources

res@gsnCenterString 			= "~Z75~ global mean temp reconstruction (black) and two times PMIP3 std (red) corrected data"
res@trXMinF	         			= 856             	
res@trXMaxF	       	  			= 1845
res2@trXMinF	         			= 856             	
res2@trXMaxF	       	  			= 1845
	
; global mean anomaly plot
 
	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_0851-1849_past1000_global_mean_anomaly_decadal_running_std_envelope_detrended")              
model_plot = new(2,graphic)
	res@trYMinF	            		= -0.9          ; set x-axis minimum
	res@trYMaxF	            		= 0.9
	res2@trYMinF	            		= -0.9          ; set x-axis minimum
	res2@trYMaxF	            		= 0.9
	res@tiMainString				= "global mean anomaly" 

	res@gsnXYFillColors = (/0.80,0.00,0.00,0.30/) 
    res@xyLineColor = -1 
   	model_plot(0) = gsn_csm_xy (wks,time_running,gm_bnd(:,:),res)
	model_plot(1) = gsn_csm_xy (wks,time_running,all_fields_gm_anomaly_running(ncl_join|10,time|:),res2)
	overlay(model_plot(1),model_plot(0))
	
    draw(model_plot)
   frame(wks)
	


       

; NH mean anomaly plot

	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_0851-1849_past1000_NH_mean_anomaly_decadal_running_std_envelope_detrended")               
model_plot = new(2,graphic)
res@gsnCenterString 			= "~Z75~ NH mean temp reconstruction (black) and two times PMIP3 std (red) corrected data"


	res@trYMinF	            		= -0.9          ; set x-axis minimum
	res@trYMaxF	            		= 0.9
	res@tiMainString				= "NH mean anomaly" 

	;model_plot = gsn_csm_xy (wks,time_running,all_fields_nh_anomaly_running(ncl_join|9,time|:),res) 
 	res@gsnXYFillColors = (/0.80,0.00,0.00,0.30/) 
     res@xyLineColor = -1 
    model_plot(0) = gsn_csm_xy (wks,time_running,nh_bnd(:,:),res)
 	model_plot(1) = gsn_csm_xy (wks,time_running,all_fields_nh_anomaly_running(ncl_join|10,time|:),res2)
 	overlay(model_plot(1),model_plot(0))
	
     draw(model_plot)
    frame(wks)
	  

end

