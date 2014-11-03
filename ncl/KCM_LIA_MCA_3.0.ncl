;***************************************************************************************** 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

; detect CMIP directory
wd = systemfunc("pwd")
dir_split = str_split(wd, "/") 
CMIP_dir=str_concat("/"+dir_split(0:dimsizes(dir_split)-3))

print("The current working directory is: "+(CMIP_dir(0)))

; load data
order=(/3,1,5,2,4,0/) ; arrange by forcing period (long to short)
forcing_period=(/"1000 years","1000 years","200 years","100 years","60 years","control"/)

directory=CMIP_dir+"/data/KCM/"
files_nh = systemfunc ("ls "+directory+"NH_mean/*temp2*NH_mean_anomaly_yearly_mean*detrended*.nc")
files_whole = systemfunc ("ls "+directory+"whole_field/*temp2*whole_field_anomaly_yearly_mean*detrended*.nc")
nh_tmp=addfiles(files_nh(order),"r")
whole_tmp=addfiles(files_whole(order),"r")
ListSetType (nh_tmp, "join")
ListSetType (whole_tmp, "join")


files_whole_pr = systemfunc ("ls "+directory+"whole_field/*pr*whole_field_anomaly_yearly_mean*detrended*.nc")
files_whole_slp = systemfunc ("ls "+directory+"whole_field/*slp*whole_field_anomaly_yearly_mean*detrended*.nc")
whole_tmp_pr=addfiles(files_whole_pr(order),"r")
whole_tmp_slp=addfiles(files_whole_slp(order),"r")
ListSetType (whole_tmp_pr, "join")
ListSetType (whole_tmp_slp, "join")


files_ordered=files_nh(order)
model_name=files_ordered
do nt = 0,(dimsizes(files_ordered)-1)
	strs=str_split(files_ordered(nt),"_")
	model_name(nt)=strs(2)
	delete(strs)
end do

print(model_name)

;*****************************************************************************************
; Plots
;*****************************************************************************************

;NH mean

res                     		= True  
res@gsnDraw  = False                         
res@gsnFrame = False            
;res@vpHeightF 	 				= 0.4              	
;res@vpWidthF 	        		= 0.7
;res@tmYMajorGrid				= "True"
;res@tmYMajorGridLineColor		= "grey"
;res@tmYMajorGridLineDashPattern	= 16
;res@tmYMajorGridThicknessF		= 1.0            
res@xyLineThicknessF   		= (/2.0/) 
res@xyDashPattern      			= 0
res@tiYAxisString	 			= "[~S~o~N~C]"     	    	
res@tmYRLabelsOn 				= True
res@gsnPaperOrientation = "auto"
 
 
; define variable resources

fraction_of_std=3
running_mean=21

; global mean plot

global_mean=0

if (global_mean .eq. 1) then
 
wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/KCM_temp2_NH_mean_detrended_3_0") 
plot = new(6,graphic)
plot2 = new(6,graphic)
do nn=0,5

print(nn)
		

	nh=nh_tmp[nn]->temp2(:,:,0,0)
	time=nh_tmp[nn]->time
	time_new=cd_calendar(time,0)
	nh&time=time_new(:,0)
	
	res@trXMinF	         			= min(time_new(:,0))        	
    res@trXMaxF	       	  			= max(time_new(:,0)) 
           
	res@trYMinF	            		= -0.65        
	res@trYMaxF	            		= 0.65
	res@tiMainString				= model_name(nn)+" ("+forcing_period(nn)+")" 
	

  	res@gsnYRefLineColor      = (/"black"/)
  	res@gsnAboveYRefLineColor = (/ "transparent"/)
  	res@gsnBelowYRefLineColor = (/ "dodgerblue4"/)
  	res@gsnYRefLineDashPattern      			= 16
  	res@gsnYRefLine           = (/ (stddev(nh)/fraction_of_std)*-1/)


  plot(nn) = gsn_csm_xy (wks,time_new(:,0),runave(nh,running_mean,0),res) 
  

  	res@gsnYRefLineColor      = (/"black"/)
  	res@gsnAboveYRefLineColor = (/ "firebrick"/)
  	res@gsnBelowYRefLineColor = (/ "transparent"/)
  	res@gsnYRefLine           = (/ stddev(nh)/fraction_of_std/)


  plot2(nn) = gsn_csm_xy (wks,time_new(:,0),runave(nh,running_mean,0),res)
  overlay(plot(nn),plot2(nn))
  
  delete([/nh,time,time_new/])   
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ NH mean temperature anomaly; "+running_mean+"-year filter ~C~ ~Z50~ shaded regions are above/below one "+fraction_of_std+" standard deviation"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/3,2/),resP)               ; now draw as one plot

