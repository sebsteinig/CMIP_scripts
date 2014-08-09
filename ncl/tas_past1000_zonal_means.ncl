;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
;*****************************************************************************************

begin

CMIP_dir="/Volumes/HiWi_data/CMIP/"
zonal_mean_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/zonal_means/"
zonal_mean_files = systemfunc ("ls "+zonal_mean_directory+"*851-1849"+"*zonal_mean_anomaly.nc")
zonal_mean_minus_gm_files = systemfunc ("ls "+zonal_mean_directory+"*851-1849"+"*gm_subtracted.nc")

zonal_mean=addfiles(zonal_mean_files,"r")
zonal_mean_minus_gm=addfiles(zonal_mean_minus_gm_files,"r")

proxy_zonal_mean=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/reconstruction_zonal_mean_anomaly.nc","r")
proxy_zonal_mean_minus_gm=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/reconstruction_zonal_mean_anomaly_gm_subtracted.nc","r")


ListSetType (zonal_mean, "join")
ListSetType (zonal_mean_minus_gm, "join")


model_name=zonal_mean_files
do nt = 0,(dimsizes(zonal_mean_files)-1)
	strs=str_split(zonal_mean_files(nt),"_")
	model_name(nt)=strs(4)
	delete(strs)
end do


zonal_mean_monthly=zonal_mean[:]->tas(:,:,:,0)
zonal_mean_minus_gm_monthly=zonal_mean_minus_gm[:]->tas(:,:,:,0)

proxy_zonal_mean_annual=new((/1,36,999/),float)
proxy_zonal_mean_minus_gm_annual=new((/1,36,999/),float)

proxy_zonal_mean_annual_tmp=proxy_zonal_mean->tas(:,:,0)
proxy_zonal_mean_minus_gm_annual_tmp=proxy_zonal_mean_minus_gm->tas(:,:,0)




zonal_mean_annual_tmp=month_to_annual(zonal_mean_monthly(time|:,ncl_join|:,lat|:),1)
zonal_mean_minus_gm_annual_tmp=month_to_annual(zonal_mean_minus_gm_monthly(time|:,ncl_join|:,lat|:),1)

zonal_mean_annual=zonal_mean_annual_tmp(ncl_join|:,lat|:,year|:)
zonal_mean_minus_gm_annual=zonal_mean_minus_gm_annual_tmp(ncl_join|:,lat|:,year|:)

copy_VarMeta(zonal_mean_annual_tmp(0,:,:),proxy_zonal_mean_annual_tmp)
copy_VarMeta(zonal_mean_minus_gm_annual_tmp(0,:,:),proxy_zonal_mean_minus_gm_annual_tmp)

proxy_zonal_mean_annual_tmp!0="year"
proxy_zonal_mean_minus_gm_annual_tmp!0="year"

proxy_zonal_mean_annual_tmp2=proxy_zonal_mean_annual_tmp(lat|:,year|:)
proxy_zonal_mean_minus_gm_annual_tmp2=proxy_zonal_mean_minus_gm_annual_tmp(lat|:,year|:)

proxy_zonal_mean_annual(0,:,:)=proxy_zonal_mean_annual_tmp2
proxy_zonal_mean_minus_gm_annual(0,:,:)=proxy_zonal_mean_minus_gm_annual_tmp2

proxy_zonal_mean_annual!0="ncl_join"
proxy_zonal_mean_minus_gm_annual!0="ncl_join"



all_fields=array_append_record(zonal_mean_annual,zonal_mean_annual,0)
all_fields_minus_gm=array_append_record(zonal_mean_minus_gm_annual,zonal_mean_minus_gm_annual,0)

names=array_append_record(model_name,"Mann et al. 2009 reconstruction",0)

all_fields_100=runave(all_fields,100,0)
all_fields_minus_gm_100=runave(all_fields_minus_gm,100,0)
copy_VarMeta(all_fields,all_fields_100)
copy_VarMeta(all_fields_minus_gm,all_fields_minus_gm_100)

;*************************
; plot
;*************************

 wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/zonal_mean/tas_0851-1849_past1000_zonal_mean_anomaly")  ; open workstation 
 plot = new(9,graphic)
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
 res@cnMinLevelValF       = -1.4
 res@cnMaxLevelValF       =  1.4
 res@cnLevelSpacingF      =  0.2 
 
 res@gsnRightString		= "degC"
 
 res@tmXBMode      = "Explicit"                ; Define own tick mark labels.
 res@tmXBValues    = (/  150. ,  350.,  550.,   750., 950 /)
 res@tmXBLabels    = (/"1000","1200","1400","1600" ,"1800" /)

 do nn=0,8
    res@tiMainString     = names(nn)     ; title
 	plot(nn) = gsn_csm_lat_time(wks, all_fields(nn,:,:), res )
 end do
 
 resP                  = True                   ; modify the panel plot
 resP@txString         = "Annual mean surface temperature anomalies 0850-1850 ~C~ from CMIP5 past1000 experiment"
 resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
 resP@gsnPanelLabelBar = True                   ; add common label bar

 gsn_panel(wks,plot,(/3,3/),resP)

;*****************************************************************************************
  
 wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/zonal_mean/tas_0851-1849_past1000_zonal_mean_anomaly_gm_subtracted")  ; open workstation 
 plot = new(9,graphic)
 gsn_define_colormap(wks,"ncl_default")
 res2                  = True                ; plot mods desired
 res2@gsnDraw  = False                          ; don't draw
 res2@gsnFrame = False                          ; don't advance frame
 res2@tiYAxisString    = "Latitude"              ; y axis title
 res2@tiXAxisString    = "Year"              ; y axis title
 res2@lbLabelBarOn         = False              	; turn off individual lb's
 res2@cnLineLabelsOn       = False             	; default is True
 

 res2@cnFillOn         = True                ; color on
 res2@lbOrientation    = "Vertical"          ; vertical label bar
 res2@cnLinesOn        = False               ; turn off contour lines
 res2@gsnSpreadColors  = True                ; use full range of color map

 res2@cnLevelSelectionMode = "ManualLevels" ; manual levels
 res2@cnMinLevelValF       = -1.4
 res2@cnMaxLevelValF       =  1.4
 res2@cnLevelSpacingF      =  0.2 
 
 res2@gsnRightString		= "degC"
 
 res2@tmXBMode      = "Explicit"                ; Define own tick mark labels.
 res2@tmXBValues    = (/  150. ,  350.,  550.,   750., 950 /)
 res2@tmXBLabels    = (/"1000","1200","1400","1600" ,"1800" /)

 do nn=0,8
    res2@tiMainString     = names(nn)     ; title
 	plot(nn) = gsn_csm_lat_time(wks, all_fields_minus_gm(nn,:,:), res2 )
 end do
 
 res2P                  = True                   ; modify the panel plot
 res2P@txString         = "Annual mean surface temperature anomalies 0850-1850 ~C~ from CMIP5 past1000 experiment (gm field subtracted)"
 res2P@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
 res2P@gsnPanelLabelBar = True                   ; add common label bar
 
 gsn_panel(wks,plot,(/3,3/),res2P)

end