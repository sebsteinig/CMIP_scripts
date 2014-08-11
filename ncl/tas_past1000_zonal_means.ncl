;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
;*****************************************************************************************

begin

CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP/"

means=(/"decadal_mean","decadal_mean_detrended"/)

do ii=0,dimsizes(means)-1

zonal_mean_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/zonal_mean_anomaly_"+means(ii)+"/"
model_name_files=systemfunc ("ls "+CMIP_dir+"processed/CMIP5/past1000/Amon/tas/zonal_mean_anomaly_decadal_mean/*.nc")
zonal_mean_files = systemfunc ("ls "+zonal_mean_directory+"*.nc")
zonal_mean_tmp=addfiles(zonal_mean_files,"r")
ListSetType (zonal_mean_tmp, "join")

proxy_zonal_mean_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_0851-1849_"+means(ii)+"_zonal_mean_anomaly.nc","r")

model_name=model_name_files
do nt = 0,(dimsizes(model_name_files)-1)
	strs=str_split(model_name_files(nt),"_")
	model_name(nt)=strs(6)
	delete(strs)
end do

zonal_mean=zonal_mean_tmp[:]->tas(:,:,:,0)
dims=dimsizes(zonal_mean)
proxy_zonal_mean=new((/1,dims(1),36/),float)

proxy_zonal_mean(0,:,:)=proxy_zonal_mean_tmp->tas(:,:,0)

all_fields=array_append_record(zonal_mean,proxy_zonal_mean,0)

names=array_append_record(model_name,"Mann et al. 2009 reconstruction",0)

time=zonal_mean_tmp[0]->time
time_new=cd_calendar(time,0)
all_fields&time = time_new(:,0)


;*************************
; plot
;*************************

 wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/zonal_mean/tas_0851-1849_past1000_zonal_mean_anomaly_"+means(ii))  ; open workstation 
 plot = new(11,graphic)
 gsn_define_colormap(wks,"ncl_default")
 res                  = True                ; plot mods desired
 res@gsnDraw  = False                          ; don't draw
 res@gsnFrame = False                          ; don't advance frame
 res@tiYAxisString    = "Latitude"              ; y axis title
 res@tiXAxisString    = "Year"              ; y axis title
 res@lbLabelBarOn         = False              	; turn off individual lb's
 res@cnLineLabelsOn       = False             	; default is True
 

 res@cnFillOn         = True                ; color on
 res@lbOrientation    = "Vertical"          ; vertical label bar
 res@cnLinesOn        = False               ; turn off contour lines
 res@gsnSpreadColors  = True                ; use full range of color map

 res@cnLevelSelectionMode = "ManualLevels" ; manual levels
 res@cnMinLevelValF       = -1.0
 res@cnMaxLevelValF       =  1.0
 res@cnLevelSpacingF      =  0.1 
 
 res@gsnRightString		= "deg C"
 res@cnFillMode       = "RasterFill"       ; Raster Mode
 res@cnInfoLabelOn       = False       ; turn off info label
 
 

 do nn=0,10
    res@tiMainString     = names(nn)     ; title
 	plot(nn) = gsn_csm_lat_time(wks, all_fields(ncl_join|nn,lat|:,time|:), res )
 end do
 
 resP                  = True                   ; modify the panel plot
 resP@txString         = "Zonal mean temperature anomalies for past1000 "+means(ii)
 resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
 resP@gsnPanelLabelBar = True                   ; add common label bar
 resP@lbOrientation       = "horizontal" ; vertical label bar

 gsn_panel(wks,plot,(/3,4/),resP)
 
delete([/zonal_mean_directory,zonal_mean_files,zonal_mean_tmp,proxy_zonal_mean_tmp,zonal_mean,proxy_zonal_mean,all_fields,time,time_new,model_name/])
 
 end do

end
