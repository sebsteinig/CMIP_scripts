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

directory=CMIP_dir+"/processed/CMIP5/"+experiment+"/"+realm+"/"+var+"/remapped_to_"+res+"/"			; directory of processed fields
obs_directory=CMIP_dir+"/data/observations/"												; directory of observations
ppp=16 																				; desired plots per page
rows=4																				; desired rows of panel plots per page
columns=4																			; desired colums of panel plots per page
sigr=0.95																			; significance level for t-test
model_count=dimsizes(systemfunc ("ls "+directory+"*"+realm+"*"+period_1+"*.nc"))-1	; count number of models


;*****************************************************************************************
; load data
;*****************************************************************************************

observation_flag_period_1=0		; initialise flags which are used to indicate whether observational data is available or not
observation_flag_period_2=0
KCM_flag=0

;*****************************************************************************************
; calculate number of pages needed to plot all models (depends on ppp and model_count)
;*****************************************************************************************

number_of_pages=(model_count/int2flt(ppp))

if (number_of_pages .eq. floattointeger(number_of_pages)) then
	number_of_pages=number_of_pages
else
	number_of_pages=floattointeger(number_of_pages)+1
end if

;*****************************************************************************************

do pp = 0,((number_of_pages)-1)			; run script for each output page; only load the data that is plotted on the first page

print("page "+pp) 

model_files_temp_period_1_tmp = systemfunc ("ls "+directory+"*"+realm+"*"+period_1+"*.nc")
model_files_temp_period_1 = model_files_temp_period_1_tmp(0:model_count-1)


ensemble_file_period_1 = systemfunc ("ls "+directory+"*"+"mmm"+"*"+period_1+"*.nc")


if (pp .lt. ((number_of_pages)-1)) then
	model_files_period_1=model_files_temp_period_1((pp*ppp):(pp+1)*ppp) 		; put "ppp" plot on the first pages
else
	model_files_period_1=model_files_temp_period_1((pp*ppp):((model_count)-1))					; put the rest on the last page
end if

;*****************************************************************************************
; get model names from file names
;*****************************************************************************************

model_name_period_1=model_files_temp_period_1

do nt = 0,(dimsizes(model_files_temp_period_1)-1)
	strs=str_split(model_files_temp_period_1(nt),"_")
	model_name_period_1(nt)=strs(4)
	delete(strs)
end do

print(model_name_period_1)


delete([/model_files_temp_period_1/])

;*****************************************************************************************

; calculate number of timesteps for whole time series
last_timestep_for_plot=((stringtointeger(end_1))-(stringtointeger(start_1))+1)*12
; calculate timestep for beginning of the last 30-yr period
first_timestep_for_plot=last_timestep_for_plot-(12*30)
timesteps_CMAP=((stringtointeger(end_1))-(1979)+1)*12
timesteps_KCM=100*12

;load ensemble mean data
mm_period_1  = addfile (ensemble_file_period_1, "r")
ensemble_temp_period_1 = mm_period_1->$var$(first_timestep_for_plot:last_timestep_for_plot-1,:,:)

; get grid information from ensemble mean file to use it for the rest of the models
grid=dimsizes(ensemble_temp_period_1)

; initialize model array for first page
model_fields_temp_period_1=new((/dimsizes(model_files_period_1),last_timestep_for_plot-first_timestep_for_plot,grid(1),grid(2)/),float)

model_f_period_1   = addfiles (model_files_period_1, "r")
ListSetType (model_f_period_1, "join")

; load only subset of data for the last 30 years
model_fields_temp_period_1   = model_f_period_1[:]->$var$(:,first_timestep_for_plot:last_timestep_for_plot-1,:,:)

; reorder dimensions of data to prepare for processing
model_fields_period_1=model_fields_temp_period_1(ncl_join|:,lat|:,lon|:,time|:)
ensemble_period_1=ensemble_temp_period_1(lat|:,lon|:,time|:)

delete([/model_fields_temp_period_1,ensemble_temp_period_1,model_f_period_1,mm_period_1/])


if (var .eq. "tos") then
	observation_flag_period_1=1		; observations for this variable exist
	KCM_flag=0						; KCM experiments for this variable exist
	
	obs_files_period_1 = systemfunc ("ls "+obs_directory+"HadISST/*"+period_1+"*remap"+"*.nc")
	obs_f_period_1   = addfile (obs_files_period_1, "r")
		
	observation_temp_period_1   = obs_f_period_1->sst
	observation_period_1=observation_temp_period_1(lat|:,lon|:,time|:)
	heading="HadISST"
	
	delete([/obs_files_period_1,obs_f_period_1,observation_temp_period_1/])
	
	if (KCM_flag .eq.1) then

	KCM_fields_temp=new((/4,timesteps_KCM,180,360/),float)
	KCM_files=systemfunc ("ls "+CMIP_dir+"/KCM/"+"*remap"+"*sosstsst.nc")
	KCM_f   = addfiles (KCM_files, "r")
	ListSetType (KCM_f, "join")
			
	KCM_exp=KCM_files
	do kt = 0,(dimsizes(KCM_files)-1)
		strs=str_split(KCM_files(kt),"_")
		if (strs(1) .eq. "P14" .or. strs(1) .eq. "P16") then
			KCM_exp(kt)=strs(1)+"_sosstsst_0300-0399"
		else if (strs(1) .eq. "W03" .or. strs(1) .eq. "W04") then
			KCM_exp(kt)=strs(1)+"_sosstsst_0900-0999"
		end if
		end if
		delete(strs)
	end do

	
	KCM_fields_temp=KCM_f[:]->sosstsst
	KCM_fields=KCM_fields_temp(ncl_join|:,lat|:,lon|:,time|:)
	
	delete([/KCM_fields_temp,KCM_files,KCM_f/])	
	
	end if	
