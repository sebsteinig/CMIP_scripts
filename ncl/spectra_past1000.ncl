;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

; load data

CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP/"

gm_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/global_mean_decadal_running_mean/"
gm_files = systemfunc ("ls "+gm_directory+"*.nc")
gm_tmp=addfiles(gm_files,"r")
ListSetType (gm_tmp, "join")

gm_annual_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/global_mean_annual_mean/"
gm_annual_files = systemfunc ("ls "+gm_annual_directory+"*.nc")
gm_annual_tmp=addfiles(gm_annual_files,"r")
ListSetType (gm_annual_tmp, "join")

gm_ctrl_directory=CMIP_dir+"processed/CMIP5/piControl/Amon/tas/global_mean_decadal_running_mean/"
gm_ctrl_files = systemfunc ("ls "+gm_ctrl_directory+"*.nc")
gm_ctrl_tmp=addfiles(gm_ctrl_files,"r")
ListSetType (gm_ctrl_tmp, "join")

gm_annual_ctrl_directory=CMIP_dir+"processed/CMIP5/piControl/Amon/tas/global_mean_annual_mean/"
gm_annual_ctrl_files = systemfunc ("ls "+gm_annual_ctrl_directory+"*.nc")
gm_annual_ctrl_tmp=addfiles(gm_annual_ctrl_files,"r")
ListSetType (gm_annual_ctrl_tmp, "join")

nh_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/NH_mean_decadal_running_mean/"
nh_files = systemfunc ("ls "+nh_directory+"*.nc")
nh_tmp=addfiles(nh_files,"r")
ListSetType (nh_tmp, "join")

nh_annual_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/NH_mean_annual_mean/"
nh_annual_files = systemfunc ("ls "+nh_annual_directory+"*.nc")
nh_annual_tmp=addfiles(nh_annual_files,"r")
ListSetType (nh_annual_tmp, "join")

nh_ctrl_directory=CMIP_dir+"processed/CMIP5/piControl/Amon/tas/NH_mean_decadal_running_mean/"
nh_ctrl_files = systemfunc ("ls "+nh_ctrl_directory+"*.nc")
nh_ctrl_tmp=addfiles(nh_ctrl_files,"r")
ListSetType (nh_ctrl_tmp, "join")

nh_annual_ctrl_directory=CMIP_dir+"processed/CMIP5/piControl/Amon/tas/NH_mean_annual_mean/"
nh_annual_ctrl_files = systemfunc ("ls "+nh_annual_ctrl_directory+"*.nc")
nh_annual_ctrl_tmp=addfiles(nh_annual_ctrl_files,"r")
ListSetType (nh_annual_ctrl_tmp, "join")

proxy_gm_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_global_mean_0856-1845_decadal_running_mean.nc","r")
proxy_nh_tmp=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_0856-1845_decadal_running_mean.nc","r")

model_name=gm_files
do nt = 0,(dimsizes(gm_files)-1)
	strs=str_split(gm_files(nt),"_")
	model_name(nt)=strs(8)
	delete(strs)
end do

print(model_name)

names=array_append_record(model_name,"Mann et al. 2009 reconstruction",0)

gm=gm_tmp[:]->tas(:,:,0,0)
nh=nh_tmp[:]->tas(:,:,0,0)
gm_annual=gm_annual_tmp[:]->tas(:,:,0,0)
nh_annual=nh_annual_tmp[:]->tas(:,:,0,0)

proxy_gm=proxy_gm_tmp->tas(:,:,0)
proxy_nh=proxy_nh_tmp->tas(:,:,0)

proxy_gm!1="ncl_join"
proxy_nh!1="ncl_join"

all_fields_gm=array_append_record(gm,proxy_gm(ncl_join|:,time|:),0)
all_fields_nh=array_append_record(nh,proxy_nh(ncl_join|:,time|:),0)

