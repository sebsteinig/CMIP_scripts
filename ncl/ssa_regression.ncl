load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  

begin

; detect CMIP directory
wd = systemfunc("pwd")
dir_split = str_split(wd, "/") 
CMIP_dir=str_concat("/"+dir_split(0:dimsizes(dir_split)-3))

print("The current working directory is: "+(CMIP_dir(0)))

; load data

f = systemfunc ("ls "+CMIP_dir+"/processed/CMIP5/past1000/Amon/tas/remapped_to_HadCRUT4_decadal_running_mean_detrended/*.nc")
files=addfiles(f,"r")
ListSetType (files, "join")
model_fields=files[:]->tas

model_name=f
do nt = 0,(dimsizes(f)-1)
	strs=str_split(f(nt),"_")
	model_name(nt)=strs(8)
	delete(strs)
end do

print(model_name)

dims=dimsizes(model_fields)
proxy=new((/1,dims(1),dims(2),dims(3)/),"float")
copy_VarMeta(model_fields,proxy)
proxy_file=addfile(CMIP_dir+"/data/observations/Mann_et_al_2009/mann2009_reconstruction_0856-1845_decadal_mean.nc","r")
proxy=proxy_file->tas
proxy@_FillValue=1e+36

all_fields=array_append_record(model_fields,proxy,0)
names=array_append_record(model_name,"Mann et al. 2009 reconstruction",0)

print(names)


ssa_1_file=addfile(CMIP_dir+"/data/TSI/roth_for_sebastian/roth_ym_0000-2005.tsi_rec1.nc","r")
ssa_1_tmp=ssa_1_file->tsi(:,0,0)
ssa_1=ssa_1_tmp({time|856:1845})
ssa_23_file=addfile(CMIP_dir+"/data/TSI/roth_for_sebastian/roth_ym_0000-2005.tsi_rec23.nc","r")
ssa_23_tmp=ssa_23_file->tsi(:,0,0)
ssa_23=ssa_23_tmp({time|856:1845})
ssa_45_file=addfile(CMIP_dir+"/data/TSI/roth_for_sebastian/roth_ym_0000-2005.tsi_rec45.nc","r")
ssa_45_tmp=ssa_45_file->tsi(:,0,0)
ssa_45=ssa_45_tmp({time|856:1845})
ssa_67_file=addfile(CMIP_dir+"/data/TSI/roth_for_sebastian/roth_ym_0000-2005.tsi_rec67.nc","r")
ssa_67_tmp=ssa_67_file->tsi(:,0,0)
ssa_67=ssa_67_tmp({time|856:1845})


dim_proxy = dimsizes(proxy)    ; determine the dimensions of "y"
nlat = dim_proxy(2)
nlon = dim_proxy(3)
ntim = dim_proxy(1)        ; not used in this example

tval = new ((/nlat,nlon/) , float)    ; explicitly allocate space
nxy  = new ((/nlat,nlon/) , integer)  ; explicitly allocate space
rc   = regcoef (ssa_1,all_fields(ncl_join|0,latitude|:,longitude|:,time|:),tval,nxy)

copy_VarMeta(proxy(0,0,:,:),rc)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Plots
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

res=True
res@gsnDraw  = False                          ; don't draw
res@gsnFrame = False                          ; don't advance frame
res@cnFillOn         = True               ; color Fill 
res@cnFillMode       = "RasterFill"       ; Raster Mode
res@cnLinesOn        =  False             ; Turn off contour lines
res@gsnSpreadColors  = True                ; use full range of color map
res@cnLevelSelectionMode = "ManualLevels" ; manual levels

res@lbLabelBarOn         = False             	; turn off individual lb's
res@gsnLeftString=""
res@gsnRightString=""


resP                  = True                   ; modify the panel plot
resP@lbOrientation    = "Horizontal"          ; vertical label bar
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
resP@gsnPanelLabelBar = True                   ; add common label bar

; Rec 1
wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/SSA_1_regression")  ; open workstation 

plot = new(11,graphic)

gsn_define_colormap(wks,"BlueDarkRed18")
res@cnMinLevelValF       = -2.0
res@cnMaxLevelValF       =  2.0
res@cnLevelSpacingF      =  .2

do nn=0,10
	rc   = regcoef (ssa_1,all_fields(ncl_join|nn,latitude|:,longitude|:,time|:),tval,nxy)
	copy_VarMeta(proxy(0,0,:,:),rc)
	res@tiMainString     = names(nn)
	plot(nn)=gsn_csm_contour_map(wks,rc,res)
end do

resP@txString         = "Linear regression coeffcients SAT with TSI rec1"

gsn_panel(wks,plot,(/4,3/),resP)               ; create panel plot

; Rec 23
wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/SSA_23_regression")  ; open workstation 
plot = new(11,graphic)

gsn_define_colormap(wks,"BlueDarkRed18")
res@cnMinLevelValF       = -1.2
res@cnMaxLevelValF       =  1.2
res@cnLevelSpacingF      =  .1

do nn=0,10
	rc   = regcoef (ssa_23,all_fields(ncl_join|nn,latitude|:,longitude|:,time|:),tval,nxy)
	copy_VarMeta(proxy(0,0,:,:),rc)
	res@tiMainString     = names(nn)
	plot(nn)=gsn_csm_contour_map(wks,rc,res)
end do

resP@txString         = "Linear regression coeffcients SAT with TSI rec23"

gsn_panel(wks,plot,(/4,3/),resP)               ; create panel plot

; Rec 45
wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/SSA_45_regression")  ; open workstation 
plot = new(11,graphic)

gsn_define_colormap(wks,"BlueDarkRed18")
res@cnMinLevelValF       = -2.0
res@cnMaxLevelValF       =  2.0
res@cnLevelSpacingF      =  .2

do nn=0,10
	rc   = regcoef (ssa_45,all_fields(ncl_join|nn,latitude|:,longitude|:,time|:),tval,nxy)
	copy_VarMeta(proxy(0,0,:,:),rc)
	res@tiMainString     = names(nn)
	plot(nn)=gsn_csm_contour_map(wks,rc,res)
end do

resP@txString         = "Linear regression coeffcients SAT with TSI rec45"

gsn_panel(wks,plot,(/4,3/),resP)               ; create panel plot

; Rec 67
wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/SSA_67_regression")  ; open workstation 
plot = new(11,graphic)

gsn_define_colormap(wks,"BlueDarkRed18")
res@cnMinLevelValF       = -2.5
res@cnMaxLevelValF       =  2.5
res@cnLevelSpacingF      =  .2

do nn=0,10
	rc   = regcoef (ssa_67,all_fields(ncl_join|nn,latitude|:,longitude|:,time|:),tval,nxy)
	copy_VarMeta(proxy(0,0,:,:),rc)
	res@tiMainString     = names(nn)
	plot(nn)=gsn_csm_contour_map(wks,rc,res)
end do

resP@txString         = "Linear regression coeffcients SAT with TSI rec67"

gsn_panel(wks,plot,(/4,3/),resP)               ; create panel plot




end