end if

if (var .eq. "tas") then
	observation_flag_period_1=0
	KCM_flag=0
	
	if (KCM_flag .eq.1) then
	KCM_fields_temp=new((/4,timesteps_KCM,180,360/),float)
	KCM_files=systemfunc ("ls "+CMIP_dir+"/KCM/"+"*remap"+"*temp2.nc")
	KCM_f   = addfiles (KCM_files, "r")
	ListSetType (KCM_f, "join")
		
	KCM_exp=KCM_files
	do kt = 0,(dimsizes(KCM_files)-1)
		strs=str_split(KCM_files(kt),"_")
		if (strs(1) .eq. "P14" .or. strs(1) .eq. "P16") then
			KCM_exp(kt)=strs(1)+"_temp2_0300-0399"
		else if (strs(1) .eq. "W03" .or. strs(1) .eq. "W04") then
			KCM_exp(kt)=strs(1)+"_temp2_0900-0999"
		end if
		end if
		delete(strs)
	end do
	
	KCM_fields_temp(0:1,:,:,:)=KCM_f[0:1]->var167
	KCM_fields_temp(2:3,:,:,:)=KCM_f[2:3]->temp2
	KCM_fields=KCM_fields_temp(ncl_join|:,lat|:,lon|:,time|:)
	
	delete([/KCM_files,KCM_f/])	
	end if	
end if

if (var .eq. "psl") then
	observation_flag_period_1=1
	KCM_flag=0

	obs_files_period_1 = systemfunc ("ls "+obs_directory+"HadSLP2/*"+period_1+"*remap"+"*.nc")

	obs_f_period_1   = addfile (obs_files_period_1, "r")
	
	observation_temp_period_1   = obs_f_period_1->slp
	observation_period_1=observation_temp_period_1(lat|:,lon|:,time|:)
	heading="HadSLP2"
	
	delete([/obs_files_period_1,obs_f_period_1,observation_temp_period_1/])
end if

if (var .eq. "pr" )	then	
	observation_flag_period_1=1
	KCM_flag=0
	
	obs_files_period_1 = systemfunc ("ls "+obs_directory+"CMAP/CMAP_1979-2005_remapbil_ERSST.nc") ;

	obs_f_period_1   = addfile (obs_files_period_1, "r")
	
	observation_temp_period_1   = obs_f_period_1->precip
	observation_period_1=observation_temp_period_1(lat|:,lon|:,time|:)	
	heading="CMAP"
	
	delete([/obs_files_period_1,obs_f_period_1,observation_temp_period_1/])
	
	if (KCM_flag .eq.1) then
	KCM_fields_temp=new((/4,timesteps_KCM,180,360/),float)
	KCM_files=systemfunc ("ls "+CMIP_dir+"/KCM/"+"*remap"+"*precip.nc")
	KCM_f   = addfiles (KCM_files, "r")
	ListSetType (KCM_f, "join")
		
	KCM_exp=KCM_files
	do kt = 0,(dimsizes(KCM_files)-1)
		strs=str_split(KCM_files(kt),"_")
		if (strs(1) .eq. "P14" .or. strs(1) .eq. "P16") then
			KCM_exp(kt)=strs(1)+"_precip_0300-0399"
		else if (strs(1) .eq. "W03" .or. strs(1) .eq. "W04") then
			KCM_exp(kt)=strs(1)+"_precip_0900-0999"
		end if
		end if
		delete(strs)
	end do
	
	KCM_fields_temp=KCM_f[:]->var4
	KCM_fields=KCM_fields_temp(ncl_join|:,lat|:,lon|:,time|:)
	
	delete([/KCM_fields_temp,KCM_files,KCM_f/])	
	end if
end if

;*****************************************************************************************

kk=0
do while (kk .le. 4) 				; loop over all seasons (kk=0:3) or only the annual mean (kk=4)
	
if (plot_seasons .eq. 0) then 	; skip seasonal data if not needed
	kk = 4
end if

print(seasons(kk))

