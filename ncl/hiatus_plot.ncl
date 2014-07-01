;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

CMIP_dir="/Volumes/HiWi_data/CMIP_test/"

trend_directory=CMIP_dir+"processed/CMIP5/rcp45/Amon/tas/hiatus/"

trend_files = systemfunc ("ls "+trend_directory+"*2014*"+"*.nc")
trend_files_2100 = systemfunc ("ls "+trend_directory+"*2100*"+"*.nc")


trends=addfiles(trend_files,"r")
trends_2100=addfiles(trend_files_2100,"r")

ListSetType (trends, "join")
ListSetType (trends_2100, "join")

obs=addfile(CMIP_dir+"data/observations/HadCRUT4/HadCRUT4_1900-2014_gm_am_anomaly.nc","r")



model_name=trend_files
do nt = 0,(dimsizes(trend_files)-1)
	strs=str_split(trend_files(nt),"_")
	model_name(nt)=strs(4)
	delete(strs)
end do


trend_series=trends[:]->tas(:,:,0,0)
trend_series_2100=trends_2100[:]->tas(:,:,0,0)

obs_series=obs->temperature_anomaly(:,0,0)


runave_obs=runave(obs_series,10,0)

runave_CMIP5=runave(trend_series,10,0)
runave_CMIP5_2100=runave(trend_series_2100,10,0)

runave_trend_obs=runave_obs
runave_trend_CMIP5=runave(trend_series,10,0)
runave_trend_CMIP5_2100=runave(trend_series_2100,10,0)




do nn=4,109
	dummy_obs=dtrend(obs_series(nn-4:nn+5),True)
	dummy_CMIP5=dtrend(trend_series(:,nn-4:nn+5),True)
	runave_trend_obs(nn)=(dummy_obs@slope)*10
	runave_trend_CMIP5(:,nn)=(dummy_CMIP5@slope)*10
end do

do nn=4,195
	dummy_CMIP5_2100=dtrend(trend_series_2100(:,nn-4:nn+5),True)
	runave_trend_CMIP5_2100(:,nn)=(dummy_CMIP5_2100@slope)*10
end do


time = ispan(1900,2100,1)

wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/tas/gm/tas_1900-2014_global_mean_trend")               ; open pdf file

res                    = True             ; plot mods desired
res@gsnDraw            = False           ; don't draw yet
res@gsnFrame           = False           ; don't advance frame yet
res@vpHeightF 	 = 0.4               ; change aspect ratio of plot
res@vpWidthF 	         = 0.7
res@trXMinF	         = 1900             ; set x-axis minimum
res@trXMaxF	         = 2014
ymin=16
ymax=20
res@trYMinF	         = -1.0          ; set x-axis minimum
res@trYMaxF	         = 1.5
res@gsnMaximize      = True                   ; use full page

res@xyMonoLineColor    = True             ; want colored lines
res@xyLineColor       = "coral" ; colors chosen
res@tiMainString=	"global mean surface air temperature" 
res@tiYAxisString	 = "[~S~o~N~C]"     ; add an axis title    	
res@tiXAxisString	 = "Year"      ; add an axis title    
 res@tmYRLabelsOn = True
model_plot = gsn_csm_xy (wks,time,trend_series(ncl_join|0:dimsizes(trend_files)-2,time|:),res)       ; create line plot

res@xyLineColor       = "red" ; colors chosen
res@xyLineThicknesses  = (/5/)
ensemble_plot = gsn_csm_xy (wks,time,trend_series(ncl_join|dimsizes(trend_files)-1,time|:),res)       ; create line plot

res@xyLineColor       = "black" ; colors chosen
res@xyLineThicknesses  = (/5/)
obs_plot = gsn_csm_xy (wks,time,obs_series,res)       ; create line plot

overlay(model_plot,ensemble_plot)
overlay(model_plot,obs_plot)

res_vert = True
res_vert@gsLineColor       = "black"    
res_vert@gsLineDashPattern    = 1
gsn_polyline(wks,model_plot,(/1900,2014/),(/0,0/),res_vert)


res_text                    = True                  ; text mods desired
res_text@txFontHeightF      = 0.015                 ; change text size
res_text@txJust             = "CenterLeft"          ; text justification
res_lines                   = True                  ; polyline mods desired
  