d   = 1    ; detrending opt: 0=>remove mean 1=>remove mean + detrend
sm  = 3   ; smooth: should be at least 3 and odd
pct = 0.10 ; percent taper: (0.0 <= pct <= 1.0) 0.10 common. 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; decadal running mean
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/spectra/tas_0851-1849_past1000_spectra_global_mean")  ; open workstation 
plot = new(11,graphic)
plot2=new(11,graphic)

r = True                                      ; plot mods desired 
r@tiXAxisString = "Frequency (1/yrs)"  ; xaxis
r@tiYAxisString = "Variance"                  ; yaxis
r@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r@trYLog              = True                 ; log scaling
r@trXLog              = True                 ; log scaling
;r@xyLineColors        = (/"foreground","green","blue","red"/)
r@xyLineColors        = (/"foreground","foreground","foreground","foreground"/)
r@gsnDraw  = False                         
r@gsnFrame = False 
r@tiMainFont      = "helvetica-bold"			; set main title to helvetica
r@trXMinF	         			= 0.001             	
r@trXMaxF	       	  			= 0.55
r@trYMinF	         			= 0.00000001             	
r@trYMaxF	       	  			= 30.0
r@tmXBMinorPerMajor = 8
r@tmYLMinorPerMajor = 8
r@tmXTMinorPerMajor = 8
r@tmYRMinorPerMajor = 8



r2 = True                                      ; plot mods desired 
r2@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r2@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r2@trYLog              = True                 ; log scaling
r2@trXLog              = True                 ; log scaling
r2@xyLineColors        = (/"deepskyblue","deepskyblue","deepskyblue","deepskyblue"/)
r2@gsnDraw  = False                         
r2@gsnFrame = False 
r2@trXMinF	         			= 0.001             	
r2@trXMaxF	       	  			= 0.55
r2@trYMinF	         			= 0.00000001             	
r2@trYMaxF	       	  			= 30.0
r2@tmXBMinorPerMajor = 8
r2@tmYLMinorPerMajor = 8
r2@tmXTMinorPerMajor = 8
r2@tmYRMinorPerMajor = 8



do nn=0,10

	if (nn .le. 8) then 
		gm_ctrl=gm_ctrl_tmp[nn]->tas(:,:,0,0)
		sdof_ctrl = specx_anal(gm_ctrl(0,:),d,sm,pct)
		splt_ctrl = specx_ci (sdof_ctrl, 0.01, 0.99)
	end if
	
	; calculate spectrum
	sdof = specx_anal(all_fields_gm(nn,:),d,sm,pct)
	
	; calculate confidence interval [here 5 and 95%] return 4 curves to be plotted
	splt = specx_ci (sdof, 0.01, 0.99)
		
	r@tiMainString = names(nn)  
	 
	plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)
	
	if (nn .le. 8) then 
		plot2(nn) = gsn_csm_xy(wks,sdof_ctrl@frq, splt_ctrl,r2)
		overlay (plot(nn), plot2(nn))
		delete([/sdof_ctrl,splt_ctrl,gm_ctrl/])
	end if
	
	delete([/sdof,splt/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for global mean surface temperature running decadal~C~ ~Z50~past1000 (black), piControl (blue); 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/4,3/),resP)               ; now draw as one plot



wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/spectra/tas_0851-1849_past1000_spectra_NH_mean")  ; open workstation 
plot = new(11,graphic)
plot2=new(11,graphic)

r = True                                      ; plot mods desired 
r@tiXAxisString = "Frequency (1/yrs)"  ; xaxis
r@tiYAxisString = "Variance"                  ; yaxis
r@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r@trYLog              = True                 ; log scaling
r@trXLog              = True                 ; log scaling
;r@xyLineColors        = (/"foreground","green","blue","red"/)
r@xyLineColors        = (/"foreground","foreground","foreground","foreground"/)
r@gsnDraw  = False                         
r@gsnFrame = False 
r@tiMainFont      = "helvetica-bold"			; set main title to helvetica
r@trXMinF	         			= 0.001             	
r@trXMaxF	       	  			= 0.55
r@trYMinF	         			= 0.00000001             	
r@trYMaxF	       	  			= 30.0


