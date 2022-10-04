function linear_extrapolate(grdin,grdout)

   [range,azimuth,phase] = grdread2(grdin);
   phase = double(phase);
   
   [xo,yo] = meshgrid(range,azimuth);
   x = xo(~isnan(phase));
   y = yo(~isnan(phase));
   ph_raw = phase(~isnan(phase));
   
   % invert parameters of linear trend
   G = [ones(size(x)),x,y];
   p = G \ ph_raw; % 3x1 column
   
   % use linear trend to interpolate nan area phase
   % better than neareast neighboring interpolation
   x_nan = xo(isnan(phase));
   y_nan = yo(isnan(phase));
   ph_nan = [ones(size(x_nan)),x_nan,y_nan] * p;
   tmp = phase;
   tmp(isnan(tmp)) = ph_nan;
   
   if exist(grdout,'file') == 2
       delete(grdout);
   end
   grdwrite2(range,azimuth,tmp,grdout);

end
