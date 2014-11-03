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

directory=CMIP_dir+"/data/KCM_copy/"
files_nino = systemfunc ("ls "+directory+"NINO3/*NINO3_yearly_mean_*detrended*.nc")
files_amo = systemfunc ("ls "+directory+"AMO/*AMO_decadal_mean_*detrended*.nc")
nino_tmp=addfiles(files_nino,"r")
amo_tmp=addfiles(files_amo,"r")
ListSetType (nino_tmp, "join")
ListSetType (amo_tmp, "join")

model_name=files_nino
do nt = 0,(dimsizes(files_nino)-1)
	strs=str_split(files_nino(nt),"_")
	model_name(nt)=strs(2)
	delete(strs)
end do

print(model_name)


d   = 1    ; detrending opt: 0=>remove mean 1=>remove mean + detrend
sm  = 47    ; smooth: should be at least 3 and odd
pct = 0.10 ; percent taper: (0.0 <= pct <= 1.0) 0.10 common. 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Spectra
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 
; NINO3
create_plot=0

if (create_plot .eq. 1) then

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/spectra/KCM_NINO3")  ; open workstation 
plot = new(5,graphic)
plot2= new(5,graphic)

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
r@trXMinF	         			= 0.06             	
r@trXMaxF	       	  			= 0.5
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
r2@trXMinF	         			= 0.06             	
r2@trXMaxF	       	  			= 0.5
r2@trYMinF	         			= 0.2             	
r2@trYMaxF	       	  			= 3.0
r2@tmXBMinorPerMajor = 8
r2@tmYLMinorPerMajor = 8
r2@tmXTMinorPerMajor = 8
r2@tmYRMinorPerMajor = 8

do nn=0,4
	
	nino=nino_tmp[nn+1]->sosstsst(:,:,0,0)
	; calculate spectrum
	sdof = specx_anal(nino(0,:),d,sm,pct)

	; calculate confidence interval [here 1 and 99%] return 4 curves to be plotted
	splt = specx_ci (sdof, 0.01, 0.99)
	
	; repeat calculations for control run
	nino_ctrl=nino_tmp[0]->sosstsst(:,:,0,0)
	sdof_ctrl = specx_anal(nino_ctrl(0,:),d,sm,pct)
	splt_ctrl = specx_ci (sdof_ctrl, 0.01, 0.99)

	r@tiMainString = model_name(nn+1)  
	 
	plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)	
	plot2(nn) = gsn_csm_xy(wks,sdof_ctrl@frq, splt_ctrl,r2)
	
	overlay (plot(nn), plot2(nn))
	
	delete([/nino_ctrl,nino,sdof,sdof_ctrl,splt,splt_ctrl/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for NINO3 index ~Z50~ full-forcing (red), control (black); 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/2,3/),resP)               ; now draw as one plot


end if


; AMO
create_plot=1

if (create_plot .eq. 1) then

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/spectra/KCM_AMO")  ; open workstation 
plot = new(6,graphic)
plot2= new(6,graphic)

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
r@trXMaxF	       	  			= 0.5
r@trYMinF	         			= 0.00001             	
r@trYMaxF	       	  			= 10.0
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
r2@trXMaxF	       	  			= 0.5
r2@trYMinF	         			= 0.00001             	
r2@trYMaxF	       	  			= 10.0
r2@tmXBMinorPerMajor = 8
r2@tmYLMinorPerMajor = 8
r2@tmXTMinorPerMajor = 8
r2@tmYRMinorPerMajor = 8

do nn=0,4
	
	amo=amo_tmp[nn+1]->sosstsst(:,:,0,0)
	; calculate spectrum
	sdof = specx_anal(amo(0,:),d,sm,pct)

	; calculate confidence interval [here 1 and 99%] return 4 curves to be plotted
	splt = specx_ci (sdof, 0.01, 0.99)
	
	; repeat calculations for control run
	amo_ctrl=amo_tmp[0]->sosstsst(:,:,0,0)
	sdof_ctrl = specx_anal(amo_ctrl(0,:),d,sm,pct)
	splt_ctrl = specx_ci (sdof_ctrl, 0.01, 0.99)

	r@tiMainString = model_name(nn+1)  
	 
	plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)	
	plot2(nn) = gsn_csm_xy(wks,sdof_ctrl@frq, splt_ctrl,r2)
	
	overlay (plot(nn), plot2(nn))
	
	delete([/amo_ctrl,amo,sdof,sdof_ctrl,splt,splt_ctrl/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for AMO index ~Z50~ full-forcing (red), control (black); 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/2,3/),resP)               ; now draw as one plot


end if


end