end if

; MCA surface patterns

siglvl=0.01

res2                  = True                ; plot mods desired
res2@gsnDraw  = False                          ; don't draw
res2@gsnFrame = False                          ; don't advance frame
res2@lbLabelBarOn         = False             	; turn off individual lb's
res2@cnLineLabelsOn       = False             	; default is True

res2@cnLevelSelectionMode = "ManualLevels" ; manual levels
res2@cnMinLevelValF       = -.5
res2@cnMaxLevelValF       =  .5
res2@cnLevelSpacingF      =  .05

res2@cnFillOn         = True               ; color Fill 
res2@cnFillMode       = "RasterFill"       ; Raster Mode
res2@cnLinesOn        =  False             ; Turn off contour lines
res2@gsnSpreadColors  = True                ; use full range of color map


res3=True
res3@gsnDraw             = False       ; Do not draw plot
res3@gsnFrame            = False       ; Do not advance frome
res3@cnLinesOn        =  False             ; Turn off contour lines
res3@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
res3@cnMinLevelValF      = 0.00        ; set min contour level
res3@cnMaxLevelValF      = 0.015        ; set max contour level
res3@cnLevelSpacingF     = 0.001        ; set contour spacing
res3@cnLineLabelsOn       = False             	; default is True
res3@cnInfoLabelOn       = False       ; turn off info label
res3@gsnLeftString=""
res3@gsnRightString=""
res3@cnFillScaleF=1.0
res3@cnFillDotSizeF=0.002

resP2                  = True                   ; modify the panel plot
resP2@lbOrientation    = "Horizontal"          ; vertical label bar
resP2@gsnMaximize      = True                ; make ps, eps, pdf, ... large
resP2@gsnPanelLabelBar = True 

MCA_pattern=1             

if (MCA_pattern .eq. 1) then

	wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/KCM_MCA_temp2_3_0")  ; open workstation 
	plot = new(6,graphic)
	plot2 = new(6,graphic)

	do nn=0,5
	
		print(nn)
	
		; load data
		field=whole_tmp[nn]->temp2
		nh=nh_tmp[nn]->temp2(:,:,0,0)
		time=nh_tmp[nn]->time
		time_new=cd_calendar(time,0)
		field&time=time_new(:,0)
		nh&time=time_new(:,0)
		
		; average over time periods of high NH mean temperature
		MCA_indices=where(runave(nh,running_mean,0) .ge. stddev(nh)/fraction_of_std,1,0)
		MCA_field=mask(field(lat|:,lon|:,time|:),MCA_indices(0,:),1)
		copy_VarMeta(field(lat|:,lon|:,time|:),MCA_field)
		MCA=dim_avg_n_Wrap(MCA_field,2)
		whole_period=dim_avg_n_Wrap(field(lat|:,lon|:,time|:),2)
		field_to_plot=(MCA-whole_period)
		copy_VarMeta(field(lat|:,lon|:,time|:),field_to_plot)
		
		res2@tiMainString     = model_name(nn)+" ("+forcing_period(nn)+")" 
		plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res2)
		
		; test significance
		var_MCA=dim_variance_n_Wrap(MCA_field,2)
		var_whole_period=dim_variance_n_Wrap(field(lat|:,lon|:,time|:),2)
		size_MCA=equiv_sample_size (MCA_field,siglvl,0)
		size_whole_period=equiv_sample_size (field(lat|:,lon|:,time|:),siglvl,0)
		
		;print(avg(whole_period))
		;print(avg(MCA))
		;printVarSummary(MCA_field)
	
		prob=ttest(MCA,var_MCA,size_MCA,whole_period,var_whole_period,size_whole_period,False,False)
		copy_VarMeta(MCA,prob)
		plot2(nn)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res3)
		plot2(nn)=ShadeLtContour(plot2(nn), 0.011, 17)
		overlay (plot(nn), plot2(nn))

		;print(mask(time_new(:,0),MCA_indices(0,:),1))

		
		delete([/field,nh,MCA,MCA_indices,MCA_field,time,time_new/])

	end do
	
	resP2@txString         = "Surface temperature anomaly for warm periods "

	gsn_panel(wks,plot,(/3,2/),resP2)               ; create panel plot

