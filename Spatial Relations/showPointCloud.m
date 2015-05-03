function ax = showPointCloud(varargin)
%showPointCloud Plot 3-D point cloud.
%   showPointCloud(ptCloud) displays points with locations and colors
%   stored in the pointCloud object ptCloud.
% 
%   showPointCloud(xyzPoints) displays points at the locations that are
%   contained in an M-by-3 or M-by-N-by-3 xyzPoints matrix. The matrix,
%   xyzPoints, contains M or M-by-N [x,y,z] points. The color of each point
%   is determined by its Z value, which is linearly mapped to a color in
%   the current colormap.
%
%   showPointCloud(xyzPoints,C) displays points at the locations that are
%   contained in the M-by-3 or M-by-N-by-3 xyzPoints matrix with colors
%   specified by C. To specify the same color for all points, C must be a
%   color string or a 1-by-3 RGB vector. To specify a different color for
%   each point, C must be one of the following:
%   - A vector or M-by-N matrix containing values that are linearly mapped
%   to a color in the current colormap.
%   - An M-by-3 or M-by-N-by-3 matrix containing RGB values for each point.
%
%   ax = showPointCloud(...) returns the plot's axes.
%
%   showPointCloud(...,Name,Value) uses additional options specified by one
%   or more Name,Value pair arguments below:
%
%   'MarkerSize'       A positive scalar specifying the approximate
%                      diameter of the point marker in points, a unit
%                      defined by matlab graphics.
%
%                      Default: 6
%                       
%   'VerticalAxis'     A string specifying the vertical axis, whose value
%                      is 'X', 'Y' or 'Z'. 
%
%                      Default: 'Z'
%
%   'VerticalAxisDir'  A string specifying the direction of the vertical
%                      axis, whose value is 'Up' or 'Down'.
%
%                      Default: 'Up'
%
%   'Parent'           Specify an output axes for displaying the
%                      visualization. 
%
%   Notes 
%   ----- 
%   Points with NaN or inf coordinates will not be plotted. 
%
%   It is recommended to specify a small size of the marker. Size larger
%   than 6 may reduce the rendering performance.
% 
%   cameratoolbar will be automatically turned on in the current figure.
%
%   Class Support 
%   ------------- 
%   ptCloud must be a pointCloud object. xyzPoints must be numeric. C must
%   be a color string or numeric.
% 
%   Example: Plot spherical point cloud with color 
%   ----------------------------------------------------------------- 
%   % Generate a sphere consisting of 600-by-600 faces
%   numFaces = 600;
%   [x,y,z] = sphere(numFaces);
%
%   % plot the sphere with the default color map
%   figure;
%   showPointCloud([x(:),y(:),z(:)]);
%   title('Sphere with the default color map');
%   xlabel('X');
%   ylabel('Y');
%   zlabel('Z');
%
%   % load an image for texture mapping
%   I = im2double(imread('visionteam1.jpg'));
%
%   % resize and flip the image for mapping the coordinates 
%   J = flipud(imresize(I, size(x)));
%
%   % plot the sphere with the color texture
%   figure;
%   showPointCloud([x(:), y(:), z(:)], reshape(J, [], 3));
%   title('Sphere with the color texture');
%   xlabel('X');
%   ylabel('Y');
%   zlabel('Z');
%
% See also pointCloud, reconstructScene, triangulate, plot3, scatter3 

%  Copyright 2013-2014 The MathWorks, Inc.

[X, Y, Z, C, markerSize, vertAxis, vertAxisDir, currentAxes] = ...
                            validateAndParseInputs(varargin{:});

% Plot to the specified axis, or create a new one
if isempty(currentAxes)
    currentAxes = newplot;
end

if isempty(C)
    scatter3(currentAxes, X, Y, Z, markerSize, Z, '.');
elseif (ischar(C) || isequal(size(C),[1,3]))
    try
        plot3(currentAxes, X, Y, Z, '.', 'Color', C, 'MarkerSize', markerSize);
        grid(currentAxes, 'on');
    catch exception
        throwAsCaller(exception);
    end
