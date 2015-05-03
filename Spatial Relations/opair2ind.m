function ind = opair2ind(i, j, N)

ind = (j - 1)*(N - 1) + i;
if i >= j, ind = ind - 1; end

end
