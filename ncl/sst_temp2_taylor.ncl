;**********************************
; Taylor Diagram
;**********************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "./taylor_diagram.ncl"
load "./taylor_metrics_table.ncl"
;**********************************
begin
;**********************************
; Assume the following have already been computed:
;   _ratio are the ratio:  Case_Variance/Reference_Variance
;   _cc    are the cross correlation coef of Case to Reference
; In this example, these are derived for annual mean climatologies.
;**********************************

CMIP_dir="/Volumes/HiWi_data/CMIP_test"

sst_CMIP5_file_list=systemfunc ("ls "+CMIP_dir+"/processed/CMIP5/historical/Omon/tos/nino3/"+"*index.nc")
tas_CMIP5_file_list=systemfunc ("ls "+CMIP_dir+"/processed/CMIP5/historical/Amon/tas/gm/"+"*gm.nc")
pr_CMIP5_file_list=systemfunc ("ls "+CMIP_dir+"/processed/CMIP5/historical/Amon/pr/pacific_mean/"+"*pacific_mean.nc")
sst_obs_file_list=CMIP_dir+"/data/observations/ERSST/ERSST_1870-1999_nino3_index.nc"
tas_obs_file_list=CMIP_dir+"/data/observations/NCEP/NCEP_tas_1948-1999_gm.nc"
pr_obs_file_list=CMIP_dir+"/data/observations/GPCP/GPCP_pr_1980-1999_pacific_mean.nc"
sst_CMIP5_files   = addfiles (sst_CMIP5_file_list, "r")
tas_CMIP5_files   = addfiles (tas_CMIP5_file_list, "r")
pr_CMIP5_files   = addfiles (pr_CMIP5_file_list, "r")
sst_obs_file   = addfile (sst_obs_file_list, "r")
tas_obs_file   = addfile (tas_obs_file_list, "r")
pr_obs_file   = addfile (pr_obs_file_list, "r")
ListSetType (sst_CMIP5_files, "join")
ListSetType (tas_CMIP5_files, "join")
ListSetType (pr_CMIP5_files, "join")


sst_CMIP5_fields_tmp   = sst_CMIP5_files[:]->tos(:,:,0,0)
tas_CMIP5_fields_tmp   = tas_CMIP5_files[:]->tas(:,:,0,0)
pr_CMIP5_fields_tmp   = pr_CMIP5_files[:]->pr(:,:,0,0)

sst_CMIP5_fields_annual   = month_to_annual(sst_CMIP5_fields_tmp(time|:,ncl_join|:),1)
tas_CMIP5_fields_annual   = month_to_annual(tas_CMIP5_fields_tmp(time|:,ncl_join|:),1)
pr_CMIP5_fields_annual   = month_to_annual(pr_CMIP5_fields_tmp(time|:,ncl_join|:),1)

sst_CMIP5_fields   = dtrend(sst_CMIP5_fields_annual(ncl_join|:,year|:),True)
tas_CMIP5_fields   = dtrend(tas_CMIP5_fields_annual(ncl_join|:,year|:),True)
pr_CMIP5_fields   = dtrend(pr_CMIP5_fields_annual(ncl_join|:,year|:),True)

sst_obs_field_tmp  = sst_obs_file->sst(:,0,0)*0.01
tas_obs_field_tmp  = tas_obs_file->air(:,0,0)
pr_obs_field_tmp  = pr_obs_file->precip(:,0,0)

sst_obs_field_annual  = month_to_annual(sst_obs_field_tmp,1)
tas_obs_field_annual   = month_to_annual(tas_obs_field_tmp,1)
pr_obs_field_annual   = month_to_annual(pr_obs_field_tmp,1)

sst_obs_field  = dtrend(sst_obs_field_annual ,True)
tas_obs_field  = dtrend(tas_obs_field_annual ,True)
pr_obs_field  = dtrend(pr_obs_field_annual ,True)


sst_CMIP5_std=dim_stddev(sst_CMIP5_fields)
tas_CMIP5_std=dim_stddev(tas_CMIP5_fields)
pr_CMIP5_std=dim_stddev(pr_CMIP5_fields)
sst_obs_std=dim_stddev(sst_obs_field)
tas_obs_std=dim_stddev(tas_obs_field)
pr_obs_std=dim_stddev(pr_obs_field)
sst_CMIP5_normalized_std=sst_CMIP5_std/sst_obs_std
tas_CMIP5_normalized_std=tas_CMIP5_std/tas_obs_std
pr_CMIP5_normalized_std=pr_CMIP5_std/pr_obs_std
sst_CMIP5_cor=escorc(sst_CMIP5_fields,sst_obs_field)
tas_CMIP5_cor=escorc(tas_CMIP5_fields,tas_obs_field)
pr_CMIP5_cor=escorc(pr_CMIP5_fields,pr_obs_field)



model_names=sst_CMIP5_file_list
do nt = 0,dimsizes(sst_CMIP5_file_list)-1

	strs_CMIP5=str_split(sst_CMIP5_file_list(nt),"_")
	model_names(nt)=strs_CMIP5(4)

end do


;sst_CMIP5_cor(39)=sst_CMIP5_cor(39)+0.05

; Cases [Model]
  case      = (/ "nino3 index anomaly", "global mean temp2 anomaly", "tropical Pacific precipitation anomaly" /) 
  nCase     = dimsizes(case )                 ; # of Cases [Cases]

; variables compared
  var       = model_names
  nVar      = dimsizes(var)                   ; # of Variables