res_lines@gsLineDashPattern = 0.                    ; solid line
res_lines@gsLineThicknessF  = 5.                    ; line thicker
res_lines@gsLineColor       = "blue"                 ; line color
xx = (/1907,1917/)
yy = (/1.3,1.3/)
res_lines@gsLineColor       = "black"                                 ; change to blue
dum1 = gsn_add_polyline(wks,model_plot,xx,yy,res_lines)              ; add polyline
dum2 = gsn_add_text(wks,model_plot,"Observations (HadCRUT4)",1920,1.3,res_text); add text

yy = (/1.1,1.1/)
res_lines@gsLineColor       = "red"                                 ; change to blue
dum3 = gsn_add_polyline(wks,model_plot,xx,yy,res_lines)                ; add polyline
dum4 = gsn_add_text(wks,model_plot,"CMIP5 ensemble mean",1920,1.1,res_text)       ; add text

yy = (/0.9/)
res_lines@gsLineColor       = "coral"                                 ; change to blue
dum5 = gsn_add_polyline(wks,model_plot,xx,yy,res_lines)                ; add polyline
dum6 = gsn_add_text(wks,model_plot,"CMIP5 ensemble member",1920,0.9,res_text)       ; add text


pres = True
;maximize_output(wks,pres)
draw(wks)




wks_2 = gsn_open_wks("pdf" ,CMIP_dir+"/plots/tas/gm/tas_decadal_trends")               ; open pdf file

res@gsnDraw            = False           ; don't draw yet
res@gsnFrame           = False           ; don't advance frame yet
res@vpHeightF 	 = 0.4               ; change aspect ratio of plot
res@vpWidthF 	         = 0.7
res@trXMinF	         = 1900             ; set x-axis minimum
res@trXMaxF	         = 2014
ymin=16
ymax=20
res@trYMinF	         = -1.0          ; set x-axis minimum
res@trYMaxF	         = 1.5
res@gsnMaximize      = True                   ; use full page

res@xyMonoLineColor    = True             ; want colored lines

res@tiMainString	="decadal trends"	
res@gsnCenterString = "global mean surface air temperature" 
res@gsnCenterStringOrthogonalPosF =0.05
res@tiYAxisString	 = "[~S~o~N~C per decade]"     ; add an axis title    	
res@tiXAxisString	 = "Year"      ; add an axis title

res@xyLineColor       = "coral" ; colors chosen
res@xyLineThicknesses  = (/1/)
model_plot = gsn_csm_xy (wks_2,time,runave_trend_CMIP5(0:29,:),res)       ; create line plot


	
res@xyLineColor       = "black" ; colors chosen
    
 res@tmYRLabelsOn = True
 res@xyLineThicknesses  = (/5/)
obs_plot = gsn_csm_xy (wks_2,time,runave_trend_obs,res)       ; create line plot

res@xyLineColor       = "red" ; colors chosen
res@xyLineThicknesses  = (/5/)
ensemble_plot = gsn_csm_xy (wks_2,time,runave_trend_CMIP5(30,:),res)       ; create line plot

overlay(model_plot,ensemble_plot)
overlay(model_plot,obs_plot)

res_vert = True
res_vert@gsLineColor       = "black"    
res_vert@gsLineDashPattern    = 1
gsn_polyline(wks_2,obs_plot,(/1900,2014/),(/0,0/),res_vert)


res_text                    = True                  ; text mods desired
res_text@txFontHeightF      = 0.015                 ; change text size
res_text@txJust             = "CenterLeft"          ; text justification
res_lines                   = True                  ; polyline mods desired
  
res_lines@gsLineDashPattern = 0.                    ; solid line
res_lines@gsLineThicknessF  = 5.                    ; line thicker
res_lines@gsLineColor       = "blue"                 ; line color

xx = (/1907,1917/)
yy = (/1.3,1.3/)
res_lines@gsLineColor       = "black"                                 ; change to blue
dum1 = gsn_add_polyline(wks,model_plot,xx,yy,res_lines)              ; add polyline
dum2 = gsn_add_text(wks_2,model_plot,"Observations (HadCRUT4)",1920,1.3,res_text); add text

