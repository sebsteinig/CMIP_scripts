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

directory=CMIP_dir+"/data/TSI/"

vieira_tmp = addfile (directory+"Vieira_2011/TSI_Holocene_Vieira_et_al_2011.nc","r")
vieira=vieira_tmp->TSI_10_year_mean
time_vieira_tmp=vieira_tmp->time
time_vieira_new=cd_calendar(time_vieira_tmp,0)
time_vieira=time_vieira_new(:,0)

roth_tmp = addfile (directory+"Roth_and_Joos_2013/TSI_Holocene_Roth_and_Joos_2013.nc","r")
roth=roth_tmp->TSI
time_roth=roth_tmp->time

steinhilber_2009_tmp = addfile (directory+"Steinhilber_2009/TSI_Holocene_Steinhilber_2009.nc","r")
steinhilber_2009=steinhilber_2009_tmp->TSI
time_steinhilber_2009=steinhilber_2009_tmp->time

steinhilber_2012_tmp = addfile (directory+"Steinhilber_2012/TSI_Holocene_Steinhilber_2012.nc","r")
steinhilber_2012=steinhilber_2012_tmp->TSI
time_steinhilber_2012=steinhilber_2012_tmp->time

WLS_tmp=readAsciiTable(directory+"PMIP3/tsi_WLS.txt",3,"float",(/4,1/))
WLS_time=WLS_tmp(:,0)
WLS_time!0="time"
WLS_time&time=WLS_time

WLS_noback=WLS_tmp(:,1)
WLS_noback!0="time"
WLS_noback&time=WLS_time

WLS_back=WLS_tmp(:,2)
WLS_back!0="time"
WLS_back&time=WLS_time

DB_tmp=readAsciiTable(directory+"PMIP3/tsi_DB_lin_40_11yr.txt",3,"float",(/4,0/))
DB_time=DB_tmp(:,0)
DB_time!0="time"
DB_time&time=DB_time

DB_noback=DB_tmp(:,2)
DB_noback!0="time"
DB_noback&time=DB_time

DB_back=DB_tmp(:,1)
DB_back!0="time"
DB_back&time=DB_time

VSK_tmp=readAsciiTable(directory+"PMIP3/tsi_VK.txt",2,"float",(/4,0/))
VSK_time=VSK_tmp(:,0)
VSK_time!0="time"
VSK_time&time=VSK_time

VSK_noback=VSK_tmp(:,1)
VSK_noback!0="time"
VSK_noback&time=VSK_time

SBF_tmp=readAsciiTable(directory+"PMIP3/tsi_SBF_11yr.txt",2,"float",(/4,0/))
SBF_time=SBF_tmp(:,0)
SBF_time!0="time"
SBF_time&time=SBF_time

SBF_noback=SBF_tmp(:,1)
SBF_noback!0="time"
SBF_noback&time=SBF_time

; look up indices for time periods: -10000 to -4000; -4000 to 2000 and 850 to 2000

	period_indices=new((/3,4,2/),"integer")

do nn=0,3
	if (nn .eq. 0) then
		time_axis=time_vieira
	else if (nn .eq. 1) then
		time_axis=time_roth
	else if (nn .eq. 2) then
		time_axis=time_steinhilber_2009
	else if (nn .eq. 3) then
		time_axis=time_steinhilber_2012
	end if
	end if
	end if
	end if
	
	time_span_period_1=ind(time_axis .le. -4000 .and. time_axis .ge. -10000)
	time_span_period_2=ind(time_axis .le. 2000 .and. time_axis .ge. -4000)
	time_span_period_3=ind(time_axis .le. 2000 .and. time_axis .ge. 850)

	period_indices(0,nn,0)=time_span_period_1(0)
	period_indices(0,nn,1)=time_span_period_1(dimsizes(time_span_period_1)-1)
	period_indices(1,nn,0)=time_span_period_2(0)
	period_indices(1,nn,1)=time_span_period_2(dimsizes(time_span_period_2)-1)
	period_indices(2,nn,0)=time_span_period_3(0)
	period_indices(2,nn,1)=time_span_period_3(dimsizes(time_span_period_3)-1)
	
	delete([/time_axis,time_span_period_1,time_span_period_2,time_span_period_3/])

end do


;*****************************************************************************************
; Plots
;*****************************************************************************************

