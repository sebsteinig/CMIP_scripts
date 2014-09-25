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


dims=dimsizes(model_fields)
proxy=new((/1,dims(1),dims(2),dims(3)/),"float")
copy_VarMeta(model_fields,proxy)
proxy_file=addfile(CMIP_dir+"/data/observations/Mann_et_al_2009/mann2009_reconstruction_0856-1845_decadal_mean.nc","r")
proxy=proxy_file->tas
proxy@_FillValue=1e+36

all_fields=array_append_record(model_fields,proxy,0)
names=array_append_record(model_name,"Mann et al. 2009 reconstruction",0)

print(names)


ssa_1_file=addfile(CMIP_dir+"/data/TSI/roth_for_sebastian_new_ssa300/roth_ym_0000-2005.tsi_rec1.nc","r")
ssa_1_tmp=ssa_1_file->tsi(:,0,0)
ssa_1=ssa_1_tmp({time|856:1845})
ssa_23_file=addfile(CMIP_dir+"/data/TSI/roth_for_sebastian_new_ssa300/roth_ym_0000-2005.tsi_rec23.nc","r")
ssa_23_tmp=ssa_23_file->tsi(:,0,0)
ssa_23=ssa_23_tmp({time|856:1845})
ssa_56_file=addfile(CMIP_dir+"/data/TSI/roth_for_sebastian_new_ssa300/roth_ym_0000-2005.tsi_rec56.nc","r")
ssa_56_tmp=ssa_56_file->tsi(:,0,0)
ssa_56=ssa_56_tmp({time|856:1845})

total_TSI_file=addfile(CMIP_dir+"/data/TSI/Roth_and_Joos_2013/TSI_Holocene_Roth_and_Joos_2013.nc","r")
total_TSI_tmp=total_TSI_file->TSI
total_TSI=total_TSI_tmp({time|856:1845.5})


dim_proxy = dimsizes(proxy)    ; determine the dimensions of "y"
nlat = dim_proxy(2)
nlon = dim_proxy(3)
ntim = dim_proxy(1)        ; not used in this example

tval = new ((/nlat,nlon/) , float)    ; explicitly allocate space
nxy  = new ((/nlat,nlon/) , integer)  ; explicitly allocate space
nxy@_FillValue = 0
ccr=new((/nlat,nlon/),float)
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

res2=True
res2@gsnDraw             = False       ; Do not draw plot
res2@gsnFrame            = False       ; Do not advance frome
res2@cnLinesOn        =  False             ; Turn off contour lines
res2@cnLevelSelectionMode = "ExplicitLevels"
res2@cnLevels             = (/.1,.2,.3,.4/)

; Control which contour lines get drawn.
res2@cnFillPatterns        = (/-1,17,3,4,6/)

res2@lbLabelAutoStride   = True        ; Control labelbar spacing
res2@cnMonoFillPattern    = False
res2@cnMonoFillColor      = True  
res2@cnFillOn            = True        ; Turn on contour fill
res2@cnFillColor		="black"
res2@cnFillScaleF	=	.5
res2@cnInfoLabelOn	=	False
res2@lbTitleOn        = True                  ; turn on title
res2@lbTitleString    = "Explained Variance"
res2@cnLineLabelsOn = False

res3=True
res3@gsnDraw             = False       ; Do not draw plot
res3@gsnFrame            = False       ; Do not advance frome
res3@cnLinesOn        =  False             ; Turn off contour lines
res3@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
res3@cnMinLevelValF      = 0.00        ; set min contour level
res3@cnMaxLevelValF      = 0.1        ; set max contour level
res3@cnLevelSpacingF     = 0.01        ; set contour spacing
res3@cnLineLabelsOn       = False             	; default is True
res3@cnInfoLabelOn       = False       ; turn off info label
res3@gsnLeftString=""
res3@gsnRightString=""
res3@cnFillScaleF=0.5
res3@cnFillDotSizeF=0.002



      



resP                  = True                   ; modify the panel plot
resP@lbOrientation    = "Horizontal"          ; vertical label bar
resP@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
resP@gsnPanelLabelBar = True                   ; add common label bar


; Rec 1
wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/surface/SSA_1_regression_tas_ttest_2")  ; open workstation 
plot = new(11,graphic)
plot2 = new(11,graphic)
gsn_define_colormap(wks,"BlueDarkRed18")

res@cnMinLevelValF       = -2.0
res@cnMaxLevelValF       =  2.0
res@cnLevelSpacingF      =  .2

do nn=0,10
print(nn)
	rc   = regcoef (ssa_1,all_fields(ncl_join|nn,latitude|:,longitude|:,time|:),tval,nxy)
	ccr_tmp = escorc(all_fields(ncl_join|nn,latitude|:,longitude|:,time|:),ssa_1)
	ccr=ccr_tmp^2
	;df=equiv_sample_size (all_fields(ncl_join|nn,latitude|:,longitude|:,time|:),0.01,0)
	df   = nxy-2
    prob=student_t(tval,df)
	copy_VarMeta(proxy(0,0,:,:),rc)
	copy_VarMeta(proxy(0,0,:,:),ccr)
	copy_VarMeta(proxy(0,0,:,:),prob)
	;print(df(0,0))
	;print(size(0,0))
	res@tiMainString     = names(nn)
	if nn .eq. 10
		res2@lbLabelBarOn         = True             	; turn off individual lb's
		res2@lbOrientation    = "Vertical"          ; vertical label bar
	else
		res2@lbLabelBarOn         = False             	; turn off individual lb's
	end if
	plot(nn)=gsn_csm_contour_map(wks,rc,res)
	;plot2(nn)=gsn_csm_contour(wks,ccr,res2)
	;overlay (plot(nn), plot2(nn))
	plot2(nn)=gsn_csm_contour(wks,gsn_add_cyclic_point(prob), res3)
	plot2(nn)=ShadeLtContour(plot2(nn), 0.02, 17)
    overlay (plot(nn), plot2(nn))


end do

resP@txString         = "Linear regression coeffcients SAT with TSI rec1"

gsn_panel(wks,plot,(/4,3/),resP)               ; create panel plot

end

