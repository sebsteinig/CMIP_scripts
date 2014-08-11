;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

; load data

CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP/"

directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/remapped_to_HadCRUT4_decadal_mean_detrended/"
;directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/remapped_to_HadCRUT4_decadal_mean/"

f = systemfunc ("ls "+directory+"*.nc")
files=addfiles(f,"r")
ListSetType (files, "join")

proxy=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_0851-1849_decadal_mean.nc","r")

model_name=f
do nt = 0,(dimsizes(f)-1)
	strs=str_split(f(nt),"_")
	model_name(nt)=strs(7)
	;model_name(nt)=strs(6)
	delete(strs)
end do

fields_tmp=files[:]->tas
fields=fields_tmp(ncl_join|:,latitude|:,longitude|:,time|:)

proxy_field_tmp=proxy->tas
proxy_field=proxy_field_tmp(latitude|:,longitude|:,time|:)


ccr=new((/10,36,72/),float)
prob=new((/10,36,72/),float)
copy_VarMeta(fields,ccr)
copy_VarMeta(fields,prob)

do nn=0,9
	ccr(nn,:,:) = escorc(fields(nn,:,:,:),proxy_field)
	prob(nn,:,:) = rtest(ccr(nn,:,:),99,0)
end do

do nn=0,9
	do ii=0,35
		do jj=0,71
			if (prob(nn,ii,jj) .eq. 0) then
				prob(nn,ii,jj)=1
				end if
		end do
	end do
end do

 wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/grid_point_correlations_detrended")  ; open workstation 
 ;wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/grid_point_correlations")  ; open workstation 
 plot = new(10,graphic)
 plot2 = new(10,graphic)
 gsn_define_colormap(wks,"BlueDarkRed18")
 res                  = True                ; plot mods desired
 res@gsnDraw  = False                          ; don't draw
 res@gsnFrame = False                          ; don't advance frame
 res@lbLabelBarOn         = False             	; turn off individual lb's
 res@cnLineLabelsOn       = False             	; default is True
 
 res@cnLevelSelectionMode = "ManualLevels" ; manual levels
 res@cnMinLevelValF       = -.9
 res@cnMaxLevelValF       =  .9
 res@cnLevelSpacingF      =  .1
 
 
  res@cnFillOn         = True               ; color Fill 
  res@cnFillMode       = "RasterFill"       ; Raster Mode
  res@cnLinesOn        =  False             ; Turn off contour lines
 res@gsnSpreadColors  = True                ; use full range of color map
 res@gsnRightString="deg C"
 
 resP                  = True                   ; modify the panel plot
 resP@lbOrientation    = "Horizontal"          ; vertical label bar
 resP@txString         = "Grid-point correlation between models and reconstruction (detrended)"
 ;resP@txString         = "Grid-point correlation between models and reconstruction"
 resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
 resP@gsnPanelLabelBar = True                   ; add common label bar
 
 res2=True
 res2@gsnDraw             = False       ; Do not draw plot
 res2@gsnFrame            = False       ; Do not advance frome
 res2@cnLinesOn        =  False             ; Turn off contour lines
 res2@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
 res2@cnMinLevelValF      = 0.00        ; set min contour level
 res2@cnMaxLevelValF      = 0.15        ; set max contour level
 res2@cnLevelSpacingF     = 0.01        ; set contour spacing
 res2@cnLineLabelsOn       = False             	; default is True
 res2@cnInfoLabelOn       = False       ; turn off info label
 res2@gsnLeftString=""
 res2@gsnRightString=""
 res2@cnFillScaleF=0.5
 res2@cnFillDotSizeF=0.002
 
 
 
 
 do nn=0,9
    res@tiMainString     = model_name(nn)     ; title
 	plot(nn) = gsn_csm_contour_map(wks,ccr(nn,:,:),res)
	plot2(nn)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob(nn,:,:)), res2)
	plot2(nn)=ShadeLtContour(plot2(nn), 0.02, 17)
	overlay (plot(nn), plot2(nn))
 end do

gsn_panel(wks,plot,(/4,3/),resP)               ; create panel plot


end