;NH mean
colors							= (/"black","firebrick2","deepskyblue","palegreen4"/)
res                     		= True
res@gsnDraw  					= False                       
res@gsnFrame 					= False                                   
res@vpHeightF 	 				= 0.4              	
res@vpWidthF 	        		= 0.7
res@gsnMaximize     			= True              
res@tmYMajorGrid				= "True"
res@tmYMajorGridLineColor		= "grey"
res@tmYMajorGridLineDashPattern	= 16
res@tmYMajorGridThicknessF		= 1.0
res@xyLineThicknesses   		= (/2.0/) 
res@xyDashPattern      			= 0
res@tiYAxisString	 			= "[W/m^2]"     	    	
res@tiXAxisString	 			= "Year"      		 
res@tmYRLabelsOn 				= True
res@trXMinF	         			= min(time_vieira)          	
res@trXMaxF	       	  			= max(time_vieira) 
res@tmYLMode      			  	= "Manual"
res@trYMinF	            		= 1364.5       
res@trYMaxF	            		= 1366.5
res@tmYLTickSpacingF			= .5
res@tiMainString				= "TSI reconstructions Holocene" 


mean=70
opt=0

res@gsnCenterString 			= "~Z75~"+mean+" year running mean"

 
; define variable resources
 
wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/TSI_holocene")   
		 
; Vieira et al
	res@xyLineColors       			= colors(0) 
	vieira_plot = gsn_csm_xy (wks,time_vieira,runave(vieira,mean/10,opt),res) 
	
; Roth and Joos
	res@xyLineColors       			= colors(1) 
	roth_plot = gsn_csm_xy (wks,time_roth,runave(roth,mean,opt),res)
	
; Steinhilber (2009)
	res@xyLineColors       			= colors(2) 
	steinhilber_2009_plot = gsn_csm_xy (wks,time_steinhilber_2009,runave(steinhilber_2009,mean/5,opt),res) 

; Steinhilber (2012)
	res@xyLineColors       			= colors(3) 
	steinhilber_2012_plot = gsn_csm_xy (wks,time_steinhilber_2012,runave(steinhilber_2012,mean/22,opt),res)  
	  
	
overlay(vieira_plot,roth_plot)
overlay(vieira_plot,steinhilber_2009_plot)
overlay(vieira_plot,steinhilber_2012_plot)

; Attach a legend

lgres                    = True
lgres@lgLineColors       = colors
lgres@lgLineThicknessF	 = 5.0
lgres@lgItemType         = "Lines"        ; show lines only (default)
lgres@lgLabelFontHeightF = .1            ; legend label font thickness
lgres@vpWidthF           = 0.3           ; width of legend (NDC)
lgres@vpHeightF          = 0.15           ; height of legend (NDC)
lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
lgres@lgMonoDashIndex    = True
lgres@lgDashIndex        = 0

labels = (/"   Vieira et al. (2011)","   Roth and Joos (2013)","   Steinhilber et al. (2009)","   Steinhilber et al. (2012)"/) 
legend = gsn_create_legend (wks, 4, labels,lgres)

amres = True
amres@amParallelPosF   = -0.5		    ; move legend to the right
amres@amOrthogonalPosF = 0.83             ; move the legend down
annoid1 = gsn_add_annotation(vieira_plot,legend,amres)   ; add legend to plot
 
draw(wks)

delete([/vieira_plot,roth_plot,steinhilber_2009_plot,steinhilber_2012_plot/])


;*****************************************************************************************
;*****************************************************************************************

wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/TSI_holocene_panels")   

res@vpHeightF 	 				= 0.4              	
res@vpWidthF 	        		= 1.0

vieira_plot = new(3,graphic)
roth_plot = new(3,graphic)
steinhilber_2009_plot = new(3,graphic)
steinhilber_2012_plot = new(3,graphic)

panels_min	=	(/-10000,-4000,850/)
panels_max	=	(/-4000,2000,2000/)

