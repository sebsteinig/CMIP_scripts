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

realm=getenv("realm")
CMIP_dir=getenv("CMIP_dir")
experiment=getenv("experiment")

;*****************************************************************************************
; define some other variables
;*****************************************************************************************

setfileoption("nc","SuppressClose",False) 

period="1980-2000"


CMIP5_climatology_directory=CMIP_dir+"/processed/historical/Amon/" ; directory of processed CMIP5 climatologies
CMIP3_climatology_directory=CMIP_dir+"/processed/CMIP3/20c3m/atm/" ; directory of processed CMIP5 climatologies
KCM_climatology_directory=CMIP_dir+"/data/KCM/"
obs_climatology_directory=CMIP_dir+"/data/observations/"

variable_folder=(/"pr","tas","zg","va","va","ua","ua","ta","ta","rlut","rsut","sw_cre","lw_cre"/)
variables=(/"pr","tas","zg_500","va_200","va_850","ua_200","ua_850","ta_200","ta_850","rlut","rsut","sw_cre","lw_cre"/)
obs_folder=(/"GPCP","NCEP","NCEP","NCEP","NCEP","NCEP","NCEP","NCEP","NCEP","CERES_EBAF","CERES_EBAF","CERES_EBAF","CERES_EBAF"/)

variable_folder=variable_folder(::-1) 
variables=variables(::-1)
obs_folder=obs_folder(::-1)

number_of_CMIP5_models=stringtointeger(systemfunc ("ls -1 "+CMIP5_climatology_directory+variable_folder(0)+"/"+"*"+variables(0)+"*"+period+"*clim_remapbil_T42"+"*"+"| wc -l"))
number_of_CMIP3_models=stringtointeger(systemfunc ("ls -1 "+CMIP3_climatology_directory+variable_folder(0)+"/"+"*"+variables(0)+"*1980-1999"+"*clim_remapbil_T42"+"*"+"| wc -l"))
number_of_KCM_models=stringtointeger(systemfunc ("ls -1 "+KCM_climatology_directory+"*"+variables(0)+"*clim_remapbil_T42"+"*"+"| wc -l"))

;*****************************************************************************************
; read in files
;*****************************************************************************************

all_files=new((/dimsizes(variables),number_of_CMIP5_models+number_of_CMIP3_models+number_of_KCM_models/),string)
obs_files=new((/dimsizes(variables),1/),string)


do vv=0,dimsizes(variables)-1
	all_files(vv,0:number_of_CMIP5_models-1)=systemfunc ("ls "+CMIP5_climatology_directory+variable_folder(vv)+"/"+"*"+variables(vv)+"*"+period+"*clim_remapbil_T42"+"*")
	all_files(vv,number_of_CMIP5_models:(number_of_CMIP5_models+number_of_KCM_models)-1)=systemfunc("ls "+KCM_climatology_directory+"*"+variables(vv)+"*clim_remapbil_T42"+"*")
	all_files(vv,(number_of_CMIP5_models+number_of_KCM_models):(number_of_CMIP5_models+number_of_CMIP3_models+number_of_KCM_models)-1)=systemfunc("ls "+CMIP3_climatology_directory+variable_folder(vv)+"/"+variables(vv)+"*"+"*clim_remapbil_T42"+"*")

if (obs_folder(vv) .ne. "CERES_EBAF") then
	obs_files(vv,0) = systemfunc ("ls "+obs_climatology_directory+obs_folder(vv)+"/"+"*"+variables(vv)+"*"+period+"*"+"clim_*"+"*T42"+"*")
else
	obs_files(vv,0) = systemfunc ("ls "+obs_climatology_directory+obs_folder(vv)+"/"+"*"+variables(vv)+"*"+"clim_*"+"*T42"+"*")
end if

end do

all_files_ordered=all_files	
print(all_files)
	
do vv=0,dimsizes(variables)-1
	all_files_ordered(vv,0:number_of_KCM_models-1)=array_append_record(\
												   all_files(vv,(number_of_CMIP5_models+number_of_KCM_models)-2:(number_of_CMIP5_models+number_of_KCM_models)-1),\
												   all_files(vv,number_of_CMIP5_models:number_of_CMIP5_models+1),0)
	all_files_ordered(vv,number_of_KCM_models:(number_of_CMIP5_models+number_of_KCM_models)-1)=array_append_record(\
																		   all_files(vv,number_of_CMIP5_models-1),\
																		   all_files(vv,0:number_of_CMIP5_models-2),0)
	all_files_ordered(vv,number_of_CMIP5_models+number_of_KCM_models:(number_of_CMIP5_models+number_of_CMIP3_models+number_of_KCM_models)-1)=array_append_record(\
																		   all_files(vv,number_of_CMIP5_models+number_of_CMIP3_models+number_of_KCM_models-1),\
																		   all_files(vv,number_of_CMIP5_models+number_of_KCM_models:number_of_CMIP5_models+number_of_CMIP3_models+number_of_KCM_models-2),0)																	   
																		  
end do