if (kk .eq. 4) then ; calculate annual means
	
	mean_model_fields_period_1_temp=month_to_annual(model_fields_period_1(time|:,ncl_join|:,lat|:,lon|:),1)
	mean_model_fields_period_1=dim_avg_n_Wrap(mean_model_fields_period_1_temp,0)
	var_model_fields_period_1=dim_variance_n_Wrap(mean_model_fields_period_1_temp,0)
	size_model_fields_period_1=equiv_sample_size (mean_model_fields_period_1_temp(ncl_join|:,lat|:,lon|:,year|:),sigr,0)
	delete([/mean_model_fields_period_1_temp,mean_model_fields_period_1_temp/])

	mean_ensemble_period_1_temp=month_to_annual(ensemble_period_1(time|:,lat|:,lon|:),1)
	mean_ensemble_period_1=dim_avg_n_Wrap(mean_ensemble_period_1_temp,0)
	var_ensemble_period_1=dim_variance_n_Wrap(mean_ensemble_period_1_temp,0)
	size_ensemble_period_1=equiv_sample_size (mean_ensemble_period_1_temp(lat|:,lon|:,year|:),sigr,0)
	delete([/mean_ensemble_period_1_temp/])



	if (KCM_flag .eq. 1) then
		mean_KCM_fields_temp=month_to_annual(KCM_fields(time|:,ncl_join|:,lat|:,lon|:),1)
		mean_KCM_fields=dim_avg_n_Wrap(mean_KCM_fields_temp,0)
		var_KCM_fields=dim_variance_n_Wrap(mean_KCM_fields_temp,0)
		size_KCM_fields=equiv_sample_size (mean_KCM_fields_temp(ncl_join|:,lat|:,lon|:,year|:),sigr,0)
		delete(mean_KCM_fields_temp)
	end if
	
	if (observation_flag_period_1 .eq. 1) then
		mean_observation_period_1_temp=month_to_annual(observation_period_1(time|:,lat|:,lon|:),1)
		mean_observation_period_1=dim_avg_n_Wrap(mean_observation_period_1_temp,0)
		var_observation_period_1=dim_variance_n_Wrap(mean_observation_period_1_temp,0)
		size_observation_period_1=equiv_sample_size (mean_observation_period_1_temp(lat|:,lon|:,year|:),sigr,0)
		delete(mean_observation_period_1_temp)
	end if
	
;*****************************************************************************************
	
else ; calculate seasonal means

	mean_model_fields_period_1=new((/dimsizes(model_files_period_1)-1,grid(1),grid(2)/),float)
	var_model_fields_period_1=new((/dimsizes(model_files_period_1)-1,grid(1),grid(2)/),float)
	size_model_fields_period_1=new((/dimsizes(model_files_period_1)-1,grid(1),grid(2)/),float)
	mean_KCM_fields=new((/4,grid(1),grid(2)/),float)
	var_KCM_fields=new((/4,grid(1),grid(2)/),float)
	size_KCM_fields=new((/4,grid(1),grid(2)/),float)

	do nn=0,((dimsizes(model_files_period_1))-2)
		mean_model_fields_period_1_temp=month_to_season(model_fields_period_1(time|:,ncl_join|nn,lat|:,lon|:),seasons(kk))
		mean_model_fields_period_1(nn,:,:)=dim_avg_n_Wrap(mean_model_fields_period_1_temp,0)
		var_model_fields_period_1(nn,:,:)=dim_variance_n_Wrap(mean_model_fields_period_1_temp,0)
		size_model_fields_period_1(nn,:,:)=equiv_sample_size (mean_model_fields_period_1_temp(lat|:,lon|:,time|:),sigr,0)
		delete([/mean_model_fields_period_1_temp/])
	end do
	
	mean_ensemble_period_1_temp=month_to_season(ensemble_period_1(time|:,lat|:,lon|:),seasons(kk))
	mean_ensemble_period_1=dim_avg_n_Wrap(mean_ensemble_period_1_temp,0)
	var_ensemble_period_1=dim_variance_n_Wrap(mean_ensemble_period_1_temp,0)
	size_ensemble_period_1=equiv_sample_size (mean_ensemble_period_1_temp(lat|:,lon|:,time|:),sigr,0)
	delete([/mean_ensemble_period_1_temp/])

	if (KCM_flag .eq. 1) then
		mean_KCM_fields=new((/4,grid(1),grid(2)/),float)
		do nn=0,3
			mean_KCM_fields_temp=month_to_season(KCM_fields(time|:,ncl_join|nn,lat|:,lon|:),seasons(kk))
			mean_KCM_fields(nn,:,:)=dim_avg_n_Wrap(mean_KCM_fields_temp,0)
			var_KCM_fields(nn,:,:)=dim_variance_n_Wrap(mean_KCM_fields_temp,0)
			size_KCM_fields(nn,:,:)=equiv_sample_size (mean_KCM_fields_temp(lat|:,lon|:,time|:),sigr,0)
			delete(mean_KCM_fields_temp)
		end do
	end if
	
	if (observation_flag_period_1 .eq. 1) then
		mean_observation_period_1_temp=month_to_season(observation_period_1(time|:,lat|:,lon|:),seasons(kk))
		mean_observation_period_1=dim_avg_n_Wrap(mean_observation_period_1_temp,0)
		var_observation_period_1=dim_variance_n_Wrap(mean_observation_period_1_temp,0)
		size_observation_period_1=equiv_sample_size (mean_observation_period_1_temp(lat|:,lon|:,time|:),sigr,0)
		delete(mean_observation_period_1_temp)
	end if
		
end if

;**********************************************************************************
;**********************************************************************************
; annual and seasonal means
;**********************************************************************************
;**********************************************************************************

if (plot_means .eq. 1) then
print("plotting means")


model=mean_model_fields_period_1
ensemble=mean_ensemble_period_1
name=model_name_period_1

if (observation_flag_period_1 .eq. 1) then
	observation=mean_observation_period_1
end if

