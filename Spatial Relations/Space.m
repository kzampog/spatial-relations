classdef Space < handle

properties
    type
    space1
    space2
    metadata
end

methods
    
    function obj = Space(type, space1, varargin)
        obj.type = type;
        obj.space1 = space1;
        obj.metadata = [];
        if strcmp(type, 'ConvexPolyhedron')
            obj.space2 = [];
        elseif strcmp(type, 'RelativeComplement')
            obj.space2 = varargin{1};
        elseif strcmp(type, 'Union')
            obj.space2 = varargin{1};
        elseif strcmp(type, 'Intersection')
            obj.space2 = varargin{1};
        else
            error('Unknown space type.');
        end
        if strcmp(type, 'ConvexPolyhedron') && nargin > 2
            obj.metadata = varargin{1};
        elseif nargin > 3
            obj.metadata = varargin{2};
        end
    end
    
    function res = isInterior(obj, x)
        if strcmp(obj.type, 'ConvexPolyhedron')
            res = obj.space1.isInterior(x);
        elseif strcmp(obj.type, 'RelativeComplement')
            res = ~obj.space1.isInterior(x) & obj.space2.isInterior(x);
        elseif strcmp(obj.type, 'Union')
            res = obj.space1.isInterior(x) | obj.space2.isInterior(x);
        elseif strcmp(obj.type, 'Intersection')
            res = obj.space1.isInterior(x) & obj.space2.isInterior(x);
        end
    end
    
%     function res = score(obj, x)
%         if ~isempty(obj.metadata)
%             res = pointScore(x, obj.metadata);
%         elseif strcmp(obj.type, 'ConvexPolyhedron')
%             error('Not enough info on how to calculate point scores.');
%         elseif strcmp(obj.type, 'RelativeComplement')
%             res = min(1 - obj.space1.score(x), obj.space2.score(x));
% %             res = (1 - obj.space1.score(x)) .* obj.space2.score(x);
%         elseif strcmp(obj.type, 'Union')
%             res = max(obj.space1.score(x), obj.space2.score(x));
% %             s1 = obj.space1.score(x); s2 = obj.space2.score(x);
% %             res = s1 + s2 - s1.*s2;
% %             temp = Space('Intersection',obj.space1,obj.space2);
% %             res = obj.space1.score(x) + obj.space2.score(x) - temp.score(x);
%         elseif strcmp(obj.type, 'Intersection')
%             res = min(obj.space1.score(x), obj.space2.score(x));
% %             res = obj.space1.score(x) .* obj.space2.score(x);
%         end
%     end

    function h = draw(obj, varargin)
        if strcmp(obj.type, 'ConvexPolyhedron')
            h = zeros(6,1);
            T = obj.metadata.lookAtTransform;
            V = obj.space1.vertices';
            Vt = T*V;
            val = [0,1,3,2];
            flag = ishold;
            if ~flag, hold on; end
            for dim = 1:3
                [~,ind] = sort(Vt(dim,:));
                for m = 1:2
                    if m == 1, Vcur = V(:,ind(1:4)); else Vcur = V(:,ind(5:end)); end
                    Vth = T*Vcur;
                    [~,ind1] = sort(Vth(mod(dim-1+1,3)+1,:));
                    [~,ind2] = sort(Vth(mod(dim-1+2,3)+1,:));
                    v = zeros(2,4);
                    v(1,ind1(1:2)) = 1;
                    v(2,ind2(1:2)) = 1;
                    v = 2*v(1,:) + v(2,:) + 1;
                    [~,ord] = sort(val(v));
                    Vcur = Vcur(:,ord);
                    ht = fill3(Vcur(1,:),Vcur(2,:),Vcur(3,:),varargin{:});
                    h(2*(dim-1)+m) = ht;
                end
            end
            if ~flag, hold off; end
        else
            error('Can only draw spaces of type ''ConvexPolyhedron''');
        end
    end
    
end

end
