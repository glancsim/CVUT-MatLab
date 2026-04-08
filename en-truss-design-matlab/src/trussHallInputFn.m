function [nodes, members, sections, kinematic, loadParams] = trussHallInputFn(params)
% trussHallInputFn  Generate 2D truss geometry for an industrial hall.
%
% Supports multiple topologies and chord shapes, compatible with the
% fem-2d-truss-matlab linearSolverFn.  Also returns loadParams for use
% in loadCombinationsFn.
%
% TOPOLOGY options (params.topology):
%   'pratt'  — (default) diagonals lean toward nearest support → tension
%              under downward gravity load
%   'howe'   — diagonals lean away from nearest support → compression
%              under gravity (opposite of Pratt)
%   'warren' — alternating diagonals, no verticals (or with verticals if
%              params.warren_verticals = true)
%
% SHAPE options (params.shape):
%   'saddle' — (default) symmetric saddle (sedlový): linear rise from each
%              support to midspan; max height = h_support + slope * L/2
%   'flat'   — flat (pultový rovný): constant height h_support
%   'mono'   — mono-pitch (pultový šikmý): linearly rising from left
%              (h_support) to right (h_support + slope * span)
%
%   Section groups (input):  1 = top chord, 2 = bottom chord, 3 = diagonals, [4 = verticals]
%   Symmetric expansion:  diagonals and verticals are automatically split
%   into symmetric sub-groups (each pair equidistant from midspan = one group).
%   Output sections has nGroups entries: 1=top, 2=bot, 3..2+nD = diag, 2+nD+1..end = vert.
%
% INPUTS:
%   params  - struct with fields (all optional, defaults shown):
%     .span             [m]      Total span                    (30)
%     .slope            [-]      Roof slope (rise/run)         (0.05)
%     .purlin_spacing   [m]      Panel / purlin spacing        (3)
%     .h_support        [m]      Truss height at support       (2.5)
%     .truss_spacing    [m]      Distance between trusses      (6)
%     .f_y              [Pa]     Yield strength                (355e6)
%     .E                [Pa]     Young's modulus               (210e9)
%     .g_roof           [kN/m²]  Dead load (cladding only)    (0.35)
%     .s_k              [kN/m²]  Snow load characteristic     (0.7)
%     .w_suction        [kN/m²]  Wind suction char. (>0=up)   (0.5)
%     .topology         char     Truss topology                ('pratt')
%     .shape            char     Chord shape                   ('saddle')
%     .warren_verticals logical  Add verticals to Warren truss (false)
%     .sections         struct   Cross-section properties (required):
%                                  .A        [m²]   (3×1 or 4×1)
%                                  .E        [Pa]   (3×1 or 4×1)
%                                  .I        [m⁴]   (3×1 or 4×1)
%                                  .i_radius [m]    (3×1 or 4×1)
%                                  .curve    cell   (3×1 or 4×1)
%                                  Groups: 1=top chord, 2=bottom chord,
%                                          3=diagonals, 4=verticals
%
% OUTPUTS:
%   nodes     - struct: .x, .z (nnodes×1) [m]
%   members   - struct: .nodesHead, .nodesEnd, .sections (nmembers×1)
%   sections  - same as params.sections (passed through for solver + checks)
%   kinematic - struct: .x.nodes, .z.nodes (pin + roller)
%   loadParams - struct with load calculation inputs:
%     .top_nodes      (n+1)×1  node indices of top chord
%     .trib           (n+1)×1  tributary lengths [m]
%     .truss_spacing  [m]
%     .g_total        [kN/m²]  total dead load incl. self-weight (upper estimate)
%     .g_min          [kN/m²]  minimum dead load (lower estimate for wind combo)
%     .s_k            [kN/m²]
%     .w_suction      [kN/m²]
%     .f_y, .E        material
%     .purlin_spacing [m]
%     .bracing_spacing [m]     = truss_spacing (default out-of-plane bracing)
%     .n_panels       integer
%     .topology       char     (for informational use)
%     .shape          char     (for informational use)
%
% (c) S. Glanc, 2026

%% --- Defaults -----------------------------------------------------------
if ~isfield(params, 'span'),              params.span              = 30;     end
if ~isfield(params, 'slope'),             params.slope             = 0.05;   end
if ~isfield(params, 'purlin_spacing'),    params.purlin_spacing    = 3;      end
if ~isfield(params, 'h_support'),         params.h_support         = 2.5;    end
if ~isfield(params, 'truss_spacing'),     params.truss_spacing     = 6;      end
if ~isfield(params, 'f_y'),               params.f_y               = 355e6;  end
if ~isfield(params, 'E'),                 params.E                 = 210e9;  end
if ~isfield(params, 'g_roof'),            params.g_roof            = 0.35;   end
if ~isfield(params, 's_k'),               params.s_k               = 0.7;    end
if ~isfield(params, 'w_suction'),         params.w_suction         = 0.5;    end
if ~isfield(params, 'v_b'),              params.v_b              = [];      end
if ~isfield(params, 'terrain_cat'),      params.terrain_cat      = 'II';    end
if ~isfield(params, 'h_eave'),           params.h_eave           = 0;       end
if ~isfield(params, 'topology'),          params.topology          = 'pratt'; end
if ~isfield(params, 'shape'),             params.shape             = 'saddle'; end
if ~isfield(params, 'warren_verticals'),  params.warren_verticals  = false;  end

