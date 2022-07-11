% This runs the MR code. The main components of this code are 0) Check
% coupling to validate Tx location and element coupling, 1) register
% the transducer to the MR coordinates, 2) Select a focal spot, 3) sonicate
% that spot with user provided sonicatino duration and voltage, 4)
% reconstructe thermometry and overlay it on the original anatomy image, 5)
% repeat until satisfactory focal spots are obtained.
% 
% The code keeps track of relevant variables in a system struct called sys.
% This struct has the following fields
% @FIELDS in sys
%   logFile: Full file name of location in which to save results - this is
%     done regularly in order to avoid data loss with errors
%   mrPath: Path to MR images generated during this session.
%   aSeriesNo: MR series number of anatomical imaging dataset
%   aImg: Anatomical Imaging Data set
%   txCenter: Location of transducer center in MR Coordinates
%   txTheta: Angle of Tx x-axis and MR x-axis
%   txCenterIdx: Index of txCenter into anatomical imaging data
%   ux: x-axis of anatomical image dataset in ultrasound coordinates
%   uy: y-axis of anatomical image dataset in ultrasound coordinates
%   uz: z-axis of anatomical image dataset in ultrasound coordinates
%   ax: x-axis of anatomical image dataset in MR coordinates
%   ay: y-axis of anatomical image dataset in MR coordinates
%   az: z-axis of anatomical image dataset in MR coordinates
%   focalSpot: Location of current target in Tx coordinates
%   focalSpotMR: location of current target in Mr coordinates
%   focalSpotIdx: Index of focal spot location in anatomy MR dataset
%   sonications: Struct containing information about each sonication. Grows
%     as sonications are performed
%       @FIELDS in sonications
%         duration: duration of sonication in seconds
%         voltage: peak voltage applied to each element during sonication
%         focus: MR coords of focus targeted with this sonication (can be
%           different from current target to enable tracking of different
%           foci in the same MR session).
%         focusTx: Tx coords of focus targeted with this sonication
%         phaseSeriesNo: MR series number for the phase images
%           corresponding to this sonication
%         magSeriesNo: MR series number for the magnitude images
%           corresponding to this sonication
%   tImg: Thermometry dataset for the most recent sonication. This gets
%     replaced with each new sonication but can be easliy re-loaded using
%     sys.sonications(sonicationOfInterest).thermPath.

clear all; close all; clc;
%% Setup
% verasonicsDir = 'C:\Users\Verasonics\Desktop\Taylor\Code\verasonics\';
verasonicsDir = 'C:\Users\Taylor\Documents\Projects\registrationAlone\registration\';
% Add relevant paths to give access to library functions

% addpath([verasonicsDir, 'MonkeyTx\lib'])
% addpath([verasonicsDir, 'MonkeyTx\lib\griddedImage'])
% addpath([verasonicsDir, 'MonkeyTx\lib\placementVerification'])
% addpath([verasonicsDir, 'MonkeyTx\MATFILES\'])
% addpath([verasonicsDir, 'MonkeyTx\setupScripts\'])
% addpath([verasonicsDir, 'lib'])
addpath(verasonicsDir);
addpath([verasonicsDir, 'thermometry\'])
addpath([verasonicsDir, 'transducerLocalization\']);

% Experiment Path
sys.expPath = 'D:\MR\Thermometry\20220203\';

% Imaging paths
sys.mrPath = [sys.expPath,'Images\'];

% Set the transducer you are using
sys.txSn = 'JAB800';

if strcmp(sys.txSn,'JEC482')
    sys.zDist = 9.53e-3;
    sys.xDist = 187.59e-3/2;
    sys.yDist = 35e-3/2;
else
    % zDist is 2.53 + whatever the Tx offset is.
    sys.zDist = 9.53e-3;
    sys.xDist = (169/2)*1e-3;
    sys.yDist = (35/2)*1e-3;
end
    

% Log file
logFile ='boltzmann20210929.mat';
sys.logFile = [sys.expPath,'Logs\',logFile];

% Anatomical Series
sys.aSeriesNo = 6;

% Invert Transducer
sys.invertTx = 0;

%% Localize Transducer
sys = registerTx(sys);
saveState(sys);

%% Select Focus
sys = selectFocus(sys);
saveState(sys);