wks = gsn_open_wks("pdf",plot_dir+"/"+var+"_"+seasons(kk)+"_mean_"+flt2string((int2flt((stringtointeger(end_1)-30))))+"-"+end_1+"_"+(pp+1))               ; open pdf file

plot= new (ppp, graphic)      ; create graphical array
;*****************************************************************************************

res_mean                      	= True               	; plot mods desired
res_mean@gsnDraw             	= False             	; don't draw yet 
res_mean@gsnFrame            	= False              	; don't advance frame yet
res_mean@cnFillOn             	= True               	; color contours
res_mean@cnLinesOn            	= False              	; default is True
res_mean@cnLineLabelsOn       	= False             	; default is True
res_mean@lbLabelBarOn         	= False              	; turn off individual lb's
res_mean@cnMissingValFillColor 	= "gray80"
res_mean@cnLevelSelectionMode 	= "ManualLevels"		; manually set the contour levels 
res_mean@vpWidthF            	= 0.5          			; change aspect ratio of plot
res_mean@vpHeightF           	= 0.3
res_mean@mpCenterLonF		  	= 220 
if (var .eq. "tos") then
	res_mean@cnMinLevelValF  	= 0.					; set the minimum contour level
	res_mean@cnMaxLevelValF  	= 30.					; set the maximum contour level
	res_mean@cnLevelSpacingF 	= 2.					; set the interval between contours
	gsn_define_colormap(wks,"BlAqGrYeOrReVi200")  ; choose colormap
end if

if (var .eq. "tas") then
	res_mean@cnMinLevelValF  	= -30.					; set the minimum contour level
	res_mean@cnMaxLevelValF  	= 30.					; set the maximum contour level
	res_mean@cnLevelSpacingF 	= 4.					; set the interval between contours
	gsn_define_colormap(wks,"BlAqGrYeOrReVi200")  ; choose colormap
end if


if (var .eq. "psl") then
	res_mean@cnMinLevelValF  	= 990.					; set the minimum contour level
	res_mean@cnMaxLevelValF  	= 1028.					; set the maximum contour level
	res_mean@cnLevelSpacingF 	= 2.					; set the interval between contours
	gsn_define_colormap(wks,"BlAqGrYeOrReVi200")  ; choose colormap
end if

if (var .eq. "pr") then
	res_mean@cnMinLevelValF  	= 1.					; set the minimum contour level
	res_mean@cnMaxLevelValF  	= 10.					; set the maximum contour level
	res_mean@cnLevelSpacingF 	= 1.					; set the interval between contours
	res_mean@cnFillPalette 		= "CBR_wet"
	gsn_define_colormap(wks,"CBR_wet")  ; choose colormap
end if

res_mean_Panel                  = True                   ; modify the panel plot
res_mean_Panel@txString         = var+"_"+seasons(kk)+"_mean_"+flt2string((int2flt((stringtointeger(end_1)-30))))+"-"+end_1     ; plot title
res_mean_Panel@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
res_mean_Panel@gsnPanelLabelBar = True                   ; add common label bar

;*****************************************************************************************

do ii = 0,ppp-1
print(ii)
	number_of_plot=ii+((ppp)*(pp))
	if (ii+(pp*ppp) .lt. model_count-1) then 	
		res_mean@tiMainString=name(number_of_plot)
		plot(ii)  = gsn_csm_contour_map(wks,model(ii,:,:),res_mean)
		last=ii		
	end if
	
	if (pp .eq. ((number_of_pages)-1) .and. ii .eq. (ppp-1)) then

		n=1	

		res_mean@tiMainString="ensemble_mean"

		plot(last+n)  = gsn_csm_contour_map(wks,ensemble,res_mean)
	
		n=n+1
		
		if (observation_flag_period_1 .eq. 1 ) then			
			res_mean@tiMainString=heading
			plot(last+n)  = gsn_csm_contour_map(wks,observation,res_mean)
			n=n+1		
		end if
		
		if (KCM_flag .eq. 1) then
			do xx=0,3
				res_mean@tiMainString=KCM_exp(xx)
				plot(last+n)  = gsn_csm_contour_map(wks,mean_KCM_fields(xx,:,:),res_mean)
				n=n+1
			end do		
		end if			
	end if	
end do; ii
gsn_panel(wks,plot,(/rows,columns/),res_mean_Panel)               ; create panel plot
delete([/model,ensemble,name/])

end if

;**********************************************************************************
;**********************************************************************************
; bias against ensemble-mean
;**********************************************************************************
;**********************************************************************************

res_bias                      = True               	; plot mods desired
res_bias@gsnDraw              = False             	; don't draw yet 
res_bias@gsnFrame             = False              	; don't advance frame yet
res_bias@cnFillOn             = True               	; color contours
res_bias@cnLinesOn            = False              	; default is True
res_bias@cnLineLabelsOn       = False             	; default is True
res_bias@lbLabelBarOn         = False              	; turn off individual lb's
res_bias@cnMissingValFillColor = "gray80"
res_bias@cnLevelSelectionMode = "ManualLevels"		; manually set the contour levels 
res_bias@vpWidthF            = 0.5          			; change aspect ratio of plot
res_bias@vpHeightF           = 0.3
res_bias@mpCenterLonF		  = 220 

res_sig = True                            ; res2 probability plots