else
    scatter3(currentAxes, X, Y, Z, markerSize, C, '.');
end

% Equal axis is required for cameratoolbar
axis(currentAxes, 'equal');

% Get the current figure handle
hFigure = get(currentAxes,'Parent');

% Check the renderer
if strcmpi(hFigure.Renderer, 'painters')
    error(message('vision:pointcloud:badRenderer'));
end

% Set up the cameratoolbar
cameratoolbar(hFigure);
vis = cameratoolbar('GetVisible');
if ~vis
    cameratoolbar('Show');
end

% Turn on the orbit mode of the cameratoolbar
mode = cameratoolbar('GetMode');
if ~strcmpi(mode, 'orbit')
    cameratoolbar('SetMode', 'orbit');
end

% Set up the camera
cameratoolbar('ResetCamera');

currentVertAxis = cameratoolbar('GetCoordsys');
if ~strcmpi(currentVertAxis, vertAxis)
    cameratoolbar('SetCoordSys',vertAxis);
end

if strcmpi(vertAxis, 'X')
    if strncmpi(vertAxisDir, 'Up', 1)
        set(currentAxes, 'CameraUpVector', [1 0 0]);
    else
        set(currentAxes, 'CameraUpVector', [-1 0 0]);
    end
elseif strcmpi(vertAxis, 'Y')
    % This setup is best used to visualize data in a camera centric view point
    if strncmpi(vertAxisDir, 'Up', 1)
        set(currentAxes, 'CameraUpVector', [0 1 0]);
        camorbit(currentAxes, 60, 0, 'data', [0 1 0]);
    else
        set(currentAxes, 'CameraUpVector', [0 -1 0]);
        camorbit(currentAxes, -120, 0, 'data', [0 1 0]);
    end
else        
    if strncmpi(vertAxisDir, 'Up', 1)
        set(currentAxes, 'CameraUpVector', [0 0 1]);
    else
        % This setup is best used to visualize data where world coordinate
        % system is set on the checkerboard during camera calibration process
        set(currentAxes, 'CameraUpVector', [0 0 -1]);
        camorbit(currentAxes, -110, 60, 'data', [0 0          1]);
    end
end

% Change the icon to indicate the rotation
SetData = setptr('rotate');
set(hFigure, SetData{:});

if nargout > 0
    ax = currentAxes;
end
end

%========================================================================== 
function [X, Y, Z, C, markerSize, vertAxis, vertAxisDir, ax] = validateAndParseInputs(varargin)
% Validate and parse inputs
narginchk(1, 10);

% the 2nd argument is C only if the number of arguments is even and the
% first argument is not a pointCloud object
if  ~bitget(nargin, 1) && ~isa(varargin{1}, 'pointCloud')
    [X, Y, Z, C] = validateAndParseInputsXYZC(varargin{1:2});
    pvpairs = varargin(3:end);
else
    [X, Y, Z, C] = validateAndParseInputsXYZC(varargin{1});
    pvpairs = varargin(2:end);
end

% Parse the PV-pairs
defaults = struct('MarkerSize', 6, 'Parent', [], 'VerticalAxis', 'Z', ...
                  'VerticalAxisDir', 'Up');

% Setup parser
parser = inputParser;
parser.CaseSensitive = false;
parser.FunctionName  = mfilename;

parser.addParameter('MarkerSize', defaults.MarkerSize, @checkMarkerSize);
parser.addParameter('VerticalAxis', defaults.VerticalAxis, @checkVerticalAxis);
parser.addParameter('VerticalAxisDir', defaults.VerticalAxisDir, @checkVerticalAxisDir);
parser.addParameter('Parent', defaults.Parent, ...
            @vision.internal.inputValidation.validateAxesHandle);

% Parse input
parser.parse(pvpairs{:});
    
