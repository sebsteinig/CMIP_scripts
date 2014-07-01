;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

;*****************************************************************************************
; read in environment variables set in 'cmip5_processing.sh'
;*****************************************************************************************

var=getenv("variable")
res=getenv("res")
realm=getenv("realm")
period_1=getenv("period")
start_1=getenv("start_period")
end_1=getenv("end_period")
plot_dir=getenv("plot_dir")
CMIP_dir=getenv("CMIP_dir")
experiment=getenv("experiment")
plot_seasons=getenv("plot_seasons")
plot_means=getenv("plot_means")
plot_bias_ensemble=getenv("plot_bias_ensemble")
plot_bias_observations=getenv("plot_bias_observations")
plot_bias_KCM=getenv("plot_bias_KCM")
plot_change=getenv("plot_change")
periods=(/period_1/)
seasons=(/"DJF","MAM","JJA","SON","annual"/)

;*****************************************************************************************
; define some other variables
;*****************************************************************************************

directory=CMIP_dir+"/processed/CMIP5"+experiment+"/"+realm+"/"+var+"/" ; directory of processed fields
correlations_directory=directory+"correlations/"
gm_directory=directory+"global_mean/"
gm_removed_directory=directory+"global_mean_removed/"
trends_directory=directory+"trends/"
obs_directory=CMIP_dir+"data/observations/"
ppp=16 ;plots per page
rows=4
columns=4
sigr=0.95

model_count=dimsizes(systemfunc ("ls "+directory+"*"+period_1+"*"+remap+"_"+resolution+"*.nc"))

correlations_files = systemfunc ("ls "+correlations_directory+"*"+"ERSST"+"*"+period_1+"*"+remap+"_"+resolution+"*NH.nc")
initial_conditions_files = systemfunc ("ls "+gm_removed_directory+"*"+"decadal_patterns"+"*.nc")
gm_files = systemfunc ("ls "+gm_directory+"*"+period_1+"*"+remap+"_"+resolution+"*.nc")
trend_files = systemfunc ("ls "+trends_directory+"*"+period_1+"*"+remap+"_"+resolution+"*.nc")
;print(initial_conditions_files)

;print(trend_files)
;print(correlations_files)

model_name=correlations_files
do nt = 0,(dimsizes(correlations_files)-1)
	strs=str_split(correlations_files(nt),"_")
	model_name(nt)=strs(9)
	delete(strs)
end do

;print(model_name)

;*****************************************************************************************
; load data
;*****************************************************************************************

if (var .eq. "tos") then
	ERSST_gm = addfile(gm_directory+"/ERSST_gm_"+period_1+".nc","r")
	ERSST_trend=addfile(trends_directory+"/ERSST_gm_decadal_trends_"+period_1+".nc","r")
	
	mm_gm_ERSST= ERSST_gm->sst
	ym_gm_ERSST=month_to_annual(short2flt(mm_gm_ERSST),1)
	trend_ERSST=ERSST_trend->sst(time|:,lat|0,lon|0)

	mm_gm_HadISST= HadISST_gm->sst
	ym_gm_HadISST=month_to_annual(mm_gm_HadISST,1)
	trend_HadISST=HadISST_trend->sst(time|:,lat|0,lon|0)*10
end if

model_corr  = addfiles (correlations_files, "r")
model_gm   = addfiles (gm_files, "r")
model_trends   = addfiles (trend_files, "r")
;initial_conditions   = addfiles (initial_conditions_files, "r")
;print(initial_conditions)

ListSetType (model_corr, "join")
ListSetType (model_gm, "join")
ListSetType (model_trends, "join")
;ListSetType (initial_conditions, "join")



;printVarSummary(model_trends(0))
;print(model_corr)

correlation_fields=model_corr[:]->sst(:,:,0,0)
trend_fields=model_trends[:]->tos(:,:,0,0)*100
mm_gm_fields= model_gm[:]->tos(:,:,0,0)
ym_gm_fields=month_to_annual(mm_gm_fields(time|:,ncl_join|:),1)
;initial_condition_fields=initial_conditions[:]->tos(:,:,0,0)

;printVarSummary(ym_gm_fields)
;print(model_name)
;printVarSummary(initial_conditions)
global=0

if (global .eq. 1) then

;**********************************************************************************
;**********************************************************************************
; global mean trends
;**********************************************************************************
;**********************************************************************************
  
time = ispan(1870,2005,1)

wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/"+var+"/gm/"+var+"_"+"1870-2005"+"_global_mean_trend")               ; open pdf file

res                    = True             ; plot mods desired
res@gsnDraw            = False           ; don't draw yet
res@gsnFrame           = False           ; don't advance frame yet
res@vpHeightF 	 = 0.4               ; change aspect ratio of plot
res@vpWidthF 	         = 0.7
res@trXMinF	         = 1870             ; set x-axis minimum
res@trXMaxF	         = 2005
ymin=16
ymax=20
res@trYMinF	         = ymin          ; set x-axis minimum
res@trYMaxF	         = ymax
res@gsnMaximize      = True                   ; use full page

