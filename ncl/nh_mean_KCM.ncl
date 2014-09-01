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

directory=CMIP_dir+"/data/KCM/NH_mean_annual/"
files = systemfunc ("ls "+directory+"*mean_anomaly_annual_2500-6699_detrended.nc")
nh_tmp=addfiles(files,"r")
ListSetType (nh_tmp, "join")

forcing_P90_f=addfile(CMIP_dir+"/data/KCM/P90/P90_ym_2500-6699.solc.nc","r")
forcing_P93_f=addfile(CMIP_dir+"/data/KCM/P93/P93_ym_2500-6699.solc.nc","r")

forcing_P90=forcing_P90_f->solc(:,0,0)
forcing_P93=forcing_P93_f->solc(:,0,0)


model_name=files
do nt = 0,(dimsizes(files)-1)
	strs=str_split(files(nt),"_")
	model_name(nt)=strs(3)
	delete(strs)
end do

nh=nh_tmp[:]->temp2(:,:,0,0)
time=nh_tmp[0]->time
time_new=cd_calendar(time,0)
nh&time=time_new(:,0)

print(maxind(forcing_P93))


; calculate lagged correlation between NH mean and solar forcing

mxlag=500
lags=ispan(-500,500,1)

t_lead_s_P90=esccr(nh(1,:),forcing_P90,mxlag)
s_lead_t_P90=esccr(forcing_P90,nh(1,:),mxlag)
t_lead_s_P93=esccr(nh(2,:),forcing_P93,mxlag)
s_lead_t_P93=esccr(forcing_P93,nh(2,:),mxlag)

ccr=new ( (/2,2*mxlag+1/), "float") 
ccr(0,0:mxlag-1) = t_lead_s_P90(1:mxlag:-1)  ; "negative lag", -1 reverses order
ccr(0,mxlag:)    = s_lead_t_P90(0:mxlag)     ; "positive lag"

ccr(1,0:mxlag-1) = t_lead_s_P93(1:mxlag:-1)  ; "negative lag", -1 reverses order
ccr(1,mxlag:)    = s_lead_t_P93(0:mxlag)     ; "positive lag"


;*****************************************************************************************
; Plots
;*****************************************************************************************

;NH mean

res                     		= True             
res@vpHeightF 	 				= 0.4              	
res@vpWidthF 	        		= 0.7
res@gsnMaximize     			= True              
res@tmYMajorGrid				= "True"
res@tmYMajorGridLineColor		= "grey"
res@tmYMajorGridLineDashPattern	= 16
res@tmYMajorGridThicknessF		= 1.0
res@pmLegendDisplayMode    		= "Always"   		
res@xyExplicitLegendLabels 		= model_name         	
res@pmLegendWidthF         		= 0.30              
res@pmLegendHeightF        		= 0.15              
res@xyLineColors       			= (/"black","firebrick2","deepskyblue"/) ; colors chosen
res@xyLineThicknesses   		= (/2.0,2.0,2.0/) 
res@xyDashPattern      			= 0
res@tiYAxisString	 			= "[~S~o~N~C]"     	    	
res@tiXAxisString	 			= "Model Year"      		 
res@tmYRLabelsOn 				= True
 
 
 
; define variable resources

res@gsnCenterString 			= "~Z75~ surface air temperature corrected; 31-year running mean"
res@trXMinF	         			= min(time_new(:,0))          	
res@trXMaxF	       	  			= max(time_new(:,0)) 

; global mean plot
 
	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/KCM_temp2_NH_mean_decadal_detrended")            

	res@trYMinF	            		= -0.8         
	res@trYMaxF	            		= 0.8
	res@tiMainString				= "NH mean" 

	model_plot = gsn_csm_xy (wks,time_new(:,0),runave(nh,31,0),res)     

;*****************************************************************************************
; Lagged correlation

resl                     		= True             
resl@vpHeightF 	 				= 0.4              	
resl@vpWidthF 	        		= 0.7
resl@gsnMaximize     			= True              
resl@tmYMajorGrid				= "True"
resl@tmYMajorGridLineColor		= "grey"
resl@tmYMajorGridLineDashPattern	= 16
resl@tmYMajorGridThicknessF		= 1.0
resl@pmLegendDisplayMode    		= "Always"   		
resl@xyExplicitLegendLabels 		= (/"P90","P93"/)         	
resl@pmLegendWidthF         		= 0.30              
resl@pmLegendHeightF        		= 0.08        
resl@xyLineColors       			= (/"firebrick2","deepskyblue"/) ; colors chosen
resl@xyLineThicknesses   		= (/5.0,5.0/) 
resl@xyDashPattern      			= 0
resl@tiYAxisString	 			= "~Z75~correlation coefficient"     	    	
resl@tiXAxisString	 			= "~Z75~Lag [years]"      		 
resl@tmYRLabelsOn 				= True
 
 
 
