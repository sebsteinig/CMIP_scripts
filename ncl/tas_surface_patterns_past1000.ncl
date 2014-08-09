;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
;*****************************************************************************************

begin

CMIP_dir="/Volumes/HiWi_data/CMIP/"
directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/extended_to_2000/"
f = systemfunc ("ls "+directory+"*0851-2000_remapbil_HadCRUT4_anomaly.nc")

files=addfiles(f,"r")

ListSetType (files, "join")

model_name=f
do nt = 0,(dimsizes(f)-1)
	strs=str_split(f(nt),"_")
	model_name(nt)=strs(5)
	delete(strs)
end do

print(model_name)

fields=files[:]->tas
time=files[0]->time

printVarSummary(fields)
print(time/365+851)
;*****************************************************************************************


 wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface_fields/tas_0950-1250_past1000_MCA")  ; open workstation 
 plot = new(9,graphic)
 gsn_define_colormap(wks,"ncl_default")
 res                  = True                ; plot mods desired
 res@gsnDraw  = False                          ; don't draw
 res@gsnFrame = False                          ; don't advance frame
 ;res@tiYAxisString    = "Latitude"              ; y axis title
 ;res@tiXAxisString    = "Year"              ; y axis title
 res@lbLabelBarOn         = True             	; turn off individual lb's
 res@cnLineLabelsOn       = False             	; default is True
 
 res@cnLevelSelectionMode = "ManualLevels" ; manual levels
 res@cnMinLevelValF       = -3.
 res@cnMaxLevelValF       =  3.
 res@cnLevelSpacingF      =  .4
 
 res@cnFillOn         = True                ; color on
 res@lbOrientation    = "Horizontal"          ; vertical label bar
 res@cnLinesOn        = False               ; turn off contour lines
 res@gsnSpreadColors  = True                ; use full range of color map
 
 resP                  = True                   ; modify the panel plot
 resP@txString         = "MCA (0950-1250) as anomaly to 1961-1990"
 resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
 ;resP@gsnPanelLabelBar = True                   ; add common label bar
 
 do nn=0,6
    res@tiMainString     = model_name(nn+2)     ; title
	array=dim_avg_n_Wrap(fields(nn+2,99:399,:,:),0)
 	plot(nn) = gsn_csm_contour_map(wks,array,res)
	delete(array)
 end do

gsn_panel(wks,plot,(/3,3/),resP)               ; create panel plot

;*****************************************************************************************

 wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface_fields/tas_1400-1700_past1000_LIA")  ; open workstation 
 plot = new(9,graphic)
 gsn_define_colormap(wks,"ncl_default")
 res                  = True                ; plot mods desired
 res@gsnDraw  = False                          ; don't draw
 res@gsnFrame = False                          ; don't advance frame
 ;res@tiYAxisString    = "Latitude"              ; y axis title
 ;res@tiXAxisString    = "Year"              ; y axis title
 res@lbLabelBarOn         = True             	; turn off individual lb's
 res@cnLineLabelsOn       = False             	; default is True
 
 res@cnLevelSelectionMode = "ManualLevels" ; manual levels
 res@cnMinLevelValF       = -3.
 res@cnMaxLevelValF       =  3.
 res@cnLevelSpacingF      =  .4
 
 res@cnFillOn         = True                ; color on
 res@lbOrientation    = "Horizontal"          ; vertical label bar
 res@cnLinesOn        = False               ; turn off contour lines
 res@gsnSpreadColors  = True                ; use full range of color map
 
 resP                  = True                   ; modify the panel plot
 resP@txString         = "LIA (1400-1700) as anomaly to 1961-1990"
 resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
 ;resP@gsnPanelLabelBar = True                   ; add common label bar
 
 do nn=0,6
    res@tiMainString     = model_name(nn+2)     ; title
	array=dim_avg_n_Wrap(fields(nn+2,549:849,:,:),0)
 	plot(nn) = gsn_csm_contour_map(wks,array,res)
	delete(array)
 end do

gsn_panel(wks,plot,(/3,3/),resP)               ; create panel plot

end