end if

MCA_pattern_pr=0             

if (MCA_pattern_pr .eq. 1) then

	wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/KCM_MCA_pr_3_0")  ; open workstation 
	plot = new(6,graphic)
	plot2 = new(6,graphic)
	res2@cnMinLevelValF       = -.15
	res2@cnMaxLevelValF       =  .15
	res2@cnLevelSpacingF      =  .015
	res2@gsnLeftString="precipiation"
   res2@gsnRightString="mm/day"

	do nn=0,5
	
		print(nn)
		gsn_define_colormap(wks,"ncl_default")
		gsn_reverse_colormap(wks)
	
		; load data
		field_tmp=whole_tmp_pr[nn]->precip
		field=field_tmp*86400
		copy_VarMeta(field_tmp,field)
		nh=nh_tmp[nn]->temp2(:,:,0,0)
		time=nh_tmp[nn]->time
		time_new=cd_calendar(time,0)
		field&time=time_new(:,0)
		nh&time=time_new(:,0)
		
		; average over time periods of high NH mean temperature
		MCA_indices=where(runave(nh,running_mean,0) .ge. stddev(nh)/fraction_of_std,1,0)
		MCA_field=mask(field(lat|:,lon|:,time|:),MCA_indices(0,:),1)
		copy_VarMeta(field(lat|:,lon|:,time|:),MCA_field)
		MCA=dim_avg_n_Wrap(MCA_field,2)
		whole_period=dim_avg_n_Wrap(field(lat|:,lon|:,time|:),2)
		field_to_plot=(MCA-whole_period)
		copy_VarMeta(field(lat|:,lon|:,time|:),field_to_plot)
		
		res2@tiMainString     = model_name(nn)+" ("+forcing_period(nn)+")" 
		plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res2)
		
		; test significance
		var_MCA=dim_variance_n_Wrap(MCA_field,2)
		var_whole_period=dim_variance_n_Wrap(field(lat|:,lon|:,time|:),2)
		size_MCA=equiv_sample_size (MCA_field,siglvl,0)
		size_whole_period=equiv_sample_size (field(lat|:,lon|:,time|:),siglvl,0)
	
		prob=ttest(MCA,var_MCA,size_MCA,whole_period,var_whole_period,size_whole_period,False,False)
		copy_VarMeta(MCA,prob)
		plot2(nn)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res3)
		plot2(nn)=ShadeLtContour(plot2(nn), 0.02, 17)
		overlay (plot(nn), plot2(nn))

		;print(mask(time_new(:,0),MCA_indices(0,:),1))

		
		delete([/field,field_tmp,nh,MCA,MCA_indices,MCA_field,time,time_new/])

	end do
	
	resP2@txString         = "Precipitation anomaly for warm periods "

	gsn_panel(wks,plot,(/3,2/),resP2)               ; create panel plot

end if