res@xyMonoLineColor    = True             ; want colored lines
res@xyLineColor       = "gray" ; colors chosen
res@tiYAxisString	 = "global mean SST"      ; add an axis title    	
res@tiXAxisString	 = "Year"      ; add an axis title    

gm_plot = gsn_csm_xy (wks,time,ym_gm_fields(ncl_join|:,year|:),res)       ; create line plot

res@xyLineColor       = "black" ; colors chosen
res@xyLineThicknesses  = (/5/)
ensemble_plot = gsn_csm_xy (wks,time,ym_gm_fields(:,37),res)       ; create line plot

res@xyLineColor       = "red" ; colors chosen
res@xyLineThicknesses  = (/5/)
ERSST_plot = gsn_csm_xy (wks,time,ym_gm_ERSST(:,0,0),res)       ; create line plot

overlay(gm_plot,ensemble_plot)
overlay(gm_plot,ERSST_plot)

res_vert = True
res_vert@gsLineColor       = "black"    
res_vert@gsLineDashPattern    = 16
res_ERSST_trend = True
res_ERSST_trend@gsLineColor       = "red"    
res_ERSST_trend@gsLineDashPattern    = 2 
res_ERSST_trend@gsLineThicknessF  = 5
res_ensemble_trend = True
res_ensemble_trend@gsLineColor       = "black"    
res_ensemble_trend@gsLineDashPattern    = 2 
res_ensemble_trend@gsLineThicknessF  = 5

do ii=0,12
	gsn_polyline(wks,ERSST_plot,(/1870+(ii*10),1870+(ii*10)/),(/ymin,ymax/),res_vert)
	gsn_polyline(wks,ERSST_plot,(/1870+(ii*10),1880+(ii*10)/),(/ym_gm_HadISST(ii*10,0,0),ym_gm_HadISST((ii*10)+9,0,0)/),res_HadISST_trend) 
	gsn_polyline(wks,ERSST_plot,(/1870+(ii*10),1880+(ii*10)/),(/ym_gm_ERSST(ii*10,0,0),ym_gm_ERSST((ii*10)+9,0,0)/),res_ERSST_trend) 
	gsn_polyline(wks,ERSST_plot,(/1870+(ii*10),1880+(ii*10)/),(/ym_gm_fields(ii*10,37),ym_gm_fields((ii*10)+9,37)/),res_ensemble_trend) 

end do
gsn_polyline(wks,ERSST_plot,(/2000,2000/),(/ymin,ymax/),res_vert)
gsn_polyline(wks,ERSST_plot,(/2000,2005/),(/ym_gm_HadISST(130,0,0),ym_gm_HadISST(135,0,0)/),res_HadISST_trend) 
gsn_polyline(wks,ERSST_plot,(/2000,2005/),(/ym_gm_ERSST(130,0,0),ym_gm_ERSST(135,0,0)/),res_ERSST_trend) 
gsn_polyline(wks,ERSST_plot,(/2000,2005/),(/ym_gm_fields(130,37),ym_gm_fields(135,37)/),res_ensemble_trend) 

res_text                    = True                  ; text mods desired
res_text@txFontHeightF      = 0.015                 ; change text size
res_text@txJust             = "CenterLeft"          ; text justification
res_lines                   = True                  ; polyline mods desired
  
res_lines@gsLineDashPattern = 0.                    ; solid line
res_lines@gsLineThicknessF  = 5.                    ; line thicker
res_lines@gsLineColor       = "blue"                 ; line color
xx = (/1875,1885/)
yy = (/19.8,19.8/)
dum1 = gsn_add_polyline(wks,HadISST_plot,xx,yy,res_lines)              ; add polyline
dum2 = gsn_add_text(wks,HadISST_plot,"HadISST",1888,19.8,res_text); add text

yy = (/19.5,19.5/)
res_lines@gsLineColor       = "red"                                 ; change to blue
dum3 = gsn_add_polyline(wks,HadISST_plot,xx,yy,res_lines)                ; add polyline
dum4 = gsn_add_text(wks,HadISST_plot,"ERSST",1888,19.5,res_text)       ; add text

yy = (/19.2,19.2/)
res_lines@gsLineColor       = "black"                                 ; change to blue
dum5 = gsn_add_polyline(wks,HadISST_plot,xx,yy,res_lines)                ; add polyline
dum6 = gsn_add_text(wks,HadISST_plot,"CMIP5 ensemble mean",1888,19.2,res_text)       ; add text

;*****************************************************   
; Manually create and attach legend
;***************************************************** 
res_text                    = True                  ; text mods desired
res_text@txFontHeightF      = 0.015                 ; change text size
res_text@txJust             = "CenterLeft"          ; text justification
  
pres = True
;maximize_output(wks,pres)
draw(wks)

end if

end



begin

correlation=0

 
if (correlation .eq. 1) then