; define variable resources


resl@gsnLeftString 			= "~Z75~ P90 max. corr. at "+maxind(s_lead_t_P90)+" years"
resl@gsnRightString 			= "~Z75~ P93 max. corr. at "+maxind(s_lead_t_P93)+" years"
resl@trXMinF	         			= -500          	
resl@trXMaxF	       	  			= 500 

; global mean plot
 
	wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/KCM_lagged_correlation_NH_mean_solar_forcing")            

	;res@trYMinF	            		= -0.8         
	;res@trYMaxF	            		= 0.8
	resl@tiMainString				= "~Z50~Lagged correlation between Solar Forcing and NH mean temperature" 

	corr_plot = gsn_csm_xy (wks,lags,ccr,resl)     


;*****************************************************************************************
; Spectra


d   = 1    ; detrending opt: 0=>remove mean 1=>remove mean + detrend
sm  = 3   ; smooth: should be at least 3 and odd
pct = 0.1 ; percent taper: (0.0 <= pct <= 1.0) 0.10 common. 

wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/spectra/KCM_spectra_temp2")

r = True                                      ; plot mods desired 
r@tiXAxisString = "Frequency (1/yrs)"  ; xaxis
r@tiYAxisString = "Variance"                  ; yaxis
r@xyLineThicknesses   = (/2.,1.,1.,1./)       ; Define line thicknesses 
r@xyDashPatterns      = (/0,0,1,1/)           ; Dash patterns 
r@trYLog              = True                 ; log scaling
r@trXLog              = True                 ; log scaling
r@gsnDraw  = False                         
r@gsnFrame = False 
r@tiMainFont      = "helvetica-bold"			; set main title to helvetica
r@trXMinF	         			= 0.0005             	
r@trXMaxF	       	  			= 0.5
r@trYMinF	         			= 0.0001             	
r@trYMaxF	       	  			= 100.0
r@tmXBMinorPerMajor = 8
r@tmYLMinorPerMajor = 8
r@tmXTMinorPerMajor = 8
r@tmYRMinorPerMajor = 8
r@gsnMaximize=True

sdof_P86 = specx_anal(nh(0,:),d,sm,pct)
splt_P86 = specx_ci (sdof_P86, 0.05, 0.95)

sdof_P90 = specx_anal(nh(1,:),d,sm,pct)
splt_P90 = specx_ci (sdof_P90, 0.05, 0.95)

sdof_P93 = specx_anal(nh(2,:),d,sm,pct)
splt_P93 = specx_ci (sdof_P93, 0.05, 0.95)

r@tiMainString   = "~Z75~ spectra for NH mean surface temperature 2500-6699 ~C~                        ~Z50~ black: P86, red: P90, blue: P93"


r@xyLineColors        = (/"foreground","foreground","foreground","foreground"/)
plot = gsn_csm_xy(wks,sdof_P86@frq,splt_P86,r)

r@xyLineColors        = (/"firebrick2","firebrick2","firebrick2","firebrick2"/)
plot2 = gsn_csm_xy(wks,sdof_P90@frq,splt_P90,r)

r@xyLineColors        = (/"deepskyblue","deepskyblue","deepskyblue","deepskyblue"/)
plot3 = gsn_csm_xy(wks,sdof_P93@frq,splt_P93,r)


overlay(plot,plot2)
overlay(plot,plot3)

draw(plot)

;*****************************************************************************************
; individual Spectra

wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/spectra/KCM_individual_spectra_temp2")

plot_ind = new(3,graphic)

r@xyLineColors        = (/"foreground","foreground","foreground","foreground"/)
r@tiMainString        = "P86"
plot_ind(0) = gsn_csm_xy(wks,sdof_P86@frq,splt_P86,r)
r@xyLineColors        = (/"firebrick2","firebrick2","firebrick2","firebrick2"/)
r@tiMainString        = "P90"
plot_ind(1) = gsn_csm_xy(wks,sdof_P90@frq,splt_P90,r)
r@xyLineColors        = (/"deepskyblue","deepskyblue","deepskyblue","deepskyblue"/)
r@tiMainString        = "P93"
plot_ind(2) = gsn_csm_xy(wks,sdof_P93@frq,splt_P93,r)

resP            = True                         ; modify the panel plot
resP@txString   = "~Z75~ spectra for NH mean surface temperature 2500-6699"
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
gsn_panel(wks,plot_ind,(/1,3/),resP)               ; now draw as one plot

end