MCA_pattern_slp=0             

if (MCA_pattern_slp .eq. 1) then

	wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/KCM_MCA_slp_3_0")  ; open workstation 
	plot = new(6,graphic)
	plot2 = new(6,graphic)
	res2@cnMinLevelValF       = -.4
	res2@cnMaxLevelValF       =  .4
	res2@cnLevelSpacingF      =  .05
	res2@gsnLeftString="sea level pressure"
   res2@gsnRightString="hPa"

	do nn=0,5
	
		print(nn)
		gsn_define_colormap(wks,"ncl_default")
	
		; load data
		field_tmp=whole_tmp_slp[nn]->aps
		field=field_tmp/100
		copy_VarMeta(field_tmp,field)
		nh=nh_tmp[nn]->temp2(:,:,0,0)
		time=nh_tmp[nn]->time
		time_new=cd_calendar(time,0)
		field&time=time_new(:,0)
		nh&time=time_new(:,0)
		
		; average over time periods of high NH mean temperature
		MCA_indices=where(runave(nh,running_mean,0) .ge. stddev(nh)/fraction_of_std,1,0)
		MCA_field=mask(field(lat|:,lon|:,time|:),MCA_indices(0,:),1)
		copy_VarMeta(field(lat|:,lon|:,time|:),MCA_field)
		MCA=dim_avg_n_Wrap(MCA_field,2)
		whole_period=dim_avg_n_Wrap(field(lat|:,lon|:,time|:),2)
		field_to_plot=(MCA-whole_period)
		copy_VarMeta(field(lat|:,lon|:,time|:),field_to_plot)
		
		res2@tiMainString     = model_name(nn)+" ("+forcing_period(nn)+")" 
		plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res2)
		
		; test significance
		var_MCA=dim_variance_n_Wrap(MCA_field,2)
		var_whole_period=dim_variance_n_Wrap(field(lat|:,lon|:,time|:),2)
		size_MCA=equiv_sample_size (MCA_field,siglvl,0)
		size_whole_period=equiv_sample_size (field(lat|:,lon|:,time|:),siglvl,0)
	
		prob=ttest(MCA,var_MCA,size_MCA,whole_period,var_whole_period,size_whole_period,False,False)
		copy_VarMeta(MCA,prob)
		plot2(nn)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res3)
		plot2(nn)=ShadeLtContour(plot2(nn), 0.02, 17)
		overlay (plot(nn), plot2(nn))

		;print(mask(time_new(:,0),MCA_indices(0,:),1))

		
		delete([/field,field_tmp,nh,MCA,MCA_indices,MCA_field,time,time_new/])

	end do
	
	resP2@txString         = "Sea level pressure anomaly for warm periods "

	gsn_panel(wks,plot,(/3,2/),resP2)               ; create panel plot

end if

; LIA surface patterns


LIA_pattern=0             