model_names=all_files_ordered(0,:)
do nt = 0,(number_of_CMIP5_models+number_of_CMIP3_models+number_of_KCM_models)-1

	if (nt .le. number_of_KCM_models-1)
		strs_KCM_path=str_split(all_files_ordered(0,nt),"/")
		strs_KCM=str_split(strs_KCM_path(5),"_")
		print(strs_KCM)
		model_names(nt)=strs_KCM(0)
		delete([/strs_KCM/])
	else
		strs_CMIP=str_split(all_files_ordered(0,nt),"_")
		model_names(nt)=strs_CMIP(6)
		delete([/strs_CMIP/])
	end if

end do

delete([/strs_KCM_path,all_files/])

print(model_names)

;*****************************************************************************************
; compute error matrix
;*****************************************************************************************



all_data=new((/dimsizes(variables),number_of_CMIP5_models+number_of_CMIP3_models+number_of_KCM_models,12,64,128/),double)
obs_data=new((/dimsizes(variables),12,64,128/),double)


CMIP5_variables=(/"pr","tas","zg","va","va","ua","ua","ta","ta","rlut","rsut","sw_cre","lw_cre"/)
KCM_variables=(/"precip","temp2","geopoth","v","v","u","u","t","t","trad0","srad0u","sw_cre","lw_cre"/)
obs_variables=(/"precip","air","hgt","vwnd","vwnd","uwnd","uwnd","air","air","toa_lw_all_mon","toa_sw_all_mon","toa_cre_sw_mon","toa_cre_lw_mon"/)

CMIP5_variables=CMIP5_variables(::-1)
KCM_variables=KCM_variables(::-1)
obs_variables=obs_variables(::-1)

do vv=0,dimsizes(variables)-1

	all_fields=addfiles(all_files_ordered(vv,:),"r")
	obs_fields=addfile(obs_files(vv,0),"r")
	ListSetType (all_fields, "join")
	
	do kk = 0,(number_of_CMIP5_models+number_of_CMIP3_models+number_of_KCM_models)-1
	
		if (kk .le. number_of_KCM_models-1)
			if ( (CMIP5_variables(vv) .eq. "zg") .or. \ 
				 (CMIP5_variables(vv) .eq. "va") .or. \ 
				 (CMIP5_variables(vv) .eq. "ua") .or. \
				 (CMIP5_variables(vv) .eq. "ta") )
				 dummy=all_fields[kk]->$KCM_variables(vv)$(:,:,0,:,:)
				 all_data(vv,kk,:,:,:)=dummy(0,:,:,:)
			else if ( (CMIP5_variables(vv) .eq. "rlut") .or. \ 
					  (CMIP5_variables(vv) .eq. "rsut") )
	 				  all_data(vv,kk,:,:,:)=all_fields[kk]->$KCM_variables(vv)$*(-1)				  
			else
				 all_data(vv,kk,:,:,:)=all_fields[kk]->$KCM_variables(vv)$
		    end if
			end if	 
			
		else if (kk .gt. number_of_KCM_models-1)
			if ( (CMIP5_variables(vv) .eq. "zg") .or. \ 
				 (CMIP5_variables(vv) .eq. "va") .or. \ 
				 (CMIP5_variables(vv) .eq. "ua") .or. \
				 (CMIP5_variables(vv) .eq. "ta") )
				 dummy=all_fields[kk]->$CMIP5_variables(vv)$(:,:,0,:,:) 
				 all_data(vv,kk,:,:,:)=dummy(0,:,:,:)
			else
				 all_data(vv,kk,:,:,:)=all_fields[kk]->$CMIP5_variables(vv)$		
			end if
		end if
		end if
	end do
	
		if (CMIP5_variables(vv) .eq. "zg")
			dummy=obs_fields->$obs_variables(vv)$(:,0,:,:)
			obs_data(vv,:,:,:)=dummy(0,:,:,:)
		else if ( (CMIP5_variables(vv) .eq. "va") .or. \ 
			      (CMIP5_variables(vv) .eq. "ua") )
	  			  dummy=obs_fields->$obs_variables(vv)$(:,0,:,:)
				  obs_data(vv,:,:,:)=(dummy(0,:,:,:)*0.01)+202.65
		else if   (CMIP5_variables(vv) .eq. "ta")
	  			  dummy=obs_fields->$obs_variables(vv)$(:,0,:,:)
				  obs_data(vv,:,:,:)=(dummy(0,:,:,:)*0.01)+127.65	  
		else
			obs_data(vv,:,:,:)=obs_fields->$obs_variables(vv)$
		end if
		end if
		end if
end do

lat=obs_fields->lat
lon=obs_fields->lon
  
nlat = 64
gwt  = latGauWgt(nlat, "lat", "gaussian weights", "")

monthweights=(/31,28,31,30,31,30,31,31,30,31,30,31/)

rmse_tmp=new(dimsizes(all_data),double)
rmse_array=new((/5,dimsizes(variables),number_of_CMIP5_models+number_of_CMIP3_models+number_of_KCM_models/),double)

bias=new(dimsizes(all_data),double)
do kk=0,number_of_CMIP5_models+number_of_CMIP3_models+number_of_KCM_models-1
	bias(:,kk,:,:,:)=(all_data(:,kk,:,:,:)-obs_data)