;**********************************************************************************
;**********************************************************************************
; correlation/trend scatter plot
;**********************************************************************************
;**********************************************************************************

  colors  = (/"white","black","dodgerblue2","firebrick","forestgreen",\
              "darkorange2","deeppink2","yellow",\
              "grey40","purple","salmon","cadetblue1",\
			  "dodgerblue2","firebrick","forestgreen",\
			  "darkorange2","deeppink2","yellow",\
			  "grey40","purple","salmon","cadetblue1",\
			  "dodgerblue2","firebrick","forestgreen",\
			  "darkorange2","deeppink2","yellow",\
			  "grey40","purple","salmon","cadetblue1",\
			  "dodgerblue2","firebrick","forestgreen",\
			  "darkorange2","deeppink2","yellow",\
			   "grey40","purple","salmon","cadetblue1"/)

wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/"+var+"/correlations/"+var+"_"+"1870-2005"+"_decadal_scatter_plots_NH_HadISST_1"); open pdf file
 gsn_define_colormap(wks,colors)

;----------------------------------------------------------------------
; Set some plot resources
;----------------------------------------------------------------------
  res_scatter                    = True

  res_scatter@gsnDraw            = False       ; Don't draw plot
  res_scatter@gsnFrame           = False       ; Don't advance frame


  trend_min=min(trend_fields)
  trend_max=max(trend_fields)
  correlation_min=min(correlation_fields)
  correlation_max=max(correlation_fields)
  res_scatter@vpXF              = 0.23
  res_scatter@vpYF              = .83
  res_scatter@vpWidthF          = 0.7
  res_scatter@vpHeightF         = 0.7
  
    res_scatter@trYMinF            =  trend_min               ; min value on y-axis
    res_scatter@trYMaxF            =  trend_max              ; max value on y-axis
    res_scatter@trXMinF            =  correlation_min                 ; min value on x-axis
    res_scatter@trXMaxF            =  correlation_max                 ; max value on x-axis

  ;---XY marker resources
    res_scatter@xyMarkLineMode     = "Markers"
    res_scatter@xyMarkerSizeF      = 0.03
    res_scatter@xyMarkerThicknessF = 3.
    res_scatter@xyMonoMarkerColor  = False          ; Allow different colors for markers
    res_scatter@xyMarkerColors     = colors(2:)     ; It's okay to list more than
                                            ; you need here
    res_scatter@xyMarkers          = (/2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5/)


plot=new (14, graphic)      ; create graphical array
dum=new (14, graphic)      ; create graphical array
reg=new (14, graphic)      ; create graphical array

res_ERSST = True
res_ERSST@gsLineColor       = "black"    
res_ERSST@gsLineDashPattern    = 0 
res_ERSST@gsLineThicknessF  = 3

res_panel = True
res_panel@gsnMaximize      = True 
res_panel@gnFrame        = True
res_panel@txString       = "tos global decadal trend against pattern correlation with HadISST NH"

res_regression = True
res_regression@xyLineColor       = "black" ; colors chosen
res_regression@gsnDraw            = False       ; Don't draw plot
res_regression@gsnFrame           = False       ; Don't advance frame
res_regression@xyLineThicknesses  = 3
res_regression@xyDashPatterns    = 16

res_scatter@xyMarkerSizeF      = 50
res_scatter@xyMarkerThicknessF = 5.
res_scatter@xyMarkers          = (/12,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5/)

do nn=0,13
	
if (nn .lt. 13) then
	res_scatter@tiXAxisString       = sprintf("%6.0f",1870+(nn*10))+" -"+sprintf("%5.0f",1879+(nn*10))+" pattern correlation (NH)"

else
	res_scatter@tiXAxisString       = "2000-2005 pattern correlation (NH)"
end if

    res_scatter@tiYAxisString      = sprintf("%6.0f",1870+(nn*10))+" - 2005 "+"global SST trend per 100 yrs "
	res_scatter@tiMainFontHeightF  = 0.03
	

plot(nn) = gsn_csm_xy (wks,transpose((/correlation_fields(:,nn),correlation_fields(:,nn)/)),transpose((/trend_fields(:,nn),trend_fields(:,nn)/)),res_scatter)

rc=regline(correlation_fields(:,nn),trend_fields(:,nn))
x=ispan(-100,100,1)*1
regression=rc*(x-rc@xave)+rc@yave

reg(nn)=gsn_csm_xy (wks,x,regression,res_regression)
overlay(plot(nn),reg(nn))

dum(nn)=gsn_add_polyline(wks,plot(nn),(/correlation_min,correlation_max/),(/trend_HadISST(nn),trend_HadISST(nn)/),res_ERSST)

end do  

gsn_panel(wks,plot,(/3,5/),res_panel)               ; create panel plot


end if

end




begin

initial_conditions=0

 
if (initial_conditions .eq. 1) then


;**********************************************************************************
;**********************************************************************************
; spatial plots of initial conditions
;**********************************************************************************
;**********************************************************************************


end if

end