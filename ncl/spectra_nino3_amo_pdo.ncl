;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

; load data

CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP/"

nino_past_directory=CMIP_dir+"processed/CMIP5/past1000/Omon/tos/NINO3_original_resolution_monthly_mean_detrended/"
nino_past_files = systemfunc ("ls "+nino_past_directory+"*.nc")
nino_past_tmp=addfiles(nino_past_files,"r")
ListSetType (nino_past_tmp, "join")

nino_ctrl_directory=CMIP_dir+"processed/CMIP5/piControl/Omon/tos/NINO3_original_resolution_monthly_mean_detrended/"
nino_ctrl_files = systemfunc ("ls "+nino_ctrl_directory+"*.nc")
nino_ctrl_tmp=addfiles(nino_ctrl_files,"r")
ListSetType (nino_ctrl_tmp, "join")

amo_past_directory=CMIP_dir+"processed/CMIP5/past1000/Omon/tos/AMO_original_resolution_monthly_mean_detrended/"
amo_past_files = systemfunc ("ls "+amo_past_directory+"*.nc")
amo_past_tmp=addfiles(amo_past_files,"r")
ListSetType (amo_past_tmp, "join")

amo_ctrl_directory=CMIP_dir+"processed/CMIP5/piControl/Omon/tos/AMO_original_resolution_monthly_mean_detrended/"
amo_ctrl_files = systemfunc ("ls "+amo_ctrl_directory+"*.nc")
amo_ctrl_tmp=addfiles(amo_ctrl_files,"r")
ListSetType (amo_ctrl_tmp, "join")

model_name=nino_past_files
do nt = 0,(dimsizes(nino_past_files)-1)
	strs=str_split(nino_past_files(nt),"_")
	model_name(nt)=strs(7)
	delete(strs)
end do

print(model_name)






d   = 1    ; detrending opt: 0=>remove mean 1=>remove mean + detrend
sm  = 27    ; smooth: should be at least 3 and odd
pct = 0.10 ; percent taper: (0.0 <= pct <= 1.0) 0.10 common. 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Spectra
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 
; NINO3
create_plot=1

if (create_plot .eq. 1) then

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/spectra/tos_NINO3_past1000_and_piControl")  ; open workstation 
plot = new(7,graphic)
plot2= new(7,graphic)

r = True                                      ; plot mods desired 
r@tiXAxisString = "Frequency (1/yrs)"  ; xaxis
r@tiYAxisString = "Variance"                  ; yaxis
r@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r@trYLog              = True                 ; log scaling
r@trXLog              = True                 ; log scaling
r@xyLineColors        = (/"firebrick","firebrick","firebrick","firebrick"/)
r@gsnDraw  = False                         
r@gsnFrame = False 
r@tiMainFont      = "helvetica-bold"			; set main title to helvetica
r@trXMinF	         			= 0.01             	
r@trXMaxF	       	  			= 2.0
r@trYMinF	         			= 0.0001             	
r@trYMaxF	       	  			= 500.0
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
r2@trXMinF	         			= 0.01             	
r2@trXMaxF	       	  			= 2.0
r2@trYMinF	         			= 0.0001             	
r2@trYMaxF	       	  			= 500.0
r2@tmXBMinorPerMajor = 8
r2@tmYLMinorPerMajor = 8
r2@tmXTMinorPerMajor = 8
r2@tmYRMinorPerMajor = 8

do nn=0,6
	
	nino_past=nino_past_tmp[nn]->tos(:,:,0,0)
	; calculate spectrum
	sdof_past = specx_anal(nino_past(0,:),d,sm,pct)

	; calculate confidence interval [here 1 and 99%] return 4 curves to be plotted
	splt_past = specx_ci (sdof_past, 0.01, 0.99)
	
	; repeat calculations for control run
	nino_ctrl=nino_ctrl_tmp[nn]->tos(:,:,0,0)
	sdof_ctrl = specx_anal(nino_ctrl(0,:),d,sm,pct)
	splt_ctrl = specx_ci (sdof_ctrl, 0.01, 0.99)

	r@tiMainString = model_name(nn)  
	 
	plot(nn) = gsn_csm_xy(wks,sdof_past@frq*12, splt_past,r)	
	plot2(nn) = gsn_csm_xy(wks,sdof_ctrl@frq*12, splt_ctrl,r2)
	
	overlay (plot(nn), plot2(nn))
	
	delete([/nino_ctrl,nino_past,sdof_past,sdof_ctrl,splt_past,splt_ctrl/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for NINO3 index ~Z50~past1000 (red), piControl (black); 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/2,4/),resP)               ; now draw as one plot


end if


; AMO
create_plot=1

if (create_plot .eq. 1) then

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/spectra/tos_AMO_past1000_and_piControl")  ; open workstation 
plot = new(7,graphic)
plot2= new(7,graphic)

r = True                                      ; plot mods desired 
r@tiXAxisString = "Frequency (1/yrs)"  ; xaxis
r@tiYAxisString = "Variance"                  ; yaxis
r@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r@trYLog              = True                 ; log scaling
r@trXLog              = True                 ; log scaling
r@xyLineColors        = (/"firebrick","firebrick","firebrick","firebrick"/)
r@gsnDraw  = False                         
r@gsnFrame = False 
r@tiMainFont      = "helvetica-bold"			; set main title to helvetica
r@trXMinF	         			= 0.001             	
r@trXMaxF	       	  			= 2.0
r@trYMinF	         			= 0.00001             	
r@trYMaxF	       	  			= 100.0
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
r2@trXMinF	         			= 0.001             	
r2@trXMaxF	       	  			= 2.0
r2@trYMinF	         			= 0.00001             	
r2@trYMaxF	       	  			= 100.0
r2@tmXBMinorPerMajor = 8
r2@tmYLMinorPerMajor = 8
r2@tmXTMinorPerMajor = 8
r2@tmYRMinorPerMajor = 8

do nn=0,6
	
	amo_past=amo_past_tmp[nn]->tos(:,:,0,0)
	; calculate spectrum
	sdof_past = specx_anal(amo_past(0,:),d,sm,pct)

	; calculate confidence interval [here 1 and 99%] return 4 curves to be plotted
	splt_past = specx_ci (sdof_past, 0.01, 0.99)
	
	; repeat calculations for control run
	amo_ctrl=amo_ctrl_tmp[nn]->tos(:,:,0,0)
	sdof_ctrl = specx_anal(amo_ctrl(0,:),d,sm,pct)
	splt_ctrl = specx_ci (sdof_ctrl, 0.01, 0.99)

	r@tiMainString = model_name(nn)  
	 
	plot(nn) = gsn_csm_xy(wks,sdof_past@frq*12, splt_past,r)	
	plot2(nn) = gsn_csm_xy(wks,sdof_ctrl@frq*12, splt_ctrl,r2)
	
	overlay (plot(nn), plot2(nn))
	
	delete([/amo_ctrl,amo_past,sdof_past,sdof_ctrl,splt_past,splt_ctrl/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for AMO index ~Z50~past1000 (red), piControl (black); 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/2,4/),resP)               ; now draw as one plot


end if


end


