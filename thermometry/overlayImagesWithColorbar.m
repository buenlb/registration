% Overlays an intensity image in color over a gray scale image. For
% example, you can overlay a simulation on a medical image.
% 
% @INPUTS
%   gImg: Grayscale image (MxN matrix)
%   cImg: intensity image (MxN matrix). This will be converted into a true
%       color image and overlaid on gImg
%   handle: handle to figure on which to generate the image
%   xAx: Nx2 vector containing x-limits of image
%   yAx: Nx2 vector containing y-limits of image
%   threshold: Selects which values of cImg to display. Anything less than
%       threshold will be set to full transparency and will therefore be
%       invisible
%   window: Optional input specifying a window for the gray image data
% 
% @OUTPUTS
%   none
% 
% Taylor Webb
% University of Utah
% Summer 2019

function [ax,ax2,clBar] = overlayImagesWithColorbar(gImg,cImg,handle,xAx,yAx,threshold,window,cWindow)
figure(handle);

if nargin < 7
    window = [min(gImg(:)),max(gImg(:))];
    cWindow = [min(cImg(:)),max(cImg(:))];
elseif nargin < 8
    cWindow = [min(cImg(:)),max(cImg(:))];
end

if isempty(window)
    window = [min(gImg(:)),max(gImg(:))];
end

% Display the gray scale image
imagesc(xAx,yAx,gImg,window);
ax = gca;
colormap(ax,'gray')
axis('equal')

% Display the color image
ax2 = axes();
cHandle = imagesc(xAx,yAx,cImg,cWindow);
colormap(ax2,'hot');
axis('equal');
aData = zeros(size(cImg));
aData(cImg > threshold) = 0.8;
set(cHandle,'AlphaData',aData);

ax2.Visible = 'off';
linkprop([ax ax2],'Position');
clBar = colorbar(ax2,'EastOutside');
c2Bar = colorbar(ax,'EastOutside');
set(c2Bar,'TickLabels',{})