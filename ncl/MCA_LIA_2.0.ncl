load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  

begin

; detect CMIP directory
wd = systemfunc("pwd")
dir_split = str_split(wd, "/") 
CMIP_dir=str_concat("/"+dir_split(0:dimsizes(dir_split)-3))

print("The current working directory is: "+(CMIP_dir(0)))

; load data

directory=CMIP_dir+"/processed/CMIP5/past1000/Amon/tas/"

f = systemfunc ("ls "+directory+"remapped_to_HadCRUT4_decadal_running_mean/*.nc")
f_detrended = systemfunc ("ls "+directory+"remapped_to_HadCRUT4_decadal_running_mean_detrended/*.nc")
files=addfiles(f,"r")
files_detrended=addfiles(f_detrended,"r")
ListSetType (files, "join")
ListSetType (files_detrended, "join")

proxy_f=addfile(CMIP_dir+"/data/observations/Mann_et_al_2009/mann2009_reconstruction_0856-1845_decadal_mean.nc","r")


model_name=f
do nt = 0,(dimsizes(f)-1)
	strs=str_split(f(nt),"_")
	model_name(nt)=strs(7)
	delete(strs)
end do

fields=files[:]->tas
fields_detrended=files_detrended[:]->tas
dims=dimsizes(fields)
proxy_field=new((/1,dims(1),dims(2),dims(3)/),"float")
copy_VarMeta(fields,proxy_field)
proxy_field=proxy_f->tas

; change time axis to years
time=files[0]->time
time_new=cd_calendar(time,0)
fields&time = time_new(:,0)
fields_detrended&time = time_new(:,0)
proxy_field&time = time_new(:,0)

all_fields=array_append_record(fields,proxy_field,0)
all_fields_detrended=array_append_record(fields_detrended,proxy_field,0)
names=array_append_record(model_name,"Mann et al. 2009 reconstruction",0)

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
res2@cnFillScaleF=0.5
res2@cnFillDotSizeF=0.002


resP                  = True                   ; modify the panel plot
resP@lbOrientation    = "Horizontal"          ; vertical label bar
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
resP@gsnPanelLabelBar = True                   ; add common label bar

siglvl=0.05

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;MCA

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/MCA_all_models")  ; open workstation 
plot = new((dimsizes(names)),graphic)
plot2 = new((dimsizes(names)),graphic)

print("Creating Plot: MCA")

gsn_define_colormap(wks,"BlueDarkRed18")

do nn=0,(dimsizes(names)-1)

	print("Plotting model: "+(names(nn)))
	res@tiMainString     = names(nn)
	MCA=dim_avg_n_Wrap(all_fields(ncl_join|nn,{time|950:1250},latitude|:,longitude|:),0)
	whole_period=dim_avg_n_Wrap(all_fields(ncl_join|nn,time|:,latitude|:,longitude|:),0)
	field_to_plot=MCA-whole_period
	copy_VarMeta(MCA,field_to_plot)
	plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res)
	
	; test significance
	var_MCA=dim_variance_n_Wrap(all_fields(ncl_join|nn,{time|950:1250},latitude|:,longitude|:),0)
	var_whole_period=dim_variance_n_Wrap(all_fields(ncl_join|nn,time|:,latitude|:,longitude|:),0)
	size_MCA=equiv_sample_size (all_fields(ncl_join|nn,latitude|:,longitude|:,{time|950:1250}),siglvl,0)
	size_whole_period=equiv_sample_size (all_fields(ncl_join|nn,latitude|:,longitude|:,time|:),siglvl,0)
	
	prob=ttest(MCA,var_MCA,size_MCA,whole_period,var_whole_period,size_whole_period,True,False)
	copy_VarMeta(MCA,prob)
	plot2(nn)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res2)
	plot2(nn)=ShadeLtContour(plot2(nn), 0.06, 17)
	overlay (plot(nn), plot2(nn))

end do

resP@txString         = "Surface temperature anomaly for MCA (950 to 1250)"

gsn_panel(wks,plot,(/4,3/),resP)               ; create panel plot

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;LIA

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/LIA_all_models")  ; open workstation 
plot = new((dimsizes(names)),graphic)
plot2 = new((dimsizes(names)),graphic)

print("Creating Plot: LIA")

gsn_define_colormap(wks,"BlueDarkRed18")

do nn=0,(dimsizes(names)-1)
	print("Plotting model: "+(names(nn)))
	res@tiMainString     = names(nn)
	MCA=dim_avg_n_Wrap(all_fields(ncl_join|nn,{time|1400:1700},latitude|:,longitude|:),0)
	whole_period=dim_avg_n_Wrap(all_fields(ncl_join|nn,time|:,latitude|:,longitude|:),0)
	field_to_plot=MCA-whole_period
	copy_VarMeta(MCA,field_to_plot)
	plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res)

end do

resP@txString         = "Surface temperature anomaly for LIA (1400 to 1700)"

gsn_panel(wks,plot,(/4,3/),resP)               ; create panel plot

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;MCA detrended

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/MCA_all_models_detrended")  ; open workstation 
plot = new((dimsizes(names)),graphic)
plot2 = new((dimsizes(names)),graphic)

gsn_define_colormap(wks,"BlueDarkRed18")

print("Creating Plot: MCA detrended")

