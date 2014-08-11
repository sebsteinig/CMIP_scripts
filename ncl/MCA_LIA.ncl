;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

; load data

CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP/"

directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/"

f_MCA = systemfunc ("ls "+directory+"MCA_anomaly_decadal_mean/*.nc")
f_LIA = systemfunc ("ls "+directory+"LIA_anomaly_decadal_mean/*.nc")
files_MCA=addfiles(f_MCA,"r")
files_LIA=addfiles(f_LIA,"r")
ListSetType (files_MCA, "join")
ListSetType (files_LIA, "join")

proxy_MCA=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_MCA_anomaly.nc","r")
proxy_LIA=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_LIA_anomaly.nc","r")


model_name=f_MCA
do nt = 0,(dimsizes(f_MCA)-1)
	strs=str_split(f_MCA(nt),"_")
	model_name(nt)=strs(5)
	delete(strs)
end do

fields_MCA=files_MCA[:]->tas(:,0,:,:)
fields_LIA=files_LIA[:]->tas(:,0,:,:)

proxy_field_MCA=proxy_MCA->tas(0,:,:)
proxy_field_LIA=proxy_LIA->tas(0,:,:)

MCA_bias=proxy_field_MCA-fields_MCA(9,:,:)
LIA_bias=proxy_field_LIA-fields_LIA(9,:,:)

copy_VarMeta(proxy_field_MCA,MCA_bias)
copy_VarMeta(proxy_field_LIA,LIA_bias)

MCA_std=dim_stddev_n_Wrap(fields_MCA(0:8,:,:),0)*2
LIA_std=dim_stddev_n_Wrap(fields_LIA(0:8,:,:),0)*2

copy_VarMeta(proxy_field_MCA,MCA_std)
copy_VarMeta(proxy_field_LIA,LIA_std)

MCA_sig=MCA_std
MCA_sig=where(MCA_std.le.abs(MCA_bias),0,1)
LIA_sig=LIA_std
LIA_sig=where(LIA_std.le.abs(LIA_bias),0,1)



;*****************************************************************************************


wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/MCA_LIA")  ; open workstation 
plot = new(4,graphic)
plot2 = new(4,graphic)

gsn_define_colormap(wks,"BlueDarkRed18")
res                  = True                ; plot mods desired
res@gsnDraw  = False                          ; don't draw
res@gsnFrame = False                          ; don't advance frame
;res@tiYAxisString    = "Latitude"              ; y axis title
;res@tiXAxisString    = "Year"              ; y axis title
res@lbLabelBarOn         = False             	; turn off individual lb's
res@cnLineLabelsOn       = False             	; default is True

res@cnLevelSelectionMode = "ManualLevels" ; manual levels
res@cnMinLevelValF       = -.6
res@cnMaxLevelValF       =  .6
res@cnLevelSpacingF      =  .1
;res@gsnRightString="linear trend/century [deg C]"


res@cnFillOn         = True               ; color Fill 
res@cnFillMode       = "RasterFill"       ; Raster Mode
res@cnLinesOn        =  False             ; Turn off contour lines
res@gsnSpreadColors  = True                ; use full range of color map

res2=True
res2@gsnDraw             = False       ; Do not draw plot
res2@gsnFrame            = False       ; Do not advance frome
res2@cnLinesOn        =  False             ; Turn off contour lines
res2@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
res2@cnMinLevelValF      = 0.00        ; set min contour level
res2@cnMaxLevelValF      = 0.05        ; set max contour level
res2@cnLevelSpacingF     = 0.01        ; set contour spacing
res2@cnLineLabelsOn       = False             	; default is True
res2@cnInfoLabelOn       = False       ; turn off info label
res2@gsnLeftString=""
res2@gsnRightString=""
res2@cnFillScaleF=0.7
res2@cnFillDotSizeF=0.003


resP                  = True                   ; modify the panel plot
resP@lbOrientation    = "Horizontal"          ; vertical label bar
resP@txString         = "Bias between mmm and reconstruction for MCA and LIA ~C~ ~Z50~                                              stippling where bias greater than 2 std of model simulations"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
resP@gsnPanelLabelBar = True                   ; add common label bar

res@tiMainString     = "~Z75~ MCA bias (reconstruction minus ensemble)"
plot(0) = gsn_csm_contour_map(wks,MCA_bias,res)
plot2(0)=gsn_csm_contour(wks,gsn_add_cyclic_point(MCA_sig), res2)
plot2(0)=ShadeLtContour(plot2(0), 0.02, 17)
overlay (plot(0), plot2(0))

res@tiMainString     = "~Z75~ LIA bias (reconstruction minus ensemble)"
plot(1) = gsn_csm_contour_map(wks,LIA_bias,res)
plot2(1)=gsn_csm_contour(wks,gsn_add_cyclic_point(LIA_sig), res2)
plot2(1)=ShadeLtContour(plot2(1), 0.02, 17)
overlay (plot(1), plot2(1))





f_MCA = systemfunc ("ls "+directory+"MCA_anomaly_decadal_mean_detrended/*.nc")
f_LIA = systemfunc ("ls "+directory+"LIA_anomaly_decadal_mean_detrended/*.nc")
files_MCA=addfiles(f_MCA,"r")
files_LIA=addfiles(f_LIA,"r")
ListSetType (files_MCA, "join")
ListSetType (files_LIA, "join")

proxy_MCA=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_MCA_anomaly.nc","r")
proxy_LIA=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_LIA_anomaly.nc","r")


model_name=f_MCA
do nt = 0,(dimsizes(f_MCA)-1)
	strs=str_split(f_MCA(nt),"_")
	model_name(nt)=strs(5)
	delete(strs)
end do

fields_MCA=files_MCA[:]->tas(:,0,:,:)
fields_LIA=files_LIA[:]->tas(:,0,:,:)

proxy_field_MCA=proxy_MCA->tas(0,:,:)
proxy_field_LIA=proxy_LIA->tas(0,:,:)

MCA_bias=proxy_field_MCA-fields_MCA(9,:,:)
LIA_bias=proxy_field_LIA-fields_LIA(9,:,:)

copy_VarMeta(proxy_field_MCA,MCA_bias)
copy_VarMeta(proxy_field_LIA,LIA_bias)

MCA_std=dim_stddev_n_Wrap(fields_MCA(0:8,:,:),0)*2
LIA_std=dim_stddev_n_Wrap(fields_LIA(0:8,:,:),0)*2

copy_VarMeta(proxy_field_MCA,MCA_std)
copy_VarMeta(proxy_field_LIA,LIA_std)

MCA_sig=MCA_std
MCA_sig=where(MCA_std.le.abs(MCA_bias),0,1)
LIA_sig=LIA_std
LIA_sig=where(LIA_std.le.abs(LIA_bias),0,1)




res@tiMainString     = "~Z75~ MCA bias corrected (reconstruction minus ensemble)"
plot(2) = gsn_csm_contour_map(wks,MCA_bias,res)
plot2(2)=gsn_csm_contour(wks,gsn_add_cyclic_point(MCA_sig), res2)
plot2(2)=ShadeLtContour(plot2(2), 0.02, 17)
overlay (plot(2), plot2(2))

res@tiMainString     = "~Z75~ LIA bias corrected (reconstruction minus ensemble)"
plot(3) = gsn_csm_contour_map(wks,LIA_bias,res)
plot2(3)=gsn_csm_contour(wks,gsn_add_cyclic_point(LIA_sig), res2)
plot2(3)=ShadeLtContour(plot2(3), 0.02, 17)
overlay (plot(3), plot2(3))


gsn_panel(wks,plot,(/2,2/),resP)               ; create panel plot

end