; "Case A"                        
  CA_ratio   = sst_CMIP5_normalized_std
  CA_cc      = abs(sst_CMIP5_cor)
  print(CA_ratio(39))
  print(CA_cc(39))

; "Case B" 
  CB_ratio   = tas_CMIP5_normalized_std
  CB_cc      = abs(tas_CMIP5_cor)
  
  print(CB_ratio(39))
  print(CB_cc(39))
; "Case B" 
  CC_ratio   = pr_CMIP5_normalized_std
  CC_cc      = abs(pr_CMIP5_cor)

; arrays to be passed to taylor_diagram. It will calculate the x xnd y coordinates.
  ratio      = new ((/nCase, nVar/),typeof(CA_cc) )  
  cc         = new ((/nCase, nVar/),typeof(CA_cc) ) 

  ratio(0,:) = CA_ratio 
  ratio(1,:) = CB_ratio
  ratio(2,:) = CC_ratio

  cc(0,:)    = CA_cc 
  cc(1,:)    = CB_cc
  cc(2,:)    = CC_cc

;**********************************
; create plot
;**********************************
  varSource = var               ; add extra info [*not* required]

  ty_opt   = True                           ; taylor diagram with options
        
  ;ty_opt@Markers       = (/19, 15, 15/)         ; make all solid fill
  ty_opt@Colors        = (/"red", "blue", "green" /)          
  ty_opt@varLabels     = varSource
  ty_opt@caseLabels    = case

  ty_opt@varLabelsYloc = 1.5                ; Move location of variable labels [default 0.45]
  ty_opt@caseLabelsFontHeightF = 0.2       ; make slight larger   [default=0.12 ]
  ty_opt@varLabelsFontHeightF  = 0.01      ; make slight smaller  [default=0.013]
 
  ty_opt@tiMainString  = "Annual"           ; title
  ty_opt@stnRad        = (/ 0.5, 1.5 /)     ; additional standard radii
  ty_opt@ccRays        = (/ 0.6, 0.9 /)     ; correllation rays
  ty_opt@centerDiffRMS = True               ; RMS 'circles'

  wks   = gsn_open_wks("pdf",CMIP_dir+"/plots/taylor_diagrams/test")
  plot  = taylor_diagram(wks,ratio,cc,ty_opt)

delete([/tas_CMIP5_normalized_std,tas_CMIP5_cor,CA_ratio,CA_cc,CB_ratio,CB_cc,CC_ratio,CC_cc,ratio,cc/])
end 

begin

do nn=0,1

tas_CMIP5_normalized_std=new((/5,40/),double)
tas_CMIP5_cor=new((/5,40/),double)

tas_CMIP5_std=dim_stddev(tas_CMIP5_fields)
tas_obs_std=dim_stddev(tas_obs_field)
printVarSummary(tas_CMIP5_std)
tas_CMIP5_normalized_std(nn,:)=tas_CMIP5_std/tas_obs_std
tas_CMIP5_cor(nn,:)=escorc(tas_CMIP5_fields,tas_obs_field)


end do


printVarSummary(tas_CMIP5_normalized_std)

; Cases [Model]
  case      = (/ "nino3 index anomaly", "global mean temp2 anomaly", "tropical Pacific precipitation anomaly" /) 
  nCase     = dimsizes(case )                 ; # of Cases [Cases]

; variables compared
  var       = model_names
  nVar      = dimsizes(var)                   ; # of Variables

; "Case A"                        
  CA_ratio   = tas_CMIP5_normalized_std(0,:)
  CA_cc      = tas_CMIP5_cor(0,:)
  print()

; "Case B" 
  CB_ratio   = tas_CMIP5_normalized_std(0,:)
  CB_cc      = tas_CMIP5_cor(0,:)
  
; "Case B" 
  CC_ratio   = tas_CMIP5_normalized_std(0,:)
  CC_cc      = tas_CMIP5_cor(0,:)

; arrays to be passed to taylor_diagram. It will calculate the x xnd y coordinates.
  ratio      = new ((/nCase, nVar/),typeof(CA_cc) )  
  cc         = new ((/nCase, nVar/),typeof(CA_cc) ) 

  ratio(0,:) = CA_ratio 
  ratio(1,:) = CB_ratio
  ratio(2,:) = CC_ratio

  cc(0,:)    = CA_cc 
  cc(1,:)    = CB_cc
  cc(2,:)    = CC_cc

;**********************************
; create plot
;**********************************
  varSource = var               ; add extra info [*not* required]

  ty_opt   = True                           ; taylor diagram with options
        
  ;ty_opt@Markers       = (/16, 16, 16/)         ; make all solid fill
  ty_opt@Colors        = (/"red", "blue", "green" /)          
  ty_opt@varLabels     = varSource
  ty_opt@caseLabels    = case

  ty_opt@varLabelsYloc = 1.5                ; Move location of variable labels [default 0.45]
  ty_opt@caseLabelsFontHeightF = 0.2       ; make slight larger   [default=0.12 ]
  ty_opt@varLabelsFontHeightF  = 0.01      ; make slight smaller  [default=0.013]
 
  ty_opt@tiMainString  = "Annual"           ; title
  ty_opt@stnRad        = (/ 0.5, 1.5 /)     ; additional standard radii
  ty_opt@ccRays        = (/ 0.6, 0.9 /)     ; correllation rays
  ty_opt@centerDiffRMS = True               ; RMS 'circles'

  wks   = gsn_open_wks("pdf",CMIP_dir+"/plots/taylor_diagrams/test_2")
  plot  = taylor_diagram(wks,ratio,cc,ty_opt)
  
end 