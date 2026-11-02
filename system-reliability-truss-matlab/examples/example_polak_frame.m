% example_polak_frame.m
%
% Candidate REAL structure for the system-reliability study: the lattice
% portal frame of lightweight steel halls -- Polák "konstrukce AT" (tapered,
% single-point column foot) and the same frame with two-point column bases
% (Montcome hall: both column branches land on the floor separately). The
% committee asked for an existing statically indeterminate structure;
% ordinary roof trusses are statically determinate, a lattice portal frame
% is not -- and it needs no X-bracing to be so.
%
% WHAT WAS READ OFF THE MANUFACTURER'S SCHEMATIC (polak_at.jpg, corner_at.png,
% base_at.png -- elevation of one frame, no dimensions) -- INFERRED, not from
% drawings:
%   - rafter: parallel chords, global-vertical posts + one diagonal per panel,
%     diagonals rising towards the ridge (Pratt/"N"), ~square panels, a ridge
%     post; pitch ~15 deg measured on the image (rise 94 px / 360 px);
%   - eaves corner: both chords continuous round the corner, an (almost)
%     horizontal strut O1-C_in from the outer column chord to the inner
%     corner, and the corner diagonal drawn from O1 up to the first rafter
%     top-chord node T0 -> the outer corner node C_out is a 2-bar node;
%   - column: two branches, Warren zigzag without struts, ~45 deg;
%   - foot: a short strut between the branches, the inner branch bends with an
%     inclined member into the foot of the outer branch -> ONE support point.
% The two-point-base frame (Montcome, described in words by the coordinator,
% not seen) is modelled with the SAME polakFrameModelFn, taperedFoot = false.
% Its rafter infill "looks like zigzag diagonals" -> rafterPattern = 'warren'
% is also reported.
%
% ALL DIMENSIONS, LOADS AND SECTIONS ARE PLACEHOLDERS (span 15 m, eaves 5 m,
% pitch 15 deg, depth 0.6 m; roof G 2.4 kN/m + snow 2.0 kN/m mean on the
% horizontal projection; FSD sizing as in example_warren_xbrace.m). This is a
% topology study plus a first pipeline run, NOT a design.
%
% Cut-sets depend only on topology plus generic geometry; Part 2 checks this
% by perturbing every dimension. With gH = 3 (two-point base) the number of
% size-(gH+1) cut-sets is in the millions: they are COUNTED (polakFrameModelFn
% computeCutSets = 'count', verified against nullSpaceCutSetsFn on a small
% frame in Part 3). The reliability pipeline cannot process 5.5 million
% cut-sets, so Part 5b runs on the size <= MAX_SIZE_TWOPOINT cut-sets only --
% a truncation that can only UNDER-estimate Pf_sys (see there).
%
% Runs fully under `matlab -batch` (no figures).
%
% (c) S. Glanc, 2026

clear;
rng(42);   % mvncdf QMC is randomised for m >= 4 (JOURNAL.md); fixed for reproducibility

exDir  = fileparts(mfilename('fullpath'));
addpath(exDir);
addpath(fullfile(exDir, '..', 'src'));
addpath(fullfile(exDir, '..', '..', 'fem-2d-truss-matlab', 'src'));

RUN_RELIABILITY_TAPERED  = true;   % ~10 min (7754 cut-sets of size <= 2)
RUN_RELIABILITY_TWOPOINT = true;   % truncated, see Part 5b
MAX_SIZE_TWOPOINT        = 2;      % 2: 553 cut-sets, ~1 min; 3: +16636, ~40 min (measured)

%% Part 1 -- Polák AT, tapered single-point foot (gH expected 1)
fprintf('\n===== Part 1: Polak AT, tapered foot =====\n');
at = polakFrameModelFn(struct('verbose', true));
reportCutSets(at);

