;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
;*****************************************************************************************

begin

CMIP_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP/"
gm_directory=CMIP_dir+"processed/CMIP5/past1000/Amon/tas/global_mean_decadal_mean/"
gm_files = systemfunc ("ls "+gm_directory+"*0851-2000"+"*.nc")
gm=addfiles(gm_files,"r")
ListSetType (gm, "join")

proxy=addfile(CMIP_dir+"data/observations/Mann_et_al_2009/reconstruction_global_mean_anomaly.nc","r")


model_name=gm_files
do nt = 0,(dimsizes(gm_files)-1)
	strs=str_split(gm_files(nt),"_")
	model_name(nt)=strs(5)
	delete(strs)
end do

gm_annual=gm[:]->tas(:,:,0,0)
proxy_annual=proxy->tas(:,:,0)

proxy_annual!1="ncl_join"


all_fields=array_append_record(gm_annual,proxy_annual(ncl_join|:,time|:),0)


time = ispan(851,2000,1)


wks = gsn_open_wks("pdf" ,CMIP_dir+"/plots/global_mean/tas_0851-2000_past1000_global_mean")               ; open pdf file


res                    = True             ; plot mods desired
res@gsnDraw            = False           ; don't draw yet
res@gsnFrame           = False           ; don't advance frame yet
res@vpHeightF 	 = 0.4              ; change aspect ratio of plot
res@vpWidthF 	         = 0.7
res@trXMinF	         = 851             ; set x-axis minimum
res@trXMaxF	         = 2000
ymin=16
ymax=20
res@gsnMaximize      = True                   ; use full page
;res@trYMinF	         = -1.0          ; set x-axis minimum
;res@trYMaxF	         = 1.5
res@xyLineThicknessF = 2.0 

 
names=array_append_record(model_name,"Mann et al. 2009 reconstruction",0)

res@pmLegendDisplayMode    = "Always"   ; Display a legend.
res@xyExplicitLegendLabels = names         ; create explicit labels
  res@pmLegendWidthF         = 0.30                ; Change width and
  res@pmLegendHeightF        = 0.15                ; height of legend.



res@xyLineColors       = (/"coral3","cyan","gold","firebrick3","darkorchid2","darkseagreen4","royalblue4","darkorange1","black"/) ; colors chosen
res@xyDashPattern      = 0
res@tiMainString=	"global mean surface air temperature" 
res@tiYAxisString	 = "[~S~o~N~C]"     ; add an axis title    	
res@tiXAxisString	 = "Year"      ; add an axis title    
 res@tmYRLabelsOn = True
model_plot = gsn_csm_xy (wks,time,all_fields(ncl_join|0:dimsizes(gm_files),time|:),res)       ; create line plot

  

  

res_text                    = True                  ; text mods desired
res_text@txFontHeightF      = 0.015                 ; change text size
res_text@txJust             = "CenterLeft"          ; text justification
res_lines                   = True                  ; polyline mods desired



pres = True
draw(wks)

end



