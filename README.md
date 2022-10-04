# ionospheric_correction

We use the split-spectrum method (Gomba etal., 2015; Heresh et al., 2017) to correct ionospheric noise

$$ \Delta \hat{\phi}_{iono} = \frac{f_L f_H}{f_0 (f^2_H - f^2_L)}(\Delta \phi_L f_H - \Delta \phi_H f_L) $$

Because ALOS-2 data has a narrow bandwidth ($f_H - f_L$) compared to its central frequency ($f_0$), 
for instance, $f_0 = 1.24$ GHz, but the bandwith is 4 MHz, the correction formula would amplify the noise in the interferogram.

To solve this issue, not only do we need a large filter, but also rule out pixels whose amplitude is too large after the correction.

The command to correct ionospheric noise:
```
cd iono_correction

estimate_ionospheric_phase_local.csh  ../../intf_h/20160518_20161019  ../../intf_l/20160518_20161019  
../../intf_o/20160518_20161019  ../../20160518_20161019  0.82  7.5
```
The last two parameters denote the filter wavelength ratio along range and azimuth directions.

Plot the comparison between original and corrected interferogram:
```
plot_iono.csh  20160518_20161019
```
It generates a figure named with "iono_correct.pdf"

<p align="center">
  <img src="iono_correction/plots/coseismic.jpg">
  <img src="iono_correction/plots/posteismic.jpg">
</p>
