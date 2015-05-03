function f = getFeatureVector(obj1, obj2, fv_type, varargin)

rel = {'in','left','right','infront','behind','above','below','touching'};

d = length(rel);
t = zeros(d,1);
for k = 1:d
    t(k) = evaluateRelation(rel{k},obj1,obj2,varargin{:});
end

if strcmp(fv_type, 'full')
    f = t;
elseif strcmp(fv_type, 'abstracted')
    f = zeros(5,1);
    f(1) = t(1);
    f(2) = sum(t(2:5));
    f(3:5) = t(6:8);
else
    error('Unknown feature vector type.');
end

% f = f / sum(f);

end
