function playTrackedAction(pcd_fmt, p_coeff, varargin)

if isfloat(p_coeff)
    p = double(p_coeff);
    p = p / norm(p(1:3));
elseif strcmp(p_coeff(end-2:end), 'csv')
    % From PCL tracker
    p = double(csvread(p_coeff))';
    p = p / norm(p(1:3));
    p(4) = 1000*p(4);
elseif strcmp(p_coeff(end-2:end), 'mat')
    S = load(p_coeff);
    p = double(S.p);
    p = p / norm(p(1:3));
else
    error('Unkown plane normal format.');
end

pcd_reader = trackedObjPCDReader(pcd_fmt);
No = pcd_reader.No;
Nf = pcd_reader.Nf;

upVector = sign([0,-1,0]*p(1:3)) * p(1:3);
lookAtVector = [0;0;1];
v = -upVector/norm(upVector);
w = lookAtVector - (v'*lookAtVector)*v; w = w/norm(w);
u = cross(v,w);
T = [u,v,w]';

tmp = T*[0;0;-p(4)/p(3)];
v0 = tmp(2);

ptsc = cell(1,No);
for o = 1:No
    ptsc{o} = pcd_reader.getObjPCD(o,1);
end
pts = cell2mat(ptsc);
pts = T*pts;

f = 1.5;
umean = mean(pts(1,:)); wmean = mean(pts(3,:));
umin = min(pts(1,:)); umax = max(pts(1,:));
wmin = min(pts(3,:)); wmax = max(pts(3,:));
ud = f*max(abs(umean-umin), abs(umax-umean));
wd = f*max(abs(wmean-wmin), abs(wmax-wmean));
umin = umean - ud; umax = umean + ud;
wmin = wmean - wd; wmax = wmean + wd;

pcorners = T\[umin,umax,umax,umin; v0,v0,v0,v0; wmin,wmin,wmax,wmax];
bcorners = T\[umin,umax,umax,umin,umin,umax,umax,umin; ...
    v0+100,v0+100,v0+100,v0+100,v0-700,v0-700,v0-700,v0-700; ...
    wmin,wmin,wmax,wmax,wmin,wmin,wmax,wmax];

xmin = min(bcorners(1,:)); xmax = max(bcorners(1,:));
ymin = min(bcorners(2,:)); ymax = max(bcorners(2,:));
zmin = min(bcorners(3,:)); zmax = max(bcorners(3,:));

colors = [0,0,1;1,0,0;0,1,0;1,1,0;0,1,1;1,0,1];
col_ind = mod(0:No-1,length(colors)) + 1;
colc = cell(No,1);
for o = 1:No
    colc{o} = repmat(colors(col_ind(o),:), [size(ptsc{o},2),1]);
end
col = cell2mat(colc);

if nargin < 3
    ind = 1:Nf;
else
    ind = varargin{1};
end

ax = gca;
% hold(ax,'on');
ptsc = cell(No,1);
pos = cell(No,1);
for t = ind
%     cla(ax);
    for o = 1:No
        ptsc{o} = pcd_reader.getObjPCD(o,t)';
        pos{o} = mean(ptsc{o},1);
    end
    pts = cell2mat(ptsc);
    
    showPointCloud(pts, col);
    for o = 1:No
        text(pos{o}(1),pos{o}(2),pos{o}(3),sprintf('%d',o), ...
            'FontSize', 18, 'FontWeight', 'bold', 'Color', 'y');
    end
    patch(pcorners(1,:),pcorners(2,:),pcorners(3,:), 0.5);
    axis(ax,[xmin xmax ymin ymax zmin zmax]);
    campos(ax,[0,0,-10000]);
%     camup(ax,[0,-1,0]);
    camup(ax,-v);
    camtarget(ax,[0,0,1500]);
    camva(ax,10);
    camproj(ax,'perspective');
    grid(ax,'off');
    axis(ax,'off');
    title(ax,sprintf('Frame %d', t));
    drawnow;
end
% hold(ax,'off');
