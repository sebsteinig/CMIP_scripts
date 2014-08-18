load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  

begin

; detect CMIP directory
wd = systemfunc("pwd")
dir_split = str_split(wd, "/") 
CMIP_dir=str_concat("/"+dir_split(0:dimsizes(dir_split)-3))

print("The current working directory is: "+(CMIP_dir(0)))

; load data

directory=CMIP_dir+"/processed/CMIP5/past1000/Amon/tas/"

f = systemfunc ("ls "+directory+"remapped_to_HadCRUT4_decadal_running_mean/*.nc")
f_NH = systemfunc ("ls "+directory+"NH_mean_decadal_running_mean_detrended/*.nc")
files=addfiles(f,"r")
files_NH=addfiles(f_NH,"r")
ListSetType (files, "join")
ListSetType (files_NH, "join")

proxy_f=addfile(CMIP_dir+"/data/observations/Mann_et_al_2009/mann2009_reconstruction_0856-1845_decadal_mean.nc","r")
proxy_f_NH=addfile(CMIP_dir+"/data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_0856-1845_decadal_running_mean.nc","r")


model_name=f
do nt = 0,(dimsizes(f)-1)
	strs=str_split(f(nt),"_")
	model_name(nt)=strs(7)
	delete(strs)
end do

fields=files[:]->tas
fields_NH=files_NH[:]->tas(:,:,0,0)
dims=dimsizes(fields)
dims_NH=dimsizes(fields_NH)
proxy_field=new((/1,dims(1),dims(2),dims(3)/),"float")
proxy_field_NH=new((/1,dims(1)/),"float")



copy_VarMeta(fields,proxy_field)
proxy_field=proxy_f->tas
proxy_field_NH=proxy_f_NH->tas(:,0,0)


; change time axis to years
time=files[0]->time
time_new=cd_calendar(time,0)
fields&time = time_new(:,0)
fields_NH&time = time_new(:,0)
proxy_field&time = time_new(:,0)

proxy_field!0 = "ncl_join"
proxy_field_NH!0 = "ncl_join"

all_fields_tmp=array_append_record(fields,proxy_field,0)
all_fields_NH_tmp=array_append_record(fields_NH,proxy_field_NH,0)
all_fields=dtrend_msg_n(time_new(:,0),all_fields_tmp,False,False,1)
all_fields_NH=dtrend_msg_n(time_new(:,0),all_fields_NH_tmp,False,False,1)
names=array_append_record(model_name,"Mann et al. 2009 reconstruction",0)

copy_VarMeta(all_fields_tmp,all_fields)
copy_VarMeta(all_fields_NH_tmp,all_fields_NH)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/spatial_correlation_NH_SAT")  ; open workstation 
plot = new(11,graphic)
gsn_define_colormap(wks,"ncl_default")
res                  = True                ; plot mods desired
res@gsnDraw  = False                          ; don't draw
res@gsnFrame = False                          ; don't advance frame
;res@tiYAxisString    = "Latitude"              ; y axis title
;res@tiXAxisString    = "Year"              ; y axis title
res@lbLabelBarOn         = False             	; turn off individual lb's
res@cnLineLabelsOn       = False             	; default is True

res@cnLevelSelectionMode = "ManualLevels" ; manual levels
res@cnMinLevelValF       = -.9
res@cnMaxLevelValF       =  .9
res@cnLevelSpacingF      =  .1

res@cnFillOn         = True               ; color Fill 
res@cnFillMode       = "RasterFill"       ; Raster Mode
res@cnLinesOn        =  False             ; Turn off contour lines
res@gsnSpreadColors  = True                ; use full range of color map

resP                  = True                   ; modify the panel plot
resP@txString         = "Correlation between NH mean and grid-point temperature"
resP@lbOrientation    = "Horizontal"          ; vertical label bar
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
resP@gsnPanelLabelBar = True                   ; add common label bar

do nn=0,10
	res@tiMainString     = names(nn)     ; title
	array=escorc(all_fields_NH(nn,:),all_fields(ncl_join|nn,latitude|:,longitude|:,time|:))
	copy_VarMeta(all_fields(0,0,:,:),array)
	plot(nn) = gsn_csm_contour_map(wks,array,res)
end do

gsn_panel(wks,plot,(/4,3/),resP)               ; create panel plot


end