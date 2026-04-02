function combos = loadCombinationsFn(loadParams)
% loadCombinationsFn  Generate ULS load combinations for a hall truss.
%
% Two governing combinations for saddle roofs with slope ≤ 20%
% per Jandera — OK 01, kap. 1.4.4:
%
%   Combo 1:  1.35·G + 1.5·S   (permanent + snow)
%             → max compression in top chord
%
%   Combo 2:  1.0·G_min + 1.5·W_suction
%             → wind uplift, possible compression in bottom chord
%             → G_min = g_roof + 0.5·g_self  (lower dead load estimate)
%
% Loads are applied as concentrated forces at top chord nodes (purlin locations).
% Forces are in [N], positive = upward.
%
% INPUTS:
%   loadParams - struct from trussHallInputFn with fields:
%     .top_nodes      (nb×1) node indices for top chord
%     .trib           (nb×1) tributary lengths [m]
%     .truss_spacing  [m]
%     .g_total        [kN/m²]  dead load (upper bound)
%     .g_min          [kN/m²]  dead load (lower bound)
%     .s_k            [kN/m²]  snow characteristic
%     .w_suction      [kN/m²]  wind suction characteristic (>0 = upward)
%
% OUTPUTS:
%   combos  - (2×1) cell array, each element is a struct with:
%     .loads        struct compatible with linearSolverFn
%       .x.nodes, .x.value   (empty — no horizontal loads)
%       .z.nodes, .z.value   [N] vertical nodal forces
%     .description  string label
%     .gamma_G      partial factor for permanent action
%     .gamma_Q      partial factor for variable action
%     .q_net        [kN/m²]  net distributed load for reference
%
% (c) S. Glanc, 2026

b    = loadParams.truss_spacing;   % [m]
trib = loadParams.trib;            % [m], tributary length per top node
top  = loadParams.top_nodes;       % node indices

%% Combo 1: 1.35·G + 1.5·S  (downward)
q1 = 1.35 * loadParams.g_total + 1.5 * loadParams.s_k;   % [kN/m²]
Fz1 = -q1 * b * trib * 1e3;   % [N], negative = downward

loads1.x.nodes = [];  loads1.x.value = [];
loads1.z.nodes = top;
loads1.z.value = Fz1;

c1.loads       = loads1;
c1.description = '1.35·G + 1.5·S  (stálé + sníh)';
c1.gamma_G     = 1.35;
c1.gamma_Q     = 1.5;
c1.q_net       = q1;

%% Combo 2: 1.0·G_min + 1.5·W_suction  (uplift)
% Net force per unit area (positive = upward):
%   gravity component: -1.0 * g_min  (downward = negative)
%   wind suction:      +1.5 * w_suction (upward = positive)
q2  = -1.0 * loadParams.g_min + 1.5 * loadParams.w_suction;   % [kN/m²]
Fz2 = q2 * b * trib * 1e3;   % [N], positive if net uplift

loads2.x.nodes = [];  loads2.x.value = [];
loads2.z.nodes = top;
loads2.z.value = Fz2;

c2.loads       = loads2;
c2.description = '1.0·G_min + 1.5·W  (min stálé + sání)';
c2.gamma_G     = 1.0;
c2.gamma_Q     = 1.5;
c2.q_net       = q2;

combos = {c1; c2};

end
