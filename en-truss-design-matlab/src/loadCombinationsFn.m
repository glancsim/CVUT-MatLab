function combos = loadCombinationsFn(loadParams)
% loadCombinationsFn  Generate ULS load combinations for a hall truss.
%
% Five governing combinations for saddle roofs per Jandera — OK 01, kap. 3
% and EN 1990, Eq. 6.10:
%
%   KZS 1:  1.35·G + 1.5·S              → max compression in top chord
%   KZS 2:  1.35·G + 1.5·S + 0.9·Wt    → combined snow + transverse wind
%   KZS 3:  1.35·G + 1.5·Wt + 0.75·S   → dominant wind + reduced snow
%   KZS 4:  1.0·Gmin + 1.5·Wt          → uplift — transverse wind suction
%   KZS 5:  1.0·Gmin + 1.5·Wl          → uplift — longitudinal wind suction
%
% Snow design value:  S = μ₁·sk = 0.8·sk  (EN 1991-1-3, Tab. 5.2, α ≤ 30°)
% Combination factors: ψ₀,S = 0.5,  ψ₀,W = 0.6
%
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
%     .q_Wt           [kN/m²]  transverse wind uplift (>0 = upward)
%                              fallback: .w_suction
%     .q_Wl           [kN/m²]  longitudinal wind uplift (>0 = upward)
%                              fallback: .w_suction
%
% OUTPUTS:
%   combos  - (5×1) cell array, each element is a struct with:
%     .loads        struct compatible with linearSolverFn
%       .x.nodes, .x.value   (empty — no horizontal loads)
%       .z.nodes, .z.value   [N] vertical nodal forces
%     .description  string label (HTML)
%     .gamma_G      partial factor for permanent action
%     .gamma_Q      partial factor for leading variable action
%     .q_G          [kN/m²] dead load component (factored)
%     .q_S          [kN/m²] snow component (factored, downward positive)
%     .q_W          [kN/m²] wind component (factored, upward positive)
%     .q_net        [kN/m²] net downward load (positive = downward)
%
% (c) S. Glanc, 2026

b    = loadParams.truss_spacing;   % [m]
trib = loadParams.trib;            % [m]
top  = loadParams.top_nodes;

% Self-weight: actual nodal forces (if available) or legacy scalar
hasSW = isfield(loadParams, 'selfWeight');
if hasSW
    sw     = loadParams.selfWeight;      % struct .nodes, .values [N]
    g_roof = loadParams.g_roof;          % [kN/m²] roof + purlins only
else
    sw     = struct('nodes', [], 'values', []);
    g_roof = loadParams.g_total;         % legacy — all dead load in one scalar
end

% Snow design value: μ₁ = 0.8 per EN 1991-1-3 Tab. 5.2 (saddle, α ≤ 30°)
mu1 = 0.8;
s_d = mu1 * loadParams.s_k;       % [kN/m²]

% Wind uplift (fallback to w_suction if computed values not available)
if isfield(loadParams, 'q_Wt')
    q_Wt = loadParams.q_Wt;
elseif isfield(loadParams, 'w_suction')
    q_Wt = loadParams.w_suction;
else
    q_Wt = 0;
end

if isfield(loadParams, 'q_Wl')
    q_Wl = loadParams.q_Wl;
elseif isfield(loadParams, 'w_suction')
    q_Wl = loadParams.w_suction;
else
    q_Wl = 0;
end

%% Helper — assemble one combo struct -----------------------------------
    function c = makeCombo(gG, qG_roof, gS, qS, gW, qW, desc)
        % qG_roof: roof+purlins [kN/m²]; qS: snow [kN/m²]; qW: wind [kN/m²]
        q_net_top = gG*qG_roof + gS*qS - gW*qW;  % net on top chord [kN/m²]
        Fz_top    = -q_net_top * b .* trib * 1e3;  % [N], negative = downward

        % Self-weight nodal forces (all nodes)
        if hasSW && ~isempty(sw.nodes)
            Fz_sw      = gG * sw.values;            % [N], gamma_G applied
            all_nodes  = [top;    sw.nodes];
            all_values = [Fz_top; Fz_sw];
        else
            all_nodes  = top;
            all_values = Fz_top;
        end

        lds.x.nodes = [];  lds.x.value = [];
        lds.z.nodes = all_nodes;
        lds.z.value = all_values;
        c.loads       = lds;
        c.description = desc;
        c.gamma_G     = gG;
        c.gamma_Q     = max([gS, gW]);
        c.q_G         = gG * qG_roof;
        c.q_S         = gS * qS;
        c.q_W         = gW * qW;
        c.q_net       = q_net_top;
    end

%% 5 KZS ----------------------------------------------------------------
c1 = makeCombo(1.35, g_roof, 1.50, s_d,  0,    0,    ...
    '1,35&middot;G + 1,5&middot;S');

c2 = makeCombo(1.35, g_roof, 1.50, s_d,  0.90, q_Wt, ...
    '1,35&middot;G + 1,5&middot;S + 0,9&middot;W<sub>t</sub>');

c3 = makeCombo(1.35, g_roof, 0.75, s_d,  1.50, q_Wt, ...
    '1,35&middot;G + 1,5&middot;W<sub>t</sub> + 0,75&middot;S');

c4 = makeCombo(1.00, g_roof, 0,    0,    1.50, q_Wt, ...
    '1,0&middot;G<sub>inf</sub> + 1,5&middot;W<sub>t</sub>');

c5 = makeCombo(1.00, g_roof, 0,    0,    1.50, q_Wl, ...
    '1,0&middot;G<sub>inf</sub> + 1,5&middot;W<sub>l</sub>');

combos = {c1; c2; c3; c4; c5};

end
