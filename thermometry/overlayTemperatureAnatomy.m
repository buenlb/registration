% Overlays thermometry data on a different anatomical MR image. Uses the
% headers to align the data automatically.
% 
% @INPUTS
%   sys: Struct containing the following fields
%     @MANDATORY FIELDS
%       anatomyPath: Directory in which Anatomical MR images are stored
%       thermPath: Directory in which thermometry images are held
%       thermMagPath: Directory in which magnitude images corresponding to
%         thermometry phase images are found.
%     @OPTIONAL FIELDS
%       baseline: Baseline images in thermometry data set - defaults to 1
%       focus: focus in MR coordinates. This dictates which slice is shown.
%          If not provided then the function prompts the user to select one
%          using a GUI that shows the temperature results.
%   sonicationNo: Number of sonication to reconstruct
% @OUTPUTS
%   sys: Struct with the above fields and the addition of the following
%     fields
%       @Fields
%           aImg: Anatomy Image
%           tImg: phase image that has zeros where there is low magnitude
%           ax, ay, and az: x, y, and z axes of the anatomy Image in MR
%              coords
%           tx, ty, and tz: x, y, and z axes of the thermometry Image in MR
%              coords
%           T: Temperature results - zero where there is low magnitude
%           tInterp: Temperature results interpolated onto the anatomy
%              image dataset

% 
% Taylor Webb
% University of Utah

function sys = overlayTemperatureAnatomy(sys,sonicationNo,plotResults)
% if no sonication number is provided, default to the last one
if nargin < 2
    sonicationNo = length(sys.sonication);
    plotResults = 0;
elseif nargin < 3
    plotResults = 0;
end
%% Set baseline default if no baseline is provided
if ~isfield(sys,'baseline')
    sys.baseline = 1;
end

%% Anatomical Data
if ~isfield(sys,'aImg')
    disp('Reloading anatomical Image.')
    [aImg,aHeader] = loadDicomDir([sys.mrPath,num2str(sys.aSeriesNo,'%03d')]);
    [ax,ay,az,~,aDimOrder] = findMrCoordinates(aHeader);
    dimOrderTx = [aDimOrder(1),aDimOrder(3),aDimOrder(2)];
    sys.aImg = permute(aImg,dimOrderTx);
else
    ax = sys.ax;
    ay = sys.ay;
    az = sys.az;
end

%% Temperature Data
[T,tImg,tMagImg,tx,ty,tz,phHeader,~,acqTime] = loadTemperatureSonication(sys,sonicationNo);
T_deNoised = denoiseThermometry(T,sys.sonication(sonicationNo).firstDynamic,sys.sonication(sonicationNo).duration,phHeader,tMagImg);
%% Interpolate temperature data onto anatomical data
[tY,tX,tZ] = meshgrid(ty,tx,tz);
[aY,aX,aZ] = meshgrid(ay,ax,az);

d = waitbar(0,'Interpolating');
tInterp = zeros([size(aX),size(T,4)]);
tInterp_deNoised = zeros([size(aX),size(T,4)]);

tMagImgInterp = interp3(tY,tX,tZ,tMagImg(:,:,:),aY,aX,aZ,'nearest');

for ii = 1:size(T,4)
    tInterp(:,:,:,ii) = interp3(tY,tX,tZ,T(:,:,:,ii),aY,aX,aZ,'nearest');
    tInterp_deNoised(:,:,:,ii) = interp3(tY,tX,tZ,T_deNoised(:,:,:,ii),aY,aX,aZ,'nearest');
    waitbar((ii)/size(T,4),d,['Interpolating... Dynamic: ', num2str(ii), ' of ', num2str(size(T,4))]);
end
close(d)
%% Load results into sys
sys.tInterp = tInterp;
sys.tInterp_deNoised = tInterp_deNoised;
sys.T = T;
sys.tx = tx;
sys.ty = ty;
sys.tz = tz;
sys.tImg = tImg;
sys.tMagImg = tMagImg;
sys.tMagImgInterp = tMagImgInterp;
sys.dynamicLength = acqTime;
sys.curSonication = sonicationNo;
sys.tHeader = phHeader;
%% Plot Results
if plotResults
    orthogonalTemperatureViews(sys,6,sonicationNo,[]);
end