assert(isfield(params, 'sections'), ...
    'trussHallInputFn: params.sections is required (fields: A, E, I, i_radius, curve)');

L  = params.span;
sl = params.slope;
a  = params.purlin_spacing;
hs = params.h_support;
n  = round(L / a);   % number of panels

assert(abs(n*a - L) < 1e-6, ...
    'trussHallInputFn: span (%.1f m) must be divisible by purlin_spacing (%.1f m)', L, a);

nb = n + 1;   % nodes per chord

%% --- Node coordinates ---------------------------------------------------
x_chord = (0 : a : L)';   % (nb×1)

% Bottom chord: z = 0
z_bot = zeros(nb, 1);

% Top chord shape
switch lower(params.shape)
    case 'saddle'
        % Symmetric saddle — linear rise from each support to midspan
        z_top = hs + sl * min(x_chord, L - x_chord);

    case 'flat'
        % Flat top chord — constant height
        z_top = hs * ones(nb, 1);

    case 'mono'
        % Mono-pitch — linear rise from left (hs) to right (hs + sl*L)
        z_top = hs + sl * x_chord;

    otherwise
        error('trussHallInputFn: unknown shape ''%s''. Use ''saddle'', ''flat'', or ''mono''.', ...
              params.shape);
end

nodes.x = [x_chord; x_chord];
nodes.z = [z_bot;   z_top  ];

%% --- Members ------------------------------------------------------------
% --- Bottom chord (section 2): nodes 1..nb ---
botHead  = (1 : n)';
botEnd   = (2 : nb)';
sec_bot  = 2 * ones(n, 1);

% --- Top chord (section 1): nodes nb+1..2*nb ---
topHead  = (nb+1 : nb+n)';
topEnd   = (nb+2 : 2*nb)';
sec_top  = 1 * ones(n, 1);

% --- Verticals and diagonals (topology-dependent) ------------------------
% Each case builds diagHead, diagEnd, vertHead, vertEnd.
% Section assignment (symmetric groups) is done after the switch.
vertHead = zeros(0, 1);
vertEnd  = zeros(0, 1);