if (LIA_pattern .eq. 1) then



	wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/KCM_LIA_temp2_3_0")  ; open workstation 
	plot = new(6,graphic)
	plot2 = new(6,graphic)
	res2@gsnLeftString="2m temperature"
    res2@gsnRightString="K"
    res2@cnLevelSelectionMode = "ManualLevels" ; manual levels
	res2@cnMinLevelValF       = -.5
	res2@cnMaxLevelValF       =  .5
	res2@cnLevelSpacingF      =  .05

	do nn=0,5
	
		print(nn)
	
		; load data
		field=whole_tmp[nn]->temp2
		nh=nh_tmp[nn]->temp2(:,:,0,0)
		time=nh_tmp[nn]->time
		time_new=cd_calendar(time,0)
		field&time=time_new(:,0)
		nh&time=time_new(:,0)
		
		; average over time periods of high NH mean temperature
		LIA_indices=where(runave(nh,running_mean,0) .le. (stddev(nh)/fraction_of_std)*-1,1,0)
		LIA_field=mask(field(lat|:,lon|:,time|:),LIA_indices(0,:),1)
		copy_VarMeta(field(lat|:,lon|:,time|:),LIA_field)
		LIA=dim_avg_n_Wrap(LIA_field,2)
		whole_period=dim_avg_n_Wrap(field(lat|:,lon|:,time|:),2)
		field_to_plot=(LIA-whole_period)
		copy_VarMeta(field(lat|:,lon|:,time|:),field_to_plot)
		
		res2@tiMainString     = model_name(nn)+" ("+forcing_period(nn)+")" 
		plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res2)
		
		; test significance
		var_LIA=dim_variance_n_Wrap(LIA_field,2)
		var_whole_period=dim_variance_n_Wrap(field(lat|:,lon|:,time|:),2)
		size_LIA=equiv_sample_size (LIA_field,siglvl,0)
		size_whole_period=equiv_sample_size (field(lat|:,lon|:,time|:),siglvl,0)
	
		prob=ttest(LIA,var_LIA,size_LIA,whole_period,var_whole_period,size_whole_period,False,False)
		copy_VarMeta(LIA,prob)
		plot2(nn)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res3)
		plot2(nn)=ShadeLtContour(plot2(nn), 0.02, 17)
		overlay (plot(nn), plot2(nn))

		;print(mask(time_new(:,0),LIA_indices(0,:),1))

		
		delete([/field,nh,LIA,LIA_indices,LIA_field,time,time_new/])

	end do
	
	resP2@txString         = "Surface temperature anomaly for cold periods "

	gsn_panel(wks,plot,(/3,2/),resP2)               ; create panel plot

end if

LIA_pattern_pr=0              

if (LIA_pattern_pr .eq. 1) then



	wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/KCM_LIA_pr_3_0")  ; open workstation 
	plot = new(6,graphic)
	plot2 = new(6,graphic)
	res2@cnMinLevelValF       = -.15
	res2@cnMaxLevelValF       =  .15
	res2@cnLevelSpacingF      =  .015
	res2@gsnLeftString="precipiation"
    res2@gsnRightString="mm/day"

	do nn=0,5
	
		print(nn)
		gsn_define_colormap(wks,"ncl_default")
		gsn_reverse_colormap(wks)
	
		; load data
		field_tmp=whole_tmp_pr[nn]->precip
		field=field_tmp*86400
		copy_VarMeta(field_tmp,field)
		nh=nh_tmp[nn]->temp2(:,:,0,0)
		time=nh_tmp[nn]->time
		time_new=cd_calendar(time,0)
		field&time=time_new(:,0)
		nh&time=time_new(:,0)
		
		; average over time periods of high NH mean temperature
		LIA_indices=where(runave(nh,running_mean,0) .le. (stddev(nh)/fraction_of_std)*-1,1,0)
		LIA_field=mask(field(lat|:,lon|:,time|:),LIA_indices(0,:),1)
		copy_VarMeta(field(lat|:,lon|:,time|:),LIA_field)
		LIA=dim_avg_n_Wrap(LIA_field,2)
		whole_period=dim_avg_n_Wrap(field(lat|:,lon|:,time|:),2)
		field_to_plot=(LIA-whole_period)
		copy_VarMeta(field(lat|:,lon|:,time|:),field_to_plot)
		
		res2@tiMainString     = model_name(nn)+" ("+forcing_period(nn)+")" 
		plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res2)
		
		; test significance
		var_LIA=dim_variance_n_Wrap(LIA_field,2)
		var_whole_period=dim_variance_n_Wrap(field(lat|:,lon|:,time|:),2)
		size_LIA=equiv_sample_size (LIA_field,siglvl,0)
		size_whole_period=equiv_sample_size (field(lat|:,lon|:,time|:),siglvl,0)
	
		prob=ttest(LIA,var_LIA,size_LIA,whole_period,var_whole_period,size_whole_period,False,False)
		copy_VarMeta(LIA,prob)
		plot2(nn)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res3)
		plot2(nn)=ShadeLtContour(plot2(nn), 0.02, 17)
		overlay (plot(nn), plot2(nn))

		;print(mask(time_new(:,0),LIA_indices(0,:),1))

		
		delete([/field,field_tmp,nh,LIA,LIA_indices,LIA_field,time,time_new/])

	end do
	
	resP2@txString         = "Precipitation anomaly for cold periods "

	gsn_panel(wks,plot,(/3,2/),resP2)               ; create panel plot