% Retrieve the optional P-V pairs
markerSize = parser.Results.MarkerSize;
ax = parser.Results.Parent;
vertAxis = parser.Results.VerticalAxis;
vertAxisDir = parser.Results.VerticalAxisDir;

end

%========================================================================== 
function [X, Y, Z, C] = validateAndParseInputsXYZC(varargin)
% Validate and parse points and colors

if isa(varargin{1}, 'pointCloud')
    % Retrieve the regular parameters
    ptCloud = varargin{1};
    xyzPoints = ptCloud.Location;
    C = ptCloud.Color;
else
    if ismatrix(varargin{1})
        xyzPoints = varargin{1};
        validateattributes(xyzPoints,{'numeric'}, {'real','ncols',3},mfilename,'xyzPoints');
    else
        xyzPoints = varargin{1};
        validateattributes(xyzPoints,{'numeric'}, {'real','size',[NaN,NaN,3]},mfilename,'xyzPoints');    
    end
    
    if nargin > 1
        C = varargin{2};
        validateattributes(C,{'numeric', 'char'}, {'nonempty','nonsparse','real'});
    else
        C = [];
    end
    
    % Check the color input
    if ~isempty(C)
        if ischar(C)
            validateattributes(C,{'char'}, {'nonempty'}, mfilename, 'C', 2);
        elseif numel(C) == 3
            validateattributes(C,{'numeric'}, {'real','ncols',3}, mfilename, 'C', 2);
        else
            if ismatrix(xyzPoints)
                if isvector(C)
                    validateattributes(C,{'numeric'}, {'real'}, mfilename, 'C', 2);
                    if numel(C) ~= size(xyzPoints,1)
                        error(message('vision:pointcloud:unmatchedXYZC'));
                    end
                else
                    validateattributes(C,{'numeric'}, {'real','size',[NaN,3]}, mfilename, 'C', 2);
                    if size(C, 1) ~= size(xyzPoints, 1)
                        error(message('vision:pointcloud:unmatchedXYZC'));
                    end
                end
            else
                if ismatrix(C)
                    validateattributes(C,{'numeric'}, {'real'}, mfilename, 'C', 2);
                else
                    validateattributes(C,{'numeric'}, {'real','size',[NaN,NaN,3]}, mfilename, 'C', 2);
                end
                if (size(C, 1) ~= size(xyzPoints, 1) || size(C, 2) ~= size(xyzPoints, 2))
                    error(message('vision:pointcloud:unmatchedXYZC'));
                end
            end
        end
    end
    
end

if ismatrix(xyzPoints)
    X = xyzPoints(:, 1);
    Y = xyzPoints(:, 2);
    Z = xyzPoints(:, 3);
else
    X = reshape(xyzPoints(:,:,1), [], 1);
    Y = reshape(xyzPoints(:,:,2), [], 1);
    Z = reshape(xyzPoints(:,:,3), [], 1);
    if ndims(C) == 3
        C = reshape(C, [], 3);
    elseif ~isvector(C)
        C = C(:);
    end
end

% Convert to double precision, rescaling the data if necessary
if (size(C, 2) == 3 && isnumeric(C))
    C = im2double(C);
end

end

%========================================================================== 
function checkVerticalAxis(value)
% Validate 'VerticalAxis'

list = {'X', 'Y', 'Z'};
validateattributes(value, {'char'}, {'nonempty'}, mfilename, 'VerticalAxis');

validatestring(value, list, mfilename, 'VerticalAxis');
end

%========================================================================== 
function checkVerticalAxisDir(value)
% Validate 'VerticalAxisDir'

list = {'Up', 'Down'};
validateattributes(value, {'char'}, {'nonempty'}, mfilename, 'VerticalAxisDir');

validatestring(value, list, mfilename, 'VerticalAxisDir');
end

%==========================================================================
function checkMarkerSize(value)
% Validate 'MarkerSize'

validateattributes(value, {'numeric'}, {'nonempty', 'nonnan', ...
    'finite', 'nonsparse', 'real', 'scalar', '>', 0}, mfilename, 'MarkerSize');
end