yy = (/1.1,1.1/)
res_lines@gsLineColor       = "red"                                 ; change to blue
dum3 = gsn_add_polyline(wks,model_plot,xx,yy,res_lines)                ; add polyline
dum4 = gsn_add_text(wks_2,model_plot,"CMIP5 ensemble mean",1920,1.1,res_text)       ; add text

yy = (/0.9/)
res_lines@gsLineColor       = "coral"                                 ; change to blue
dum5 = gsn_add_polyline(wks,model_plot,xx,yy,res_lines)                ; add polyline
dum6 = gsn_add_text(wks_2,model_plot,"CMIP5 ensemble member",1920,0.9,res_text)       ; add text




pres = True
draw(wks_2)



wks_3 = gsn_open_wks("pdf" ,CMIP_dir+"/plots/tas/gm/tas_decadal_trends_2100")               ; open pdf file

res@gsnDraw            = False           ; don't draw yet
res@gsnFrame           = False           ; don't advance frame yet
res@vpHeightF 	 = 0.4               ; change aspect ratio of plot
res@vpWidthF 	         = 0.7
res@trXMinF	         = 1900             ; set x-axis minimum
res@trXMaxF	         = 2100
ymin=16
ymax=20
res@trYMinF	         = -1.0          ; set x-axis minimum
res@trYMaxF	         = 1.5
res@gsnMaximize      = True                   ; use full page

res@xyMonoLineColor    = True             ; want colored lines

res@tiMainString	="decadal trends"	
res@gsnCenterString = "global mean surface air temperature" 
res@gsnCenterStringOrthogonalPosF =0.05
res@tiYAxisString	 = "[~S~o~N~C per decade]"     ; add an axis title    	
res@tiXAxisString	 = "Year"      ; add an axis title

res@xyLineColor       = "coral" ; colors chosen
res@xyLineThicknesses  = (/1/)
model_plot = gsn_csm_xy (wks_3,time,runave_trend_CMIP5_2100(0:29,:),res)       ; create line plot


	
res@xyLineColor       = "black" ; colors chosen
    
 res@tmYRLabelsOn = True
 res@xyLineThicknesses  = (/5/)
obs_plot = gsn_csm_xy (wks_3,time,runave_trend_obs,res)       ; create line plot

res@xyLineColor       = "red" ; colors chosen
res@xyLineThicknesses  = (/5/)
ensemble_plot = gsn_csm_xy (wks_3,time,runave_trend_CMIP5_2100(30,:),res)       ; create line plot

overlay(model_plot,ensemble_plot)
overlay(model_plot,obs_plot)

res_vert = True
res_vert@gsLineColor       = "black"    
res_vert@gsLineDashPattern    = 1
gsn_polyline(wks_3,model_plot,(/1900,2100/),(/0,0/),res_vert)


res_text                    = True                  ; text mods desired
res_text@txFontHeightF      = 0.015                 ; change text size
res_text@txJust             = "CenterLeft"          ; text justification
res_lines                   = True                  ; polyline mods desired
  
res_lines@gsLineDashPattern = 0.                    ; solid line
res_lines@gsLineThicknessF  = 5.                    ; line thicker
res_lines@gsLineColor       = "blue"                 ; line color

xx = (/1907,1917/)
yy = (/1.3,1.3/)
res_lines@gsLineColor       = "black"                                 ; change to blue
dum1 = gsn_add_polyline(wks_3,model_plot,xx,yy,res_lines)              ; add polyline
dum2 = gsn_add_text(wks_3,model_plot,"Observations (HadCRUT4)",1920,1.3,res_text); add text

yy = (/1.1,1.1/)
res_lines@gsLineColor       = "red"                                 ; change to blue
dum3 = gsn_add_polyline(wks_3,model_plot,xx,yy,res_lines)                ; add polyline
dum4 = gsn_add_text(wks_3,model_plot,"CMIP5 ensemble mean",1920,1.1,res_text)       ; add text

yy = (/0.9/)
res_lines@gsLineColor       = "coral"                                 ; change to blue
dum5 = gsn_add_polyline(wks_3,model_plot,xx,yy,res_lines)                ; add polyline
dum6 = gsn_add_text(wks_3,model_plot,"CMIP5 ensemble member",1920,0.9,res_text)       ; add text




pres = True
draw(wks_3)


end



