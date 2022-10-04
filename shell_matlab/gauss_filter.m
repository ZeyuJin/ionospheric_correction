function gauss_filter(nx, ny, theta, input_grid, output_grid) 
   % nx, ny is the size of gaussian filter
   % theta define its strike angle (generally use 0)

   % construct Gaussian filter 
   cost = cosd(theta);
   sint = sind(theta);
   sigx=floor(nx / 6.0);  % not hard-coded in the future
   sigy=floor(ny / 6.0);

   x=((-nx/2:(nx/2-1))+.5)/sigx;
   y=((-ny/2:(ny/2-1))+.5)/sigy;
   [x,y] = meshgrid(x,y);
   x2=(x*cost - y*sint).^2;  % rotation matrix
   y2=(x*sint + y*cost).^2;  
   r2 = x2 + y2;
   gauss=exp(-.5*r2);
   
   % read file
   [range,azimuth,phase] = grdread2(input_grid);
%    [range,azimuth,phase] = grdread2('tmp_ph_interp.grd');
   
   % non-isotropic filter
   ph_filt = nanconv(phase,gauss,'edge');
   
   % save to file
   if exist(output_grid,'file') == 2
       delete(output_grid);
   end
   grdwrite2(range,azimuth,ph_filt,output_grid);
   
%    if exist('ph_filt.grd','file') == 2
%        delete('ph_filt.grd');
%    end
%    grdwrite2(range,azimuth,ph_filt,'ph_filt.grd');

end