r2 = True                                      ; plot mods desired 
r2@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r2@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r2@trYLog              = True                 ; log scaling
r2@trXLog              = True                 ; log scaling
r2@xyLineColors        = (/"deepskyblue","deepskyblue","deepskyblue","deepskyblue"/)
r2@gsnDraw  = False                         
r2@gsnFrame = False 
r2@trXMinF	         			= 0.001             	
r2@trXMaxF	       	  			= 0.55
r2@trYMinF	         			= 0.00000001             	
r2@trYMaxF	       	  			= 30.0




do nn=0,10

	if (nn .le. 8) then 
		nh_ctrl=nh_ctrl_tmp[nn]->tas(:,:,0,0)
		sdof_ctrl = specx_anal(nh_ctrl(0,:),d,sm,pct)
		splt_ctrl = specx_ci (sdof_ctrl, 0.01, 0.99)
	end if
	
	; calculate spectrum
	sdof = specx_anal(all_fields_nh(nn,:),d,sm,pct)
	
	; calculate confidence interval [here 5 and 95%] return 4 curves to be plotted
	splt = specx_ci (sdof, 0.01, 0.99)
		
	r@tiMainString = names(nn)  
	 
	plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)
	
	if (nn .le. 8) then 
		plot2(nn) = gsn_csm_xy(wks,sdof_ctrl@frq, splt_ctrl,r2)
		overlay (plot(nn), plot2(nn))
		delete([/sdof_ctrl,splt_ctrl,nh_ctrl/])
	end if
	
	delete([/sdof,splt/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for NH mean surface temperature running decadal~C~ ~Z50~past1000 (black), piControl (blue); 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/4,3/),resP)               ; now draw as one plot


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; annual mean
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/spectra/tas_0851-1849_past1000_spectra_global_mean_annual")  ; open workstation 
plot = new(11,graphic)
plot2=new(11,graphic)

r = True                                      ; plot mods desired 
r@tiXAxisString = "Frequency (1/yrs)"  ; xaxis
r@tiYAxisString = "Variance"                  ; yaxis
r@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r@trYLog              = True                 ; log scaling
r@trXLog              = True                 ; log scaling
;r@xyLineColors        = (/"foreground","green","blue","red"/)
r@xyLineColors        = (/"foreground","foreground","foreground","foreground"/)
r@gsnDraw  = False                         
r@gsnFrame = False 
r@tiMainFont      = "helvetica-bold"			; set main title to helvetica
r@trXMinF	         			= 0.001             	
r@trXMaxF	       	  			= 0.55
r@trYMinF	         			= 0.0001             	
r@trYMaxF	       	  			= 10.0


r2 = True                                      ; plot mods desired 
r2@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r2@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r2@trYLog              = True                 ; log scaling
r2@trXLog              = True                 ; log scaling
r2@xyLineColors        = (/"deepskyblue","deepskyblue","deepskyblue","deepskyblue"/)
r2@gsnDraw  = False                         
r2@gsnFrame = False 
r2@trXMinF	         			= 0.001             	
r2@trXMaxF	       	  			= 0.55
r2@trYMinF	         			= 0.0001             	
r2@trYMaxF	       	  			= 10.0


