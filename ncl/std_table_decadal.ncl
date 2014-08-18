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

; decadal running mean

	nh_ctrl_directory=CMIP_dir+"/processed/CMIP5/piControl/Amon/tas/NH_mean_anomaly_decadal_running_mean/"
	nh_ctrl_detrended_directory=CMIP_dir+"/processed/CMIP5/piControl/Amon/tas/NH_mean_anomaly_decadal_running_mean_detrended/"
	nh_past_directory=CMIP_dir+"/processed/CMIP5/past1000/Amon/tas/NH_mean_anomaly_decadal_running_mean/"
	nh_past_detrended_directory=CMIP_dir+"/processed/CMIP5/past1000/Amon/tas/NH_mean_anomaly_decadal_running_mean_detrended/"

	nh_ctrl_files = systemfunc ("ls "+nh_ctrl_directory+"*.nc")
	nh_ctrl_detrended_files = systemfunc ("ls "+nh_ctrl_detrended_directory+"*.nc")
	nh_past_files = systemfunc ("ls "+nh_past_directory+"*.nc")
	nh_past_detrended_files = systemfunc ("ls "+nh_past_detrended_directory+"*.nc")
	
	nh_ctrl_tmp=addfiles(nh_ctrl_files,"r")
	nh_ctrl_detrended_tmp=addfiles(nh_ctrl_detrended_files,"r")
	nh_past_tmp=addfiles(nh_past_files,"r")
	nh_past_detrended_tmp=addfiles(nh_past_detrended_files,"r")
	
	ListSetType (nh_ctrl_tmp, "join")
	ListSetType (nh_ctrl_detrended_tmp, "join")
	ListSetType (nh_past_tmp, "join")
	ListSetType (nh_past_detrended_tmp, "join")
	
	proxy_nh_anomaly_running_tmp=addfile(CMIP_dir+"/data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_anomaly_0856-1845_decadal_running_mean.nc","r")

model_name=nh_past_files
do nt = 0,(dimsizes(nh_past_files)-1)
	strs=str_split(nh_past_files(nt),"_")
	model_name(nt)=strs(10)
	delete(strs)
end do

names=array_append_record(model_name,"Mann et al. 2009",0)

nh_ctrl_std=new((/11,1/),"float")
nh_ctrl_detrended_std=new((/11,1/),"float")
do nn=0,8
	tmp=nh_ctrl_tmp[nn]->tas
	tmp_detrended=nh_ctrl_detrended_tmp[nn]->tas
	nh_ctrl_std(nn,0)=stddev(tmp(:,0,0))
	nh_ctrl_detrended_std(nn,0)=stddev(tmp_detrended(:,0,0))
	
	delete([/tmp,tmp_detrended/])
end do

nh_past=nh_past_tmp[:]->tas(:,:,0,0)
nh_past_detrended=nh_past_detrended_tmp[:]->tas(:,:,0,0)
proxy_nh=new((/1,990/),"float")
proxy_nh(0,:)=proxy_nh_anomaly_running_tmp->tas(:,0,0)
proxy_nh!0="ncl_join"

all_nh_past=array_append_record(nh_past,proxy_nh,0)
all_nh_past_detrended=array_append_record(nh_past_detrended,proxy_nh,0)

all_nh_past_std=dim_stddev(all_nh_past)
all_nh_past_detrended_std=dim_stddev(all_nh_past_detrended)

all_nh_past_dtr=dtrend(all_nh_past,False)
all_nh_past_dtr_detrended=dtrend(all_nh_past_detrended,False)

nh_cor=new((/11/),"float")
nh_cor_detrended=new((/11/),"float")
nh_cor_dtr=new((/11/),"float")
nh_cor_dtr_detrended=new((/11/),"float")

do nn=0,10
	nh_cor(nn)=escorc(all_nh_past(nn,:),all_nh_past(10,:))
	nh_cor_detrended(nn)=escorc(all_nh_past_detrended(nn,:),all_nh_past_detrended(10,:))
	nh_cor_dtr(nn)=escorc(all_nh_past_dtr(nn,:),all_nh_past_dtr(10,:))
	nh_cor_dtr_detrended(nn)=escorc(all_nh_past_dtr_detrended(nn,:),all_nh_past_dtr_detrended(10,:))
end do


;*************************************************
; Table
;*************************************************

; Header
  ncr1  = (/1,1/)               ; 1 row, 1 column
  x1    = (/0.000,0.335/)       ; Start and end X
  y1    = (/0.900,0.995/)       ; Start and end Y
  text1 = "Model"

; Sub header
  ncr2  = (/1,2/)               ; 2 rows, 2 columns
  x2    = (/0.335,0.995/)       ; Start and end X
  y2    = (/0.9475,0.995/)       ; Start and end Y
  text2 = (/ (/"standard deviation","correlation with proxy"/)/)
  
; Sub header
  ncr3  = (/1,4/)               ; 2 rows, 2 columns
  x3    = (/0.335,0.995/)       ; Start and end X
  y3    = (/0.900,0.9475/)       ; Start and end Y
  text3 = (/ (/"~Z75~ control","~Z75~ full forcing","~Z75~ original","~Z75~ detrended"/)/)
  