do np=0,2

	if (np .eq. 0) then
		res@tiMainString				= "TSI reconstructions Holocene" 
		res@gsnCenterString 			= "~Z75~Period: "+panels_min(np)*(-1)+" B.C. - "+panels_max(np)*(-1)+" B.C."
	else if (np .eq. 1) then
		res@tiMainString				= "" 
		res@gsnCenterString 			= "~Z75~Period: "+panels_min(np)*(-1)+" B.C. - present"
	else if (np .eq. 2) then
		res@tiMainString				= "" 
		res@gsnCenterString 			= "~Z75~Period: "+panels_min(np)+" A.D. - present"
	end if
	end if
	end if
	
	res@gsnCenterStringOrthogonalPosF	= 0.07
	res@trXMinF	         			= panels_min(np)          	
	res@trXMaxF	       	  			= panels_max(np) 

	; Vieira et al
		res@xyLineColors       			= colors(0) 
		vieira_plot(np) = gsn_csm_xy (wks,time_vieira(period_indices(np,0,0):period_indices(np,0,1)),runave(vieira(period_indices(np,0,0):period_indices(np,0,1)),mean/10,opt),res) 
	
	; Roth and Joos
		res@xyLineColors       			= colors(1) 
		roth_plot(np) = gsn_csm_xy (wks,time_roth(period_indices(np,1,0):period_indices(np,1,1)),runave(roth(period_indices(np,1,0):period_indices(np,1,1)),mean/10,opt),res) 

	; Steinhilber (2009)
		res@xyLineColors       			= colors(2) 
		steinhilber_2009_plot(np) = gsn_csm_xy (wks,time_steinhilber_2009(period_indices(np,2,0):period_indices(np,2,1)),runave(steinhilber_2009(period_indices(np,2,0):period_indices(np,2,1)),mean/5,opt),res) 

	; Steinhilber (2012)
		res@xyLineColors       			= colors(3) 
		steinhilber_2012_plot(np) = gsn_csm_xy (wks,time_steinhilber_2012(period_indices(np,3,0):period_indices(np,3,1)),runave(steinhilber_2012(period_indices(np,3,0):period_indices(np,3,1)),mean/22,opt),res) 

	overlay(vieira_plot(np),roth_plot(np))
	overlay(vieira_plot(np),steinhilber_2009_plot(np))
	overlay(vieira_plot(np),steinhilber_2012_plot(np))

	resP                  = True                   ; modify the panel plot
	;resP@lbOrientation    = "Horizontal"          ; vertical label bar
	;MresP@txString         = "Linear trends from control simulation"
	resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
	;resP@gsnPanelLabelBar = True                   ; add common label bar


end do     

lgres                    = True
lgres@lgLineColors       = colors
lgres@lgLineThicknessF	 = 5.0
lgres@lgItemType         = "Lines"        ; show lines only (default)
lgres@lgLabelFontHeightF = .1            ; legend label font thickness
lgres@vpWidthF           = 0.25           ; width of legend (NDC)
lgres@vpHeightF          = 0.12           ; height of legend (NDC)
lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
lgres@lgMonoDashIndex    = True
lgres@lgDashIndex        = 0

labels = (/"   Vieira et al. (2011)","   Roth and Joos (2013)","   Steinhilber et al. (2009)","   Steinhilber et al. (2012)"/) 
legend = gsn_create_legend (wks, 4, labels,lgres)

amres = True
amres@amParallelPosF   = -.5		    ; move legend to the right
amres@amOrthogonalPosF = -.8             ; move the legend down
annoid1 = gsn_add_annotation(vieira_plot(2),legend,amres)   ; add legend to plot

gsn_panel(wks,vieira_plot,(/3,1/),resP)  

delete([/vieira_plot,roth_plot,steinhilber_2009_plot,steinhilber_2012_plot/])
 
;*****************************************************************************************
;*****************************************************************************************

wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/TSI_last_millenium")   

mean=11

colors2							= (/"grey","grey","grey","grey","black","firebrick2","deepskyblue","palegreen4","gold","darkorchid4"/)

res@vpHeightF 	 				= 0.4              	
res@vpWidthF 	        		= 0.7

res@gsnCenterStringOrthogonalPosF	= 0.07
res@trXMinF	         			= panels_min(2)          	
res@trXMaxF	       	  			= panels_max(2) 
res@tiMainString				= "~Z75~PMIP3 TSI reconstructions" 
res@gsnCenterString 			= "~Z75~Period: "+panels_min(2)+" A.D. - present; 11-year running mean"