do nn=0,10

	if (nn .le. 8) then 
		gm_annual_ctrl=gm_annual_ctrl_tmp[nn]->tas(:,:,0,0)
		sdof_ctrl = specx_anal(gm_annual_ctrl(0,:),d,sm,pct)
		splt_ctrl = specx_ci (sdof_ctrl, 0.01, 0.99)
	end if
	
	if (nn .le. 9) then 
	; calculate spectrum
	sdof = specx_anal(gm_annual(nn,:),d,sm,pct)
	; calculate confidence interval [here 5 and 95%] return 4 curves to be plotted
	splt = specx_ci (sdof, 0.01, 0.99)		
	r@tiMainString = names(nn)  	 
	plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)
	end if
	
	if (nn .le. 8) then 
		plot2(nn) = gsn_csm_xy(wks,sdof_ctrl@frq, splt_ctrl,r2)
		overlay (plot(nn), plot2(nn))
		delete([/sdof_ctrl,splt_ctrl,gm_annual_ctrl/])
	end if
	
	if (nn .eq. 10) then 
		
		sdof = specx_anal(all_fields_gm(nn,:),d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)
		r@tiMainString = names(nn)  
		plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)
		
	end if
	
	delete([/sdof,splt/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for global mean surface temperature annual~C~ ~Z50~past1000 (black), piControl (blue); 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/4,3/),resP)               ; now draw as one plot



wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/spectra/tas_0851-1849_past1000_spectra_NH_mean_annual")  ; open workstation 
plot = new(11,graphic)
plot2=new(11,graphic)

r = True                                      ; plot mods desired 
r@tiXAxisString = "Frequency (1/yrs)"  ; xaxis
r@tiYAxisString = "Variance"                  ; yaxis
r@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r@trYLog              = True                 ; log scaling
r@trXLog              = True                 ; log scaling
;r@xyLineColors        = (/"foreground","green","blue","red"/)
r@xyLineColors        = (/"foreground","foreground","foreground","foreground"/)
r@gsnDraw  = False                         
r@gsnFrame = False 
r@tiMainFont      = "helvetica-bold"			; set main title to helvetica
r@trXMinF	         			= 0.001             	
r@trXMaxF	       	  			= 0.55
r@trYMinF	         			= 0.0001             	
r@trYMaxF	       	  			= 10.0
r@tmXBMinorPerMajor = 8



r2 = True                                      ; plot mods desired 
r2@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r2@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r2@trYLog              = True                 ; log scaling
r2@trXLog              = True                 ; log scaling
r2@xyLineColors        = (/"deepskyblue","deepskyblue","deepskyblue","deepskyblue"/)
r2@gsnDraw  = False                         
r2@gsnFrame = False 
r2@trXMinF	         			= 0.001             	
r2@trXMaxF	       	  			= 0.55
r2@trYMinF	         			= 0.0001             	
r2@trYMaxF	       	  			= 10.0
r2@tmXBMinorPerMajor = 8


do nn=0,10

	if (nn .le. 8) then 
		nh_annual_ctrl=nh_annual_ctrl_tmp[nn]->tas(:,:,0,0)
		sdof_ctrl = specx_anal(nh_annual_ctrl(0,:),d,sm,pct)
		splt_ctrl = specx_ci (sdof_ctrl, 0.01, 0.99)
	end if
	
	if (nn .le. 9) then 
	; calculate spectrum
	sdof = specx_anal(nh_annual(nn,:),d,sm,pct)
	; calculate confidence interval [here 5 and 95%] return 4 curves to be plotted
	splt = specx_ci (sdof, 0.01, 0.99)		
	r@tiMainString = names(nn)  	 
	plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)
	end if
	
	if (nn .le. 8) then 
		plot2(nn) = gsn_csm_xy(wks,sdof_ctrl@frq, splt_ctrl,r2)
		overlay (plot(nn), plot2(nn))
		delete([/sdof_ctrl,splt_ctrl,nh_annual_ctrl/])
	end if
	
	if (nn .eq. 10) then 
		
		sdof = specx_anal(all_fields_nh(nn,:),d,sm,pct)
		splt = specx_ci (sdof, 0.01, 0.99)
		r@tiMainString = names(nn)  
		plot(nn) = gsn_csm_xy(wks,sdof@frq, splt,r)
		
	end if
	
	delete([/sdof,splt/])
	
end do

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for global mean surface temperature annual~C~ ~Z50~past1000 (black), piControl (blue); 99% confidence for AR-1 processes"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot,(/4,3/),resP)               ; now draw as one plot


end


