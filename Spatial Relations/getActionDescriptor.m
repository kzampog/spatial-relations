function D = getActionDescriptor(pcd_fmt, p_normal, fv_type)

if isfloat(p_normal)
    p = double(p_normal);
elseif strcmp(p_normal(end-2:end), 'csv')
    % From PCL tracker
    p = double(csvread(p_normal))';
elseif strcmp(p_normal(end-2:end), 'mat')
    S = load(p_normal);
    p = double(S.p);
else
    error('Unkown plane normal format.');
end

p = p/norm(p(1:3));

upVector = sign([0,-1,0]*p(1:3)) * p(1:3);
lookAtVector = [0;0;1];
options = {'upVector', upVector, 'lookAtVector', lookAtVector};

pcd_reader = trackedObjPCDReader(pcd_fmt);
No = pcd_reader.No;
Nf = pcd_reader.Nf;

Nrel = No*(No-1);
D = cell(Nrel,1);
obj = cell(No,1);

if strcmp(fv_type, 'full')
    Ndim = 8;
elseif strcmp(fv_type, 'abstracted')
    Ndim = 5;
else
    error('Unknown feature vector type.');
end

for r = 1:Nrel
    D{r} = zeros(Ndim,Nf);
end

for t = 1:Nf
    for i = 1:No
        obj{i} = pcd_reader.getObjPCD(i, t);
    end
    for r = 1:Nrel
        [o1,o2] = ind2opair(r, No);
        D{r}(:,t) = getFeatureVector(obj{o1}, obj{o2}, fv_type, options{:});
    end
    fprintf(1, 'Frame %d of %d...\n', t, Nf);
end

end
