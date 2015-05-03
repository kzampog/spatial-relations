function [dist, oA] = compareActions(D1, D2, opt_type)

if nargin < 3, opt_type = 'MIQP'; end

Nrel1 = size(D1,1);
Nrel2 = size(D2,1);
No1 = round((1+sqrt(1+4*Nrel1))/2);
No2 = round((1+sqrt(1+4*Nrel2))/2);

% disp('COST MATRIX');
% tic;
M = zeros(Nrel1,Nrel2);
for i = 1:Nrel1
    for j = 1:Nrel2
        M(i,j) = dtw_c(D1{i}',D2{j}');
    end
end
% toc

if strcmp(opt_type, 'MILP')
    len = Nrel1*Nrel2+No1*No2;

    % disp('CONSTRUCT PROBLEM');
    % tic;
    f = [M(:); zeros(No1*No2,1)];
    zero_pad = zeros(1,Nrel1*Nrel2);
    
    % Constraints on object assignment variables "x"
    Axeq = [zero_pad ones(1,No1*No2)];
    bxeq = min(No1,No2);

    Ax1 = zeros(No1,len);
    for i = 1:No1
        tmp = zeros(1,No1);
        tmp(i) = 1;
        Ax1(i,:) = [zero_pad repmat(tmp,[1,No2])];
    end
    bx1 = ones(No1,1);

    Ax2 = zeros(No2,len);
    for j = 1:No2
        tmp = zeros(1,No1*No2);
        tmp((j-1)*No1+1:j*No1) = 1;
        Ax2(j,:) = [zero_pad tmp];
    end
    bx2 = ones(No2,1);

    Ax = [Ax1; Ax2];
    bx = [bx1; bx2];

    % Constraints on auxiliary (relation assignment) variables "y"
    Ay = zeros(3*Nrel1*Nrel2,len);
    by = zeros(3*Nrel1*Nrel2,1);
    for indy = 1:Nrel1*Nrel2
        [r1,r2] = ind2sub([Nrel1,Nrel2],indy);
        [o1_1,o2_1] = ind2opair(r1,No1);
        [o1_2,o2_2] = ind2opair(r2,No2);
        indx1 = Nrel1*Nrel2 + sub2ind([No1,No2],o1_1,o1_2);
        indx2 = Nrel1*Nrel2 + sub2ind([No1,No2],o2_1,o2_2);
        ind = 3*(indy-1)+1;

        Ay(ind,indy) = -1; Ay(ind,indx1) = 1; Ay(ind,indx2) = 1;
        Ay(ind+1,indy) = 1; Ay(ind+1,indx1) = -1;
        Ay(ind+2,indy) = 1; Ay(ind+2,indx2) = -1;

        by(ind:ind+2) = [1; 0; 0];
    end
    
    % Aeq = Axeq; beq = bxeq;
    % A = [Ax; Ay]; b = [bx; by];
    Aeq = sparse(Axeq); beq = bxeq;
    A = sparse([Ax; Ay]); b = [bx; by];
    
    lb = zeros(len,1);
    ub = ones(len,1);
    % toc
    
    % Solution
    % disp('OPTIMIZATION');
    % tic;
    % opt = optimoptions('bintprog','Display','off');
    % [sol,dist] = bintprog(f,A,b,Aeq,beq,[],opt);
    % opt = optimoptions('intlinprog','Display','off');
    % [sol,dist] = intlinprog(f,1:len,A,b,Aeq,beq,lb,ub,opt);
    opt = optiset('solver', 'MATLAB');
    opt_prob = opti('f',f,'ineq',A,b,'eq',Aeq,beq,'bounds',lb,ub,'xtype',repmat('I',1,len),'options',opt);
    [sol,dist] = solve(opt_prob);
    % toc

    % disp(sol);
    % disp(reshape(sol(1:Nrel1*Nrel2),[Nrel1,Nrel2]));
    
%     dist = dist/min(Nrel1,Nrel2);
    oA = reshape(sol(Nrel1*Nrel2+1:end),[No1,No2]) > 0.5;
    
elseif strcmp(opt_type, 'MIQP')
    len = No1*No2;
    
    % disp('CONSTRUCT PROBLEM');
    % tic;
    H = zeros(len);
    for rr = 1:Nrel1*Nrel2
        [r1,r2] = ind2sub([Nrel1,Nrel2],rr);
        [o1_1,o2_1] = ind2opair(r1,No1);
        [o1_2,o2_2] = ind2opair(r2,No2);
        ind1 = sub2ind([No1,No2],o1_1,o1_2);
        ind2 = sub2ind([No1,No2],o2_1,o2_2);
        H(ind1,ind2) = M(r1,r2);
    end
    
    H = sparse(H);
    
    f = zeros(len,1);
    
    Aeq = sparse(ones(1,len));
    beq = min(No1,No2);
    
    A1 = zeros(No1,len);
    for i = 1:No1
        tmp = zeros(1,No1);
        tmp(i) = 1;
        A1(i,:) = repmat(tmp,[1,No2]);
    end
    b1 = ones(No1,1);

    A2 = zeros(No2,len);
    for j = 1:No2
        A2(j,(j-1)*No1+1:j*No1) = 1;
    end
    b2 = ones(No2,1);
    
    A = sparse([A1; A2]);
    b = [b1; b2];
    
    lb = zeros(len,1);
    ub = ones(len,1);
    % toc
    
    % disp('OPTIMIZATION');
    % tic;
    opt = optiset('solver', 'SCIP');
    opt_prob = opti('qp',H,f,'ineq',A,b,'eq',Aeq,beq,'bounds',lb,ub,'xtype',repmat('I',1,len),'options',opt);
    % opt_prob = opti('qp',H,f,'ineq',A,b,'eq',Aeq,beq,'bounds',lb,ub,'xtype',repmat('I',1,len));
    [sol,dist] = solve(opt_prob);
    % toc
    
    dist = 2*dist;
%     dist = 2*dist/min(Nrel1,Nrel2);
    oA = reshape(sol,[No1,No2]) > 0.5;
    
else
    error('Unknown optimization type.');
end

end
