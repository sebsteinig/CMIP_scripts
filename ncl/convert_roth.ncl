begin

; detect CMIP directory
wd = systemfunc("pwd")
dir_split = str_split(wd, "/") 
CMIP_dir=str_concat("/"+dir_split(0:dimsizes(dir_split)-3))

print("The current working directory is: "+(CMIP_dir(0)))

; load data
data_dir=CMIP_dir+"/data/TSI/Roth_and_Joos_2013/"

f=data_dir+"ROTH_AND_JOOS_CP2013.dat"

ncols = numAsciiCol(f)
nrows = numAsciiRow(f)
data = asciiread(f,(/nrows,ncols/),"float")
data@_FillValue = 1E30

printVarSummary(data)

time=data(:,0)
time@long_name="time"
time@units="Years since 0000-01-01"

Q=data(:,1)
Q!0="time"
Q&time=time
Q@long_name="Radiocarbon Production"
Q@units="mol/yr"

Q_err=data(:,2)
Q_err!0="time"
Q_err&time=time
Q_err@long_name="Estimated Error in Radiocarbon Production"
Q_err@units="mol/yr"

PHI=data(:,3)
PHI!0="time"
PHI&time=time
PHI@long_name="Solar Modulation Potential"
PHI@units="mol/yr"

PHI_err=data(:,4)
PHI_err!0="time"
PHI_err&time=time
PHI_err@long_name="Estimated Error in Solar Modulation Potential"
PHI_err@units="mol/yr"

TSI=data(:,5)
TSI!0="time"
TSI&time=time
TSI@long_name="Total Solar Insolation"
TSI@units="W/m^2"

TSI_err=data(:,6)
TSI_err!0="time"
TSI_err&time=time
TSI_err@long_name="Estimated Error in Total Solar Insolation"
TSI_err@units="W/m^2"

delta_SAT=data(:,7)
delta_SAT!0="time"
delta_SAT&time=time
delta_SAT@long_name="Difference in global mean SAT between full forcing and control run"
delta_SAT@units="K"


; save variables as netcdf file
system("/bin/rm -f "+CMIP_dir+"/data/TSI/Roth_and_Joos_2013/TSI_Holocene_Roth_and_Joos_2013.nc")   ; remove any pre-existing file
ncdf     = addfile(CMIP_dir+"/data/TSI/Roth_and_Joos_2013/TSI_Holocene_Roth_and_Joos_2013.nc","c")  ; open output netCDF file

; create unlimited time axis
dim_names = (/ "time" /)
dim_sizes = (/ -1 /)
dimUnlim = (/ True /)
filedimdef( ncdf, dim_names, dim_sizes, dimUnlim )
  
;output variables directly
ncdf->Q  = Q
ncdf->Q_err  = Q_err
ncdf->PHI  = PHI
ncdf->PHI_err  = PHI_err 
ncdf->TSI  = TSI
ncdf->TSI_err  = TSI_err
ncdf->delta_SAT  = delta_SAT
 
end