res_sig@gsnDraw             = False       ; Do not draw plot
res_sig@gsnFrame            = False       ; Do not advance frome

res_sig@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
res_sig@cnMinLevelValF      = 0       ; set min contour level
res_sig@cnMaxLevelValF      = 10       ; set max contour level
res_sig@cnLevelSpacingF     = 1     ; set contour spacing

res_sig@cnInfoLabelOn       = False       ; turn off info label

res_sig@cnLinesOn           = False       ; do not draw contour lines
res_sig@cnLineLabelsOn      = False       ; do not draw contour labels

res_sig@cnFillScaleF        = .25        ; add extra density 
res_sig@gsnLeftString 		= ""
res_sig@gsnRightString 		= ""

if (var .eq. "tos") then
	res_bias@cnMinLevelValF  = -5.					; set the minimum contour level
	res_bias@cnMaxLevelValF  = 5.					; set the maximum contour level
	res_bias@cnLevelSpacingF = .5					; set the interval between contours
	;gsn_define_colormap(wks,"BlAqGrYeOrReVi200")  ; choose colormap
end if

if (var .eq. "tas") then
	res_bias@cnMinLevelValF  = -5.					; set the minimum contour level
	res_bias@cnMaxLevelValF  = 5.					; set the maximum contour level
	res_bias@cnLevelSpacingF = .5					; set the interval between contours
	;gsn_define_colormap(wks,"BlAqGrYeOrReVi200")  ; choose colormap
end if

;if (var .eq. "psl") then
;	res_bias@cnMinLevelValF  = 990.					; set the minimum contour level
;	res_bias@cnMaxLevelValF  = 1028.					; set the maximum contour level
;	res_bias@cnLevelSpacingF = 2.					; set the interval between contours
;	gsn_define_colormap(wks,"BlAqGrYeOrReVi200")  ; choose colormap
;end if

if (var .eq. "pr") then
	res_bias@cnMinLevelValF  = -5.					; set the minimum contour level
	res_bias@cnMaxLevelValF  = 5.					; set the maximum contour level
	res_bias@cnLevelSpacingF = .5					; set the interval between contours
	;res_bias@cnFillPalette = "CBR_wet"
	;gsn_define_colormap(wks,"CBR_wet")  ; choose colormap
end if

if (plot_bias_ensemble .eq. 1) then
print("plotting bias against ensemble-mean")

model=mean_model_fields_period_1
ensemble=mean_ensemble_period_1
var_model=var_model_fields_period_1
var_ensemble=var_ensemble_period_1
size_model=size_model_fields_period_1
size_ensemble=size_ensemble_period_1
name=model_name_period_1
observation_flag=observation_flag_period_1

if (observation_flag_period_1 .eq. 1) then
	observation=mean_observation_period_1
	var_observation=var_observation_period_1
	size_observation=size_observation_period_1
end if

wks = gsn_open_wks("pdf" ,plot_dir+"/"+var+"_"+seasons(kk)+"_mean_bias_against_ensemble_"+flt2string((int2flt((stringtointeger(end_1)-30))))+"-"+end_1+"_"+(pp+1))               ; open pdf file

plot= new (ppp, graphic)      ; create graphical array
plot2= new (ppp, graphic)      ; create graphical array

;*****************************************************************************************

res_bias_ensemble_Panel                  = True                   ; modify the panel plot
res_bias_ensemble_Panel@txString         = var+"_"+flt2string((int2flt((stringtointeger(end_1)-30))))+"-"+end_1+"_"+seasons(kk)+"_mean_bias_against_ensemble_mean  (model minus ensemble)"      ; plot title
res_bias_ensemble_Panel@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
res_bias_ensemble_Panel@gsnPanelLabelBar = True                   ; add common label bar

;*****************************************************************************************

do ii = 0,ppp-1
	number_of_plot=ii+(ppp*pp)
	
	if (ii+(pp*ppp) .lt. model_count-2) then 	
		res_bias@tiMainString=name(number_of_plot)
		array=model(ii,:,:)
		array=(/model(ii,:,:)-ensemble/)
		prob=100.*(ttest(model(ii,:,:),var_model(ii,:,:),size_model(ii,:,:),ensemble,var_ensemble,size_ensemble,False,False))
		copyatt(prob,array)
		plot(ii)  = gsn_csm_contour_map(wks,array,res_bias)
		plot2(ii)=gsn_csm_contour(wks,prob, res_sig)
		plot2(ii)   = ShadeLtContour(plot2(ii), 5, 3)
		overlay (plot(ii), plot2(ii))
		last=ii
	end if
	
	if (pp .eq. ((number_of_pages)-1) .and. ii .eq. (ppp-1)) then	
		n=1
		
		if (observation_flag(0) .eq. 1 ) then		
			res_bias@tiMainString=heading
			array=(/observation-ensemble/)
			prob=100.*(ttest(observation,var_observation,size_observation,ensemble,var_ensemble,size_ensemble,False,False))
			plot(last+n)  = gsn_csm_contour_map(wks,array,res_bias)
			plot2(last+n)=gsn_csm_contour(wks,prob, res_sig)
			plot2(last+n)   = ShadeLtContour(plot2(last+n), 5, 3)
			overlay (plot(last+n), plot2(last+n))
			n=n+1
		end if
		
		if (KCM_flag .eq. 1) then	
			do xx = 0,3
				res_bias@tiMainString=KCM_exp(xx)
				array=(/mean_KCM_fields(xx,:,:)-ensemble/)
				prob=100.*(ttest(mean_KCM_fields(xx,:,:),var_KCM_fields(xx,:,:),size_KCM_fields(xx,:,:),ensemble,var_ensemble,size_ensemble,False,False))
				plot(last+n)  = gsn_csm_contour_map(wks,array,res_bias)
				plot2(last+n)=gsn_csm_contour(wks,prob, res_sig)
				plot2(last+n)   = ShadeLtContour(plot2(last+n), 5, 3)
				overlay (plot(last+n), plot2(last+n))
				n=n+1
			end do
		end if				
	end if	
