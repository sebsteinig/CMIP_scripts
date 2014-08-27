begin

; detect CMIP directory
wd = systemfunc("pwd")
dir_split = str_split(wd, "/") 
CMIP_dir=str_concat("/"+dir_split(0:dimsizes(dir_split)-3))

print("The current working directory is: "+(CMIP_dir(0)))

; load data
data_dir=CMIP_dir+"/data/TSI/Steinhilber_2009/"

f=data_dir+"grl26405-sup-0002-ds01.txt"

ncols = numAsciiCol(f)
nrows = numAsciiRow(f)
data = asciiread(f,(/nrows,ncols/),"float")

time_tmp=data(:,0)
time=(time_tmp-1950)*(-1) ; original time axis was: years before 1950
copy_VarMeta(time_tmp,time)
time@long_name="time"
time@units="Years since 0000-01-01"

TSI=data(:,1)+1365.57 ; original values were: anomalies to value from year 1986 (1365.57 W/m2)
TSI!0="time"
TSI&time=time
TSI@long_name="Total Solar Insolation"
TSI@units="W/m^2"

TSI_err=data(:,2)
TSI_err!0="time"
TSI_err&time=time
TSI_err@long_name="Estimated 1-Sigma Error in Total Solar Insolation"
TSI_err@units="W/m^2"

; save variables as netcdf file
system("/bin/rm -f "+CMIP_dir+"/data/TSI/Steinhilber_2009/TSI_Holocene_Steinhilber_2009.nc")   ; remove any pre-existing file
ncdf     = addfile(CMIP_dir+"/data/TSI/Steinhilber_2009/TSI_Holocene_Steinhilber_2009.nc","c")  ; open output netCDF file

; create unlimited time axis
dim_names = (/ "time" /)
dim_sizes = (/ -1 /)
dimUnlim = (/ True /)
filedimdef( ncdf, dim_names, dim_sizes, dimUnlim )
  
;output variables directly
ncdf->TSI  = TSI
ncdf->TSI_err  = TSI_err
 
end