end if

LIA_pattern_slp=0              

if (LIA_pattern_slp .eq. 1) then



	wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/KCM_LIA_slp_3_0")  ; open workstation 
	plot = new(6,graphic)
	plot2 = new(6,graphic)
	res2@cnMinLevelValF       = -.4
	res2@cnMaxLevelValF       =  .4
	res2@cnLevelSpacingF      =  .05
	res2@gsnLeftString="sea level pressure"
   res2@gsnRightString="hPa"

	do nn=0,5
	
		print(nn)
		gsn_define_colormap(wks,"ncl_default")
	
		; load data
		field_tmp=whole_tmp_slp[nn]->aps
		field=field_tmp/100
		copy_VarMeta(field_tmp,field)
		nh=nh_tmp[nn]->temp2(:,:,0,0)
		time=nh_tmp[nn]->time
		time_new=cd_calendar(time,0)
		field&time=time_new(:,0)
		nh&time=time_new(:,0)
		
		; average over time periods of high NH mean temperature
		LIA_indices=where(runave(nh,running_mean,0) .le. (stddev(nh)/fraction_of_std)*-1,1,0)
		LIA_field=mask(field(lat|:,lon|:,time|:),LIA_indices(0,:),1)
		copy_VarMeta(field(lat|:,lon|:,time|:),LIA_field)
		LIA=dim_avg_n_Wrap(LIA_field,2)
		whole_period=dim_avg_n_Wrap(field(lat|:,lon|:,time|:),2)
		field_to_plot=(LIA-whole_period)
		copy_VarMeta(field(lat|:,lon|:,time|:),field_to_plot)
		
		res2@tiMainString     = model_name(nn)+" ("+forcing_period(nn)+")" 
		plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res2)
		
		; test significance
		var_LIA=dim_variance_n_Wrap(LIA_field,2)
		var_whole_period=dim_variance_n_Wrap(field(lat|:,lon|:,time|:),2)
		size_LIA=equiv_sample_size (LIA_field,siglvl,0)
		size_whole_period=equiv_sample_size (field(lat|:,lon|:,time|:),siglvl,0)
	
		prob=ttest(LIA,var_LIA,size_LIA,whole_period,var_whole_period,size_whole_period,False,False)
		copy_VarMeta(LIA,prob)
		plot2(nn)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res3)
		plot2(nn)=ShadeLtContour(plot2(nn), 0.02, 17)
		overlay (plot(nn), plot2(nn))

		;print(mask(time_new(:,0),LIA_indices(0,:),1))

		
		delete([/field,field_tmp,nh,LIA,LIA_indices,LIA_field,time,time_new/])

	end do
	
	resP2@txString         = "Sea level pressure anomaly for cold periods "

	gsn_panel(wks,plot,(/3,2/),resP2)               ; create panel plot

end if

; warm minus cold plots

; temp2

res2                  = True                ; plot mods desired
res2@gsnDraw  = False                          ; don't draw
res2@gsnFrame = False                          ; don't advance frame
res2@lbLabelBarOn         = False             	; turn off individual lb's
res2@cnLineLabelsOn       = False             	; default is True

res2@cnLevelSelectionMode = "ManualLevels" ; manual levels
res2@cnMinLevelValF       = -.8
res2@cnMaxLevelValF       =  .8
res2@cnLevelSpacingF      =  .1

