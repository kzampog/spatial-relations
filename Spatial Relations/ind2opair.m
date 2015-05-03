function [i,j] = ind2opair(ind, N)

j = floor((ind - 1)/(N - 1)) + 1;
i = mod(ind - 1, N - 1) + 1;
if i >= j, i = i + 1; end

end
