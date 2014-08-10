;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

; load data

CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP/"

gm_directory=CMIP_dir+"processed/CMIP5/piControl/Amon/tas/global_mean_anomaly_annual_mean_detrended/"
gm_files = systemfunc ("ls "+gm_directory+"*.nc") 

model_name=gm_files
do nt = 0,(dimsizes(gm_files)-1)
	strs=str_split(gm_files(nt),"_")
	model_name(nt)=strs(9)
	delete(strs)
end do

wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_piControl_annual_detrended")
plot = new(9,graphic)
dummy = new(9,graphic) 

res=True 
res@gsnDraw  = False                         
res@gsnFrame = False 
res@trYMinF	            		= -0.5        
res@trYMaxF	            		= 0.5
res@gsnMaximize     			= True              
res@tmYMajorGrid				= "True"
res@tmYMajorGridLineColor		= "grey"
res@tmYMajorGridLineDashPattern	= 16
res@tmYMajorGridThicknessF		= 1.0

do nn=0,8

	gm_file=gm_files(nn)
	gm_tmp=addfile(gm_file,"r")
	gm=gm_tmp->tas(:,0,0)
	time=gm_tmp->time
	time_new=cd_calendar(time,0)
	printVarSummary(time_new)

	; Perform linear regression 
	rc = regline(time_new(:,0), gm)                ; degC/year
	rc@long_name = "trend"
	rc@units     = "degC/year"

	xrc = rc*(time_new(:,0)-rc@xave) + rc@yave

	rc = rc*100                             ; (degC/year)(10_year/decade)  
	rc@units = "degC/century"
	
	res@trXMinF	         			= min(time_new(:,0))         	
	res@trXMaxF	       	  			= max(time_new(:,0))
    res@tiMainString     = model_name(nn)
	integration_years=max(time_new(:,0))-min(time_new(:,0))
	res@gsnLeftString=integration_years+" years of integration"
	res@gsnRightString="drift/cent: "+rc
	res@gsnRightStringFontColor="red"
	
	plot(nn) = gsn_csm_xy (wks,time_new(:,0),gm,res)
	
    gsres                   = True          
    gsres@gsLineColor       = "red"  
    gsres@gsLineThicknessF  = 3.0
    dummy(nn) = gsn_add_polyline (wks,plot(nn),time_new(:,0),xrc,gsres)
	   
	delete([/gm_file,gm_tmp,gm,time,time_new,rc,xrc/])
end do

resP            = True                         ; modify the panel plot
resP@txString   = "Control integrations of global mean surface temperature"
gsn_panel(wks,plot,(/3,3/),resP)               ; now draw as one plot

end
           
