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
files_nino = systemfunc ("ls "+directory+"NINO3/tsw*NINO3_yearly_mean_*detrended*.nc")
files_amo = systemfunc ("ls "+directory+"AMO/tsw*AMO_yearly_mean_*detrended*.nc")
files_pdo = systemfunc ("ls "+directory+"PDO/tsw*PDO_yearly_mean_*detrended*pc1*.nc")
nino_tmp=addfiles(files_nino(order),"r")
amo_tmp=addfiles(files_amo(order),"r")
pdo_tmp=addfiles(files_pdo(order),"r")

ListSetType (nino_tmp, "join")
ListSetType (amo_tmp, "join")
ListSetType (pdo_tmp, "join")


files_ordered=files_nino(order)
model_name=files_ordered
do nt = 0,(dimsizes(files_ordered)-1)
	strs=str_split(files_ordered(nt),"_")
	model_name(nt)=strs(1)
	delete(strs)
end do

print(model_name)

; indices time series

res                     		= True  
res@gsnDraw  = False                         
res@gsnFrame = False            
res@vpHeightF 	 				= 5              	
res@vpWidthF 	        		= 25.0
res@gsnScale = True  
;res@tmYMajorGrid				= "True"
;res@tmYMajorGridLineColor		= "grey"
;res@tmYMajorGridLineDashPattern	= 16
;res@tmYMajorGridThicknessF		= 1.0       
res@gsnXYBarChart         = True            ; create bar chart      
res@gsnYRefLine           = 0.              ; reference line   
res@gsnAboveYRefLineColor = "red"           ; above ref line fill red
res@gsnBelowYRefLineColor = "blue"         ; below ref line fill blue
res@xyLineColors = (/"red","blue"/)         ; colors for the above/blow

;res@gsnPaperOrientation = "auto"

res2=True
res2@gsnDraw  = False                         
res2@gsnFrame = False 
res2@xyLineThicknesses=5.0


time_series=0

if (time_series .eq. 1) then
	nino_ctrl=nino_tmp[5]->tsw(:,:,0,0)
	time_ctrl=nino_tmp[5]->time
	time_ctrl_new=cd_calendar(time_ctrl,0)
	nino_ctrl&time=time_ctrl_new(:,0)
	amo_ctrl=amo_tmp[5]->tsw(:,:,0,0)
	amo_ctrl&time=time_ctrl_new(:,0)
	pdo_ctrl=pdo_tmp[5]->tsw(:,:,0,0)
	pdo_ctrl&time=time_ctrl_new(:,0)
	
do nn=0,5

print(nn)

wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/KCM_"+model_name(nn)+"_NINO3_AMO_PDO_time_series_2_0") 
plot = new(3,graphic)
plot2 = new(3,graphic)

		

	nino=nino_tmp[nn]->tsw(:,:,0,0)
	time=nino_tmp[nn]->time
	time_new=cd_calendar(time,0)
	nino&time=time_new(:,0)
	
	amo=amo_tmp[nn]->tsw(:,:,0,0)
	amo&time=time_new(:,0)
		
	pdo=pdo_tmp[nn]->tsw(:,:,0,0)
	pdo&time=time_new(:,0)
	
	res@trXMinF	         			= min(time_new(:,0))      	
    res@trXMaxF	       	  			= max(time_new(:,0))
  	
  res@tiYAxisString		= "NINO3"
  res@trYMinF	            		= -4.0       
  res@trYMaxF	            		= 4.0
  plot(0) = gsn_csm_xy (wks,(/time_new(:,0)/),(/nino/),res)
  res@tiYAxisString		= "AMO"
  res@trYMinF	            		= -0.8       
  res@trYMaxF	            		= 0.8
  res2@trYMinF	            		= -0.8       
  res2@trYMaxF	            		= 0.8
  plot(1) = gsn_csm_xy (wks,(/time_new(:,0)/),(/amo/),res) 
  plot2(1) = gsn_csm_xy (wks,(/time_new(:,0)/),runave((/amo/),31,0),res2)
  overlay(plot(1),plot2(1))
  res@tiYAxisString		= "PDO"
  res@trYMinF	            		= -4.0       
  res@trYMaxF	            		= 4.0
  res2@trYMinF	            		= -0.8       
  res2@trYMaxF	            		= 0.8
  plot(2) = gsn_csm_xy (wks,(/time_new(:,0)/),(/pdo/),res)
  plot2(2) = gsn_csm_xy (wks,(/time_new(:,0)/),runave((/pdo/),31,0),res2)
 overlay(plot(2),plot2(2))


  
  delete([/nino,amo,pdo,time,time_new/])   


resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ "+model_name(nn)+" ("+forcing_period(nn)+") time series of NINO3, AMO and PDO index"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/3,1/),resP)               ; now draw as one plot
end do

end if




d   = 1    ; detrending opt: 0=>remove mean 1=>remove mean + detrend
sm  = 101    ; smooth: should be at least 3 and odd
pct = 0.10 ; percent taper: (0.0 <= pct <= 1.0) 0.10 common. 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Spectra
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

r = True                                      ; plot mods desired 
r@tiXAxisString = "Period (years)"  ; xaxis
r@tiYAxisString = "Variance"                  ; yaxis
r@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r@trYLog              = True                 ; log scaling
r@trXLog              = True                 ; log scaling
r@xyLineColors        = (/"firebrick","firebrick","firebrick","firebrick"/)
r@gsnDraw  = False                         
r@gsnFrame = False 
r@tiMainFont      = "helvetica-bold"			; set main title to helvetica
r@trXMinF	         			= 1.0             	
r@trXMaxF	       	  			= 2000.0
r@trYMinF	         			= 0.2            	
r@trYMaxF	       	  			= 3.0
r@tmXBMinorPerMajor = 8
r@tmYLMinorPerMajor = 8
r@tmXTMinorPerMajor = 8
r@tmYRMinorPerMajor = 8


r2 = True                                      ; plot mods desired 
r2@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r2@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r2@trYLog              = True                 ; log scaling
r2@trXLog              = True                 ; log scaling
r2@xyLineColors        = (/"foreground","foreground","foreground","foreground"/)
r2@gsnDraw  = False                         
r2@gsnFrame = False 
r2@trXMinF	         			= 1.0             	
r2@trXMaxF	       	  			= 2000.0
r2@trYMinF	         			= 0.2             	
r2@trYMaxF	       	  			= 3.0
r2@tmXBMinorPerMajor = 8
r2@tmYLMinorPerMajor = 8
r2@tmXTMinorPerMajor = 8
r2@tmYRMinorPerMajor = 8

 
; NINO3
create_plot_nino=0

if (create_plot_nino .eq. 1) then

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/spectra/KCM_NINO3_2_0")  ; open workstation 
plot = new(6,graphic)
plot2= new(6,graphic)

do nn=0,5
	
	nino=nino_tmp[nn]->tsw(:,:,0,0)
	; calculate spectrum
	sdof = specx_anal(nino(0,:),d,sm,pct)

	; calculate confidence interval [here 1 and 99%] return 4 curves to be plotted
	splt = specx_ci (sdof, 0.01, 0.99)
	
	; repeat calculations for control run
	nino_ctrl=nino_tmp[5]->tsw(:,:,0,0)
	sdof_ctrl = specx_anal(nino_ctrl(0,:),d,sm,pct)
	splt_ctrl = specx_ci (sdof_ctrl, 0.01, 0.99)

	r@tiMainString = model_name(nn)+" ("+forcing_period(nn)+")"  
	 
	plot(nn) = gsn_csm_xy(wks,1.0/sdof@frq, splt,r)	
	plot2(nn) = gsn_csm_xy(wks,1.0/sdof_ctrl@frq, splt_ctrl,r2)
	
	overlay (plot(nn), plot2(nn))
	
	delete([/nino_ctrl,nino,sdof,sdof_ctrl,splt,splt_ctrl/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for NINO3 index ~Z50~ full-forcing (red), control (black); 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/3,2/),resP)               ; now draw as one plot