res2@cnFillOn         = True               ; color Fill 
res2@cnFillMode       = "RasterFill"       ; Raster Mode
res2@cnLinesOn        =  False             ; Turn off contour lines
res2@gsnSpreadColors  = True                ; use full range of color map

warm_minus_cold_temp2=0             

if (warm_minus_cold_temp2 .eq. 1) then

	wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/KCM_warm_minus_cold_temp2_3_0")  ; open workstation 
	plot = new(6,graphic)

	do nn=0,5
	
		print(nn)
	
		; load data
		field=whole_tmp[nn]->temp2
		nh=nh_tmp[nn]->temp2(:,:,0,0)
		time=nh_tmp[nn]->time
		time_new=cd_calendar(time,0)
		field&time=time_new(:,0)
		nh&time=time_new(:,0)
		
		; average over time periods of high NH mean temperature
		MCA_indices=where(runave(nh,running_mean,0) .ge. stddev(nh)/fraction_of_std,1,0)
		LIA_indices=where(runave(nh,running_mean,0) .le. (stddev(nh)/fraction_of_std)*-1,1,0)
		MCA_field=mask(field(lat|:,lon|:,time|:),MCA_indices(0,:),1)
		LIA_field=mask(field(lat|:,lon|:,time|:),LIA_indices(0,:),1)
		copy_VarMeta(field(lat|:,lon|:,time|:),MCA_field)
		copy_VarMeta(field(lat|:,lon|:,time|:),LIA_field)
		MCA=dim_avg_n_Wrap(MCA_field,2)
		LIA=dim_avg_n_Wrap(LIA_field,2)

		field_to_plot=(MCA-LIA)
		copy_VarMeta(field(lat|:,lon|:,time|:),field_to_plot)
		
		res2@tiMainString     = model_name(nn)+" ("+forcing_period(nn)+")" 
		plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res2)
		
		delete([/field,nh,MCA,MCA_indices,MCA_field,LIA,LIA_indices,LIA_field,time,time_new/])

	end do
	
	resP2@txString         = "temp2 warm minus cold composite"

	gsn_panel(wks,plot,(/3,2/),resP2)               ; create panel plot

end if


; pr

res2                  = True                ; plot mods desired
res2@gsnDraw  = False                          ; don't draw
res2@gsnFrame = False                          ; don't advance frame
res2@lbLabelBarOn         = False             	; turn off individual lb's
res2@cnLineLabelsOn       = False             	; default is True

res2@cnMinLevelValF       = -.2
res2@cnMaxLevelValF       =  .2
res2@cnLevelSpacingF      =  .02
res2@gsnLeftString="precipiation"
res2@gsnRightString="mm/day"


res2@cnFillOn         = True               ; color Fill 
res2@cnFillMode       = "RasterFill"       ; Raster Mode
res2@cnLinesOn        =  False             ; Turn off contour lines
res2@gsnSpreadColors  = True                ; use full range of color map

warm_minus_cold_pr=0             

if (warm_minus_cold_pr .eq. 1) then

	wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/KCM_warm_minus_cold_pr_3_0")  ; open workstation 
	plot = new(6,graphic)

	do nn=0,5
	
		print(nn)
	
		gsn_define_colormap(wks,"ncl_default")
		gsn_reverse_colormap(wks)
		; load data
		field_tmp=whole_tmp_pr[nn]->precip
		field=field_tmp*86400
		copy_VarMeta(field_tmp,field)
		nh=nh_tmp[nn]->temp2(:,:,0,0)
		time=nh_tmp[nn]->time
		time_new=cd_calendar(time,0)
		field&time=time_new(:,0)
		nh&time=time_new(:,0)
		
		; average over time periods of high NH mean temperature
		MCA_indices=where(runave(nh,running_mean,0) .ge. stddev(nh)/fraction_of_std,1,0)
		LIA_indices=where(runave(nh,running_mean,0) .le. (stddev(nh)/fraction_of_std)*-1,1,0)
		MCA_field=mask(field(lat|:,lon|:,time|:),MCA_indices(0,:),1)
		LIA_field=mask(field(lat|:,lon|:,time|:),LIA_indices(0,:),1)
		copy_VarMeta(field(lat|:,lon|:,time|:),MCA_field)
		copy_VarMeta(field(lat|:,lon|:,time|:),LIA_field)
		MCA=dim_avg_n_Wrap(MCA_field,2)
		LIA=dim_avg_n_Wrap(LIA_field,2)

		field_to_plot=(MCA-LIA)
		copy_VarMeta(field(lat|:,lon|:,time|:),field_to_plot)
		
		res2@tiMainString     = model_name(nn)+" ("+forcing_period(nn)+")" 
		plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res2)
		
		delete([/field,field_tmp,nh,MCA,MCA_indices,MCA_field,LIA,LIA_indices,LIA_field,time,time_new/])

	end do
	
	resP2@txString         = "pr warm minus cold composite"

	gsn_panel(wks,plot,(/3,2/),resP2)               ; create panel plot

