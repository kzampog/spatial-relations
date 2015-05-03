function space = relativeSpace(rel, obj, varargin)

for Nobj = 1:length(varargin)
    if ischar(varargin{Nobj}), break; end
end
if ~isempty(varargin) && ~ischar(varargin{Nobj}), Nobj = Nobj + 1; end
if isempty(Nobj), Nobj = 1; end
options = varargin(Nobj:end);

p = inputParser;
p.addParameter('upVector', [0;-1;0], @isnumeric);
p.addParameter('lookAtVector', [0;0;1], @isnumeric);
p.addParameter('lookAtType', 'absolute', @ischar);
p.addParameter('nearDistance', 500, @isnumeric);
% p.addParamValue('upVector', [0;-1;0], @isnumeric);
% p.addParamValue('lookAtVector', [0;0;1], @isnumeric);
% p.addParamValue('lookAtType', 'absolute', @ischar);
% p.addParamValue('nearDistance', 350, @isnumeric);
p.parse(options{:});
opt = p.Results;

if strcmp(rel, 'far')
    tempPoly = relativeSpace('near',obj,options{:});
    space = Space('Complement',tempPoly);
    return
end

if ismember(rel,{'in','left','right','infront','behind','above','below','near'})
    % Single object
    if size(obj,2) == 3, obj = obj'; end

    if strcmp(opt.lookAtType, 'relative')
        centerDir = [0,0,0];
        while abs(centerDir * opt.lookAtVector) < cos(1.0*pi/180)
            tempPoly = relativeSpace('in',obj,'upVector',opt.upVector, ...
                'lookAtVector',opt.lookAtVector,'lookAtType','absolute');
            centerDir = mean(tempPoly.space1.vertices);
            centerDir = centerDir/norm(centerDir);
            opt.lookAtVector = centerDir';
        end
    elseif ~strcmp(opt.lookAtType, 'absolute')
        error('Invalid input argument.');
    end

    v = -opt.upVector/norm(opt.upVector);
    w = opt.lookAtVector - (v'*opt.lookAtVector)*v; w = w/norm(w);
    u = cross(v,w);
    T = [u,v,w]';

    ptsTrans = T*obj;
    minC = min(ptsTrans,[],2);
    maxC = max(ptsTrans,[],2);
    sz = abs(maxC - minC);

    A = [-1,0,0; 1,0,0; 0,-1,0; 0,1,0; 0,0,-1; 0,0,1];
    b = [-minC(1); maxC(1); -minC(2); maxC(2); -minC(3); maxC(3)];

    tempPoly = ConvexPolyhedron(A,b);
    inPoly = ConvexPolyhedron(T\tempPoly.vertices');

    if strcmp(rel, 'in')
        meta.referencePoint = mean(inPoly.vertices)';
        meta.lookAtTransform = T;
        meta.size = [sz(1); sz(2); sz(3)];
        meta.scoringType = 'inclusion';
        space = Space('ConvexPolyhedron', inPoly, meta);
        return
    elseif strcmp(rel, 'near')
        meta.referencePoint = mean(inPoly.vertices)';
        meta.lookAtTransform = T;
        meta.size = 2*opt.nearDistance*ones(3,1);
        meta.scoringType = 'inclusion';
        mm = abs(A) * mean(tempPoly.vertices)';
        b = mm.*(-1).^(1:6)' + opt.nearDistance*ones(6,1);
        tempPoly = ConvexPolyhedron(A,b);
        space = Space('ConvexPolyhedron', ConvexPolyhedron(T\tempPoly.vertices'), meta);
        return
    elseif strcmp(rel, 'left')
        d1 = -u; d2 = v; d3 = w;
        meta.size = [sz(1); sz(2); sz(3)];
    elseif strcmp(rel, 'right')
        d1 = u; d2 = v; d3 = w;
        meta.size = [sz(1); sz(2); sz(3)];
    elseif strcmp(rel, 'infront')
        d1 = -w; d2 = u; d3 = v;
        meta.size = [sz(3); sz(1); sz(2)];
    elseif strcmp(rel, 'behind')
        d1 = w; d2 = u; d3 = v;
        meta.size = [sz(3); sz(1); sz(2)];
    elseif strcmp(rel, 'above')
        d1 = -v; d2 = u; d3 = w;
        meta.size = [sz(2); sz(1); sz(3)];
    elseif strcmp(rel, 'below')
        d1 = v; d2 = u; d3 = w;
        meta.size = [sz(2); sz(1); sz(3)];
    end

    meta.lookAtTransform = [d1,d2,d3]';
    meta.size(1) = 4*opt.nearDistance;
    meta.scoringType = 'direction';

    [~,idx] = sort(d1'*inPoly.vertices','descend');
    V1 = inPoly.vertices(idx(1:4),:)';
    [~,idx] = sort(d2'*V1,'descend');
    V1 = V1(:,idx);
    for i = [1,3]
        val = d3'*V1;
        if val(i+1) > val(i)
            temp = V1(:,i); V1(:,i) = V1(:,i+1); V1(:,i+1) = temp;
        end
    end
    V2 = zeros(3,4);
    for i = 0:3
%         V2(:,i+1) = V1(:,i+1) + 700*(d1+(-1)^floor(i/2)*d2+(-1)^mod(i,2)*d3);
        V2(:,i+1) = V1(:,i+1) + 3*opt.nearDistance*(d1+(-1)^floor(i/2)*d2+(-1)^mod(i,2)*d3);
    end

    V = [V1 V2];
    meta.referencePoint = mean(V1,2);
    space = Space('ConvexPolyhedron', ConvexPolyhedron(V), meta);
else
    % Multiple objects
    objs = cell(Nobj,1);
    objs{1} = obj;
    for i = 2:Nobj
        objs{i} = varargin{i-1};
    end
    
    if strcmp(rel,'among')
        box = cell(Nobj,1);
        V = zeros(8*Nobj,3);
        for i = 1:Nobj
            idx = 8*(i-1) + 1;
            box{i} = relativeSpace('in',objs{i},options{:});
            V(idx:idx+7,:) = box{i}.space1.vertices;
        end
        V1 = V;
        m = mean(V1);
        V1 = bsxfun(@minus, V1, m);
        [~, S, T] = svd(V1);
        
        tempPoly = ConvexPolyhedron(V);
        meta.referencePoint = m';
%         meta.referencePoint = centerOfMassConvex(tempPoly);
        meta.lookAtTransform = T';
        meta.size = diag(S(1:3,1:3))/2;
        meta.scoringType = 'inclusion';
        space = Space('ConvexPolyhedron', tempPoly, meta);
    else
        error('Unknown spatial preposition.');
    end
end

end