end do; ii   

gsn_panel(wks,plot,(/rows,columns/),res_bias_ensemble_Panel)               ; create panel plot
delete([/array,prob,model,ensemble,var_model,var_ensemble,size_model,size_ensemble,name/])

end if


;**********************************************************************************
;**********************************************************************************
; bias against observations
;**********************************************************************************
;**********************************************************************************

if (plot_bias_observations .eq. 1) then

print("plotting bias against observations")

model=mean_model_fields_period_1
ensemble=mean_ensemble_period_1
var_model=var_model_fields_period_1
var_ensemble=var_ensemble_period_1
size_model=size_model_fields_period_1
size_ensemble=size_ensemble_period_1
name=model_name_period_1
observation_flag=observation_flag_period_1

if (observation_flag .eq. 1 ) then

observation=mean_observation_period_1
var_observation=var_observation_period_1
size_observation=size_observation_period_1

wks = gsn_open_wks("pdf" ,plot_dir+"/"+var+"_"+seasons(kk)+"_mean_bias_against_"+heading+"_"+flt2string((int2flt((stringtointeger(end_1)-30))))+"-"+end_1+"_"+(pp+1))               ; open pdf file

plot= new (ppp, graphic)      ; create graphical array
plot2= new (ppp, graphic)      ; create graphical array


res_bias_observations_Panel                  = True                   ; modify the panel plot
res_bias_observations_Panel@txString         = var+"_"+flt2string((int2flt((stringtointeger(end_1)-30))))+"-"+end_1+"_"+seasons(kk)+"_mean_bias_against_"+heading+" (model minus observation)"      ; plot title
res_bias_observations_Panel@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
res_bias_observations_Panel@gsnPanelLabelBar = True                   ; add common label bar

do ii = 0,(ppp-1)

	number_of_plot=ii+(ppp*(pp))
	
	if (ii+(pp*(ppp)) .lt. (model_count)-1) then 
		res_bias@tiMainString=name(number_of_plot)
		array=model(ii,:,:)
		array=(/model(ii,:,:)-observation/)
		prob=100.*(ttest(model(ii,:,:),var_model(ii,:,:),size_model(ii,:,:),observation,var_observation,size_observation,False,False))
		copyatt(prob,array)
		plot(ii)  = gsn_csm_contour_map(wks,array,res_bias)
		plot2(ii)=gsn_csm_contour(wks,prob, res_sig)
		plot2(ii)   = ShadeLtContour(plot2(ii), 5, 3)
		overlay (plot(ii), plot2(ii))
		last=ii		
	end if
	
	if (pp .eq. ((number_of_pages)-1) .and. ii .eq. (ppp-1)) then	
		n=1		
		res_bias@tiMainString="ensemble_mean"
		array=(/ensemble-observation/)
		prob=100.*(ttest(ensemble,var_ensemble,size_ensemble,observation,var_observation,size_observation,False,False))
		plot(last+n)  = gsn_csm_contour_map(wks,array,res_bias)
		plot2(last+n)=gsn_csm_contour(wks,prob, res_sig)
		plot2(last+n)   = ShadeLtContour(plot2(last+n), 5, 3)
		overlay (plot(last+n), plot2(last+n))
		n=n+1
					
		if (KCM_flag .eq. 1) then	
			do xx = 0,3
				res_bias@tiMainString=KCM_exp(xx)
				array=(/mean_KCM_fields(xx,:,:)-observation/)
				prob=100.*(ttest(mean_KCM_fields(xx,:,:),var_KCM_fields(xx,:,:),size_KCM_fields(xx,:,:),observation,var_observation,size_observation,False,False))
				plot(last+n)  = gsn_csm_contour_map(wks,array,res_bias)
				plot2(last+n)=gsn_csm_contour(wks,prob, res_sig)
				plot2(last+n)   = ShadeLtContour(plot2(last+n), 5, 3)
				overlay (plot(last+n), plot2(last+n))
				n=n+1
			end do
		end if				
	end if	
end do ; ii  

gsn_panel(wks,plot,(/rows,columns/),res_bias_observations_Panel)               ; create panel plot
delete([/array,prob,model,ensemble,var_model,var_ensemble,size_model,size_ensemble/])

end if
end if

;**********************************************************************************
;**********************************************************************************
; bias against KCM
;**********************************************************************************
;**********************************************************************************

if (plot_bias_KCM .eq. 1 .and. KCM_flag .eq. 1) then

print("plotting bias against KCM")