; Vieira et al
	res@xyLineColors       			= colors2(0)
	res@xyDashPatterns     = 1
	vieira_plot = gsn_csm_xy (wks,time_vieira(period_indices(2,0,0):period_indices(2,0,1)),runave(vieira(period_indices(2,0,0):period_indices(2,0,1)),mean/10,opt),res) 

; Roth and Joos
	res@xyLineColors       			= colors2(1)
	res@xyDashPatterns     = 2 
	roth_plot = gsn_csm_xy (wks,time_roth(period_indices(2,1,0):period_indices(2,1,1)),runave(roth(period_indices(2,1,0):period_indices(2,1,1)),mean/10,opt),res) 

; Steinhilber (2009)
	res@xyLineColors       			= colors2(2)
	res@xyDashPatterns     = 3
	steinhilber_2009_plot = gsn_csm_xy (wks,time_steinhilber_2009(period_indices(2,2,0):period_indices(2,2,1)),runave(steinhilber_2009(period_indices(2,2,0):period_indices(2,2,1)),mean/5,opt),res) 

; Steinhilber (2012)
	res@xyLineColors       			= colors2(3) 
	res@xyDashPatterns     = 15
	steinhilber_2012_plot = gsn_csm_xy (wks,time_steinhilber_2012(period_indices(2,3,0):period_indices(2,3,1)),runave(steinhilber_2012(period_indices(2,3,0):period_indices(2,3,1)),mean/22,opt),res) 

res@xyLineThicknesses   		= (/5.0/) 
res@xyDashPatterns     = 0 

; WLS (noback)
	res@xyLineColors       			= colors2(4)
	WLS_noback_plot = gsn_csm_xy (wks,WLS_time({panels_min(2):panels_max(2)}),runave(WLS_noback({panels_min(2):panels_max(2)}),mean,opt),res) 

; WLS (back)
	res@xyLineColors       			= colors2(5) 
	WLS_back_plot = gsn_csm_xy (wks,WLS_time({panels_min(2):panels_max(2)}),runave(WLS_back({panels_min(2):panels_max(2)}),mean,opt),res) 

; DB (noback)
	res@xyLineColors       			= colors2(6)
	DB_noback_plot = gsn_csm_xy (wks,DB_time({panels_min(2):panels_max(2)}),runave(DB_noback({panels_min(2):panels_max(2)}),mean,opt),res) 

; DB (back)
	res@xyLineColors       			= colors2(7) 
	DB_back_plot = gsn_csm_xy (wks,DB_time({panels_min(2):panels_max(2)}),runave(DB_back({panels_min(2):panels_max(2)}),mean,opt),res) 

; VSK (noback)
	res@xyLineColors       			= colors2(8)
	VSK_noback_plot = gsn_csm_xy (wks,VSK_time({panels_min(2):panels_max(2)}),runave(VSK_noback({panels_min(2):panels_max(2)}),mean,opt),res) 

; SBF (noback)
	res@xyLineColors       			= colors2(9)
	SBF_noback_plot = gsn_csm_xy (wks,SBF_time({panels_min(2):panels_max(2)}),runave(SBF_noback({panels_min(2):panels_max(2)}),mean,opt),res) 

overlay(vieira_plot,roth_plot)
overlay(vieira_plot,steinhilber_2009_plot)
overlay(vieira_plot,steinhilber_2012_plot)
overlay(vieira_plot,WLS_noback_plot)
overlay(vieira_plot,WLS_back_plot)
overlay(vieira_plot,DB_noback_plot)
overlay(vieira_plot,DB_back_plot)
overlay(vieira_plot,VSK_noback_plot)
overlay(vieira_plot,SBF_noback_plot)

lgres2                    = True
lgres2@lgLineColors       = colors2
lgres2@lgMonoDashIndex		=False
lgres2@lgDashIndexes    = (/1,2,3,15,0,0,0,0,0,0/) 
lgres2@lgLineThicknessF	 = 5.0
lgres2@lgItemType         = "Lines"        ; show lines only (default)
lgres2@lgLabelFontHeightF = .07            ; legend label font thickness
lgres2@vpWidthF           = 0.25           ; width of legend (NDC)
lgres2@vpHeightF          = 0.18           ; height of legend (NDC)
lgres2@lgPerimThicknessF  = 1.7            ; thicken the box perimeter
;lgres2@lgMonoDashIndex    = True
;lgres2@lgDashIndex        = 0

