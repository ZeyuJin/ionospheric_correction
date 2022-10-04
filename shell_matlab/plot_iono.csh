#!/bin/csh -f

if ($#argv != 1) then
   echo ""
   echo "plot_iono.csh dates.pair"
   echo ""
   exit 1
endif

set pair = $1
cd $pair

rm -f gmt.* *.ps iono_correct.pdf
unset noclobber
gmt gmtset IO_SEGMENT_MARKER '370'
gmt gmtset FONT_ANNOT_PRIMARY 14p
gmt gmtset FONT_TITLE 15p
gmt gmtset PS_MEDIA A3

set west = `gmt grdinfo ph0.grd -C | awk '{print $2}'`
set east = `gmt grdinfo ph0.grd -C | awk '{print $3}'`
set south = `gmt grdinfo ph0.grd -C | awk '{print $4}'`
set north = `gmt grdinfo ph0.grd -C | awk '{print $5}'`

set SIZE = 3.35i
# set XSHIFT = -6.7i

gmt psbasemap -JX$SIZE -R$west/$east/$south/$north -Ba4000:"Range":/a50000:"Azimuth":WSen:."Uncorrected": -X0.805i -Y5i -P -K > iono_correct.ps
gmt makecpt -Crainbow -T-3.15/3.15/0.1 -Z -N > phase.cpt
gmt grdimage -O -JX -R ph0.grd -Cphase.cpt -P -Q -K >> iono_correct.ps
gmt psscale -O -Dx4/-1.8/6/0.2h -Cphase.cpt -Bxa1.57+l"Phase" -By+lrad -K >> iono_correct.ps

gmt psbasemap -O -JX$SIZE -R$west/$east/$south/$north -Ba4000:"Range":/a50000:"":wSen:."Iono Phase": -X$SIZE -Y0i -P -K >> iono_correct.ps
gmt grdimage -O -JX -R ph_iono.grd -Cphase.cpt -P -Q -K >> iono_correct.ps
gmt psscale -O -Dx4/-1.8/6/0.2h -Cphase.cpt -Bxa1.57+l"Phase" -By+lrad -K >> iono_correct.ps

gmt psbasemap -O -JX$SIZE -R$west/$east/$south/$north -Ba4000:"Range":/a50000:"":wSEn:."Corrected": -X$SIZE -Y0i -P -K >> iono_correct.ps
gmt grdimage -O -JX -R ph_corrected.grd -Cphase.cpt -P -Q -K >> iono_correct.ps
gmt psscale -O -Dx4/-1.8/6/0.2h -Cphase.cpt -Bxa1.57+l"Phase" -By+lrad >> iono_correct.ps

gmt psconvert -Tf -P -Z iono_correct.ps

cd ..