end if

; slp

res2                  = True                ; plot mods desired
res2@gsnDraw  = False                          ; don't draw
res2@gsnFrame = False                          ; don't advance frame
res2@lbLabelBarOn         = False             	; turn off individual lb's
res2@cnLineLabelsOn       = False             	; default is True

	res2@cnMinLevelValF       = -.6
	res2@cnMaxLevelValF       =  .6
	res2@cnLevelSpacingF      =  .1
	res2@gsnLeftString="sea level pressure"
   res2@gsnRightString="hPa"


res2@cnFillOn         = True               ; color Fill 
res2@cnFillMode       = "RasterFill"       ; Raster Mode
res2@cnLinesOn        =  False             ; Turn off contour lines
res2@gsnSpreadColors  = True                ; use full range of color map

warm_minus_cold_slp=0            

if (warm_minus_cold_slp .eq. 1) then

	wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/KCM_warm_minus_cold_slp_3_0")  ; open workstation 
	plot = new(6,graphic)

	do nn=0,5
	
		print(nn)
	
		gsn_define_colormap(wks,"ncl_default")
		; load data
		field_tmp=whole_tmp_slp[nn]->aps
		field=field_tmp/100
		copy_VarMeta(field_tmp,field)
		nh=nh_tmp[nn]->temp2(:,:,0,0)
		time=nh_tmp[nn]->time
		time_new=cd_calendar(time,0)
		field&time=time_new(:,0)
		nh&time=time_new(:,0)
		
		; average over time periods of high NH mean temperature
		MCA_indices=where(runave(nh,running_mean,0) .ge. stddev(nh)/fraction_of_std,1,0)
		LIA_indices=where(runave(nh,running_mean,0) .le. (stddev(nh)/fraction_of_std)*-1,1,0)
		MCA_field=mask(field(lat|:,lon|:,time|:),MCA_indices(0,:),1)
		LIA_field=mask(field(lat|:,lon|:,time|:),LIA_indices(0,:),1)
		copy_VarMeta(field(lat|:,lon|:,time|:),MCA_field)
		copy_VarMeta(field(lat|:,lon|:,time|:),LIA_field)
		MCA=dim_avg_n_Wrap(MCA_field,2)
		LIA=dim_avg_n_Wrap(LIA_field,2)

		field_to_plot=(MCA-LIA)
		copy_VarMeta(field(lat|:,lon|:,time|:),field_to_plot)
		
		res2@tiMainString     = model_name(nn)+" ("+forcing_period(nn)+")" 
		plot(nn) = gsn_csm_contour_map(wks,field_to_plot,res2)
		
		delete([/field,field_tmp,nh,MCA,MCA_indices,MCA_field,LIA,LIA_indices,LIA_field,time,time_new/])

	end do
	
	resP2@txString         = "Sea level pressure warm minus cold composite"

	gsn_panel(wks,plot,(/3,2/),resP2)               ; create panel plot

end if


end