end do

mean_bias=dim_avg_n(bias,2)
copyatt(mean_bias, all_data(:,:,0,:,:))

CMIP5_index=(/17,22,25,26,20,43,31,35,37,39,8,29/)
CMIP3_index=(/50,52,54,55,56,58,59,60,63,64,65,68/)


do nn=0,dimsizes(CMIP5_index)-1

plot_maps=1

if (plot_maps .eq. 1) then
wks_map = gsn_open_wks("pdf",CMIP_dir+"/plots/metrics/"+"PCMDI_map_"+model_names(CMIP5_index(nn)))              
 gsn_define_colormap(wks_map,"hotcolr_19lev")        ; choose colormap
 plot_map = new(10,graphic)                         ; create graphic array

 res                      = True
 res@tiMainFontThicknessF = 2
 res@tiYAxisFontThicknessF = 3
 res@tiYAxisFontHeightF		=0.05
 res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
 res@cnFillOn             = True         ; turn on color fill
 res@gsnDraw              = False        ; do not draw picture
 res@gsnFrame             = False        ; do not advance frame
 res@lbOrientation        = "Vertical"   ; vertical label bar
 res@cnLinesOn            = False

 res@tiMainString		  = model_names(CMIP5_index(nn))+" (CMIP5)"
 res@tiYAxisString		  = "precipitation"
 res@tiYAxisOffsetXF	  = -.015
 res@cnMinLevelValF       =  -8.                ; set min contour level
 res@cnMaxLevelValF       =  8.               ; set max contour level
 res@cnLevelSpacingF      =   1.               ; set contour spacing
 res@gsnRightString		  = "mm/day"
 res@gsnLeftString		  = "precipitation"
 plot_map(0)=gsn_csm_contour_map(wks_map,mean_bias(12,CMIP5_index(nn),:,:),res)
 res@tiMainString		  = model_names(CMIP3_index(nn))+" (CMIP3)"
 res@tiYAxisString		  = ""
 plot_map(1)=gsn_csm_contour_map(wks_map,mean_bias(12,CMIP3_index(nn),:,:),res)
 
 res@tiMainString		  = ""
 res@tiYAxisString		  = "temp2"
 res@cnMinLevelValF       =  -10.                ; set min contour level
 res@cnMaxLevelValF       =  10.               ; set max contour level
 res@cnLevelSpacingF      =   1.               ; set contour spacing
 res@gsnRightString		  = "°C"
 res@gsnLeftString		  = "temp2"
 plot_map(2)=gsn_csm_contour_map(wks_map,mean_bias(11,CMIP5_index(nn),:,:),res)
 res@tiYAxisString		  = ""
 plot_map(3)=gsn_csm_contour_map(wks_map,mean_bias(11,CMIP3_index(nn),:,:),res)
 
 res@tiMainString		  = ""
 res@tiYAxisString		  = "zg 500"
 res@cnMinLevelValF       =  -130.                ; set min contour level
 res@cnMaxLevelValF       =  130.               ; set max contour level
 res@cnLevelSpacingF      =   20.               ; set contour spacing
 res@gsnRightString		  = "m"
 res@gsnLeftString		  = "zg 500"
 plot_map(4)=gsn_csm_contour_map(wks_map,mean_bias(10,CMIP5_index(nn),:,:),res)
 res@tiYAxisString		  = ""
 plot_map(5)=gsn_csm_contour_map(wks_map,mean_bias(10,CMIP3_index(nn),:,:),res)
 
 res@tiMainString		  = ""
 res@tiYAxisString		  = "rlut"
 res@cnMinLevelValF       =  -50.                ; set min contour level
 res@cnMaxLevelValF       =  50.               ; set max contour level
 res@cnLevelSpacingF      =   5.               ; set contour spacing
 res@gsnRightString		  = "W/m^2"
 res@gsnLeftString		  = "rlut"
 plot_map(6)=gsn_csm_contour_map(wks_map,mean_bias(3,CMIP5_index(nn),:,:),res)
 res@tiYAxisString		  = ""
 plot_map(7)=gsn_csm_contour_map(wks_map,mean_bias(3,CMIP3_index(nn),:,:),res)
 
 res@tiMainString		  = ""
 res@tiYAxisString		  = "rsut"
 res@cnMinLevelValF       =  -50.                ; set min contour level
 res@cnMaxLevelValF       =  50.               ; set max contour level
 res@cnLevelSpacingF      =   5.               ; set contour spacing
 res@gsnRightString		  = "W/m^2"
 res@gsnLeftString		  = "rsut"
 plot_map(8)=gsn_csm_contour_map(wks_map,mean_bias(2,CMIP5_index(nn),:,:),res)
 res@tiYAxisString		  = ""
 plot_map(9)=gsn_csm_contour_map(wks_map,mean_bias(2,CMIP3_index(nn),:,:),res)

 resP                = True                ; panel only resources
 resP@gsnMaximize    = True                ; maximize plots
 gsn_panel(wks_map,plot_map,(/5,2/),resP)
 

 end if
 
 end do
 
 end 