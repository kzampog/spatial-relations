% clear; clc; close all;

addpath(genpath('../Utilities'));
data_dir = '../Data/';


%% Demo 1: Compute PVS-based action descriptor from tracked object data

% Path to tracked point clouds for all objects
% (indices correspond to frames and objects respectively)
pcd_fmt = [data_dir 'Stir_02/%d_%d.pcd'];
% Plane coefficients for workspace surface
p_coeff = [data_dir 'Stir_02/plane_coefficients.csv'];

% Compute 'full' PVS-based descriptor (including all 8 spatial relations)
A = getActionDescriptor(pcd_fmt, p_coeff, 'full');

% Visualize temporal evolution of spatial relations
% Our representation contains one PVS for each ordered object pair (2 here)
figure;
for i = 1:size(A{1},2)
% for i = 100:101
    % Tracking result and workspace plane
    subplot(2,2,[1,3]);
    playTrackedAction(pcd_fmt, p_coeff, i);
    
    % First PVS in descriptor
    subplot(2,2,2);
    [o1,o2] = ind2opair(1,2);
    plotFeatureVector(A{1}(:,i));
    title(sprintf('Object %d relative to object %d', o1, o2));
    
    % Second PVS in descriptor
    subplot(2,2,4);
    [o1,o2] = ind2opair(2,2);
    plotFeatureVector(A{2}(:,i));
    title(sprintf('Object %d relative to object %d', o1, o2));
    
    drawnow;
end


%% Demo 2: Compare PVS-based representations of different actions

% Load PVS-based descriptors for a set of 21 actions
% Afull{i} contains the 'full' descriptor of action i (all 8 spatial
% relations), while A{i} contains its 'abstract' PVS descriptor (useful for
% action matching)
% label{i} holds the name of action i
load([data_dir, 'sample_data.mat']);
Na = length(A);

% Compute pairwise distances for all action pairs
d = zeros(Na);
for i = 1:Na
    for j = 1:i
        d(i,j) = compareActions(A{i},A{j});
        d(j,i) = d(i,j);
    end
end

% Visualize distance matrix
figure;
imagesc(d); colorbar; colormap jet;
axis tight; axis equal;
set(gca,'TickDir','out');
set(gca,'TickLabelInterpreter','none');
set(gca,'XTick',1:Na); set(gca,'XTickLabel',label);
set(gca,'YTick',1:Na); set(gca,'YTickLabel',label);
set(gca,'XTickLabelRotation',90);