do xx = 0,3
wks = gsn_open_wks("pdf" ,plot_dir+"/"+var+"_"+seasons(kk)+"_mean_bias_against_"+KCM_exp(xx)+"_"+(pp+1))               ; open pdf file

plot= new (ppp, graphic)      ; create graphical array
plot2= new (ppp, graphic)      ; create graphical array

res_bias@tiMainFontHeightF   = 0.015

res_bias_KCM_Panel                 = True                   ; modify the panel plot
res_bias_KCM_Panel@txString         = var+"_"+KCM_exp(xx)+"_bias_against_"+seasons(kk)+"_mean (KCM minus model)"        ; plot title
res_bias_KCM_Panel@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
res_bias_KCM_Panel@gsnPanelLabelBar = True                   ; add common label bar

do ii = 0,(stringtointeger(ppp)-1)

	number_of_plot=ii+(stringtointeger(ppp)*(pp))
	
	if (ii+(pp*(stringtointeger(ppp))) .lt. (model_count)) then 
		res_bias@tiMainString=model_name_period_1(number_of_plot)
		array=mean_model_fields_period_1(ii,:,:)
		array=(/mean_KCM_fields(xx,:,:)-mean_model_fields_period_1(ii,:,:)/)
		prob=100.*(ttest(mean_KCM_fields(xx,:,:),var_KCM_fields(xx,:,:),size_KCM_fields(xx,:,:),mean_model_fields_period_1(ii,:,:),var_model_fields_period_1(ii,:,:),size_model_fields_period_1(ii,:,:),False,False))
		copyatt(prob,array)
		plot(ii)  = gsn_csm_contour_map(wks,array,res_bias)
		plot2(ii)=gsn_csm_contour(wks,prob, res_sig)
		plot2(ii)   = ShadeLtContour(plot2(ii), 5, 3)
		overlay (plot(ii), plot2(ii))
		last=ii	
	end if
	
	if (pp .eq. ((number_of_pages)-1) .and. ii .eq. (stringtointeger(ppp)-1)) then	
		n=1
		res_bias@tiMainString="ensemble_mean"
		array=(/mean_KCM_fields(xx,:,:)-mean_ensemble_period_1/)
		prob=100.*(ttest(mean_KCM_fields(xx,:,:),var_KCM_fields(xx,:,:),size_KCM_fields(xx,:,:),mean_ensemble_period_1,var_ensemble_period_1,size_ensemble_period_1,False,False))
		plot(last+n)  = gsn_csm_contour_map(wks,array,res_bias)
		plot2(last+n)=gsn_csm_contour(wks,prob, res_sig)
		plot2(last+n)   = ShadeLtContour(plot2(last+n), 5, 3)
		overlay (plot(last+n), plot2(last+n))
		n=n+1
			
		if (observation_flag_period_1 .eq. 1) then		
			res_bias@tiMainString=heading
			array=(/mean_KCM_fields(xx,:,:)-mean_observation_period_1/)
			prob=100.*(ttest(mean_KCM_fields(xx,:,:),var_KCM_fields(xx,:,:),size_KCM_fields(xx,:,:),mean_observation_period_1,var_observation_period_1,size_observation_period_1,False,False))
			plot(last+n)  = gsn_csm_contour_map(wks,array,res_bias)
			plot2(last+n)=gsn_csm_contour(wks,prob, res_sig)
			plot2(last+n)   = ShadeLtContour(plot2(last+n), 5, 3)
			overlay (plot(last+n), plot2(last+n))
			n=n+1			
		end if
		
		do yy = 0,3
			if (xx .ne. yy)
				res_bias@tiMainString=KCM_exp(yy)
				array=(/mean_KCM_fields(xx,:,:)-mean_KCM_fields(yy,:,:)/)
				prob=100.*(ttest(mean_KCM_fields(xx,:,:),var_KCM_fields(xx,:,:),size_KCM_fields(xx,:,:),mean_KCM_fields(yy,:,:),var_KCM_fields(yy,:,:),size_KCM_fields(yy,:,:),False,False))
				plot(last+n)  = gsn_csm_contour_map(wks,array,res_bias)
				plot2(last+n)=gsn_csm_contour(wks,prob, res_sig)
				plot2(last+n)   = ShadeLtContour(plot2(last+n), 5, 3)
				overlay (plot(last+n), plot2(last+n))
				n=n+1
			end if
		end do; xx			
	end if	
end do; ii

gsn_panel(wks,plot,(/rows,columns/),res_bias_KCM_Panel)               ; create panel plot
delete([/array,prob/])
end do; xx
end if

;**********************************************************************************
;**********************************************************************************
; 20th century warming

;;; This has to be redone, since the file structure has changed ;;;
;**********************************************************************************
;**********************************************************************************

if (plot_change .eq. 1) then

res_bias_change                      = True               	; plot mods desired
res_bias_change@gsnDraw              = False             	; don't draw yet 
res_bias_change@gsnFrame             = False              	; don't advance frame yet
res_bias_change@cnFillOn             = True               	; color contours
res_bias_change@cnLinesOn            = False              	; default is True
res_bias_change@cnLineLabelsOn       = False             	; default is True
res_bias_change@lbLabelBarOn         = False              	; turn off individual lb's
res_bias_change@cnMissingValFillColor = "gray80"
res_bias_change@cnLevelSelectionMode = "ManualLevels"		; manually set the contour levels 
res_bias_change@vpWidthF            = 0.5          			; change aspect ratio of plot
res_bias_change@vpHeightF           = 0.3
res_bias_change@mpCenterLonF		  = 220 

