classdef ConvexPolyhedron < handle

properties
    constraints
    vertices
    facets
end

methods
    
    function obj = ConvexPolyhedron(arg, varargin)
        if nargin < 2
            % V-representation given
            if size(arg,1) == 3, arg = arg'; end
            K = convhulln(arg);
            arg = arg(unique(K(:)),:);
            obj.vertices = arg;
            obj.facets = convhulln(arg);
            [A,b] = vert2lcon(arg);
            obj.constraints.A = A;
            obj.constraints.b = b;
        else
            % H-representation given
            obj.constraints.A = arg;
            obj.constraints.b = varargin{1};
            if nargin > 2
                % Interior point provided
                x = varargin{2};
                obj.vertices = qlcon2vert(x,obj.constraints.A,obj.constraints.b);                
            else
                obj.vertices = lcon2vert(obj.constraints.A,obj.constraints.b);
            end
            obj.facets = convhulln(obj.vertices);
        end
    end

    function h = draw(obj, varargin)
        h = trisurf(obj.facets,obj.vertices(:,1),obj.vertices(:,2),obj.vertices(:,3),varargin{:});
    end
    
    function res = isInterior(obj, x)
        if size(x,2) == 3, x = x'; end
        res = min(bsxfun(@le,obj.constraints.A*x,obj.constraints.b));
    end
    
end

end