%% Part 2 -- topology invariance: same panel counts, every dimension changed
fprintf('\n===== Part 2: geometry perturbation (same topology) =====\n');
base = struct('nRafterPanels', at.params.nRafterPanels, 'nColumnPanels', at.params.nColumnPanels);
pert = {struct('span', 20, 'depth', 0.8, 'eaveHeight', 6, 'pitchDeg', 10), ...
        struct('span', 12, 'depth', 0.5, 'eaveHeight', 4, 'pitchDeg', 22)};
for i = 1:numel(pert)
    o = mergeStruct(base, pert{i});
    mi = polakFrameModelFn(o);
    fprintf('  %-60s gH=%d  sizes=%s\n', jsonencode(pert{i}), mi.gH, mat2str(mi.cutSetCount));
end
fprintf('  reference (defaults)                                         gH=%d  sizes=%s\n', at.gH, mat2str(at.cutSetCount));
deg = polakFrameModelFn(struct('pitchDeg', 0));
fprintf('  DEGENERATE flat roof (pitch 0): gH=%d  sizes=%s  -> necessary: %s\n', deg.gH, ...
    mat2str(deg.cutSetCount), strjoin(unique(regexprep(deg.label(deg.necessary), '^[LR] |, panel \d+| \d+$| \d+ \(.*\)$', '')), '; '));
for v = {struct('rafterPattern', 'howe'), struct('columnPattern', 'pratt'), struct('cornerDiagonal', 'Cout-Cin'), ...
         struct('rafterPattern', 'warren')}
    mi = polakFrameModelFn(v{1});
    fprintf('  infill variant %-34s nm=%3d gH=%d  sizes=%s  necessary: %s\n', jsonencode(v{1}), ...
        mi.members.nmembers, mi.gH, mat2str(mi.cutSetCount), strjoin(mi.label(mi.necessary), '; '));
end

%% Part 3 -- two-point column bases (Montcome-like), gH expected 3
fprintf('\n===== Part 3: two-point column bases =====\n');
% (a) the counting shortcut against full enumeration on a small frame
for rp = {'pratt', 'warren'}
    small = struct('nRafterPanels', 3, 'nColumnPanels', 1, 'taperedFoot', false, 'rafterPattern', rp{1});
    tic; mE = polakFrameModelFn(small);                        tE = toc;
    small.computeCutSets = 'count';
    tic; mC = polakFrameModelFn(small);                        tC = toc;
    fprintf('  check (%s, %d members): enumerated %s (%.0f s) vs counted %s (%.1f s) -> %s\n', rp{1}, ...
        mE.members.nmembers, mat2str(mE.cutSetCount), tE, mat2str(mC.cutSetCount), tC, ...
        string(isequal(mE.cutSetCount, mC.cutSetCount)));
end
% (b) full-size frames
tp = polakFrameModelFn(struct('taperedFoot', false, 'computeCutSets', 'count', 'verbose', true));
reportCutSets(tp);
pairComposition(tp);
tpw = polakFrameModelFn(struct('taperedFoot', false, 'rafterPattern', 'warren', 'computeCutSets', 'count', 'verbose', true));
reportCutSets(tpw);
tpp = polakFrameModelFn(mergeStruct(struct('nRafterPanels', tp.params.nRafterPanels, 'nColumnPanels', tp.params.nColumnPanels), struct('taperedFoot', false, 'span', 20, 'depth', 0.8, ...
    'eaveHeight', 6, 'pitchDeg', 10, 'computeCutSets', 'count')));
fprintf('  perturbed geometry (span 20, depth 0.8, eaves 6, pitch 10): gH=%d sizes=%s\n', tpp.gH, mat2str(tpp.cutSetCount));

%% Part 4 -- arched Polák UT (crude: circular chords, same infill logic)
fprintf('\n===== Part 4: Polak UT (arched), tapered foot =====\n');
ut = polakFrameModelFn(struct('shape', 'arch', 'verbose', true));
reportCutSets(ut);

