classdef trackedObjPCDReader < handle

properties
    type
    filetype
    pcd_fmt
    Nf
    No
    f_ind
    o_ind
    pcd_data
end

methods
    function obj = trackedObjPCDReader(pcd_fmt)
        obj.f_ind = []; obj.o_ind = [];
        obj.pcd_data = [];
        obj.pcd_fmt = pcd_fmt;
        tmp = sum(ismember(pcd_fmt, '%'));
        if tmp == 2
            obj.type = 'indexed';
        elseif tmp == 0
            obj.type = 'single';
        else
            error('Unknown input format.');
        end
        obj.filetype = pcd_fmt(end-2:end);
        if ~(strcmp(obj.filetype, 'pcd') || strcmp(obj.filetype, 'mat'))
            error('Unknown file type.');
        end
        if strcmp(obj.type, 'indexed')
            [data_dir,fname,ext] = fileparts(pcd_fmt);
            ids = dir(data_dir);
            
            fmin = Inf; fmax = -1;
            omin = Inf; omax = -1;
            for i = 1:length(ids)
                if ~ids(i).isdir
                    ca = textscan(ids(i).name, strcat(fname, ext));
                    f = ca{1}; o = ca{2};
                    if f < fmin, fmin = f; end; if f > fmax, fmax = f; end
                    if o < omin, omin = o; end; if o > omax, omax = o; end
                end
            end

            obj.Nf = fmax - fmin + 1; obj.No = omax - omin + 1;
            obj.f_ind = fmin:fmax; obj.o_ind = omin:omax;
        else
            S = load(pcd_fmt);
            obj.pcd_data = S.trackedObjects;
            obj.No = length(obj.pcd_data);
            obj.Nf = length(obj.pcd_data{1});
        end
        
    end
    function res = getObjPCD(obj, o, t)
        if strcmp(obj.type, 'indexed')
            fname = sprintf(obj.pcd_fmt, obj.f_ind(t), obj.o_ind(o));
            if strcmp(obj.filetype, 'pcd')
                res = 1000*double(loadpcd(fname));
                res(1,:) = -res(1,:);
            else
                S = load(fname);
                res = S.pts;
            end
        else
            res = double(obj.pcd_data{o}{t});
        end
    end
end

end
