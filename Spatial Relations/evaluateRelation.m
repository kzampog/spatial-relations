function res = evaluateRelation(rel, obj1, obj2, varargin)

for Nobj = 1:length(varargin)
    if ischar(varargin{Nobj}), break; end
end
if ~isempty(varargin) && ~ischar(varargin{Nobj}), Nobj = Nobj + 1; end
if isempty(Nobj), Nobj = 1; end
options = varargin(Nobj:end);
Nobj = Nobj + 1;


if ismember(rel, {'in','left','right','infront','behind','above','below'})
    relSpace = relativeSpace(rel, obj2, options{:});
    temp = relSpace.isInterior(obj1);
    res = sum(temp) / length(temp);
    
elseif strcmp(rel, 'touching')
    in12 = evaluateRelation('in', obj1, obj2, options{:});
    in21 = evaluateRelation('in', obj2, obj1, options{:});
    if in12 + in21 > 0, res = 1; return; end
    pts = [obj1';obj2'];
    labelref = [zeros(size(obj1,2),1);ones(size(obj2,2),1)];
    opt = statset('Display', 'off', 'MaxIter', 100000);
    svm = svmtrain(pts,labelref,'autoscale',false,'boxconstraint',0.005,'options',opt);
    label = svmclassify(svm,pts);
    if ~all(label==labelref)
        res = 1;
    else
        w = sum(bsxfun(@times, svm.SupportVectors, svm.Alpha));
        res = 2/norm(w) < 10;
    end
    
elseif ismember(rel, {'on','under'})
    if strcmp(rel,'on')
        rel_aux = 'above';
    else
        rel_aux = 'below';
    end
    res = evaluateRelation('touching', obj1, obj2, options{:}) * ...
        evaluateRelation(rel_aux, obj1, obj2, options{:});
    
elseif strcmp(rel, 'intersect')
    in12 = evaluateRelation('in', obj1, obj2, options{:});
    in21 = evaluateRelation('in', obj2, obj1, options{:});
    res = 2*in12*in21 / (in12+in21);
    if isnan(res), res = 0; end
    
elseif strcmp(rel, 'among')
    relSpace = relativeSpace(rel, obj2, varargin{1:Nobj-2}, options{:});
    temp = relSpace.isInterior(obj1);
    res = sum(temp) / length(temp);
    
else
    error('Unknown spatial preposition.');
end

end