%% Part 5a -- reliability, tapered foot (full cut-set list)
if RUN_RELIABILITY_TAPERED
    fprintf('\n===== Part 5a: reliability, Polak AT (tapered foot) =====\n');
    rng(42);
    atD = polakFrameModelFn(struct('design', true));
    printDesign(atD);
    opts = struct('eta', 0, 'rho0', 0.7, 'verbose', false);
    tic; resAT = systemReliabilityFn(atD.nodes, atD.members, atD.kinematic, atD.sections, atD.rvSpec, opts); tAT = toc;
    compAT = componentReliabilityFn(atD.nodes, atD.members, atD.kinematic, atD.sections, atD.rvSpec);
    printReliability(atD, resAT, compAT, tAT);
end

%% Part 5b -- reliability, two-point base, TRUNCATED cut-set list
% Only cut-sets of size <= MAX_SIZE_TWOPOINT are used (default 2: the 4
% necessary bars + the 549 pairs of web members = "two shear releases"
% mechanisms). The 16 636 size-3 sets (~40 min with the current per-cut-set
% code) and the 5.5 million size-4 sets (infeasible) are left out. Dropping
% failure paths can only LOWER Pf_sys, so the beta below is an UPPER bound
% (unconservative) on the full PNET beta_sys -- an indicator, not a result.
% MEASURED 2026-10-17 (MAX_SIZE_TWOPOINT = 2): every PNET group has beta >= 8.38,
% so Pf_sys ~ 1e-17 and pnetSystemReliabilityFn's 1 - prod(1 - Pf_i) rounds
% to 0 -> beta_sys prints as Inf. That is a floating-point artefact, not an
% infinitely safe frame: it only says the dominant paths of the two-point
% frame have >= 3 members and are not in this truncated list.
if RUN_RELIABILITY_TWOPOINT
    fprintf('\n===== Part 5b: reliability, two-point base (TRUNCATED to size <= %d) =====\n', MAX_SIZE_TWOPOINT);
    rng(42);
    tpD = polakFrameModelFn(struct('taperedFoot', false, 'design', true, 'computeCutSets', 'count'));
    printDesign(tpD);
    keep = cellfun(@numel, tpD.cutSetsUpToGH) <= MAX_SIZE_TWOPOINT;
    tic; resTP = truncatedSystemReliability(tpD, tpD.cutSetsUpToGH(keep), 0.7); tTP = toc;
    compTP = componentReliabilityFn(tpD.nodes, tpD.members, tpD.kinematic, tpD.sections, tpD.rvSpec);
    printReliability(tpD, resTP, compTP, tTP);
end

%% ------------------------------------------------------------------------
function reportCutSets(m)
fprintf('  members=%d  gH=%d  mechanism dofs=%d\n', m.members.nmembers, m.gH, m.rankDeficit);
fprintf('  minimal cut-sets: %d, by size 1..%d: %s\n', sum(m.cutSetCount), m.gH + 1, mat2str(m.cutSetCount));
v = sqrt(sum(m.V.^2, 2));
fprintf('  members carrying self-stress: %d of %d (min |V_i|/max|V_i| = %.2e)\n', ...
    nnz(v > 1e-10 * max(v)), numel(v), min(v(v > 1e-10 * max(v))) / max(v));
if isempty(m.necessary)
    fprintf('  necessary bars: none\n');
else
    for k = m.necessary(:)'
        fprintf('  necessary bar %3d: %s\n', k, m.label{k});
    end
end
end

function pairComposition(m)
% what the size-2 cut-sets of a gH >= 2 frame are made of (role pair, side)
c2 = m.cutSetsUpToGH(cellfun(@numel, m.cutSetsUpToGH) == 2);
side = {'L', 'ridge', 'R'};
key = cellfun(@(q) sprintf('%s + %s  [%s/%s]', m.roleNames{m.role(q(1))}, m.roleNames{m.role(q(2))}, ...
    side{m.side(q(1)) + 2}, side{m.side(q(2)) + 2}), c2, 'uni', 0);