switch lower(params.topology)

    % ── PRATT ──────────────────────────────────────────────────────────────
    case 'pratt'
        % Verticals: bot[k] → top[k],  k = 1..nb
        vertHead = (1 : nb)';
        vertEnd  = (nb+1 : 2*nb)';

        % Diagonals lean toward nearest support (tension under gravity):
        %   Left half  (k=1..nL): bot[k+1] → top[k]
        %   Right half (k=1..nR): bot[nL+k] → top[nL+k+1]
        nL = floor(n/2);
        nR = n - nL;
        diagHead = zeros(n, 1);
        diagEnd  = zeros(n, 1);
        for k = 1:nL
            diagHead(k) = k + 1;
            diagEnd(k)  = nb + k;
        end
        for k = 1:nR
            diagHead(nL + k) = nL + k;
            diagEnd(nL + k)  = nb + nL + k + 1;
        end

    % ── HOWE ───────────────────────────────────────────────────────────────
    case 'howe'
        % Verticals: same as Pratt
        vertHead = (1 : nb)';
        vertEnd  = (nb+1 : 2*nb)';

        % Diagonals lean away from nearest support (compression under gravity):
        %   Left half  (k=1..nL): bot[k] → top[k+1]
        %   Right half (k=1..nR): bot[nL+k+1] → top[nL+k]
        nL = floor(n/2);
        nR = n - nL;
        diagHead = zeros(n, 1);
        diagEnd  = zeros(n, 1);
        for k = 1:nL
            diagHead(k) = k;
            diagEnd(k)  = nb + k + 1;
        end
        for k = 1:nR
            diagHead(nL + k) = nL + k + 1;
            diagEnd(nL + k)  = nb + nL + k;
        end

    % ── WARREN ─────────────────────────────────────────────────────────────
    case 'warren'
        % Alternating diagonals, no verticals (unless warren_verticals = true).
        %   Odd  panels (k=1,3,5,...): bot[k] → top[k+1]  (going right-up)
        %   Even panels (k=2,4,6,...): bot[k+1] → top[k]  (going left-up)
        diagHead = zeros(n, 1);
        diagEnd  = zeros(n, 1);
        for k = 1:n
            if mod(k, 2) == 1   % odd panel
                diagHead(k) = k;
                diagEnd(k)  = nb + k + 1;
            else                % even panel
                diagHead(k) = k + 1;
                diagEnd(k)  = nb + k;
            end
        end

        if params.warren_verticals
            vIdx     = (2 : nb-1)';   % interior nodes of bottom chord
            vertHead = vIdx;
            vertEnd  = nb + vIdx;
        end

    % ── WARREN INVERTED ───────────────────────────────────────────────────
    case 'warren_inverted'
        % Alternating diagonals, flipped orientation compared to Warren
        %   Odd  panels: bot[k+1] → top[k]
        %   Even panels: bot[k]   → top[k+1]
        diagHead = zeros(n, 1);
        diagEnd  = zeros(n, 1);
        for k = 1:n
            if mod(k, 2) == 1   % odd panel
                diagHead(k) = k + 1;
                diagEnd(k)  = nb + k;
            else                % even panel
                diagHead(k) = k;
                diagEnd(k)  = nb + k + 1;
            end
        end

        % Verticals: always include first and last
        vIdx_edge = [1; nb];
        if params.warren_verticals
            vIdx = [vIdx_edge; (2 : nb-1)'];
        else
            vIdx = vIdx_edge;
        end
        vertHead = vIdx;
        vertEnd  = nb + vIdx;

    otherwise
        error('trussHallInputFn: unknown topology ''%s''. Use ''pratt'', ''howe'', or ''warren''.', ...
              params.topology);
end

%% --- Symmetric section groups for diagonals and verticals ---------------
%  Each symmetric pair (equidistant from midspan) gets its own section index.
%  Numbering: 1=top chord, 2=bottom chord,
%             3..2+nDiagGroups = diagonal groups (outermost first),
%             2+nDiagGroups+1..nGroups = vertical groups (outermost first).

% --- Diagonals ---
mid_x_diag = (nodes.x(diagHead) + nodes.x(diagEnd)) / 2;
dist_diag  = abs(mid_x_diag - L/2);
[uniq_dd, ~, grp_diag] = unique(round(dist_diag, 6));
% Remap so outermost = lowest section index (sec 3)
[~, sort_dd] = sort(uniq_dd, 'descend');
remap_d = zeros(numel(uniq_dd), 1);
remap_d(sort_dd) = (1:numel(sort_dd))';
sec_diag = 2 + remap_d(grp_diag);
nDiagGroups = numel(uniq_dd);

% --- Verticals ---
hasVert = ~isempty(vertHead);
if hasVert
    mid_x_vert = (nodes.x(vertHead) + nodes.x(vertEnd)) / 2;
    dist_vert  = abs(mid_x_vert - L/2);
    [uniq_dv, ~, grp_vert] = unique(round(dist_vert, 6));
    [~, sort_dv] = sort(uniq_dv, 'descend');
    remap_v = zeros(numel(uniq_dv), 1);
    remap_v(sort_dv) = (1:numel(sort_dv))';
    sec_vert = 2 + nDiagGroups + remap_v(grp_vert);
    nVertGroups = numel(uniq_dv);
else
    sec_vert = zeros(0, 1);
    nVertGroups = 0;
end

nGroups = 2 + nDiagGroups + nVertGroups;

%% --- Assemble members ---------------------------------------------------
if hasVert
    members.nodesHead = [botHead; topHead; vertHead; diagHead];
    members.nodesEnd  = [botEnd;  topEnd;  vertEnd;  diagEnd ];
    members.sections  = [sec_bot; sec_top; sec_vert; sec_diag];
else
    members.nodesHead = [botHead; topHead; diagHead];
    members.nodesEnd  = [botEnd;  topEnd;  diagEnd ];
    members.sections  = [sec_bot; sec_top; sec_diag];
end

%% --- Expand sections to nGroups ----------------------------------------
%  Input sections has 3 or 4 entries (top, bot, diag, [vert]).
%  Replicate diagonal properties to groups 3..2+nDiagGroups,
%  replicate vertical properties to groups 2+nDiagGroups+1..nGroups.
secIn = params.sections;
diagSrcIdx = 3;                                        % source for diagonals
vertSrcIdx = min(numel(secIn.A), 4);                   % source for verticals (4 if exists, else 3)

sections.A        = zeros(nGroups, 1);
sections.E        = zeros(nGroups, 1);
sections.I        = zeros(nGroups, 1);
sections.i_radius = zeros(nGroups, 1);
sections.curve    = cell(nGroups, 1);
if isfield(secIn, 'D'), sections.D = zeros(nGroups, 1); end
if isfield(secIn, 't'), sections.t = zeros(nGroups, 1); end

for sg = 1:nGroups
    if sg <= 2
        srcIdx = sg;                     % top/bottom chord
    elseif sg <= 2 + nDiagGroups
        srcIdx = diagSrcIdx;             % diagonal group → copy from input sec 3
    else
        srcIdx = vertSrcIdx;             % vertical group → copy from input sec 4 (or 3)
    end
    sections.A(sg)        = secIn.A(srcIdx);
    sections.E(sg)        = secIn.E(srcIdx);
    sections.I(sg)        = secIn.I(srcIdx);
    sections.i_radius(sg) = secIn.i_radius(srcIdx);
    sections.curve{sg}    = secIn.curve{srcIdx};
    if isfield(secIn, 'D'), sections.D(sg) = secIn.D(srcIdx); end
    if isfield(secIn, 't'), sections.t(sg) = secIn.t(srcIdx); end
end

%% --- Supports -----------------------------------------------------------
% Pin at left support (node 1), roller at right support (node nb)
kinematic.x.nodes = 1;
kinematic.z.nodes = [1; nb];

%% --- Load parameters ---------------------------------------------------
% Self-weight estimate per Jandera OK 01, kap. 1.4.4:
%   g = L/76 * sqrt(q_d * d)   [kN/m²]  — upper bound for combo 1
%   g_min = 0.5 * g            [kN/m²]  — lower bound for combo 2
g_d    = params.g_roof + params.s_k + params.g_purlins/params.purlin_spacing;
g_self = L / 76 * sqrt(g_d * params.truss_spacing) / params.truss_spacing; %[kN/m²]
g_total = params.g_roof + params.g_purlins/params.purlin_spacing +  g_self;
g_min   = params.g_roof + 0.5 * g_self;

% Tributary lengths for top chord nodes
trib        = a * ones(nb, 1);
trib(1)     = a / 2;   % left edge node
trib(nb)    = a / 2;   % right edge node

loadParams.top_nodes       = (nb+1 : 2*nb)';
loadParams.trib            = trib;
loadParams.truss_spacing   = params.truss_spacing;
loadParams.g_total         = g_total;
loadParams.g_min           = g_min;
loadParams.s_k             = params.s_k;
loadParams.w_suction       = params.w_suction;
loadParams.f_y             = params.f_y;
loadParams.E               = params.E;
loadParams.purlin_spacing  = params.purlin_spacing;
loadParams.bracing_spacing = params.truss_spacing;
loadParams.n_panels        = n;
loadParams.sections        = sections;
loadParams.sectionGroups.nDiag    = nDiagGroups;
loadParams.sectionGroups.nVert    = nVertGroups;
loadParams.sectionGroups.diagIdx  = (3 : 2+nDiagGroups);
loadParams.sectionGroups.vertIdx  = (2+nDiagGroups+1 : nGroups);
loadParams.sectionGroups.nGroups  = nGroups;
loadParams.topology        = params.topology;
loadParams.shape           = params.shape;

%% --- Wind load (optional — requires v_b) --------------------------------
% If params.v_b is set, compute q_p and c_pe via windLoadsFn.
% Ridge height = column height (h_eave) + truss height at midspan.
if ~isempty(params.v_b)
    switch lower(params.shape)
        case 'flat',  h_truss_max = params.h_support;
        case 'mono',  h_truss_max = params.h_support + params.slope * L;
        otherwise,    h_truss_max = params.h_support + params.slope * L/2;
    end
    h_ridge = params.h_eave + h_truss_max;
    wind = windLoadsFn(params.v_b, params.terrain_cat, h_ridge, params.slope);
    loadParams.q_b      = wind.q_b;
    loadParams.q_p      = wind.q_p;
    loadParams.c_e      = wind.c_e;
    loadParams.c_pe_Wt  = wind.c_pe_Wt;
    loadParams.c_pe_Wl  = wind.c_pe_Wl;
    loadParams.q_Wt     = wind.q_Wt;
    loadParams.q_Wl     = wind.q_Wl;
    loadParams.w_suction = wind.q_Wt;   % backward compat
    loadParams.v_b       = params.v_b;
    loadParams.terrain_cat = params.terrain_cat;
    loadParams.h_ridge   = h_ridge;
end

fprintf('Vazník: L = %.0f m, a = %.1f m, n = %d panelů  [%s / %s]\n', ...
    L, a, n, upper(params.topology), upper(params.shape));
fprintf('  Průřezové skupiny: %d (2 pásy + %d diag + %d vert)\n', ...
    nGroups, nDiagGroups, nVertGroups);
fprintf('  Vlastní tíha (odhad): g = %.3f kN/m²,  g_min = %.3f kN/m²\n', ...
    g_total, g_min);

end