labels2 = (/"   Vieira et al. (2011)","   Roth and Joos (2013)","   Steinhilber et al. (2009)","   Steinhilber et al. (2012)","   WLS (noback)","   WLS (back)","   DB (noback)","   DB (back)","   VSK","   SBF"/) 
legend = gsn_create_legend (wks, 10, labels2,lgres2)

amres = True
amres@amParallelPosF   = -.5		    ; move legend to the right
amres@amOrthogonalPosF = -.8             ; move the legend down
annoid1 = gsn_add_annotation(vieira_plot,legend,amres)   ; add legend to plot

draw(wks)

;*****************************************************************************************
;*****************************************************************************************


d   = 1    ; detrending opt: 0=>remove mean 1=>remove mean + detrend
sm  = 3   ; smooth: should be at least 3 and odd
pct = 0.10 ; percent taper: (0.0 <= pct <= 1.0) 0.10 common.

wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/spectra/TSI_holocene_spectra")   
plot = new(10,graphic)

r = True                                      ; plot mods desired 
r@tiXAxisString = "Frequency (1/yrs)"  ; xaxis
r@tiYAxisString = "Variance"                  ; yaxis
r@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r@trYLog              = True                 ; log scaling
r@trXLog              = True                 ; log scaling
r@xyLineColors        = (/"foreground","foreground","foreground","foreground"/)
r@gsnDraw  = False                         
r@gsnFrame = False 
r@tiMainFont      = "helvetica-bold"			; set main title to helvetica
r@trXMinF	         			= 0.0005             	
r@trXMaxF	       	  			= 0.5
r@trYMinF	         			= 0.0001             	
r@trYMaxF	       	  			= 100.0
r@tmXBMinorPerMajor = 8
r@tmXTMinorPerMajor = 8
r@tmYLMinorPerMajor = 8
r@tmYRMinorPerMajor = 8


do nn=0,9

	if (nn .eq. 0) then 
		time_series=vieira(0:1113)
		sdof = specx_anal(time_series,d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)		
		r@tiMainString = "Vieira" 	 
		plot(nn) = gsn_csm_xy(wks,sdof@frq/10, splt,r)
	else if (nn .eq. 1) then
		time_series=roth
		sdof = specx_anal(time_series,d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)		
		r@tiMainString = "Roth et al." 	 
		plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)		
	else if (nn .eq. 2) then
		time_series=steinhilber_2009
		sdof = specx_anal(time_series,d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)		
		r@tiMainString = "Steinhilber 2009" 	 
		plot(nn) = gsn_csm_xy(wks,sdof@frq/5, splt,r)
	else if (nn .eq. 3) then
		time_series=steinhilber_2012
		sdof = specx_anal(time_series,d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)		
		r@tiMainString = "Steinhilber 2012" 	 
		plot(nn) = gsn_csm_xy(wks,sdof@frq/22, splt,r)
	else if (nn .eq. 4) then
		time_series=SBF_noback
		sdof = specx_anal(time_series,d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)		
		r@tiMainString = "SBF" 	 
		plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)	
	else if (nn .eq. 5) then
		time_series=VSK_noback
		sdof = specx_anal(time_series,d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)		
		r@tiMainString = "VSK" 	 
		plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)	
	else if (nn .eq. 6) then
		time_series=DB_noback
		sdof = specx_anal(time_series,d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)		
		r@tiMainString = "DB (noback)" 	 
		plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)	
	else if (nn .eq. 7) then
		time_series=DB_back
		sdof = specx_anal(time_series,d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)		
		r@tiMainString = "DB (back)" 	 
		plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)	
	else if (nn .eq. 8) then
		time_series=WLS_noback
		sdof = specx_anal(time_series,d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)		
		r@tiMainString = "WLS (noback)" 	 
		plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)	
	else if (nn .eq. 9) then
		time_series=WLS_back
		sdof = specx_anal(time_series,d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)		
		r@tiMainString = "WLS (back)" 	 
		plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)	
	end if
	end if
	end if
	end if
	end if
	end if
	end if
	end if
	end if
	end if
				
	delete([/time_series,sdof,splt/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ TSI Holocene spectra; 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/4,3/),resP)               ; now draw as one plot


end