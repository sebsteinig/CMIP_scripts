begin

; detect CMIP directory
wd = systemfunc("pwd")
dir_split = str_split(wd, "/") 
CMIP_dir=str_concat("/"+dir_split(0:dimsizes(dir_split)-3))

print("The current working directory is: "+(CMIP_dir(0)))

; load data
data_dir=CMIP_dir+"/data/TSI/Vieira_2011/"

f=data_dir+"tsi_hol.txt"

ncols = numAsciiCol(f)
nrows = numAsciiRow(f)
data = asciiread(f,(/nrows,ncols/),"float")
data@_FillValue = -9999.90000

Year=tointeger(data(:,0))
Year@long_name="Year"
Month=tointeger(data(:,1))
Month@long_name="Month"
Day=tointeger(data(:,2))
Day@long_name="Day"

Hour=new((/dimsizes(Year)/),"integer")
Minute=new((/dimsizes(Year)/),"integer")
Second=new((/dimsizes(Year)/),"integer")
Hour=0
Minute=0
Second=0

; create time axis as "days since year 0"
time_tmp=cd_inv_calendar(Year,Month,Day,Hour,Minute,Second,"Days since 0000-01-01", 0)
time=doubletofloat(time_tmp)
copy_VarMeta(time_tmp,time)
time@long_name="time"

TSI=data(:,3)
TSI!0="time"
TSI&time=time
TSI@long_name="Irradiance (W/m^2)"
TSI@units="W/m^2"

TSI_decadal=data(:,4)
TSI_decadal!0="time"
TSI_decadal&time=time
TSI_decadal@long_name="Irradiance (10-year running after 1640 (W/m^2)"
TSI_decadal@units="W/m^2"

error=data(:,5)
error!0="time"
error&time=time
error@long_name="1-sigma error (W/m^2)"
error@units="W/m^2"

model=data(:,6)
model!0="time"
model&time=time
model@long_name="Model (3=SAT-M, 2=SAT-T, 1=SAT-S, 9=NA)"


; save variables as netcdf file
system("/bin/rm -f "+CMIP_dir+"/data/TSI/Vieira_2011/TSI_Holocene_Vieira_et_al_2011.nc")   ; remove any pre-existing file
ncdf     = addfile(CMIP_dir+"/data/TSI/Vieira_2011/TSI_Holocene_Vieira_et_al_2011.nc","c")  ; open output netCDF file

; create unlimited time axis
dim_names = (/ "time" /)
dim_sizes = (/ -1 /)
dimUnlim = (/ True /)
filedimdef( ncdf, dim_names, dim_sizes, dimUnlim )
  
;output variables directly
ncdf->TSI  = TSI 
ncdf->TSI_10_year_mean  = TSI_decadal
ncdf->1_sigma_error  = error
ncdf->model_number  = model 
 
end

