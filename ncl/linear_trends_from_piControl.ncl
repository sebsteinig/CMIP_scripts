;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

; load data

CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP/"

directory=CMIP_dir+"processed/CMIP5/piControl/Amon/tas/trends/"
f = systemfunc ("ls "+directory+"*.nc")
files=addfiles(f,"r")
ListSetType (files, "join")

model_name=f
do nt = 0,(dimsizes(f)-1)
	strs=str_split(f(nt),"_")
	model_name(nt)=strs(2)
	delete(strs)
end do

fields_tmp=files[:]->tas(:,0,:,:)
fields=fields_tmp*100
copy_VarMeta(fields_tmp,fields)

;*****************************************************************************************


 wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/tas_trends_piControl")  ; open workstation 
 plot = new(9,graphic)
 gsn_define_colormap(wks,"BlueDarkRed18")
 res                  = True                ; plot mods desired
 res@gsnDraw  = False                          ; don't draw
 res@gsnFrame = False                          ; don't advance frame
 ;res@tiYAxisString    = "Latitude"              ; y axis title
 ;res@tiXAxisString    = "Year"              ; y axis title
 res@lbLabelBarOn         = False             	; turn off individual lb's
 res@cnLineLabelsOn       = False             	; default is True
 
 res@cnLevelSelectionMode = "ManualLevels" ; manual levels
 res@cnMinLevelValF       = -0.2
 res@cnMaxLevelValF       =  0.2
 res@cnLevelSpacingF      =  .025
res@gsnRightString="linear trend/century [deg C]"
 
 
  res@cnFillOn         = True               ; color Fill 
  res@cnFillMode       = "RasterFill"       ; Raster Mode
  res@cnLinesOn        =  False             ; Turn off contour lines
 res@gsnSpreadColors  = True                ; use full range of color map
 
 resP                  = True                   ; modify the panel plot
 resP@lbOrientation    = "Horizontal"          ; vertical label bar
 resP@txString         = "Linear trends from control simulation"
 resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
 resP@gsnPanelLabelBar = True                   ; add common label bar
 
 do nn=0,8
    res@tiMainString     = model_name(nn)     ; title
 	plot(nn) = gsn_csm_contour_map(wks,fields(nn,:,:),res)
 end do

gsn_panel(wks,plot,(/3,3/),resP)               ; create panel plot

end