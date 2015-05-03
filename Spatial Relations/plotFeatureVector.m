function plotFeatureVector(fv)

if length(fv) == 8
    rel = {'in','left','right','infront','behind','above','below','touching'};
elseif length(fv) == 5
    rel = {'in','around','above','below','touching'};
end

fv = fv(:);

v1 = [fv(1:end-1); 0];
v2 = [zeros(length(fv)-1,1); fv(end)];

% bar(fv(:));

bar(v1,'b');
hold on;
bar(v2,'r');
hold off;

xlim([0.5 length(fv)+0.5]);
ylim([0 1]);
set(gca,'XTickLabel',rel);
set(gca,'TickDir','out');
set(gca,'XTickLabelRotation',90);
