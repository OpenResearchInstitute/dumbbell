function helperAnimateEHFields(obj,f,SpatialInfo, TimeInfo, DataInfo)
%byfunction helperAnimateEHFields(obj,f,SpatialInfo, TimeInfo, DataInfo)
%%original

% helperAnimateEHFields Animates Electric and Magnetic Fields 
%
% This is a helper function for example purposes and may be removed or
% modified in the future.
%
% helperAnimateEHFields calculates and animates the electric and magnetic
% fields at the frequency f, over the region of space identified in the
% structure SpatialInfo, for a given duration of time provided in the
% structure TimeInfo. Use the DataInfo structure to select the component
% to animate and scale appropriately.
%

% Copyright 2023 The MathWorks, Inc.

% Unpack Spatial Information
Xspan = SpatialInfo.XSpan;
Yspan = SpatialInfo.YSpan;
Zspan = SpatialInfo.ZSpan;
Nx = SpatialInfo.NumPointsX;
Ny = SpatialInfo.NumPointsY;
Nz = SpatialInfo.NumPointsZ;

% Create grid
delta_x = Xspan/(Nx-1);
delta_y = Yspan/(Ny-1);
delta_z = Zspan/(Nz-1);
X       = (0:Nx-1).*delta_x;
X       = X - Xspan/2;
Y       = (0:Ny-1).*delta_y;
Y       = Y - Yspan/2;
Z       = (0:Nz-1).*delta_z;
Z       = Z - Zspan/2;
plane = DataInfo.PlotPlane;
% Check if Spatial inputs and Plane selection are inconsistent
if isempty(Xspan)&& ~any(strcmpi(plane,{'YZ','ZY'})) || ...
   isempty(Yspan)&& ~any(strcmpi(plane,{'XZ','ZX'})) || ...
   isempty(Zspan)&& ~any(strcmpi(plane,{'XY','YX'}))
    error('SpatialInfo inputs and Plot plane are inconsistent');
end

switch plane
    case 'XY'
        [xm,ym] = meshgrid(X,Y);
        x       = xm(:);
        y       = ym(:);
        zslice   = 0;
        z       = zslice.*ones(numel(x),1);  
        dim1 = xm;
        dim2 = ym;
        dim3 = reshape(z,size(xm));
        az = 0;
        el = 90;
    case 'YZ'
        [ym,zm] = meshgrid(Y,Z);
        y       = ym(:);
        z       = zm(:);
        xslice  = 0; 
        x       = xslice.*ones(numel(y),1);
        dim2 = ym;
        dim3 = zm;
        dim1 = reshape(x,size(ym)); 
        az = 90;
        el = 0;
    case 'XZ'
        [xm,zm] = meshgrid(X,Z);
        x       = xm(:);
        z       = zm(:);
        yslice  = 0; 
        y       = yslice.*ones(numel(x),1);
        dim1 = xm;
        dim3 = zm;
        dim2 = reshape(y,size(xm));
        az = 0;
        el = 0;
    case other
        error('Incorrect plane specified');
end

% Steady state
points = [x y z]';
[E,H] = EHfields(obj,f,points);
[P,t] = exportMesh(obj);
TR = triangulation(t(:,1:3),P);

% Unpack Time Information
T = TimeInfo.TotalTime;
ts = TimeInfo.SamplingTime;
% Check if empty and assign 1/10*f
if isempty(ts)
    fs = 10*f;
    ts = 1/fs;
end

% Data Information to Plot
datacomponent = DataInfo.Component;
if strcmpi(datacomponent(1),'E')
    fieldMatrix = E;
    titlestr = 'Electric Field';
elseif strcmpi(datacomponent(1),'H')
    fieldMatrix = H;
    titlestr = 'Magnetic Field';
else
    error('Unsupported Field Type');
end
if any(strcmpi(datacomponent,{'Ex','Hx'}))
    indx = 1;
elseif any(strcmpi(datacomponent,{'Ey','Hy'}))
    indx = 2;
elseif any(strcmpi(datacomponent,{'Ez','Hz'}))
    indx = 3;
else
    error('Unsupported field component');
end
datalim = DataInfo.DataLimits;
A = DataInfo.ScaleFactor;

% Set-up time harmonic
omega = 2*pi*f;
N = ceil(T/ts);
F_rt = reshape(real(fieldMatrix(indx,:)),size(dim1,1),size(dim1,2));
F_rtn = A.*F_rt;
h1 = figure;
htr = trisurf(TR);
htr.FaceColor = "#EDB120";
htr.EdgeColor = [0 0 0]; %flat";
hold on;
s = surf(dim1,dim2,dim3,real(F_rtn));
if ~isempty(datalim)
    clim(datalim);
end
s.XDataSource = 'dim1';
s.YDataSource = 'dim2';
s.ZDataSource = 'dim3'; 
s.CDataSource = 'F_rtn';
s.FaceColor = "interp";
s.EdgeColor = "interp";
colormap(s.Parent,'hsv')   %was jet colormap (try hsv)
% shading interp
axis tight
xlabel('X (m)')
ylabel('Y (m)')
zlabel('Z (m)')
title([titlestr, '-', datacomponent])
grid on
view(az,el)
shg
axis equal
n = 0;
while n<N
    wT = omega.*n*ts;
    propagator = exp(1i*wT);
    n = n+1;
    % Compute the resultant at each node
    Ft = fieldMatrix.*propagator;
    F_rt = real(Ft);
    F_rt = reshape(F_rt(indx,:),size(dim1,1),size(dim1,2));
    F_rtn = A.*F_rt;
    refreshdata(s,'caller');
    drawnow
    frame = getframe(h1);
    im{n} = frame2im(frame);
end

% Save to gif
filename = DataInfo.GifFileName;
if ~isempty(filename)
    for idx = 1:N
        [A,map] = rgb2ind(im{idx},256);
        if idx == 1
            imwrite(A,map,filename,"gif","LoopCount",Inf,"DelayTime",0);
        else
            imwrite(A,map,filename,"gif","WriteMode","append","DelayTime",0);
        end
    end
end

% Close figure
if DataInfo.CloseFigure
    close(h1);
end