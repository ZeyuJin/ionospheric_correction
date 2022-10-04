function correct_subswath_local(grdfile, width, thres)
    % width represents # of pixels to average the difference
    % between each subswath
    % thres represents # of radians as a threshold to throw out
    % noisy pixels whose amplitude > threshold (most tricky part)

    % boundary.txt saves the # of pixels for each subswath along range
    % can be generated when merge the swaths
    if ~exist('boundary.txt','file')
        disp('The boundary file does not exist!');
        return;
    end

    [range,azimuth,phase] = grdread2(grdfile);
    boundary = dlmread('boundary.txt');
    b1 = boundary(1);  b2 = boundary(2);
    L = length(boundary);
    if L == 3
       b3 = boundary(3);
    elseif L == 4
       b4 = boundary(4);
    end
    % width = 30;  % number of columns to find the median value at the boundary

    % assume at least 3 subswaths for ALOS-2 interferogram
    ph1 = reshape(phase(:,b1-width:b1),1,[]);
    ph2 = reshape(phase(:,b1+1:b1+1+width),1,[]);
    offset1 = nanmedian(ph1) - nanmedian(ph2);   % subswath F1 - F2

    ph3 = reshape(phase(:,b2-width:b2),1,[]);
    ph4 = reshape(phase(:,b2+1:b2+1+width),1,[]);
    offset2 = nanmedian(ph4) - nanmedian(ph3);   % subswath F3 - F2

    if (L == 3 || L == 4) 
       ph5 = reshape(phase(:,b3-width:b3),1,[]);
       ph6 = reshape(phase(:,b3+1:b3+1+width),1,[]);
       offset3 = nanmedian(ph6) - nanmedian(ph5);   % subswath F4 - F3
    elseif (L == 4)
       ph7 = reshape(phase(:,b4-width:b4),1,[]);
       ph8 = reshape(phase(:,b4+1:b4+1+width),1,[]);
       offset4 = nanmedian(ph8) - nanmedian(ph7);   % subswath F5 - F4
    end

    ph_tmp1 = phase(:,1:b1) - offset1;
    ph_tmp2 = phase(:,b2+1:end) - offset2;
    ph_new = [ph_tmp1,phase(:,b1+1:b2),ph_tmp2];
    clear ph_tmp1 ph_tmp2
   
    if L == 3 || L == 4
       ph_tmp3 = ph_new(:,b3+1:end) - offset3;
       ph_new = [ph_new(:,1:b3),ph_tmp3];
       clear ph_tmp3
    elseif L == 4
       ph_tmp4 = ph_new(:,b4+1:end) - offset4;
       ph_new = [ph_new(:,1:b4),ph_tmp4];
       clear ph_tmp4
    end

    % set unwrapping errors to NaNs
    tmp = reshape(ph_new,1,[]);
    ph0 = nanmedian(tmp);
    clear tmp
    ph_new(abs(ph_new-ph0)>thres) = NaN;
    ph_corr = ph_new;

    % write to grd file
    if exist('ph_correct.grd','file') == 2
        delete('ph_correct.grd');
    end
    grdwrite2(range,azimuth,ph_corr,'ph_correct.grd');
end
