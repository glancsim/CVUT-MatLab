function model = polakFrameModelFn(opts)
% polakFrameModelFn  Parametric pin-jointed model of a lattice portal frame
% with a gable roof: Polák "konstrukce AT" (tapered single-point column foot,
% default), the same frame with two-point column bases (taperedFoot = false,
% e.g. the Montcome hall), optionally the arched Polák "UT" variant.
%
% WHY THIS STRUCTURE: the committee asked for a real, existing statically
% indeterminate truss. Ordinary roof trusses are statically determinate. The
% Polák AT hall frame is a planar LATTICE PORTAL FRAME: two-branch lattice
% columns, a lattice rafter whose chords run continuously round the eaves
% corner, and each column tapering at its foot into ONE support point. In the
% frame plane it is therefore a two-hinged lattice frame, gH = 1, with no
% X-bracing at all -- redundancy comes from the frame action, not from
% doubled diagonals.
%
% TOPOLOGY (inferred from the manufacturer's schematic, NOT from drawings;
% see example_polak_frame.m header for what was read off which image):
%
%   eaves corner (left):            column foot (left):
%
%   C_out ---- T0 ---- T1 ...          O_m ------ I_b      O_m-I_b  = foot strut
%     |      / |     / |                |        /         I_b-F    = inclined
%     |    /   |   /   |                |      /                       member
%     |  /     | /     |                |    /
%    O1 ------ C_in -- B1 ...           |  /
%     |  \     |                        F   <- single pinned support (x,z)
%     |    \   |
%     |      \ |   <- column Warren zigzag O1-I1-O2-I2-...-O_m
%    O2       I1
%
%   rafter : top chord C_out-T0-T1-..-Tn, bottom chord C_in=B0-B1-..-Bn,
%            posts Bk-Tk (global vertical for 'gable', radial for 'arch'),
%            one diagonal per panel; 'pratt' = B(k-1)-Tk (rising towards the
%            ridge, as drawn), 'howe' = T(k-1)-Bk. Ridge post Bn-Tn shared.
%            'warren' = zigzag without intermediate posts: top-chord nodes at
%            mid-panel, B(k-1)-T(k-1/2)-Bk; only post 0 and the ridge post.
%   corner : outer chord C_out-O1, eave strut O1-C_in, corner diagonal O1-T0.
%   column : 'warren' (as drawn) = zigzag O_j-I_j-O_(j+1), no struts;
%            'pratt' = horizontal struts O_j-I_j + one diagonal per panel.
%   foot   : taperedFoot = true (Polák AT, as drawn) = foot strut O_m-I_b +
%            inclined I_b-F + outer chord O_m-F, F pinned in x and z;
%            taperedFoot = false (two-point base, e.g. Montcome) = no taper,
%            the column zigzag runs down to z = 0 and both branch feet O_m
%            and I_b are pinned (x and z) -> 4 support points per frame.
%
% Every quadrilateral carries exactly one diagonal, so the whole frame is one
% just-rigid triangulated strip (b = 2j - 3); the two feet give 4 reactions,
% hence gH = b + r - 2j = 1 for the tapered foot. The two-point base has no
% foot strut (both its end nodes are supports), so b = 2j - 5 with r = 8
% reactions: gH = 3, the classic fixed-base portal frame.
%
% OUTER EAVES CORNER: as drawn, the corner diagonal runs O1-T0, so the outer
% corner node C_out is held by only two (non-collinear) bars -- a dyad that
% adds no rigidity. In the pin-jointed idealisation those two bars carry no
% self-stress and each is a NECESSARY bar (losing one lets C_out swing). In
% the real frame the chords are continuous through the corner, so this is an
% artefact of the pin-jointed idealisation. 'Cout-Cin' puts the diagonal on
% the other corner diagonal and removes the dyad.
%
% PLACEHOLDER DIMENSIONS: no real hall documentation is available yet. The
% defaults below are plausible values with the proportions of the schematic
% (pitch ~15 deg measured on the image; rafter depth = column width; roughly
% square rafter panels; ~45 deg column diagonals) and must be replaced by the
% real ones once obtained -- every dimension is an opts field.
%
% INPUT: opts (struct, optional), fields (default):
%   .span          (15)      [m] distance of the two support points F
%                            (= axis of the outer column chords)
%   .eaveHeight    (5)       [m] outer eaves corner C_out above the supports
%   .pitchDeg      (15)      [deg] roof pitch ('gable')
%   .depth         (0.6)     [m] column width = rafter depth (perpendicular)
%   .nRafterPanels ([])      panels per rafter half; [] = auto (~square)
%   .nColumnPanels ([])      column panels (Warren: number of V's); [] = auto
%   .footHeight    ([])      [m] height of the foot strut; [] = depth
%   .rafterPattern ('pratt') 'pratt' | 'howe' | 'warren'
%   .columnPattern ('warren')'warren' | 'pratt'
%   .taperedFoot   (true)    true = single-point pinned foot (Polák AT),
%                            false = two pinned branch feet (Montcome-like)
%   .cornerDiagonal('O1-T0') 'O1-T0' (as drawn: leaves the outer corner C_out
%                            a two-bar node, see below) | 'Cout-Cin'
%   .shape         ('gable') 'gable' | 'arch' (UT: circular chords, crude)
%   .archRise      ([])      [m] crown rise above the eaves; [] = 0.25*span
%   .computeCutSets (true)   true   = equilibriumMatrixFn + nullSpaceCutSetsFn
%                            'count'= gH, null space and cut-set COUNTS by
%                                     size only (cutSetSizeCount below), no
%                                     enumeration -- for gH <= 3 models where
%                                     the gH+1 sets number in the millions
%                            false  = skip
%   .design        (false)   build load cases, FSD sizing and rvSpec
%   .groups        ('3')     section groups: '3' = chords | rafter web |
%                            column web
%   .loadMean   ([2.4e3; 2.0e3]) [N/m] mean line load on the horizontal
%                            projection: [self-weight+roof; snow] (PLACEHOLDER)
%   .loadCOV    ([0.10; 0.25])
%   .sigmaAllow (210e6) [Pa]  FSD target stress (as warrenXbraceModelFn)
%   .f_y        (355e6) [Pa]  resMean = f_y * A (as warrenXbraceModelFn)
%   .covR       (0.08)
%   .verbose    (false)
%
% OUTPUT: model (struct)
%   .nodes, .members, .kinematic   fem-2d-truss-matlab convention
%   .role (nm x 1), .roleNames     member role codes (see ROLE_NAMES below)
%   .label (nm x 1 cell)           human-readable location of every member
%   .side  (nm x 1)                -1 left half, +1 right half, 0 ridge
%   .group, .groupNames            section/resistance group per member
%   .gH, .V, .cutSetCount (1 x gH+1), .necessary, .rankDeficit
%                                  if computeCutSets (true or 'count')
%   .cutSets                       all minimal cut-sets   (computeCutSets true)
%   .cutSetsUpToGH                 cut-sets of size <= gH (computeCutSets
%                                  'count', gH >= 2)
%   .params                        the resolved opts
%   .topNodes, .unitRoof           roof top-chord nodes and the unit (1 N/m)
%                                  load case                (if design)
%   .sections, .rvSpec, .meanLoads, .fsdHistory               (if design)
%
% DETERMINISM: no random numbers are drawn here.
%
% See also: example_polak_frame, warrenXbraceModelFn, equilibriumMatrixFn,
%           nullSpaceCutSetsFn, fullyStressedDesignFn
%
% (c) S. Glanc, 2026

if nargin < 1, opts = struct(); end
p = fillDefaults(opts);

L = p.span;  H = p.eaveHeight;  d = p.depth;
if isempty(p.footHeight), p.footHeight = d; end

ROLE_NAMES = {'rafter top chord', 'rafter bottom chord', 'rafter post', ...
    'rafter diagonal', 'column outer chord', 'column inner chord', ...
    'column diagonal', 'column strut', 'corner diagonal', 'foot inclined'};

%% Rafter chord stations (left half: eave -> ridge)
switch lower(p.shape)
    case 'gable'
        tA = tand(p.pitchDeg);  cA = cosd(p.pitchDeg);
        zTop = @(x) H + x * tA;
        zBot = @(x) H + x * tA - d / cA;
        Cout = [0, H];
        if isempty(p.nRafterPanels)
            p.nRafterPanels = max(2, round((L/2 - d) / (d / cA)));
        end
        n  = p.nRafterPanels;
        xs = linspace(d, L/2, n + 1)';
        Bk = [xs, zBot(xs)];
        Tk = [xs, zTop(xs)];
        xm = (xs(1:end-1) + xs(2:end)) / 2;
        Tm = [xm, zTop(xm)];                      % mid-panel top nodes ('warren')
    case 'arch'
        if isempty(p.archRise), p.archRise = 0.25 * L; end
        f  = p.archRise;
        R  = ((L/2)^2 + f^2) / (2 * f);          % outer-chord circle through C_out, crown, C_out'
        xc = L/2;  zc = H + f - R;
        Cout = [0, H];
        th0 = acos((d - xc) / (R - d));           % inner chord meets the inner column line x = d
        if isempty(p.nRafterPanels)
            p.nRafterPanels = max(2, round((R - d) * abs(th0 - pi/2) / d));
        end
        n  = p.nRafterPanels;
        th = linspace(th0, pi/2, n + 1)';
        Bk = [xc + (R - d) * cos(th), zc + (R - d) * sin(th)];
        Tk = [xc + R * cos(th),       zc + R * sin(th)];   % radial posts
        thm = (th(1:end-1) + th(2:end)) / 2;
        Tm = [xc + R * cos(thm), zc + R * sin(thm)];
    otherwise
        error('polakFrameModelFn:shape', 'Unknown shape ''%s''.', p.shape);
end
Cin = Bk(1, :);
O1  = [0, Cin(2)];
if Cin(2) >= H
    error('polakFrameModelFn:geometry', 'Inner eaves corner above the outer one -- check depth/pitch.');
end

%% Build the LEFT half (nodes as coordinates, members as coordinate pairs)
X = zeros(0, 2);            % node coordinates
M = zeros(0, 2);            % member node pairs (local to X)
role = zeros(0, 1);
lab  = cell(0, 1);

    function id = nd(xz)
        % node id of coordinate xz (merge exact duplicates within the half)
        if ~isempty(X)
            hit = find(abs(X(:,1) - xz(1)) < 1e-9 & abs(X(:,2) - xz(2)) < 1e-9, 1);
            if ~isempty(hit), id = hit; return; end
        end
        X(end+1, :) = xz;
        id = size(X, 1);
    end
    function mb(a, b, r, txt)
        M(end+1, :) = [nd(a), nd(b)];
        role(end+1, 1) = r;
        lab{end+1, 1} = txt;
    end

% rafter
mb(Cout, Tk(1,:), 1, 'rafter top chord, eaves segment C_out-T0');
for k = 1:n
    mb(Bk(k,:), Bk(k+1,:), 2, sprintf('rafter bottom chord, panel %d', k));
end
switch lower(p.rafterPattern)
    case {'pratt', 'howe'}
        for k = 1:n
            mb(Tk(k,:), Tk(k+1,:), 1, sprintf('rafter top chord, panel %d', k));
        end
        for k = 0:n
            if k == n, txt = 'ridge post'; else, txt = sprintf('rafter post %d', k); end
            if k == 0, txt = 'rafter post 0 (above inner eaves corner)'; end
            mb(Bk(k+1,:), Tk(k+1,:), 3, txt);
        end
        for k = 1:n
            if strcmpi(p.rafterPattern, 'pratt')
                mb(Bk(k,:), Tk(k+1,:), 4, sprintf('rafter diagonal, panel %d', k));
            else
                mb(Tk(k,:), Bk(k+1,:), 4, sprintf('rafter diagonal, panel %d', k));
            end
        end
    case 'warren'
        topChain = [Tk(1,:); Tm; Tk(end,:)];
        for k = 1:size(topChain, 1) - 1
            mb(topChain(k,:), topChain(k+1,:), 1, sprintf('rafter top chord, segment %d', k));
        end
        mb(Bk(1,:), Tk(1,:), 3, 'rafter post 0 (above inner eaves corner)');
        mb(Bk(end,:), Tk(end,:), 3, 'ridge post');
        for k = 1:n
            mb(Bk(k,:),  Tm(k,:),   4, sprintf('rafter diagonal %d', 2*k-1));
            mb(Tm(k,:),  Bk(k+1,:), 4, sprintf('rafter diagonal %d', 2*k));
        end
    otherwise
        error('polakFrameModelFn:pattern', 'Unknown rafterPattern ''%s''.', p.rafterPattern);
end

% eaves corner
mb(Cout, O1, 5, 'column outer chord, eaves segment C_out-O1');
mb(O1, Cin, 8, 'eave strut O1-C_in');
switch upper(p.cornerDiagonal)
    case 'O1-T0',    mb(O1, Tk(1,:), 9, 'corner diagonal O1-T0');
    case 'COUT-CIN', mb(Cout, Cin,    9, 'corner diagonal C_out-C_in');
    otherwise, error('polakFrameModelFn:corner', 'Unknown cornerDiagonal ''%s''.', p.cornerDiagonal);
end

% column
if p.taperedFoot, zBase = p.footHeight; else, zBase = 0; end
if isempty(p.nColumnPanels)
    p.nColumnPanels = max(1, round((O1(2) - zBase) / (2 * d)));
end
m  = p.nColumnPanels;
zO = linspace(O1(2), zBase, m + 1)';
Oj = [zeros(m+1, 1), zO];
Ib = [d, zBase];
switch lower(p.columnPattern)
    case 'warren'
        Ij = [d * ones(m, 1), (zO(1:end-1) + zO(2:end)) / 2];
        innerChain = [Cin; Ij; Ib];
        for j = 1:m
            mb(Oj(j,:), Ij(j,:),   7, sprintf('column diagonal %d (from top)', 2*j-1));
            mb(Ij(j,:), Oj(j+1,:), 7, sprintf('column diagonal %d (from top)', 2*j));
        end
    case 'pratt'
        Ij = [d * ones(m, 1), zO(2:end)];      % Ij(m) == Ib
        innerChain = [Cin; Ij];
        for j = 1:m
            mb(Oj(j,:), Ij(j,:), 7, sprintf('column diagonal %d (from top)', j));
            if j < m
                mb(Oj(j+1,:), Ij(j,:), 8, sprintf('column strut %d (from top)', j));
            end
        end
    otherwise
        error('polakFrameModelFn:pattern', 'Unknown columnPattern ''%s''.', p.columnPattern);
end
for j = 1:m
    mb(Oj(j,:), Oj(j+1,:), 5, sprintf('column outer chord %d (from top)', j));
end
for j = 1:size(innerChain, 1) - 1
    mb(innerChain(j,:), innerChain(j+1,:), 6, sprintf('column inner chord %d (from top)', j));
end
F = [0, 0];
if p.taperedFoot
    mb(Oj(end,:), Ib, 8, 'foot strut O_m-I_b');
    mb(Ib, F, 10, 'foot inclined I_b-F');
    mb(Oj(end,:), F, 5, 'foot outer chord O_m-F');
end

%% Mirror to the right half and merge coincident (ridge) nodes / members
nL  = size(X, 1);
XR  = [L - X(:,1), X(:,2)];
Xall = [X; XR];
key  = round(Xall * 1e6);
[~, iu, ic] = unique(key, 'rows', 'stable');
coords = Xall(iu, :);
Mall = [ic(M); ic(M + nL)];
roleAll = [role; role];
labAll  = [strcat('L', {' '}, lab); strcat('R', {' '}, lab)];
sideAll = [-ones(numel(role), 1); ones(numel(role), 1)];
[~, im] = unique(sort(Mall, 2), 'rows', 'stable');      % ridge post appears twice
Mall = Mall(im, :);  roleAll = roleAll(im);  labAll = labAll(im);  sideAll = sideAll(im);
isRidge = strcmp(labAll, 'L ridge post');
labAll(isRidge) = {'ridge post'};
sideAll(isRidge) = 0;

nodes.x = coords(:, 1);
nodes.z = coords(:, 2);
members.nodesHead = Mall(:, 1);
members.nodesEnd  = Mall(:, 2);
members.nmembers  = size(Mall, 1);

%% Supports
findNode = @(xz) find(abs(nodes.x - xz(1)) < 1e-9 & abs(nodes.z - xz(2)) < 1e-9, 1);
if p.taperedFoot
    sup = [findNode(F); findNode([L, 0])];
else
    sup = [findNode(Oj(end,:)); findNode(Ib); findNode([L, 0]); findNode([L - d, 0])];
end
kinematic.x.nodes = sup;
kinematic.z.nodes = sup;

%% Section groups
switch p.groups
    case '3'
        groupOfRole = [1 1 2 2 1 1 3 3 2 1];
        groupNames  = {'chords', 'rafter web', 'column web'};
    otherwise
        error('polakFrameModelFn:groups', 'Unknown groups ''%s''.', p.groups);
end
group = groupOfRole(roleAll)';
members.sections = group;

model.nodes      = nodes;
model.members    = members;
model.kinematic  = kinematic;
model.role       = roleAll;
model.roleNames  = ROLE_NAMES;
model.label      = labAll;
model.side       = sideAll;
model.group      = group;
model.groupNames = groupNames;
model.params     = p;

if p.verbose
    if p.taperedFoot, ft = 'tapered single-point'; else, ft = 'two-point'; end
    fprintf('Lattice %s frame (%s foot): %d nodes, %d members, %d rafter panels/half, %d column panels\n', ...
        upper(p.shape), ft, numel(nodes.x), members.nmembers, n, m);
end

%% Cut-sets (Phase A)
if ischar(p.computeCutSets) && strcmpi(p.computeCutSets, 'count')
    A_eq = equilibriumMatrixFn(nodes, members, kinematic);
    [model.cutSetCount, model.gH, model.V, model.necessary, model.cutSetsUpToGH] = cutSetSizeCount(A_eq);
    model.rankDeficit = size(A_eq, 1) - rank(A_eq);
    if p.verbose
        fprintf('gH = %d, minimal cut-sets by size = %s (counted, not enumerated)\n', ...
            model.gH, mat2str(model.cutSetCount));
    end
elseif ~ischar(p.computeCutSets) && p.computeCutSets
    A_eq = equilibriumMatrixFn(nodes, members, kinematic);
    [cutSets, gH, V] = nullSpaceCutSetsFn(A_eq);
    model.gH = gH;  model.cutSets = cutSets;  model.V = V;
    model.cutSetCount = accumarray(cellfun(@numel, cutSets(:)), 1, [gH + 1, 1])';
    model.necessary = [cutSets{cellfun(@numel, cutSets) == 1}]';
    model.rankDeficit = size(A_eq, 1) - rank(A_eq);   % >0 would mean a mechanism
    if p.verbose
        fprintf('gH = %d, minimal cut-sets = %d, by size %s, mechanism dofs = %d\n', gH, ...
            numel(cutSets), mat2str(model.cutSetCount), model.rankDeficit);
    end
end

%% Loads, FSD sizing, random variables (placeholders, see header)
if p.design
    % roof load on the top chord: unit case = 1 N/m on the horizontal projection
    isTop = false(numel(nodes.x), 1);
    tc = find(roleAll == 1);
    isTop([members.nodesHead(tc); members.nodesEnd(tc)]) = true;
    topNodes = find(isTop);
    [xt, o] = sort(nodes.x(topNodes));
    topNodes = topNodes(o);
    xe = [xt(1); xt; xt(end)];
    trib = (xe(3:end) - xe(1:end-2)) / 2;
    unitRoof.x.nodes = [];  unitRoof.x.value = [];
    unitRoof.z.nodes = topNodes;  unitRoof.z.value = -trib;

    rvSpec.loadCases = {unitRoof, unitRoof};          % G and S: same pattern, independent RVs
    rvSpec.loadMean  = p.loadMean(:);
    rvSpec.loadStd   = p.loadMean(:) .* p.loadCOV(:);

    meanLoads = unitRoof;
    meanLoads.z.value = -trib * sum(p.loadMean);

    nG = numel(groupNames);
    sections.A = 1e-3 * ones(nG, 1);
    sections.E = 210e9 * ones(nG, 1);
    [sections, fsdHistory] = fullyStressedDesignFn(nodes, members, kinematic, sections, ...
        meanLoads, p.sigmaAllow, struct('verbose', p.verbose));

    rvSpec.resGroup = group;
    rvSpec.resMean  = p.f_y * sections.A;
    rvSpec.resStd   = rvSpec.resMean * p.covR;

    model.topNodes   = topNodes;
    model.unitRoof   = unitRoof;
    model.meanLoads  = meanLoads;
    model.sections   = sections;
    model.rvSpec     = rvSpec;
    model.fsdHistory = fsdHistory;
end

end

%--------------------------------------------------------------------------
function p = fillDefaults(opts)
def = struct('span', 15, 'eaveHeight', 5, 'pitchDeg', 15, 'depth', 0.6, ...
    'nRafterPanels', [], 'nColumnPanels', [], 'footHeight', [], ...
    'rafterPattern', 'pratt', 'columnPattern', 'warren', 'taperedFoot', true, ...
    'shape', 'gable', 'archRise', [], 'computeCutSets', true, 'design', false, ...
    'cornerDiagonal', 'O1-T0', 'groups', '3', 'loadMean', [2.4e3; 2.0e3], 'loadCOV', [0.10; 0.25], ...
    'sigmaAllow', 210e6, 'f_y', 355e6, 'covR', 0.08, 'verbose', false);
p = def;
fn = fieldnames(opts);
for i = 1:numel(fn)
    if ~isfield(def, fn{i})
        error('polakFrameModelFn:opts', 'Unknown option ''%s''.', fn{i});
    end
    p.(fn{i}) = opts.(fn{i});
end
end

%--------------------------------------------------------------------------
function [count, gH, V, necessary, smallSets] = cutSetSizeCount(A)
% Number of minimal cut-sets of each size 1..gH+1 WITHOUT listing them.
% Same criteria and tolerances as nullSpaceCutSetsFn (Lemma 1: zero row of V;
% Lemma 2: k rows of V dependent, every k-1 of them independent). Vectorised
% screening on unit-normalised rows picks the near-dependent pairs/triples,
% each of which is then confirmed with the very rank(.,colTol) test that
% nullSpaceCutSetsFn uses. Needed because the size-(gH+1) sets of a
% two-point-base frame number in the millions and cannot be enumerated one by
% one. gH <= 3 only. Verified against nullSpaceCutSetsFn in
% example_polak_frame.m (identical histograms on a small frame).
% smallSets: cell of all minimal cut-sets of size 1..gH (NOT gH+1), member
% indices into A's columns -- only filled when gH >= 2.
smallSets = {};
[~, nel] = size(A);
[~, S, Vfull] = svd(A);
s = diag(S);
r = sum(s > max(size(A)) * eps(max(s)));
gH = nel - r;
V = Vfull(:, r+1:end);
count = zeros(1, gH + 1);
necessary = [];
if gH == 0, return; end
if gH > 3, error('polakFrameModelFn:count', 'cutSetSizeCount supports gH <= 3 only.'); end

rowTol = nel * eps(1) * 10;
isNec = sqrt(sum(V.^2, 2)) <= rowTol;
necessary = find(isNec);
count(1) = numel(necessary);
Vp = V(~isNec, :);
b  = size(Vp, 1);
colTol = max(size(Vp)) * eps(norm(Vp, 'fro') + eps);   % as nullSpaceCutSetsFn
Vn = Vp ./ sqrt(sum(Vp.^2, 2));
screen = 1e-6;                                         % loose pre-filter, confirmed by rank()

% size 2
dep2 = false(b, b);
if gH == 1
    dep2(:) = true;                                    % any two scalars are dependent
else
    P = nchoosek(1:b, 2);
    c = sum(Vn(P(:,1),:) .* Vn(P(:,2),:), 2);
    cand = find(1 - abs(c) < screen);
    for q = cand'
        if rank(Vp(P(q,:), :), colTol) < 2
            dep2(P(q,1), P(q,2)) = true;
        end
    end
end
dep2 = dep2 | dep2';
dep2(1:b+1:end) = false;
count(2) = nnz(triu(dep2));
if gH == 1, return; end
orig = find(~isNec);
smallSets = num2cell(necessary(:)');
[i2, j2] = find(triu(dep2));
for q = 1:numel(i2), smallSets{end+1} = sort(orig([i2(q), j2(q)]))'; end %#ok<AGROW>

% size 3: rank < 3 and no dependent pair inside
T = nchoosek(1:b, 3);
hasPair = dep2(sub2ind([b b], T(:,1), T(:,2))) | dep2(sub2ind([b b], T(:,1), T(:,3))) ...
        | dep2(sub2ind([b b], T(:,2), T(:,3)));
if gH == 2
    dep3 = ~hasPair;                                   % any 3 rows in 2-D are dependent
else
    dt = abs(Vn(T(:,1),1).*(Vn(T(:,2),2).*Vn(T(:,3),3) - Vn(T(:,2),3).*Vn(T(:,3),2)) ...
           - Vn(T(:,1),2).*(Vn(T(:,2),1).*Vn(T(:,3),3) - Vn(T(:,2),3).*Vn(T(:,3),1)) ...
           + Vn(T(:,1),3).*(Vn(T(:,2),1).*Vn(T(:,3),2) - Vn(T(:,2),2).*Vn(T(:,3),1)));
    dep3 = false(size(T, 1), 1);
    for q = find(~hasPair & dt < screen)'
        dep3(q) = rank(Vp(T(q,:), :), colTol) < 3;
    end
end
count(3) = nnz(dep3);
if gH == 3
    T3 = T(dep3, :);
    for q = 1:size(T3, 1), smallSets{end+1} = sort(orig(T3(q,:)))'; end %#ok<AGROW>
end
if gH == 2, return; end

% size 4 (gH = 3): ANY 4 rows are dependent; minimal iff no dependent pair or
% triple inside. A triple is "bad" if it is, or contains, a cut-set.
bad3 = false(b, b, b);
Td = T(dep3 | hasPair, :);
bad3(sub2ind([b b b], Td(:,1), Td(:,2), Td(:,3))) = true;
n4 = 0;
for i = 1:b-3                                          % chunk over the smallest index
    Q = nchoosek(i+1:b, 3);
    Q = [i * ones(size(Q,1), 1), Q];                   %#ok<AGROW>
    bad = bad3(sub2ind([b b b], Q(:,1), Q(:,2), Q(:,3))) | bad3(sub2ind([b b b], Q(:,1), Q(:,2), Q(:,4))) ...
        | bad3(sub2ind([b b b], Q(:,1), Q(:,3), Q(:,4))) | bad3(sub2ind([b b b], Q(:,2), Q(:,3), Q(:,4)));
    n4 = n4 + nnz(~bad);
end
count(4) = n4;
end
