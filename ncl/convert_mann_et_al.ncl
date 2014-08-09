;*****************************************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
;*****************************************************************************************

begin

;data_dir="/Volumes/HiWi_data/CMIP/data/observations/Mann_et_al_2009/"
data_dir="/Users/stein/Documents/Uni/Master/HiWi/CMIP/data/observations/Mann_et_al_2009/"

data_file=data_dir+"allproxyfieldrecon"
lonlat_file=data_dir+"longlat"

ncols = numAsciiCol(data_file)
ncols_lonlat = numAsciiCol(lonlat_file)
data = readAsciiTable(data_file,ncols,"float",0)
lonlat = readAsciiTable(lonlat_file,ncols_lonlat,"float",0)
nrows = dimsizes(data(:,0))    ; calculate # of rows
nrows_lonlat = dimsizes(lonlat(:,0))    ; calculate # of rows

printVarSummary(data)
printVarSummary(lonlat)

mann_reconstruction=new((/36,72,1150/),"float")
lat=new((/36/),"float")
lon=new((/72/),"float")
time=new((/1150/),"float")

do tt=351,1500
	print(tt)
	time(tt-351)=data(tt,0)
	do jj=0,35
		do ii=0,71
			mann_reconstruction(jj,ii,tt-351)=data(tt,ii+(jj*72)+1)
			lon(ii)=lonlat(ii,0)
		end do
		lat(jj)=lonlat(jj*72,1)
	end do
end do


lat@long_name="latitude"
lat@units="degrees_north"
lat@axis="Y"

lon@long_name="longitude"
lon@units="degrees_east"
lon@axis="X"

time@units="years since 0-01-01 00:00:00"
time@long_name="time"

mann_reconstruction@long_name="Near-Surface Air Temperature"
mann_reconstruction@units="degC"


mann_reconstruction!0  =  "latitude"
mann_reconstruction!1  =  "longitude"


mann_reconstruction&latitude  =  lat
mann_reconstruction&longitude  =  lon

mann_reconstruction!2  =  "time"
mann_reconstruction&time  =  time

mann_reconstruction_ordered=mann_reconstruction(time|:,latitude|:,longitude|:)

asciiwrite (data_dir+"/ascii_table", mann_reconstruction_ordered)

printVarSummary(mann_reconstruction_ordered)


print(lon)
print(lat)
print(time)

printVarSummary(mann_reconstruction_ordered)

system("/bin/rm -f "+data_dir+"mann2009_reconstruction_0851-2000.nc")   ; remove any pre-existing file
ncdf     = addfile(data_dir+"mann2009_reconstruction_0851-2000.nc" ,"c")  ; open output netCDF file

nlon =  72
nlat = 36
ntim =  -1

  dim_names = (/ "latitude",  "longitude", "time" /)
  dim_sizes = (/ nlat ,  nlon ,  ntim  /)
  dimUnlim = (/ False , False ,  True  /)
  filedimdef( ncdf, dim_names, dim_sizes, dimUnlim )
  
  


;output variables directly
 ncdf->tas  = mann_reconstruction_ordered        

			

end

