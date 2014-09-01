load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  

begin

; detect CMIP directory
wd = systemfunc("pwd")
dir_split = str_split(wd, "/") 
CMIP_dir=str_concat("/"+dir_split(0:dimsizes(dir_split)-3))

print("The current working directory is: "+(CMIP_dir(0)))

; load data

directory=CMIP_dir+"/data/KCM/"

P90_f = addfile(directory+"P90/P90_ym.temp2.nc","r")
P93_f = addfile(directory+"P93/P93_ym.temp2.nc","r")

P90_MCA_f = addfile(directory+"P90/MCA/P90_MCA_ensemble.nc","r")
P90_LIA_f = addfile(directory+"P90/LIA/P90_LIA_ensemble.nc","r")
P93_MCA_f = addfile(directory+"P93/MCA/P93_MCA_ensemble.nc","r")
P93_LIA_f = addfile(directory+"P93/LIA/P93_LIA_ensemble.nc","r")

P90=P90_f->temp2
P93=P93_f->temp2
P90_MCA=P90_MCA_f->temp2
P90_LIA=P90_LIA_f->temp2
P93_MCA=P93_MCA_f->temp2
P93_LIA=P93_LIA_f->temp2




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Plots
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

res                  = True                ; plot mods desired
res@gsnDraw  = False                          ; don't draw
res@gsnFrame = False                          ; don't advance frame
res@lbLabelBarOn         = False             	; turn off individual lb's
res@cnLineLabelsOn       = False             	; default is True

res@cnLevelSelectionMode = "ManualLevels" ; manual levels
res@cnMinLevelValF       = -.5
res@cnMaxLevelValF       =  .5
res@cnLevelSpacingF      =  .05

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
res2@cnMaxLevelValF      = 0.1        ; set max contour level
res2@cnLevelSpacingF     = 0.01        ; set contour spacing
res2@cnLineLabelsOn       = False             	; default is True
res2@cnInfoLabelOn       = False       ; turn off info label
res2@gsnLeftString=""
res2@gsnRightString=""
res2@cnFillScaleF=1.0
res2@cnFillDotSizeF=0.003


resP                  = True                   ; modify the panel plot
resP@lbOrientation    = "Horizontal"          ; vertical label bar
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
resP@gsnPanelLabelBar = True                   ; add common label bar

siglvl=0.01

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;MCA

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/KCM_MCA")  ; open workstation 
plot = new(2,graphic)
plot2 = new(2,graphic)

gsn_define_colormap(wks,"BlueDarkRed18")

;P90

res@tiMainString     = "P90"
MCA=dim_avg_n_Wrap(P90_MCA,0)
whole_period=dim_avg_n_Wrap(P90,0)
field_to_plot=MCA-whole_period
copy_VarMeta(MCA,field_to_plot)
plot(0) = gsn_csm_contour_map(wks,field_to_plot,res)

; test significance
var_MCA=dim_variance_n_Wrap(P90_MCA,0)
var_whole_period=dim_variance_n_Wrap(P90,0)
size_MCA=equiv_sample_size (P90_MCA(lat|:,lon|:,time|:),siglvl,0)
size_whole_period=equiv_sample_size (P90(lat|:,lon|:,time|:),siglvl,0)

prob=ttest(MCA,var_MCA,size_MCA,whole_period,var_whole_period,size_whole_period,True,False)
copy_VarMeta(MCA,prob)
plot2(0)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res2)
plot2(0)=ShadeLtContour(plot2(0), 0.02, 3)
overlay (plot(0), plot2(0))

;P93

res@tiMainString     = "P93"
MCA=dim_avg_n_Wrap(P93_MCA,0)
whole_period=dim_avg_n_Wrap(P93,0)
field_to_plot=MCA-whole_period
copy_VarMeta(MCA,field_to_plot)
plot(1) = gsn_csm_contour_map(wks,field_to_plot,res)

; test significance
var_MCA=dim_variance_n_Wrap(P93_MCA,0)
var_whole_period=dim_variance_n_Wrap(P93,0)
size_MCA=equiv_sample_size (P93_MCA(lat|:,lon|:,time|:),siglvl,0)
size_whole_period=equiv_sample_size (P93(lat|:,lon|:,time|:),siglvl,0)

prob=ttest(MCA,var_MCA,size_MCA,whole_period,var_whole_period,size_whole_period,True,False)
copy_VarMeta(MCA,prob)
plot2(1)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res2)
plot2(1)=ShadeLtContour(plot2(1), 0.02, 3)
overlay (plot(1), plot2(1))



resP@txString         = "~Z75~Surface temperature anomalies for KCM MCA composites"

gsn_panel(wks,plot,(/2,1/),resP)    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;LIA

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/KCM_LIA")  ; open workstation 
plot = new(2,graphic)
plot2 = new(2,graphic)

gsn_define_colormap(wks,"BlueDarkRed18")

;P90

res@tiMainString     = "P90"
LIA=dim_avg_n_Wrap(P90_LIA,0)
whole_period=dim_avg_n_Wrap(P90,0)
field_to_plot=LIA-whole_period
copy_VarMeta(LIA,field_to_plot)
plot(0) = gsn_csm_contour_map(wks,field_to_plot,res)

; test significance
var_LIA=dim_variance_n_Wrap(P90_LIA,0)
var_whole_period=dim_variance_n_Wrap(P90,0)
size_LIA=equiv_sample_size (P90_LIA(lat|:,lon|:,time|:),siglvl,0)
size_whole_period=equiv_sample_size (P90(lat|:,lon|:,time|:),siglvl,0)

prob=ttest(LIA,var_LIA,size_LIA,whole_period,var_whole_period,size_whole_period,True,False)
copy_VarMeta(LIA,prob)
plot2(0)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res2)
plot2(0)=ShadeLtContour(plot2(0), 0.02, 3)
overlay (plot(0), plot2(0))

;P93

res@tiMainString     = "P93"
LIA=dim_avg_n_Wrap(P93_LIA,0)
whole_period=dim_avg_n_Wrap(P93,0)
field_to_plot=LIA-whole_period
copy_VarMeta(LIA,field_to_plot)
plot(1) = gsn_csm_contour_map(wks,field_to_plot,res)

; test significance
var_LIA=dim_variance_n_Wrap(P93_LIA,0)
var_whole_period=dim_variance_n_Wrap(P93,0)
size_LIA=equiv_sample_size (P93_LIA(lat|:,lon|:,time|:),siglvl,0)
size_whole_period=equiv_sample_size (P93(lat|:,lon|:,time|:),siglvl,0)

prob=ttest(LIA,var_LIA,size_LIA,whole_period,var_whole_period,size_whole_period,True,False)
copy_VarMeta(LIA,prob)
plot2(1)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res2)
plot2(1)=ShadeLtContour(plot2(1), 0.02, 3)
overlay (plot(1), plot2(1))



resP@txString         = "~Z75~Surface temperature anomalies for KCM LIA composites"

gsn_panel(wks,plot,(/2,1/),resP)          

      

end