end if


; AMO

create_plot_amo=0

d   = 1    ; detrending opt: 0=>remove mean 1=>remove mean + detrend
sm  = 11    ; smooth: should be at least 3 and odd
pct = 0.10 ; percent taper: (0.0 <= pct <= 1.0) 0.10 common.

if (create_plot_amo .eq. 1) then

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/spectra/KCM_AMO_2_0")  ; open workstation 
plot = new(6,graphic)
plot2= new(6,graphic)

r@trYMinF	         			= 0.001             	
r@trYMaxF	       	  			= 10.0

r2@trYMinF	         			= 0.001             	
r2@trYMaxF	       	  			= 10.0


do nn=0,5
	
	amo=amo_tmp[nn]->tsw(:,:,0,0)
	; calculate spectrum
	sdof = specx_anal(amo(0,:),d,sm,pct)

	; calculate confidence interval [here 1 and 99%] return 4 curves to be plotted
	splt = specx_ci (sdof, 0.01, 0.99)
	
	; repeat calculations for control run
	amo_ctrl=amo_tmp[5]->tsw(:,:,0,0)
	sdof_ctrl = specx_anal(amo_ctrl(0,:),d,sm,pct)
	splt_ctrl = specx_ci (sdof_ctrl, 0.01, 0.99)

	r@tiMainString = model_name(nn)+" ("+forcing_period(nn)+")"  
	 
	plot(nn) = gsn_csm_xy(wks,1.0/sdof@frq, splt,r)	
	plot2(nn) = gsn_csm_xy(wks,1.0/sdof_ctrl@frq, splt_ctrl,r2)
	
	overlay (plot(nn), plot2(nn))
	
	delete([/amo_ctrl,amo,sdof,sdof_ctrl,splt,splt_ctrl/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for AMO index ~Z50~ full-forcing (red), control (black); 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/3,2/),resP)               ; now draw as one plot


end if

; PDO

create_plot_pdo=1

d   = 1    ; detrending opt: 0=>remove mean 1=>remove mean + detrend
sm  = 11    ; smooth: should be at least 3 and odd
pct = 0.10 ; percent taper: (0.0 <= pct <= 1.0) 0.10 common.

if (create_plot_pdo .eq. 1) then

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/spectra/KCM_PDO_2_0")  ; open workstation 
plot = new(6,graphic)
plot2= new(6,graphic)

r@trYMinF	         			= 0.1             	
r@trYMaxF	       	  			= 50.0

r2@trYMinF	         			= 0.1             	
r2@trYMaxF	       	  			= 50.0


do nn=0,5
	
	pdo=pdo_tmp[nn]->tsw(:,:,0,0)
	; calculate spectrum
	sdof = specx_anal(pdo(0,:),d,sm,pct)

	; calculate confidence interval [here 1 and 99%] return 4 curves to be plotted
	splt = specx_ci (sdof, 0.01, 0.99)
	
	; repeat calculations for control run
	pdo_ctrl=pdo_tmp[5]->tsw(:,:,0,0)
	sdof_ctrl = specx_anal(pdo_ctrl(0,:),d,sm,pct)
	splt_ctrl = specx_ci (sdof_ctrl, 0.01, 0.99)

	r@tiMainString = model_name(nn)+" ("+forcing_period(nn)+")"  
	 
	plot(nn) = gsn_csm_xy(wks,1.0/sdof@frq, splt,r)	
	plot2(nn) = gsn_csm_xy(wks,1.0/sdof_ctrl@frq, splt_ctrl,r2)
	
	overlay (plot(nn), plot2(nn))
	
	delete([/pdo_ctrl,pdo,sdof,sdof_ctrl,splt,splt_ctrl/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for PDO index ~Z50~ full-forcing (red), control (black); 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/3,2/),resP)               ; now draw as one plot


end if

end