; Sub header
  ncr4  = (/11,1/)               ; 2 rows, 2 columns
  x4    = (/0.000,0.2/)       ; Start and end X
  y4    = (/0.005,0.9000/)       ; Start and end Y
  text4 = "~Z90~"+names
  
; Sub header
  ncr5  = (/22,1/)               ; 2 rows, 2 columns
  x5    = (/0.2,0.335/)       ; Start and end X
  y5    = (/0.005,0.9000/)       ; Start and end Y
  text5 = (/(/"~Z75~ original","~Z75~ corrected","~Z75~ original","~Z75~ corrected","~Z75~ original","~Z75~ corrected","~Z75~ original","~Z75~ corrected","~Z75~ original","~Z75~ corrected","~Z75~ original","~Z75~ corrected","~Z75~ original","~Z75~ corrected","~Z75~ original","~Z75~ corrected","~Z75~ original","~Z75~ corrected","~Z75~ original","~Z75~ corrected","~Z75~ original","~Z75~ corrected"/)/)

; Main table body
  ncr6  = (/22,4/)              ; 16 rows, 3 columns
  x6   = (/0.335,0.995/)       ; Start and end X
  y6    = (/0.005,0.900/)       ; Start and end Y


text6=new((/22,4/),"string")
do ii=0,21
	if (int2flt(ii)/2 .eq. floattointeger(ii/2))
		text6(ii,0)=decimalPlaces(nh_ctrl_std(ii/2,0),3,True)
		text6(ii,1)=decimalPlaces(all_nh_past_std(ii/2),3,True)
		text6(ii,2)=decimalPlaces(nh_cor(ii/2),3,True)
		text6(ii,3)=decimalPlaces(nh_cor_dtr(ii/2),3,True)
	else
		text6(ii,0)=decimalPlaces(nh_ctrl_detrended_std(ii/2,0),3,True)
		text6(ii,1)=decimalPlaces(all_nh_past_detrended_std(ii/2),3,True)
		text6(ii,2)=decimalPlaces(nh_cor_detrended(ii/2),3,True)
		text6(ii,3)=decimalPlaces(nh_cor_dtr_detrended(ii/2),3,True)
	end if
end do

wks   = gsn_open_wks ("pdf", CMIP_dir+"/plots/tables/std_and_cor_decadal")  ; open workstation 

;
; Main header.
;
  res1               = True
  res1@txFontHeightF = 0.03
  res1@gsFillColor   = "azure3"

  gsn_table(wks,ncr1,x1,y1,text1,res1)

;
; Sub header
;
  res2               = True
  res2@txFontHeightF = 0.02
  res2@gsFillColor   = "azure3"

  gsn_table(wks,ncr2,x2,y2,text2,res2)
  
  ; Sub header
;
  res3               = True
  res3@txFontHeightF = 0.02
  res3@gsFillColor   = "azure2"

  gsn_table(wks,ncr3,x3,y3,text3,res3)
  
  ; Sub header
;
  res4               = True
  res4@txFontHeightF = 0.02
  res4@gsFillColor   = "azure3"

  gsn_table(wks,ncr4,x4,y4,text4,res4)
  
  ; Sub header
;
  res5               = True
  res5@txFontHeightF = 0.02
  res5@gsFillColor   = "azure2"

  gsn_table(wks,ncr5,x5,y5,text5,res5)

;
; Main body of table.
;
  res6 = True             ; Set up resource list

;  res3@gsnDebug = True     ; Useful to print NDC row,col values used.

  res6@txFontHeightF = 0.02
  
    res6@gsFillColor = (/ (/"white","white","white","white"/), \
                       (/"cadetblue1","cadetblue1","cadetblue1","cadetblue1"/), \
                       (/"white","white","white","white"/), \
                       (/"cadetblue1","cadetblue1","cadetblue1","cadetblue1"/), \
                       (/"white","white","white","white"/), \
                       (/"cadetblue1","cadetblue1","cadetblue1","cadetblue1"/), \
                       (/"white","white","white","white"/), \
                       (/"cadetblue1","cadetblue1","cadetblue1","cadetblue1"/), \
                       (/"white","white","white","white"/), \
                       (/"cadetblue1","cadetblue1","cadetblue1","cadetblue1"/), \
                       (/"white","white","white","white"/), \
                       (/"cadetblue1","cadetblue1","cadetblue1","cadetblue1"/), \
                       (/"white","white","white","white"/), \
                       (/"cadetblue1","cadetblue1","cadetblue1","cadetblue1"/), \
                       (/"white","white","white","white"/), \
                       (/"cadetblue1","cadetblue1","cadetblue1","cadetblue1"/), \
                       (/"white","white","white","white"/), \
                       (/"cadetblue1","cadetblue1","cadetblue1","cadetblue1"/), \
                       (/"white","white","white","white"/), \
                       (/"cadetblue1","cadetblue1","cadetblue1","cadetblue1"/), \
                       (/"white","white","white","white"/), \
                       (/"cadetblue1","cadetblue1","cadetblue1","cadetblue1"/) /)


  gsn_table(wks,ncr6,x6,y6,text6,res6)
  
  frame(wks)      ; Advance the frame.

end