key = regexprep(key, '\[(L|R)/\1\]', '[same side]');
key = regexprep(key, '\[(L/R|R/L)\]', '[both sides]');
[u, ~, k] = unique(key);
n = accumarray(k(:), 1);
[n, o] = sort(n, 'descend');
fprintf('  size-2 cut-sets by member roles:\n');
for i = 1:numel(o), fprintf('    %4d  %s\n', n(i), u{o(i)}); end
end

function printDesign(m)
fprintf('  members=%d, FSD areas [cm^2]: ', m.members.nmembers);
for g = 1:numel(m.groupNames)
    fprintf('%s %.2f  ', m.groupNames{g}, m.sections.A(g) * 1e4);
end
fprintf('\n  loads (PLACEHOLDER): G mean %.1f kN/m COV %.2f, S mean %.1f kN/m COV %.2f\n', ...
    m.rvSpec.loadMean(1)/1e3, m.rvSpec.loadStd(1)/m.rvSpec.loadMean(1), ...
    m.rvSpec.loadMean(2)/1e3, m.rvSpec.loadStd(2)/m.rvSpec.loadMean(2));
end

function printReliability(m, res, comp, t)
[bmin, imin] = min(comp.beta);
fprintf('  cut-sets used: %d (sizes %s), PNET groups (rho0=0.7): %d, time %.0f s\n', numel(res.cutSets), ...
    mat2str(accumarray(cellfun(@numel, res.cutSets(:)), 1)'), numel(res.pnetGroups), t);
fprintf('  beta_min (component) = %.4f  (%s; %d members within 1e-6 of it)\n', bmin, m.label{imin}, ...
    nnz(abs(comp.beta - bmin) < 1e-6));
fprintf('  beta_sys (PNET)      = %.4f   Pf_sys = %.3e   Pf_sys/Pf_min = %.2f\n', res.beta_sys, res.Pf_sys, ...
    res.Pf_sys / normcdf(-bmin));
[~, o] = sort([res.pnetGroups.beta]);
for r = 1:min(6, numel(o))
    g = res.pnetGroups(o(r));
    seq = res.repSequence{g.repIdx};
    fprintf('    group %d: beta=%.4f, %3d cut-sets, rep. sequence %s = %s\n', r, g.beta, numel(g.members), ...
        mat2str(seq), strjoin(m.label(seq), ' -> '));
end
end

function res = truncatedSystemReliability(m, cutSets, rho0)
% systemReliabilityFn steps 2-4 on a GIVEN cut-set list (same calls, same
% eta = 0); systemReliabilityFn itself always enumerates all cut-sets.
q = numel(cutSets);
nU = numel(m.rvSpec.resMean) + numel(m.rvSpec.loadCases);
betaTilde = zeros(q, 1); alphaTilde = zeros(q, nU); repSequence = cell(1, q);
for c = 1:q
    bestSeq = mostProbableSequenceFn(m.nodes, m.members, m.kinematic, m.sections, cutSets{c}, m.rvSpec, 0);
    seq = sequenceLimitStateFn(m.nodes, m.members, m.kinematic, m.sections, bestSeq, m.rvSpec, 0);
    k = numel(seq); alpha = zeros(k, nU); betaVec = zeros(k, 1);
    for i = 1:k
        sd = sqrt(seq(i).varG);
        alpha(i, :) = -seq(i).coeffU / sd;
        betaVec(i)  = seq(i).meanG / sd;
    end
    [betaTilde(c), alphaTilde(c, :)] = equivalentPlaneFn(alpha, betaVec);
    repSequence{c} = bestSeq;
end
[res.beta_sys, res.Pf_sys, res.pnetGroups] = pnetSystemReliabilityFn(betaTilde, alphaTilde, rho0);
res.cutSets = cutSets; res.betaTilde = betaTilde; res.repSequence = repSequence;
end

function s = mergeStruct(a, b)
s = a;
f = fieldnames(b);
for i = 1:numel(f), s.(f{i}) = b.(f{i}); end
end