if (var .eq. "tos") then
	res_bias_change@cnMinLevelValF  = -1.5					; set the minimum contour level
	res_bias_change@cnMaxLevelValF  = 1.5					; set the maximum contour level
	res_bias_change@cnLevelSpacingF = .25					; set the interval between contours
	;gsn_define_colormap(wks,"BlAqGrYeOrReVi200")  ; choose colormap
end if

if (var .eq. "tas") then
	res_bias_change@cnMinLevelValF  = -1.5					; set the minimum contour level
	res_bias_change@cnMaxLevelValF  = 1.5					; set the maximum contour level
	res_bias_change@cnLevelSpacingF = .25					; set the interval between contours
	;gsn_define_colormap(wks,"BlAqGrYeOrReVi200")  ; choose colormap
end if

res_bias_change_Panel                 = True                   ; modify the panel plot
res_bias_change_Panel@txString         = var+"_"+seasons(kk)+"_mean_change between_"+periods(0)+"_and_"+periods(1)      ; plot title
res_bias_change_Panel@gsnMaximize      = True                   ; make ps, eps, pdf, ... large
res_bias_change_Panel@gsnPanelLabelBar = True                   ; add common label bar
	
wks = gsn_open_wks("pdf" ,plot_dir+"/"+var+"_"+seasons(kk)+"_mean_change_between_"+periods(0)+"_and_"+periods(1)+"_"+(pp+1))               ; open pdf file

plot= new (stringtointeger(ppp), graphic)      ; create graphical array
plot2= new (stringtointeger(ppp), graphic)      ; create graphical array

do ii = 0,(stringtointeger(ppp)-1)

	number_of_plot=ii+(stringtointeger(ppp)*(pp))
	
	if (ii+(pp*(stringtointeger(ppp))) .lt. (model_count)) then 
		res_bias_change@tiMainString=model_name_period_2(number_of_plot)
		array=mean_model_fields_period_1(ii,:,:)
		array=(/mean_model_fields_period_2(ii,:,:)-mean_model_fields_period_1(ii,:,:)/)
		prob=100.*(ttest(mean_model_fields_period_2(ii,:,:),var_model_fields_period_2(ii,:,:),size_model_fields_period_2(ii,:,:),mean_model_fields_period_1(ii,:,:),var_model_fields_period_1(ii,:,:),size_model_fields_period_1(ii,:,:),False,False))
		copyatt(prob,array)
		plot(ii)  = gsn_csm_contour_map(wks,array,res_bias_change)
		plot2(ii)=gsn_csm_contour(wks,prob, res_sig)
		plot2(ii)   = ShadeLtContour(plot2(ii), 5, 3)
		overlay (plot(ii), plot2(ii))
		last=ii		
	end if
		
	if (pp .eq. ((number_of_pages)-1) .and. ii .eq. (stringtointeger(ppp)-1)) then	
		n=1			
		res_bias_change@tiMainString="ensemble_mean"
		array=(/mean_ensemble_period_2-mean_ensemble_period_1/)
		prob=100.*(ttest(mean_ensemble_period_2,var_ensemble_period_2,size_ensemble_period_2,mean_ensemble_period_1,var_ensemble_period_1,size_ensemble_period_1,False,False))
		plot(last+n)  = gsn_csm_contour_map(wks,array,res_bias_change)
		plot2(last+n)=gsn_csm_contour(wks,prob, res_sig)
		plot2(last+n)   = ShadeLtContour(plot2(last+n), 5, 3)
		overlay (plot(last+n), plot2(last+n))
		n=n+1
			
		if (observation_flag_period_1 .eq. 1 .and. observation_flag_period_2 .eq. 1) then	
			res_bias_change@tiMainString=heading
			array=(/mean_observation_period_2-mean_observation_period_1/)
			prob=100.*(ttest(mean_observation_period_2,var_observation_period_2,size_observation_period_2,mean_observation_period_1,var_observation_period_1,size_observation_period_1,False,False))
			plot(last+n)  = gsn_csm_contour_map(wks,array,res_bias_change)
			plot2(last+n)=gsn_csm_contour(wks,prob, res_sig)
			plot2(last+n)   = ShadeLtContour(plot2(last+n), 5, 3)
			overlay (plot(last+n), plot2(last+n))
			n=n+1		
		end if
	end if	
end do   

gsn_panel(wks,plot,(/rows,columns/),res_bias_change_Panel)               ; create panel plot
delete([/array,prob/])

end if
;**********************************************************************************
;**********************************************************************************

delete([/mean_model_fields_period_1,mean_ensemble_period_1,var_model_fields_period_1,size_model_fields_period_1/])
if (KCM_flag .eq. 1) then
	delete([/mean_KCM_fields/])
end if
kk=kk+1

end do ; end kk
delete([/model_fields_period_1,model_files_period_1/])
if (KCM_flag .eq. 1) then
	delete([/KCM_fields/])
end if

end do ; end pp

end