do nn=0,(dimsizes(names)-1)
	print("Plotting model: "+(names(nn)))
	res@tiMainString     = names(nn)
	MCA=dim_avg_n_Wrap(all_fields_detrended(ncl_join|nn,{time|950:1250},latitude|:,longitude|:),0)
	whole_period=dim_avg_n_Wrap(all_fields_detrended(ncl_join|nn,time|:,latitude|:,longitude|:),0)
	field_to_plot=MCA-whole_period
	copy_VarMeta(MCA,field_to_plot)
	plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res)
	
	; test significance
	var_MCA=dim_variance_n_Wrap(all_fields_detrended(ncl_join|nn,{time|950:1250},latitude|:,longitude|:),0)
	var_whole_period=dim_variance_n_Wrap(all_fields_detrended(ncl_join|nn,time|:,latitude|:,longitude|:),0)
	size_MCA=equiv_sample_size (all_fields_detrended(ncl_join|nn,latitude|:,longitude|:,{time|950:1250}),siglvl,0)
	size_whole_period=equiv_sample_size (all_fields_detrended(ncl_join|nn,latitude|:,longitude|:,time|:),siglvl,0)
	
	prob=ttest(MCA,var_MCA,size_MCA,whole_period,var_whole_period,size_whole_period,True,False)
	copy_VarMeta(MCA,prob)
	plot2(nn)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res2)
	plot2(nn)=ShadeLtContour(plot2(nn), 0.06, 17)
	overlay (plot(nn), plot2(nn))

end do

resP@txString         = "Surface temperature anomaly for MCA (950 to 1250) - model drift removed"

gsn_panel(wks,plot,(/4,3/),resP)               ; create panel plot

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;LIA detrended

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/LIA_all_models_detrended")  ; open workstation 
plot = new((dimsizes(names)),graphic)
plot2 = new((dimsizes(names)),graphic)

gsn_define_colormap(wks,"BlueDarkRed18")

print("Creating Plot: LIA detrended")

do nn=0,(dimsizes(names)-1)
	print("Plotting model: "+(names(nn)))
	res@tiMainString     = names(nn)
	MCA=dim_avg_n_Wrap(all_fields_detrended(ncl_join|nn,{time|1400:1700},latitude|:,longitude|:),0)
	field_to_plot=MCA-dim_avg_n_Wrap(all_fields_detrended(ncl_join|nn,time|:,latitude|:,longitude|:),0)
	copy_VarMeta(MCA,field_to_plot)
	plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res)
end do

resP@txString         = "Surface temperature anomaly for LIA (1400 to 1700) - model drift removed"

gsn_panel(wks,plot,(/4,3/),resP)               ; create panel plot



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;test
nn=1

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/"+names(nn)+"_detail")  ; open workstation 
plot3 = new(6,graphic)
gsn_define_colormap(wks,"BlueDarkRed18")



	res@tiMainString     = names(nn)
	MCA=dim_avg_n_Wrap(all_fields_detrended(ncl_join|nn,{time|950:1250},latitude|:,longitude|:),0)
	whole_period=dim_avg_n_Wrap(all_fields_detrended(ncl_join|nn,time|:,latitude|:,longitude|:),0)
	field_to_plot=MCA-whole_period
	copy_VarMeta(MCA,field_to_plot)
	plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res)
	
	; test significance
	var_MCA=dim_variance_n_Wrap(all_fields_detrended(ncl_join|nn,{time|950:1250},latitude|:,longitude|:),0)
	var_whole_period=dim_variance_n_Wrap(all_fields_detrended(ncl_join|nn,time|:,latitude|:,longitude|:),0)
	size_MCA=equiv_sample_size (all_fields_detrended(ncl_join|nn,latitude|:,longitude|:,{time|950:1250}),siglvl,0)
	size_whole_period=equiv_sample_size (all_fields_detrended(ncl_join|nn,latitude|:,longitude|:,time|:),siglvl,0)
	
	prob=ttest(MCA,var_MCA,size_MCA,whole_period,var_whole_period,size_whole_period,True,False)
	copy_VarMeta(MCA,prob)
	copy_VarMeta(MCA,size_MCA)
	copy_VarMeta(MCA,size_whole_period)


res3=True
res3@gsnDraw  = False                          ; don't draw
res3@gsnFrame = False                          ; don't advance frame
res3@cnFillOn         = True               ; color Fill 
res3@cnFillMode       = "RasterFill"       ; Raster Mode
res3@cnLinesOn        =  False             ; Turn off contour lines
res3@gsnSpreadColors  = True                ; use full range of color map
res3@cnLevelSelectionMode = "ManualLevels" ; manual levels


res3@cnMinLevelValF       = -30.0
res3@cnMaxLevelValF       =  30.0
res3@cnLevelSpacingF      =  5.0
res3@tiMainString     = "MCA"
plot3(0)=gsn_csm_contour_map(wks,MCA,res3)
res3@tiMainString     = "whole_period"
plot3(1)=gsn_csm_contour_map(wks,whole_period,res3)

res3@cnMinLevelValF       = 0.0
res3@cnMaxLevelValF       =  0.15
res3@cnLevelSpacingF      =  .01
res3@tiMainString     = "var MCA"
plot3(2)=gsn_csm_contour_map(wks,var_MCA,res3)
res3@tiMainString     = "var whole period"
plot3(3)=gsn_csm_contour_map(wks,var_whole_period,res3)

res3@cnMinLevelValF       = 0.0
res3@cnMaxLevelValF       =  100.0
res3@cnLevelSpacingF      =  5.0
res3@tiMainString     = "size MCA"
plot3(4)=gsn_csm_contour_map(wks,size_MCA,res3)
res3@tiMainString     = "size whole_period"
plot3(5)=gsn_csm_contour_map(wks,size_whole_period,res3)


resP2=True
resP2@txString         = names(nn)

gsn_panel(wks,plot3,(/3,2/),resP2)               ; create panel plot



end
