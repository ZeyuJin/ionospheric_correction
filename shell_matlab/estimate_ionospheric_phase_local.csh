#!/bin/csh -f
#	$id$
# Written by Xiaohua (Eric) Xu first, using split spectrum method
# Modified by Zeyu Jin next, using non-isotropic filter instead of rectangular filter
# Apply linear trend first to interpolate NaNs, then apply nearest neighbour interpolation
# to recover the non-linear pattern of ionospheric phase
#
# alias matlab='/Applications/MATLAB_R2020a.app/bin/matlab -nojvm -nodesktop'
# in your ~/.bashrc file

if ($#argv != 4 && $#argv != 6) then
  echo ""
  echo "Usage: estimate_ionospheric_phase.csh intf_high intf_low intf_orig intf_to_be_corrected [xratio yratio]"
  echo ""
  echo " estimate ionosphere based on split spectrum method in Gomba et. al. 2016"
  echo " with filtering method in Fattahi et. al. 2017"
  echo ""
  echo "Example: estimate_ionospheric_phase.csh ../iono_phase/intf_h ../iono_phase/intf_l ../iono_phase/intf_o"
  echo ""
  exit 1
endif

set intfH = $1
set intfL = $2
set intfO = $3
set intf = $4
set pair =  `echo $intfH | awk -F'/' '{print $NF}'`
cd $pair  # be careful with the relative path

if ($#argv == 3) then
  set rx = 1
  set ry = 1
else
  set rx = $5
  set ry = $6
endif
set prm1 = `ls $intfH/*PRM | head -1`
set prm2 = `ls $intfH/*PRM | tail -1`

set fc = `grep center_freq $intfH/params1 | awk '{print $3}'`
set fh = `grep high_freq $intfH/params1 | awk '{print $3}'`
set fl = `grep low_freq $intfH/params1 | awk '{print $3}'`
set thresh = 0.15
# set MATLAB = /nasa/matlab/2017b

echo "Applying split spectrum result to estimate ionospheric phase ($fh $fl)..."

cp $intf/phasefilt.grd ./ph0.grd

# determine how much filtering is needed
# there is one bug of path previously
set wavelengh = 20000
set rng_pxl = `grep rng_samp_rate $prm1 | head -1 | awk '{printf("%.6f\n",299792458.0/$3/2.0)}'`
set prf = `grep PRF $prm1 | awk '{print $3}'`
set vel = `grep SC_vel $prm1 | awk '{print $3}'`
set azi_pxl = `echo $vel $prf | head -1 | awk '{printf("%.6f\n",$1/$2)}'`
#gmt grdinfo $intfH/phasefilt.grd -C
set x_inc = `gmt grdinfo $intfH/phasefilt.grd -C | awk '{print $8}'`
set y_inc = `gmt grdinfo $intfH/phasefilt.grd -C | awk '{print $9}'`
#echo $wavelengh $rng_pxl $x_inc $rx
#echo $wavelengh $azi_pxl $y_inc $ry
set filtx = `echo $wavelengh $rng_pxl $x_inc $rx | awk '{print int($1*$4/$2/$3/2)*2+1}'`
set filty = `echo $wavelengh $azi_pxl $y_inc $ry | awk '{print int($1*$4/$2/$3/2)*2+1}'`
set filt_incx = `echo $filtx | awk '{print int($1/8)}'`
set filt_incy = `echo $filty | awk '{print int($1/8)}'`
echo "Filtering size is set to $filtx along range and $filty along azimuth ..."

set limit = `echo $fh $fl | awk '{printf("%.3f",$1*$2/($1*$1-$2*$2)*3.1415926)}'`

# start ionospheric phase estimate
cp $intfH/unwrap.grd ./up_h.grd
cp $intfL/unwrap.grd ./up_l.grd
cp $intfO/unwrap.grd ./up_o.grd


# correct for unwrapping errors
gmt grdmath up_h.grd up_o.grd SUB = tmp.grd
set ch = `gmt grdinfo tmp.grd -L1 -C |  awk '{if ($12 >=0) printf("%d\n",int($12/6.2831853072+0.5)); else printf("%d\n",int($12/6.2831853072-0.5))}'`
echo "Correcting high passed phase by $ch * 2PI ..."
gmt grdmath up_h.grd $ch 2 PI MUL MUL SUB = tmp.grd
mv tmp.grd up_h.grd
gmt grdmath up_l.grd up_o.grd SUB = tmp.grd
set cl = `gmt grdinfo tmp.grd -L1 -C |  awk '{if ($12 >=0) printf("%d\n",int($12/6.2831853072+0.5)); else printf("%d\n",int($12/6.2831853072-0.5))}'`
echo "Correcting high passed phase by $cl * 2PI ..."
gmt grdmath up_l.grd $cl 2 PI MUL MUL SUB = tmp.grd
mv tmp.grd up_l.grd


gmt grdmath $intfH/corr.grd $intfL/corr.grd ADD 2 DIV 0 DENAN $thresh GE 0 NAN 0 MUL 1 ADD = mask.grd
gmt grdmath $intfH/corr.grd $intfL/corr.grd ADD 2 DIV 0 DENAN $thresh GE 0 NAN ISNAN 1 SUB -1 MUL = mask1.grd
gmt grdmath mask1.grd 1 SUB -1 MUL = mask2.grd

# split-spectrum method
gmt grdmath $fh $fc DIV up_l.grd MUL $fl $fc DIV up_h.grd MUL SUB $fl $fh MUL $fh $fh MUL $fl $fl MUL SUB DIV MUL = tmp_ph0.grd
# run_correct_subswath_multiple.sh $MATLAB tmp_ph0.grd 30 220  # remove the discontinuity at the boundary
/Applications/MATLAB_R2020a.app/bin/matlab -nojvm -nodesktop  -r  "correct_subswath_local('tmp_ph0.grd', 30, 200); quit"
gmt grdedit ph_correct.grd -T -Gtmp_ph0.grd        # convert the gridline node to pixel node
rm -f ph_correct.grd
# exit 1

gmt grdmath tmp_ph0.grd mask.grd MUL = tmp_ph.grd
cp tmp_ph.grd tmp_ph1.grd

set mm = `gmt grdinfo tmp_ph1.grd -L1 -C | awk '{print $12}'`

gmt grdmath tmp_ph0.grd $mm $limit ADD LE = tmp1.grd 
gmt grdmath tmp_ph0.grd $mm $limit SUB GE = tmp2.grd
gmt grdmath tmp1.grd tmp2.grd MUL 0 NAN mask.grd MUL = tmp.grd
mv tmp.grd mask.grd
gmt grdmath tmp1.grd tmp2.grd MUL 0 NAN ISNAN 1 SUB -1 MUL mask1.grd MUL 0 DENAN = tmp.grd
mv tmp.grd mask1.grd
gmt grdmath tmp_ph0.grd mask.grd MUL = tmp_ph.grd
gmt grdmath mask1.grd 1 SUB -1 MUL = mask2.grd

# nearest_grid tmp_ph.grd tmp_ph_interp.grd
# run_linear_extrapolate.sh $MATLAB tmp_ph.grd tmp_ph_interp.grd   # use linear interpolation instead
/Applications/MATLAB_R2020a.app/bin/matlab -nojvm -nodesktop  -r  "linear_extrapolate('tmp_ph.grd', 'tmp_ph_interp.grd'); quit"
gmt grdedit tmp_ph_interp.grd -T -Gtmp_ph_interp.grd

# iterative interpolation and filtering
#foreach iteration (1 2 3 4 5 ) 
foreach iteration (1 2 3) 
  set odd = `echo $iteration | awk '{if ($1%2==0) print 0;else print 1}'`
  if ($odd == 1) then
    gmt grdfilter tmp_ph_interp.grd -Dp -Fm$filtx/$filty -Gtmp_filt.grd -V -Ni -I$filt_incx/$filt_incy
  else
    # anistropic gaussian filter instead of rectangular filter
    # run_gauss15x3_filter.sh $MATLAB $filtx $filty  
    /Applications/MATLAB_R2020a.app/bin/matlab -nojvm -nodesktop  -r  "gauss_filter($filtx, $filty, 0, 'tmp_ph_interp.grd', 'ph_filt.grd'); quit"
    gmt grdedit ph_filt.grd -T -Gtmp_filt.grd
  endif

  gmt grd2xyz tmp_filt.grd -s | gmt surface -Rtmp_ph0.grd -T0.5 -Gtmp.grd
  mv tmp.grd tmp_filt.grd
  cp tmp_filt.grd tmp_$iteration.grd
  gmt grdmath tmp_filt.grd mask.grd MUL = tmp.grd
  # nearest_grid tmp.grd tmp2.grd
  /Applications/MATLAB_R2020a.app/bin/matlab -nojvm -nodesktop  -r  "linear_extrapolate('tmp.grd', 'tmp2.grd'); quit"
  gmt grdedit tmp2.grd -T -Gtmp2.grd 
  gmt grdmath tmp2.grd mask2.grd MUL tmp_ph0.grd 0 DENAN mask1.grd MUL ADD = tmp_ph_interp.grd
#exit 1
end

# last filter step
/Applications/MATLAB_R2020a.app/bin/matlab -nojvm -nodesktop  -r  "gauss_filter($filtx, $filty, 0, 'tmp_ph_interp.grd', 'ph_filt.grd'); quit"
gmt grdedit ph_filt.grd -T -Gtmp_filt.grd

gmt grdmath tmp_filt.grd PI ADD 2 PI MUL MOD PI SUB = tmp_ph.grd
cp tmp_ph.grd ph_iono.grd


gmt grdsample tmp_filt.grd -Rph0.grd -Gtmp.grd
gmt grdmath ph0.grd tmp.grd SUB PI ADD 2 PI MUL MOD PI SUB = ph_corrected.grd

set cc = `gmt grdinfo ph_corrected.grd -L1 -C |  awk '{if ($12 >=0) printf("%d\n",int($12/3.141592653+0.5)); else printf("%d\n",int($12/3.141592653-0.5))}'`
echo "Correcting iono phase by $cc PI ..."
gmt grdmath tmp_filt.grd $cc PI MUL ADD = tmp_ph.grd
gmt grdmath tmp_ph.grd PI ADD 2 PI MUL MOD PI SUB = ph_iono.grd

gmt grdsample tmp_ph.grd -Rph0.grd -Gtmp.grd
gmt grdmath ph0.grd tmp.grd SUB PI ADD 2 PI MUL MOD PI SUB = ph_corrected.grd
mv tmp_ph.grd ph_iono_orig.grd

cd ..
