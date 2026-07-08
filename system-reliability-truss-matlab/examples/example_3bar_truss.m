% example_3bar_truss.m
%
% 3-bar truss with a variable angle theta for bar 3 — Wei & Deng (2022) /
% Rodrigues da Silva et al. (2024) Fig. 1, Table 1 boundary-case test.
%
% Geometry: single free node (apex, node 1) with 3 bars radiating to 3
% pinned supports (nodes 2-4). Bar 1 -> straight down, bar 2 -> straight
% left (both fixed), bar 3 sweeps through angle theta measured from bar 2
% (horizontal) toward bar 1 (vertical). This reproduces the qualitative
% degeneracy reported in metodika.md Table 1: at the boundary angles
% (theta=0 aligns bar 3 with bar 2's support direction structurally, theta=90
% aligns it with bar 1) one bar becomes "necessary" (Lemma 1, V_i=0) and the
% cut-set structure collapses from 3 pairs to 1 singleton + 1 pair:
%   theta=0deg:          {necessary bar} + {the other two as a pair}
%   theta=1,45,89 deg:   all three pairs {[1,2],[1,3],[2,3]}
%   theta=90deg:         {other necessary bar} + {remaining pair}
% Exact bar labels depend on the head/end numbering chosen here and may be
% permuted relative to the paper's Fig. 1 numbering — the algebraic
% STRUCTURE (1 singleton + 1 pair at boundaries, 3 pairs in between) is
% what's being verified.
%
% (c) S. Glanc, 2026

clear; close all;
srcDir = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
femDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'fem-2d-truss-matlab', 'src');
addpath(srcDir); addpath(femDir);

thetas = [0, 1, 45, 89, 90];

fprintf('=== 3-bar truss: null-space cut-sets vs. bar-3 angle theta ===\n\n');

for th = thetas
    % Node 1 = apex (free). Bar 1: node1->node2 (straight down, fixed).
    % Bar 2: node1->node3 (straight left, fixed). Bar 3: node1->node4,
    % sweeping from horizontal (theta=0) to vertical (theta=90).
    nodes.x = [0;  0; -1; -cosd(th)];
    nodes.z = [0; -1;  0; -sind(th)];

    kinematic.x.nodes = [2; 3; 4];
    kinematic.z.nodes = [2; 3; 4];

    members.nodesHead = [1; 1; 1];
    members.nodesEnd  = [2; 3; 4];
    members.nmembers  = 3;

    A = equilibriumMatrixFn(nodes, members, kinematic);
    [cutSets, gH, ~] = nullSpaceCutSetsFn(A);

    setsStr = cutSetsToStr(cutSets);
    fprintf('theta = %5.1f deg   gH = %d   cut-sets = %s\n', th, gH, setsStr);
end

fprintf('\nExpected qualitative pattern (metodika.md Table 1):\n');
fprintf('  theta=0deg:            1 necessary bar + 1 pair\n');
fprintf('  theta=1,45,89deg:      all 3 pairs, no necessary bar\n');
fprintf('  theta=90deg:           other necessary bar + 1 pair\n');

function s = cutSetsToStr(cutSets)
parts = cell(1, numel(cutSets));
for i = 1:numel(cutSets)
    parts{i} = ['[' num2str(cutSets{i}, '%d,') ']'];
    parts{i} = strrep(parts{i}, ',]', ']');
end
s = ['{' strjoin(parts, ', ') '}'];
end
