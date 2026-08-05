function make_paper_figures(outDir, whichFigs)
% make_paper_figures  Export the NNM 2026 / Acta Polytechnica figures for the
% Warren X-brace example as vector PDFs (plus PNG previews at final size).
%
%   make_paper_figures()                      % the published set
%   make_paper_figures(outDir)                % custom directory
%   make_paper_figures([], 'accumulation')    % just one, default directory
%   make_paper_figures([], {'accumulation', 'pnet_vs_mc'})
%   make_paper_figures([], 'all')             % including the retired ones
%
% Figures are selected by NAME, not by number. The paper has renumbered its
% figures twice while this script stayed put, so any numbering baked in here
% would be a standing invitation to draw the wrong conclusion; the file names
% are the stable identifiers. Selecting one at a time also keeps iterating on
% a single layout cheap, and isolates which figure is at fault when MATLAB's
% renderer misbehaves -- which it does on the machines here.
%
% PUBLISHED FIGURES
%   fig_geometry                truss, supports, mean loads, numbering
%   fig_failure_paths           the five dominant MC mechanisms on the truss
%   fig_accumulation            Pf_min vs Pf_sys (PNET) vs Pf_MC, decomposed
%   fig_pnet_vs_mc              per-group PNET Pf vs MC Pf, log axis
%   fig_cutset_correlation      (a) top cut-sets vs (b) PNET representatives
%   fig_cutset_correlation_bw   the same, ramped on |rho| for print
%   fig_rho0_sensitivity        ratio against rho0, vs the simulation line
%
% RETIRED (still callable via 'all' or by name, no longer part of the set)
%   fig_component_beta          per-member beta_i as a sorted bar chart.
%       Dropped in round 3: members 12 and 15 sit at beta = 10.2966, so the
%       axis has to span 3.9 to 10.3 and the six near-critical members occupy
%       about a fiftieth of it. Their bars are visually identical, the
%       beta_min and beta_min+0.2 guides coincide, and the whole message ends
%       up carried by a text annotation -- so the graphic was doing no work.
%       The paper's Table 4 carries it better, and shows the exactly-equal
%       pairs (11/16, 7/10, 13/14, 1/3, 4/6, 12/15) that are the fingerprint
%       of the truss's symmetry, which the bar chart hid.
%
% MONTE CARLO: fig_accumulation, fig_failure_paths, fig_pnet_vs_mc and
% fig_rho0_sensitivity consume tests/mc_neptun/mc_neptun_result.mat (10^8
% samples, 18 820 failures). The mechanism tally and the per-PNET-group MC
% probabilities are derived from out.failSequences rather than transcribed,
% so they track the raw data.
%
% STYLE: single-column Acta Polytechnica figures -- 8.4 cm wide, serif 8 pt,
% no titles (captions live in the LaTeX source), lines >= 0.75 pt, margins
% trimmed to the drawing.
%
% COLOUR: the journal prints in black and white while the online edition is
% in colour (manuscript-example-2022.tex, line 135), so colour is used only
% as a REDUNDANT channel. Every distinction that carries information is also
% encoded in lightness, hatch, marker or position. In particular no pair of
% information-bearing fills is separated by hue alone -- a saturated red and
% a saturated blue of equal lightness convert to the same grey.
%
% DATA: reuses examples/warren_xbrace_paper_results.mat if it exists (written
% by example_warren_xbrace_paper.m). Otherwise it recomputes -- the headline
% run plus the rho0 sweep, each under rng(42); roughly 1 to 5 minutes.
%
% See also: warrenXbraceModelFn, example_warren_xbrace_paper
%
% (c) S. Glanc, 2026

if nargin < 1 || isempty(outDir)
    outDir = 'C:\GitHub\ctu-nnm-2026\figures';
end
if nargin < 2, whichFigs = []; end
if ~exist(outDir, 'dir'), mkdir(outDir); end

exDir = fileparts(mfilename('fullpath'));
addpath(exDir);
addpath(fullfile(exDir, '..', 'src'));
addpath(fullfile(exDir, '..', 'tests'));
addpath(fullfile(exDir, '..', '..', 'fem-2d-truss-matlab', 'src'));

% name, maker, in the published set
CATALOGUE = { ...
    'geometry',           @figGeometryFn,          true ; ...
    'failure_paths',      @figFailurePathsFn,      true ; ...
    'accumulation',       @figAccumulationFn,      true ; ...
    'pnet_vs_mc',         @figPnetVsMcFn,          true ; ...
    'cutset_correlation', @figCutsetCorrelationFn, true ; ...
    'rho0_sensitivity',   @figRho0SensitivityFn,   true ; ...
    'component_beta',     @figComponentBetaFn,     false};

sel = selectFiguresFn(CATALOGUE, whichFigs);

fprintf('=== make_paper_figures -> %s ===\n', outDir);
fprintf('exporting: %s\n', strjoin(CATALOGUE(sel, 1)', ', '));
S = loadOrComputeFn(exDir);

for k = sel(:)'
    fprintf('-- fig_%s\n', CATALOGUE{k, 1});
    CATALOGUE{k, 2}(S, outDir);
end
fprintf('done.\n');

end

%--------------------------------------------------------------------------
function sel = selectFiguresFn(catalogue, want)
% Resolve the whichFigs argument to row indices into the catalogue. Accepts
% [] (the published set), 'all', a single name, or a cellstr of names. A
% leading 'fig_' is tolerated so the argument can be copied from a filename.
names = catalogue(:, 1)';
if isempty(want)
    sel = find([catalogue{:, 3}]);
    return;
end
if ischar(want) || isstring(want), want = cellstr(want); end
if strcmpi(want{1}, 'all')
    sel = 1:size(catalogue, 1);
    return;
end
sel = zeros(1, numel(want));
for k = 1:numel(want)
    nm = regexprep(char(want{k}), '^fig_', '');
    idx = find(strcmpi(names, nm), 1);
    if isempty(idx)
        error('make_paper_figures:unknownFigure', ...
            'Unknown figure "%s". Known: %s', nm, strjoin(names, ', '));
    end
    sel(k) = idx;
end
end

% =========================================================================
%  DATA
% =========================================================================
function S = loadOrComputeFn(exDir)
matFile = fullfile(exDir, 'warren_xbrace_paper_results.mat');
if exist(matFile, 'file')
    fprintf('loading %s\n', matFile);
    L = load(matFile);
    S.model = L.model; S.comp = L.comp; S.res = L.res;
    S.rho0Sweep   = L.paper.rho0Sweep;
    S.sweepRatio  = L.paper.sweepRatio;
    S.sweepGroups = L.paper.sweepGroups;
else
    fprintf('%s not found -- recomputing (about 4 min)\n', matFile);
    S.model = warrenXbraceModelFn(struct('verbose', false));
    m = S.model;
    S.comp = componentReliabilityFn(m.nodes, m.members, m.kinematic, m.sections, m.rvSpec);
    opts = struct('eta', 0, 'rho0', 0.7, 'verbose', false);
    rng(42);
    S.res = systemReliabilityFn(m.nodes, m.members, m.kinematic, m.sections, m.rvSpec, opts);
    Pf_min = min(S.comp.Pf(S.comp.beta == min(S.comp.beta)));
    S.rho0Sweep = [0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95];
    S.sweepRatio = zeros(1, numel(S.rho0Sweep));
    S.sweepGroups = zeros(1, numel(S.rho0Sweep));
    for k = 1:numel(S.rho0Sweep)
        o = opts; o.rho0 = S.rho0Sweep(k);
        rng(42);
        r = systemReliabilityFn(m.nodes, m.members, m.kinematic, m.sections, m.rvSpec, o);
        S.sweepRatio(k)  = r.Pf_sys / Pf_min;
        S.sweepGroups(k) = numel(r.pnetGroups);
    end
end

[S.beta_min, S.iMin] = min(S.comp.beta);
S.Pf_min  = S.comp.Pf(S.iMin);
S.Pf_sys  = S.res.Pf_sys;
S.ratio   = S.Pf_sys / S.Pf_min;
S.nInBand = sum(S.comp.beta <= S.beta_min + 0.2);

% PNET groups, worst first
[~, gOrd] = sort([S.res.pnetGroups.beta], 'ascend');
S.gOrder  = gOrd;
S.gBeta   = [S.res.pnetGroups(gOrd).beta];
S.gPf     = normcdf(-S.gBeta);
S.gRepIdx = arrayfun(@(g) g.repIdx, S.res.pnetGroups(gOrd));
S.gLabel  = cellfun(@(c) setLabelFn(c), S.res.cutSets(S.gRepIdx), 'UniformOutput', false);
S.gMembers = arrayfun(@(g) g.members, S.res.pnetGroups(gOrd), 'UniformOutput', false);

% rho0 points beyond the brief's eight, needed by figure 6
S = extendSweepFn(S);

% Monte Carlo cross-check
S.mc = mcDataFn(S, exDir);
end

%--------------------------------------------------------------------------
function S = extendSweepFn(S)
% Adds the rho0 = 0.98 and 0.999 points to the sweep.
%
% NOT a "rho0 -> 1 limit". There is no usable limit: the ratio keeps
% climbing as rho0 approaches 1 (6.78 at 0.999, 7.41 at 1-1e-5, 8.67 at
% 1-1e-6, 13.04 at 1-1e-12, 14.31 at 1-1e-15), and treating all 91 cut-sets
% as independent gives 21.21. The 6.78 quoted as "the fully-independent
% limit" is simply the value at rho0 ~ 0.999, and 0.999 is where the plateau
% at 66 groups ends. Everything past it is numerical noise about which
% near-unit correlations round which way, which is exactly why figure 6
% shades that region rather than extrapolating into it.
%
% rho0 = 1 exactly must never be passed to pnetSystemReliabilityFn: the
% equivalent alpha vectors are unit-norm only to floating-point accuracy, 32
% of the 91 self-correlations here land just below 1, and a representative
% that fails to absorb itself leaves `remaining` unchanged -- the grouping
% loop then spins forever. rho0 > 1 fails the same way for every cut-set.
%
% Both are evaluated directly on the cached seeded run's (betaTilde,
% alphaTilde) rather than by re-running the pipeline. That is EXACT, not an
% approximation: rho0 enters only pnetSystemReliabilityFn, the last step,
% and every earlier step is untouched by it -- re-seeding and re-running
% reproduces the same betaTilde/alphaTilde bit for bit (verified against all
% eight literal sweep points). example_warren_xbrace_paper.m still runs the
% whole sweep literally; this is the fast path for redrawing figures.
%
% The limit point is not a measurable rho0 at all -- it is what PNET
% degenerates to when no cut-set is ever absorbed, i.e. all q cut-sets
% counted as independent -- so it is marked as a limit in figure 6, not as a
% data point.
if isfield(S, 'sweepExtended') && S.sweepExtended, return; end
for r0 = [0.98 0.999]
    if any(abs(S.rho0Sweep - r0) < 1e-9), continue; end
    [~, pk, gk] = pnetSystemReliabilityFn(S.res.betaTilde, S.res.alphaTilde, r0);
    S.rho0Sweep(end+1)   = r0;
    S.sweepRatio(end+1)  = pk / S.Pf_min;
    S.sweepGroups(end+1) = numel(gk);
end
% The limit is rho0 -> 1 FROM BELOW, evaluated on the plateau at 1-1e-6.
% Three warnings, all learned the hard way:
%
%  * rho0 > 1 makes pnetSystemReliabilityFn loop forever. Its grouping step
%    absorbs every k with rho_1k >= rho0; above 1 that absorbs nothing, not
%    even the representative against itself, so `remaining` never shrinks.
%  * rho0 == 1 exactly is unsafe for a different reason: the equivalent
%    alpha vectors are only unit-norm to floating-point accuracy, and 32 of
%    the 91 self-correlations here evaluate just below 1. The result (ratio
%    13.04) is an artefact of which ones happen to round down.
%  * this is NOT the fully-independent limit, whatever it may be called
%    elsewhere. Treating all 91 cut-sets as independent gives ratio 21.21;
%    the rho0 -> 1- plateau still merges the perfectly correlated ones and
%    leaves 66 groups, giving 6.78.
% For the report only: what "all cut-sets independent" would actually give.
pInd = 1 - prod(1 - normcdf(-S.res.betaTilde));
S.indepRatio = pInd / S.Pf_min;
S.sweepExtended = true;
fprintf('  sweep extended to rho0 = %.3f (ratio %.2f, %d groups); all-independent would be %.2f\n', ...
    max(S.rho0Sweep), S.sweepRatio(end), S.sweepGroups(end), S.indepRatio);
end

%--------------------------------------------------------------------------
function mc = mcDataFn(S, exDir)
% Monte Carlo reference, derived from the raw failure sequences rather than
% transcribed. Each observed failure is keyed by its SET of failed members;
% the tally is then mapped onto the analytical cut-sets and, through them,
% onto the PNET groups, so figure 7 compares like with like.
mcFile = fullfile(exDir, '..', 'tests', 'mc_neptun', 'mc_neptun_result.mat');
mc = struct('available', false);
if ~exist(mcFile, 'file')
    warning('make_paper_figures:noMC', 'Monte Carlo result not found at %s', mcFile);
    return;
end
L = load(mcFile);  o = L.out;
mc.available = true;
mc.Pf     = o.Pf_MC;
mc.beta   = o.beta_MC;
mc.nFail  = o.nFail;
mc.nTotal = o.nTotal;
mc.ciLo   = o.Pf_MC - o.ciHalfWidth;
mc.ciHi   = o.Pf_MC + o.ciHalfWidth;

keys = cellfun(@(s) mat2str(sort(s(:))'), o.failSequences, 'UniformOutput', false);
[u, ~, ic] = unique(keys);
cnt = accumarray(ic, 1);
[cnt, ix] = sort(cnt, 'descend');
u = u(ix);
mc.mechSet   = cellfun(@(k) sscanf(k(2:end-1), '%d')', u, 'UniformOutput', false);
mc.mechCount = cnt(:)';
mc.mechPf    = cnt(:)' / o.nTotal;
mc.mechShare = cnt(:)' / o.nFail;
mc.mechLabel = cellfun(@(c) setLabelFn(c), mc.mechSet, 'UniformOutput', false);

% map mechanism -> cut-set index -> PNET group rank
csKey = cellfun(@(c) mat2str(sort(c(:))'), S.res.cutSets, 'UniformOutput', false);
nG = numel(S.gLabel);
mc.groupPf = zeros(1, nG);
mc.unmatched = {};
for k = 1:numel(mc.mechSet)
    ci = find(strcmp(csKey, mat2str(sort(mc.mechSet{k}))), 1);
    if isempty(ci)
        mc.unmatched{end+1} = mc.mechLabel{k};
        continue;
    end
    for g = 1:nG
        if any(S.gMembers{g} == ci)
            mc.groupPf(g) = mc.groupPf(g) + mc.mechPf(k);
            break;
        end
    end
end
fprintf('  [MC] Pf = %.6e, %d mechanisms, %d not matching any cut-set\n', ...
    mc.Pf, numel(mc.mechSet), numel(mc.unmatched));
end

function s = setLabelFn(c)
s = ['{' strjoin(arrayfun(@(v) sprintf('%d', v), c(:)', 'UniformOutput', false), ',') '}'];
end

function s = texBracesFn(s)
% Escape a cut-set label for the tex interpreter, which would otherwise eat
% the braces as grouping characters.
s = strrep(strrep(s, '{', '\{'), '}', '\}');
end

% =========================================================================
%  SHARED STYLE
% =========================================================================
function f = newFigFn(wcm, hcm)
f = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters');
f.Position = [2 2 wcm hcm];
f.PaperUnits = 'centimeters';
f.PaperSize = [wcm hcm];
f.PaperPosition = [0 0 wcm hcm];
end

function styleAxFn(ax)
set(ax, 'FontName', 'Times New Roman', 'FontSize', 8, 'LineWidth', 0.75, ...
    'TickDir', 'out', 'TickLength', [0.012 0.012], 'Box', 'off', 'Layer', 'top', ...
    'XColor', 'k', 'YColor', 'k');
end

function hL = legendKeysFn(ax, greys, xAnchor)
% Off-screen legend keys.
%
% They must be REAL quads with area. Two earlier attempts both broke the
% R2026a web renderer, which then threw "Cannot read properties of null
% (reading 'lineWidth')" and silently exported the figure with nothing in it
% but the legend: NaN vertices first, then a three-vertex patch whose x
% coordinates were all identical (zero area, collinear). Give each key a
% proper rectangle and park it below the y limits so it clips away.
hL = legendKeysColFn(ax, greys(:) * [1 1 1], xAnchor);
end

function hL = legendKeysColFn(ax, cols, xAnchor)
% As legendKeysFn, but takes an n-by-3 RGB matrix instead of grey levels.
n  = size(cols, 1);
hL = gobjects(n, 1);
for g = 1:n
    % multiplicative width so the same helper works on a log x axis too
    hL(g) = patch(ax, 'XData', xAnchor * [1 1.05 1.05 1], 'YData', [-9 -9 -8 -8], ...
        'FaceColor', cols(g, :), 'EdgeColor', 'k', 'LineWidth', 0.6);
end
end

function styleLegendFn(lg, fs)
% ItemTokenSize is not accepted as a legend() construction argument in
% R2026a ("Unknown property"), but it still works through set() on the
% finished object. Guarded so a future removal degrades to a default legend
% rather than killing the figure.
set(lg, 'FontName', 'Times New Roman', 'FontSize', fs, 'EdgeColor', [0.45 0.45 0.45]);
try
    set(lg, 'ItemTokenSize', [10 8]);
catch
end
end

function exportFn(f, outDir, name)
% 'Padding','figure' exports the whole 8.4 cm canvas. Without it
% exportgraphics crops to the ink bounding box, which lands somewhere
% different in every figure -- measured across the set: 7.41 to 8.26 cm. Each
% file then gets a different magnification from \includegraphics[width=
% \linewidth], and the 8 pt type the whole style is built on arrives in the
% typeset paper as anything from 8.1 to 9.1 pt. With the full canvas,
% width=\linewidth is the no-op it was always assumed to be.
%
% This does NOT restore MATLAB's default margins: every layout in this file
% sets its axes Position explicitly, so the canvas edge is already where the
% drawing should stop.
pdf = fullfile(outDir, [name '.pdf']);
png = fullfile(outDir, [name '.png']);
exportgraphics(f, pdf, 'ContentType', 'vector', 'BackgroundColor', 'white', ...
    'Padding', 'figure');
exportgraphics(f, png, 'Resolution', 300, 'BackgroundColor', 'white', ...
    'Padding', 'figure');
canvas = f.Position(3:4);
close(f);

% Verify the export really is the canvas. 'Padding','figure' still grows the
% page if anything is drawn outside the figure -- text objects do not clip by
% default -- and a figure that quietly comes out wider gets a different
% magnification from \includegraphics[width=\linewidth] than its neighbours.
% Cheaper to measure every time than to discover it in the typeset paper.
[pw, ph] = pdfBoxFn(pdf);
d = dir(pdf);
flag = '';
if abs(pw - canvas(1)) > 0.05 || abs(ph - canvas(2)) > 0.05
    flag = sprintf('  <-- OVERFLOWS canvas %.2f x %.2f', canvas(1), canvas(2));
end
fprintf('  %-28s %6.1f kB  %5.2f x %5.2f cm%s\n', [name '.pdf'], d.bytes/1024, pw, ph, flag);
end

function [wcm, hcm] = pdfBoxFn(pdf)
% Page size of a PDF, in cm, straight from its MediaBox.
fid = fopen(pdf, 'r');
raw = fread(fid, 4096, '*char')';
fclose(fid);
tok = regexp(raw, '/MediaBox\s*\[\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)', 'tokens', 'once');
if isempty(tok)
    wcm = NaN; hcm = NaN; return;
end
v = str2double(tok);
wcm = (v(3) - v(1)) / 72 * 2.54;
hcm = (v(4) - v(2)) / 72 * 2.54;
end

% =========================================================================
%  TRUSS DRAWING (shared by figures 1 and 4)
% =========================================================================
function drawTrussFn(ax, model, highlight, lwBase, lwHi, colBase, colHi)
% Draw every member; those in `highlight` in the emphasised style.
nodes = model.nodes; mem = model.members;
for p = 1:mem.nmembers
    xx = [nodes.x(mem.nodesHead(p)), nodes.x(mem.nodesEnd(p))];
    zz = [nodes.z(mem.nodesHead(p)), nodes.z(mem.nodesEnd(p))];
    if any(highlight == p)
        plot(ax, xx, zz, '-', 'Color', colHi, 'LineWidth', lwHi);
    else
        plot(ax, xx, zz, '-', 'Color', colBase, 'LineWidth', lwBase);
    end
end
end

function drawSupportFn(ax, x, z, kind, s, col)
% Standard pin / roller symbol, apex at (x,z), overall height ~s (data units).
hw = 0.62 * s;
if strcmp(kind, 'roller'), htri = 0.72 * s; else, htri = s; end
patch(ax, 'XData', [x, x-hw, x+hw], 'YData', [z, z-htri, z-htri], ...
    'FaceColor', 'w', 'EdgeColor', col, 'LineWidth', 0.75);
zg = z - htri;
if strcmp(kind, 'roller')
    r  = 0.13 * s;
    th = linspace(0, 2*pi, 24);
    for xc = [x - 0.5*hw, x + 0.5*hw]
        patch(ax, 'XData', xc + r*cos(th), 'YData', zg - r + r*sin(th), ...
            'FaceColor', 'w', 'EdgeColor', col, 'LineWidth', 0.6);
    end
    zg = zg - 2*r;
end
plot(ax, [x-1.35*hw, x+1.35*hw], [zg zg], '-', 'Color', col, 'LineWidth', 0.75);
xh = linspace(x - 1.15*hw, x + 1.35*hw, 7);
for k = 1:numel(xh)
    plot(ax, [xh(k), xh(k)-0.30*s], [zg, zg-0.30*s], '-', 'Color', col, 'LineWidth', 0.5);
end
end

function dimLineFn(ax, p1, p2, off, label, rot, col, gap)
% Dimension line between p1 and p2, offset by vector `off`, with arrow ends.
% `gap` keeps the extension lines clear of the structure they measure.
if nargin < 8, gap = 0; end
a = p1 + off; b = p2 + off;
eu = off / max(norm(off), eps);
plot(ax, [p1(1)+gap*eu(1) a(1)], [p1(2)+gap*eu(2) a(2)], '-', 'Color', col, 'LineWidth', 0.4);
plot(ax, [p2(1)+gap*eu(1) b(1)], [p2(2)+gap*eu(2) b(2)], '-', 'Color', col, 'LineWidth', 0.4);
plot(ax, [a(1) b(1)], [a(2) b(2)], '-', 'Color', col, 'LineWidth', 0.5);
d = (b - a); L = norm(d); if L == 0, return; end
u = d / L; n = [-u(2), u(1)]; hl = 0.055 * L; hw = 0.30 * hl;
for e = [1 -1]
    if e == 1, tip = a; ud = u; else, tip = b; ud = -u; end
    patch(ax, 'XData', [tip(1), tip(1)+hl*ud(1)+hw*n(1), tip(1)+hl*ud(1)-hw*n(1)], ...
        'YData', [tip(2), tip(2)+hl*ud(2)+hw*n(2), tip(2)+hl*ud(2)-hw*n(2)], ...
        'FaceColor', col, 'EdgeColor', 'none');
end
% label on the side of the dimension line facing away from the structure
sgn = sign(dot(n, off)); if sgn == 0, sgn = 1; end
mid = (a + b) / 2 + 0.10 * sgn * n;
text(ax, mid(1), mid(2), label, 'FontName', 'Times New Roman', 'FontSize', 8, ...
    'Color', col, 'Rotation', rot, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom', 'Interpreter', 'tex');
end

% =========================================================================
%  FIGURE 1 -- geometry
% =========================================================================
function figGeometryFn(S, outDir)
model = S.model;
nodes = model.nodes; mem = model.members;
col = 'k';

xlimits = [-2.35, 12.85];
zlimits = [-2.75, 4.25];
w = 8.4;
h = w * diff(zlimits) / diff(xlimits);

f  = newFigFn(w, h);
ax = axes('Parent', f, 'Position', [0 0 1 1]); hold(ax, 'on');
axis(ax, 'off'); set(ax, 'DataAspectRatio', [1 1 1]);
xlim(ax, xlimits); ylim(ax, zlimits);

% --- members ---------------------------------------------------------
drawTrussFn(ax, model, [], 1.1, 1.1, col, col);

% --- supports (drawn before the node discs so the apex is covered) ----
drawSupportFn(ax, nodes.x(1), nodes.z(1), 'pin',    0.80, col);
drawSupportFn(ax, nodes.x(4), nodes.z(4), 'roller', 0.80, col);

% --- mean loads -------------------------------------------------------
for n = model.topLoadNodes(:)'
    x0 = nodes.x(n); z0 = nodes.z(n);
    plot(ax, [x0 x0], [z0+0.42, z0+1.35], '-', 'Color', col, 'LineWidth', 1.0);
    patch(ax, 'XData', [x0, x0-0.20, x0+0.20], 'YData', [z0+0.42, z0+0.82, z0+0.82], ...
        'FaceColor', col, 'EdgeColor', 'none');
    text(ax, x0, z0+1.48, '75 kN', 'FontName', 'Times New Roman', 'FontSize', 8, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'Color', col);
end

% --- member numbers ---------------------------------------------------
% Diagonals get t=0.30 rather than the midpoint: in an X-braced panel both
% diagonals share the same midpoint, so midpoint labels would coincide.
for p = 1:mem.nmembers
    xh = nodes.x(mem.nodesHead(p)); zh = nodes.z(mem.nodesHead(p));
    xe = nodes.x(mem.nodesEnd(p));  ze = nodes.z(mem.nodesEnd(p));
    isDiag = (xh ~= xe) && (zh ~= ze);
    t = 0.30 * isDiag + 0.50 * ~isDiag;
    text(ax, xh + t*(xe-xh), zh + t*(ze-zh), sprintf('%d', p), ...
        'FontName', 'Times New Roman', 'FontSize', 8, 'Color', col, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'BackgroundColor', 'w', 'Margin', 0.5);
end

% --- node numbers in discs -------------------------------------------
th = linspace(0, 2*pi, 40); r = 0.34;
for n = 1:numel(nodes.x)
    patch(ax, 'XData', nodes.x(n) + r*cos(th), 'YData', nodes.z(n) + r*sin(th), ...
        'FaceColor', 'w', 'EdgeColor', col, 'LineWidth', 0.75);
    text(ax, nodes.x(n), nodes.z(n), sprintf('%d', n), ...
        'FontName', 'Times New Roman', 'FontSize', 8, 'Color', col, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
end

% --- dimensions -------------------------------------------------------
for k = 1:model.nPanels
    x1 = (k-1)*model.Lpanel; x2 = k*model.Lpanel;
    % positive gap = start the extension line clear of the structure, in the
    % direction of the offset (below the supports here, left of node 1 below)
    dimLineFn(ax, [x1 0], [x2 0], [0 -2.05], '4.0 m', 0, col, 1.10);
end
dimLineFn(ax, [0 0], [0 model.H], [-1.45 0], '2.0 m', 90, col, 0.65);

exportFn(f, outDir, 'fig_geometry');
end

% =========================================================================
%  FIGURE 2 -- component reliability index per member
% =========================================================================
function figComponentBetaFn(S, outDir)
comp = S.comp; model = S.model;
ord  = comp.sortIdx;                 % ascending beta
b    = comp.beta(ord);
grp  = model.role(ord);
nM   = numel(ord);

greys = [0.20; 0.45; 0.68; 0.88];    % bottom / top / vertical / diagonal
xLo   = 3.5;  xHi = 10.7;

f  = newFigFn(8.4, 7.5);
ax = axes('Parent', f, 'Position', [0.135 0.095 0.845 0.895]); hold(ax, 'on');
styleAxFn(ax);

% band [beta_min, beta_min+0.2] behind everything
bandHi = S.beta_min + 0.2;
patch(ax, 'XData', [S.beta_min bandHi bandHi S.beta_min], 'YData', [0.3 0.3 nM+0.7 nM+0.7], ...
    'FaceColor', [0.86 0.86 0.86], 'EdgeColor', 'none');

hb = barh(ax, (1:nM)', b(:), 0.72, 'FaceColor', 'flat', 'EdgeColor', 'k', ...
    'LineWidth', 0.6, 'BaseValue', xLo);
hb.CData = repmat(greys(grp), 1, 3);
hb.BaseLine.Visible = 'off';

plot(ax, [S.beta_min S.beta_min], [0.3 nM+0.7], 'k--', 'LineWidth', 0.9);
plot(ax, [bandHi bandHi], [0.3 nM+0.7], 'k:', 'LineWidth', 0.75);

set(ax, 'YDir', 'reverse', 'YTick', 1:nM, 'YTickLabel', arrayfun(@(v) sprintf('%d', v), ord, 'UniformOutput', false));
xlim(ax, [xLo xHi]); ylim(ax, [0.3 nM+0.7]);
set(ax, 'XTick', 4:1:10);
xlabel(ax, '\beta_i  [-]', 'FontName', 'Times New Roman', 'FontSize', 8);
ylabel(ax, 'member', 'FontName', 'Times New Roman', 'FontSize', 8);

% Both annotations go top-left, where the bars are short; the legend then
% takes the top-right corner, which is empty for the same reason.
text(ax, bandHi + 0.30, 1.1, ...
    sprintf('\\beta_{min} = %.4f', S.beta_min), 'FontName', 'Times New Roman', ...
    'FontSize', 8, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left');
text(ax, bandHi + 0.30, 3.9, ...
    sprintf('%d members within 0.2', S.nInBand), 'FontName', 'Times New Roman', ...
    'FontSize', 8, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left');

% legend from dummy patches
hL = legendKeysFn(ax, greys, xLo);
lg = legend(ax, hL, model.roleNames, 'Location', 'northeast', 'Box', 'on');
styleLegendFn(lg, 7);

exportFn(f, outDir, 'fig_component_beta');
end

% =========================================================================
%  FIGURE fig_accumulation -- Pf_min vs PNET vs simulation
% =========================================================================
function figAccumulationFn(S, outDir)
% Three totals, two of them decomposed, on one linear axis.
%
% REDRAW (round 3). The previous version stacked every PNET group and every
% observed mechanism -- eight slices keyed to an eight-entry legend that ate
% 40 % of the width. Matching swatch to slice was an assignment puzzle, and
% the identities were never the point: they are in the paper's tables. The
% point is that the slices are MANY and COMPARABLE. So: top three plus a
% pooled remainder, and the labels sit on the segments instead of in a key.
%
% Labels go INSIDE the segment wherever it is tall enough, and only spill to
% a leader line when it is not (which happens once, for the analytical bar's
% 6 % remainder). The brief asked for leader lines throughout; in-segment
% labels win the two-second test outright, because there is nothing to match
% up -- and freeing the side margins is what let the bars grow wide enough to
% hold a label in the first place.
%
% Colour is one hue per bar, four lightness steps within it, so the segment
% count survives greyscale conversion. Hue never carries information on its
% own here: the bars are told apart by position and tick label, the segments
% within a bar by lightness and by their own printed labels.

mc = S.mc;
if ~mc.available, fprintf('  fig_accumulation SKIPPED (no MC data)\n'); return; end

[aVals, aLbls] = topThreeFn(S.gPf,      S.gLabel,      S.Pf_sys);
[mVals, mLbls] = topThreeFn(mc.mechPf,  mc.mechLabel,  mc.Pf);

BLUE   = [0.13 0.29 0.53; 0.29 0.47 0.71; 0.55 0.68 0.84; 0.80 0.87 0.94];
ORANGE = [0.60 0.24 0.05; 0.85 0.44 0.13; 0.96 0.67 0.38; 0.99 0.86 0.72];
GREY   = [0.38 0.38 0.38];

yMax = 2.1e-4;
xs   = [1 2 3];
bw   = 0.62;

% Margins: the y exponent (x10^-4) needs ~0.4 cm above the axes and the
% three-line tick labels ~1.7 cm below. Both were clipped at 6.8 cm tall
% with a 0.795-high axes.
f  = newFigFn(8.4, 7.4);
ax = axes('Parent', f, 'Position', [0.155 0.235 0.815 0.705]); hold(ax, 'on');
styleAxFn(ax);

% --- bar 1: the weakest member on its own, no decomposition ----------
patch(ax, 'XData', xs(1) + bw/2*[-1 1 1 -1], 'YData', [0 0 S.Pf_min S.Pf_min], ...
    'FaceColor', GREY, 'EdgeColor', 'k', 'LineWidth', 0.7);

% --- bars 2 and 3 ------------------------------------------------------
stackedBarFn(ax, xs(2), bw, aVals, aLbls, BLUE,   S.Pf_sys, yMax, 'left');
stackedBarFn(ax, xs(3), bw, mVals, mLbls, ORANGE, mc.Pf,    yMax, 'right');

% --- 95 % CI on the simulated total ------------------------------------
% At 10^8 samples the interval is +-1.4 % of Pf_MC, which on this axis is a
% 1.3 mm gap between the caps -- shorter than the bar outline is thick. Left
% unlabelled it does not read as an error bar at all (the author's reaction
% to the first render was to ask what the symbol was), so it gets named. The
% smallness is itself the point: the simulation is precise enough that its
% uncertainty will not draw at this scale.
plot(ax, xs(3)*[1 1], [mc.ciLo mc.ciHi], 'k-', 'LineWidth', 0.9);
plot(ax, xs(3) + 0.10*[-1 1], mc.ciLo*[1 1], 'k-', 'LineWidth', 0.9);
plot(ax, xs(3) + 0.10*[-1 1], mc.ciHi*[1 1], 'k-', 'LineWidth', 0.9);
text(ax, xs(3), mc.ciHi + 0.035e-4, '95 % CI', 'FontName', 'Times New Roman', ...
    'FontSize', 6.5, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

% --- the lower bound ---------------------------------------------------
% Coincides exactly with the top of bar 2's first segment; that coincidence
% IS the message, so the line is drawn across all three bars.
plot(ax, [0.45 3.72], S.Pf_min*[1 1], 'k--', 'LineWidth', 0.8);
text(ax, 0.50, S.Pf_min + 0.025e-4, {'lower bound:', 'P_{f,sys} \geq P_{f,min}'}, ...
    'FontName', 'Times New Roman', 'FontSize', 6.5, 'VerticalAlignment', 'bottom');

% --- ratios ------------------------------------------------------------
% Two significant figures on the ratio labels, following the co-author review
% of 2026-08-05: differences in the third digit of a beta or a Pf are not
% claimable, so printing them only invites the reader to compare noise. The
% body text quotes 4.1 for this one.
xa = 3.52;
arrowPairFn(ax, xa, S.Pf_min, mc.Pf, 0.045, 0.05e-4, 'k');
text(ax, xa, mc.Pf + 0.07e-4, sprintf('%.1f\\times', mc.Pf/S.Pf_min), ...
    'FontName', 'Times New Roman', 'FontSize', 9, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom');

% DELIBERATELY still two decimals, and the only ratio label in the set that
% is. This one is the graphical form of the "68 %" underestimate quoted
% verbatim in the abstract, section 3.3, section 4 and the conclusions; at
% %.1f it prints 1.7, which reads as 70 % and contradicts all four. Do not
% "harmonise" it with the labels above and below.
xb = 2.56;
arrowPairFn(ax, xb, S.Pf_sys, mc.Pf, 0.032, 0.04e-4, [0.4 0.4 0.4]);
text(ax, xb - 0.05, (S.Pf_sys + mc.Pf)/2, sprintf('%.2f\\times', mc.Pf/S.Pf_sys), ...
    'FontName', 'Times New Roman', 'FontSize', 6.5, 'Color', [0.4 0.4 0.4], ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');

% --- axes --------------------------------------------------------------
xlim(ax, [0.45 3.85]); ylim(ax, [0 yMax]);
set(ax, 'XTick', xs, 'XTickLabel', { ...
    'P_{f,min}\newline\fontsize{6.5}weakest\newlinemember', ...
    'P_{f,sys}\newline\fontsize{6.5}cut-set\newlineanalysis', ...
    'P_{f,MC}\newline\fontsize{6.5}simulation,\newline10^{8} samples'});
ax.XAxis.TickLabelInterpreter = 'tex';
ylabel(ax, 'failure probability  [-]', 'FontName', 'Times New Roman', 'FontSize', 8);
ax.YAxis.Exponent = -4;

fprintf('  [fig3] analytical: %s\n', segSummaryFn(aVals, aLbls, S.Pf_sys));
fprintf('  [fig3] simulated : %s\n', segSummaryFn(mVals, mLbls, mc.Pf));

exportFn(f, outDir, 'fig_accumulation');
end

%--------------------------------------------------------------------------
function [v, l] = topThreeFn(vals, labels, total)
% Three largest contributors plus everything else pooled. `vals` arrives
% sorted descending in both callers (PNET groups by ascending beta, MC
% mechanisms by descending count), so no re-sort is needed -- but the
% remainder is taken against the true total rather than against sum(vals),
% so the bar height stays exactly Pf_sys / Pf_MC.
n = min(3, numel(vals));
v = vals(1:n);
l = labels(1:n);
rest = total - sum(v);
if rest > 0
    v(end+1) = rest;
    l{end+1} = 'others';
end
end

%--------------------------------------------------------------------------
function s = segSummaryFn(vals, lbls, total)
parts = arrayfun(@(k) sprintf('%s %.0f%%', lbls{k}, 100*vals(k)/total), ...
    1:numel(vals), 'UniformOutput', false);
s = strjoin(parts, ' | ');
end

%--------------------------------------------------------------------------
function stackedBarFn(ax, xc, bw, vals, lbls, cmap, total, yMax, side)
% Stacked bar with the labels on the segments. Segments are separated by a
% white rule so the count stays legible where two fills are close in tone.
MIN_H = 0.085 * yMax;          % below this a label will not fit inside
cum = 0;
for k = 1:numel(vals)
    col = cmap(min(k, size(cmap, 1)), :);
    patch(ax, 'XData', xc + bw/2*[-1 1 1 -1], ...
        'YData', [cum cum cum+vals(k) cum+vals(k)], ...
        'FaceColor', col, 'EdgeColor', 'w', 'LineWidth', 1.0);
    yMid = cum + vals(k)/2;
    pct  = sprintf('%.0f%%', 100*vals(k)/total);
    if vals(k) >= MIN_H
        text(ax, xc, yMid, {lbls{k}, pct}, 'FontName', 'Times New Roman', ...
            'FontSize', 6.5, 'Color', onFillFn(col), 'Interpreter', 'none', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    else
        if strcmp(side, 'left'), s = -1; ha = 'right'; else, s = 1; ha = 'left'; end
        plot(ax, xc + s*[bw/2 bw/2+0.10], [yMid yMid], '-', ...
            'Color', [0.45 0.45 0.45], 'LineWidth', 0.5);
        text(ax, xc + s*(bw/2 + 0.14), yMid, sprintf('%s %s', lbls{k}, pct), ...
            'FontName', 'Times New Roman', 'FontSize', 6.5, 'Interpreter', 'none', ...
            'HorizontalAlignment', ha, 'VerticalAlignment', 'middle');
    end
    cum = cum + vals(k);
end
plot(ax, xc + bw/2*[-1 1 1 -1 -1], [0 0 total total 0], '-', ...
    'Color', 'k', 'LineWidth', 0.7);
end

%--------------------------------------------------------------------------
function c = onFillFn(rgb)
% Readable ink for a label sitting on a filled patch.
if (0.299*rgb(1) + 0.587*rgb(2) + 0.114*rgb(3)) < 0.5, c = 'w'; else, c = 'k'; end
end

%--------------------------------------------------------------------------
function arrowPairFn(ax, x, y0, y1, halfW, headH, col)
% Vertical double-headed arrow between y0 and y1 at abscissa x.
plot(ax, [x x], [y0 y1], '-', 'Color', col, 'LineWidth', 0.7);
patch(ax, 'XData', x + halfW*[0 -1 1], 'YData', [y0, y0+headH, y0+headH], ...
    'FaceColor', col, 'EdgeColor', 'none');
patch(ax, 'XData', x + halfW*[0 -1 1], 'YData', [y1, y1-headH, y1-headH], ...
    'FaceColor', col, 'EdgeColor', 'none');
end
% =========================================================================
%  FIGURE 4 -- the five dominant SIMULATED failure mechanisms
% =========================================================================
function figFailurePathsFn(S, outDir)
mc = S.mc;
if ~mc.available, fprintf('  fig_failure_paths SKIPPED (no MC data)\n'); return; end
model = S.model;
nP    = 5;
tags  = {'a', 'b', 'c', 'd', 'e'};

% The highlighted members ARE the content here, so this is where colour buys
% the most. Deep red on light grey is a luminance gap of 0.29 against 0.72,
% so it survives conversion to greyscale for print; the line-weight
% difference (0.5 vs 2.1 pt) carries it a second time.
FAILED = [0.72 0.11 0.11];
INTACT = 0.72*[1 1 1];

xlimits = [-0.95, 12.95];
zlimits = [-0.95, 2.55];

w     = 8.4;
colW  = w/2;
drawW = colW - 0.32;
drawH = drawW * diff(zlimits) / diff(xlimits);
subH  = 0.60;
rowH  = drawH + subH;
h     = 3*rowH + 0.10;

f = newFigFn(w, h);
for k = 1:nP
    mech = mc.mechSet{k};
    r = ceil(k/2); c = 2 - mod(k, 2);
    ax = panelAxFn(f, w, h, colW, drawW, drawH, rowH, subH, r, c, xlimits, zlimits);

    drawTrussFn(ax, model, mech, 0.5, 2.1, INTACT, FAILED);
    drawSupportFn(ax, model.nodes.x(1), model.nodes.z(1), 'pin',    0.55, INTACT);
    drawSupportFn(ax, model.nodes.x(4), model.nodes.z(4), 'roller', 0.55, INTACT);

    text(ax, mean(xlimits), zlimits(1) - 0.09*diff(zlimits), ...
        sprintf('(%s) \\{%s\\},  %.1f %%', tags{k}, ...
        strjoin(arrayfun(@(v) sprintf('%d', v), mech(:)', 'UniformOutput', false), ','), ...
        100*mc.mechShare(k)), ...
        'FontName', 'Times New Roman', 'FontSize', 8, 'Interpreter', 'tex', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Clipping', 'off');
end

% sixth cell: key for the two line styles
ax = panelAxFn(f, w, h, colW, drawW, drawH, rowH, subH, 3, 2, xlimits, zlimits);
yk = [1.75 0.85];
plot(ax, [1.2 4.6], yk(1)*[1 1], '-', 'Color', FAILED, 'LineWidth', 2.1);
text(ax, 5.4, yk(1), 'failed member', 'FontName', 'Times New Roman', 'FontSize', 7.5, ...
    'VerticalAlignment', 'middle');
plot(ax, [1.2 4.6], yk(2)*[1 1], '-', 'Color', INTACT, 'LineWidth', 0.5);
text(ax, 5.4, yk(2), 'intact member', 'FontName', 'Times New Roman', 'FontSize', 7.5, ...
    'VerticalAlignment', 'middle');

exportFn(f, outDir, 'fig_failure_paths');
end

function ax = panelAxFn(f, w, h, colW, drawW, drawH, rowH, subH, r, c, xlimits, zlimits)
x0 = ((c-1)*colW + 0.16) / w;
y0 = (h - r*rowH + subH) / h;
ax = axes('Parent', f, 'Position', [x0, y0, drawW/w, drawH/h]);
hold(ax, 'on'); axis(ax, 'off');
set(ax, 'DataAspectRatio', [1 1 1]);
xlim(ax, xlimits); ylim(ax, zlimits);
end

% =========================================================================
%  FIGURE fig_cutset_correlation -- PNET representatives
% =========================================================================
function figCutsetCorrelationFn(S, outDir)
% Correlation among the equivalent linear planes of the eight lowest-beta
% PNET group REPRESENTATIVES. Once the grouping step has run, the survivors
% are close to independent -- which is what Pf_sys = 1 - prod(1 - Pf_i)
% assumes, so this is the panel that licenses the combination step.
%
% A second panel showing the same thing for the most critical CUT-SETS was
% dropped in round 4. It held two distinct values, 0.894 and 1.000, so it was
% a uniform dark block whose whole message was "all of these are above the
% threshold" -- one clause of text, which the paper already carries. Side by
% side the two also read as a before/after of the same objects, which they
% are not: they are different sets, and the caption then had to concede that
% the low values here are partly guaranteed by construction.
%
% The cut-set statistics are still COMPUTED and printed below, because the
% paper quotes them (0.894 / 1.000, mean 0.941). Only the panel is gone.
%
% n = 8 rather than 10: keeps the numerals legible in a single column.
rho0 = 0.7;
n    = 8;

[~, ordC] = sort(S.res.betaTilde, 'ascend');
selC = ordC(1:n);
RC   = symFn(S.res.alphaTilde(selC, :) * S.res.alphaTilde(selC, :)', n);

selG = S.gRepIdx(1:n);
RG   = symFn(S.res.alphaTilde(selG, :) * S.res.alphaTilde(selG, :)', n);
lblG = S.gLabel(1:n);

msk = triu(true(n), 1);
reportCorrFn('cut-sets (not plotted)', RC, msk, rho0);
reportCorrFn('representatives',        RG, msk, rho0);

% Two exports, per the journal's note that the printed edition is black and
% white. The diverging map is the honest choice for signed data on screen,
% but a saturated red at +0.7 and a saturated blue at -0.7 convert to nearly
% the same grey -- so the print variant ramps on |rho| instead and carries
% the sign by hatching the negative cells.
corrVariantFn(outDir, 'fig_cutset_correlation',    'colour', RG, lblG, rho0, msk);
corrVariantFn(outDir, 'fig_cutset_correlation_bw', 'bw',     RG, lblG, rho0, msk);
end

%--------------------------------------------------------------------------
function corrVariantFn(outDir, name, mode, R, lbl, rho0, msk)
% Layout, top-down in cm: 0.15 margin | 5.00 panel | 0.70 note (two lines) |
% 0.05 margin. The print variant carries one more line, so it gets 0.40 more.
%
% Across the width: 1.55 row labels | 5.00 panel | 0.15 | 0.35 colourbar |
% 1.35 colourbar labels. The panel is square, so its 8 cells are 0.625 cm --
% roomier than the two-panel layout managed, which is the point of dropping
% the second matrix.
isBW = strcmp(mode, 'bw');
w    = 8.4;
pan  = 5.00;  labW = 1.55;
noteCm = 0.70;
h    = 0.15 + pan + noteCm + 0.05 + 0.40*isBW;

f = newFigFn(w, h);
ax = axes('Parent', f, 'Position', [labW/w, (h - 0.15 - pan)/h, pan/w, pan/h]);
heatPanelFn(ax, R, lbl, rho0, '', [1 4], mode);

cb = colorbar(ax, 'eastoutside');
cb.Units = 'normalized';
cb.Position = [(labW + pan + 0.15)/w, (h - 0.15 - pan)/h, 0.35/w, pan/h];
set(cb, 'FontName', 'Times New Roman', 'FontSize', 7, 'LineWidth', 0.5);
if isBW
    set(cb, 'Ticks', [0 0.5 0.7 1], 'TickLabels', {'0', '0.5', '\rho_0=0.7', '1'});
    cb.Label.String = '|\rho|';
    set(cb.Label, 'FontName', 'Times New Roman', 'FontSize', 7, 'Interpreter', 'tex');
else
    set(cb, 'Ticks', [-1 -0.5 0 0.5 0.7 1], ...
        'TickLabels', {'-1', '-0.5', '0', '0.5', '\rho_0=0.7', '1'});
end
cb.TickLabelInterpreter = 'tex';

% NEVER put a tex command through sprintf's format string: '\rho' contains
% \r, which sprintf turns into a carriage return, so the label rendered as
% "ho_0" and split across three overlapping lines. The tex bits go through
% as %s arguments, where sprintf copies them verbatim.
%
% Two deliberate lines. One line of this at 6.5 pt measures about 9.7 cm and
% would wrap on its own, somewhere sprintf does not get to choose.
note = { ...
    sprintf('%d of %d pairs reach %s = %.1f;  range [%.2f, %.2f], mean %.2f', ...
        sum(R(msk) >= rho0), sum(msk(:)), '\rho_0', rho0, ...
        min(R(msk)), max(R(msk)), mean(R(msk))), ...
    sprintf('dotted cell: the pair that straddles %s across RNG branches', '\rho_0')};
annotation(f, 'textbox', [0.02 0.010 0.96 (noteCm - 0.05)/h], 'String', note, ...
    'FontName', 'Times New Roman', 'FontSize', 6.5, 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Interpreter', 'tex');
if isBW
    annotation(f, 'textbox', [0.02 (noteCm + 0.02)/h 0.96 0.38/h], 'String', ...
        'print variant: shade is |\rho|, hatched cells are negative', ...
        'FontName', 'Times New Roman', 'FontSize', 6.5, 'Color', [0.35 0.35 0.35], ...
        'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', 'Interpreter', 'tex');
end

fprintf('  [%s] single panel, %.2f x %.2f cm\n', name, w, h);
exportFn(f, outDir, name);
end

function R = symFn(R, n)
R = (R + R')/2;
R(1:n+1:end) = 1;
end

function reportCorrFn(name, R, msk, rho0)
fprintf('  [fig5] %-16s %d/%d off-diagonal pairs >= %.2f  (min %.3f, max %.3f, mean %.3f)\n', ...
    name, sum(R(msk) >= rho0), sum(msk(:)), rho0, min(R(msk)), max(R(msk)), mean(R(msk)));
end

function heatPanelFn(ax, R, lbl, rho0, tag, flagCell, mode)
% One correlation panel. Row and column order are identical, so only the row
% labels are drawn -- two sets of rotated column labels would not fit.
%
%   mode 'colour' : diverging map on rho, clim [-1 1]
%   mode 'bw'     : sequential ramp on |rho|, clim [0 1], negative cells
%                   hatched. The numerals keep their sign in both.
n = size(R, 1);
isBW = strcmp(mode, 'bw');
hold(ax, 'on');
if isBW
    imagesc(ax, abs(R)); colormap(ax, sequentialMapFn(255)); clim(ax, [0 1]);
else
    imagesc(ax, R); colormap(ax, divergingMapFn(255)); clim(ax, [-1 1]);
end
axis(ax, 'ij'); axis(ax, 'tight');
styleAxFn(ax);
set(ax, 'XTick', [], 'YTick', 1:n, 'YTickLabel', lbl, 'TickLength', [0 0], ...
    'FontSize', 6.5, 'Box', 'on');
ax.YAxis.TickLabelInterpreter = 'none';

for i = 1:n
    for j = 1:n
        v = R(i, j);
        if abs(v) > 0.55, tc = 'w'; else, tc = 'k'; end
        if isBW && v < 0
            hatchCellFn(ax, i, j, tc);
        end
        text(ax, j, i, sprintf('%.2f', v), 'FontName', 'Times New Roman', ...
            'FontSize', 6, 'Color', tc, 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle');
        if i ~= j && v >= rho0
            rectangle(ax, 'Position', [j-0.5, i-0.5, 1, 1], 'EdgeColor', 'k', 'LineWidth', 0.9);
        end
    end
end
% the pair that straddles rho0 across RNG branches
if ~isempty(flagCell)
    for p = [flagCell; fliplr(flagCell)]'
        rectangle(ax, 'Position', [p(2)-0.5, p(1)-0.5, 1, 1], 'EdgeColor', 'k', ...
            'LineWidth', 1.2, 'LineStyle', ':');
    end
end
for k = 0.5:1:(n+0.5)
    plot(ax, [0.5 n+0.5], [k k], '-', 'Color', 'w', 'LineWidth', 0.4);
    plot(ax, [k k], [0.5 n+0.5], '-', 'Color', 'w', 'LineWidth', 0.4);
end
if ~isempty(tag)
    text(ax, 0.5, -0.1, tag, 'FontName', 'Times New Roman', 'FontSize', 7.5, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Clipping', 'off');
end
end

function hatchCellFn(ax, i, j, col)
% Diagonal hatch marking a negative correlation in the print variant.
%
% Confined to the cell's bottom-left corner rather than run across the whole
% cell: full-width strokes cut straight through the numeral and made "-0.07"
% and "-0.54" hard to read, which defeats the point, since the numeral is
% the primary carrier of the sign and the hatch is only the redundant cue.
% The furthest stroke still clears the text box (it lies on v-u = 0.58 in
% cell-relative coordinates; the nearest corner of a 6 pt numeral is at
% v-u = 0.47). The panel axes are square with unit cells, so these render at
% a true 45 degrees on the page.
for d = [0.20 0.31 0.42]
    plot(ax, [j-0.5+d, j-0.5], [i+0.5, i+0.5-d], '-', ...
        'Color', col, 'LineWidth', 0.45);
end
end

function cm = sequentialMapFn(n)
% White -> near-black ramp for |rho|. Monotone in luminance by construction,
% so it already IS its own greyscale.
t  = linspace(0, 1, n)';
cm = (1 - t) * [1 1 1] + t * [0.12 0.14 0.20];
end

function cm = divergingMapFn(n)
lo = [0.13 0.30 0.60]; hi = [0.66 0.11 0.11];
t  = linspace(-1, 1, n)';
cm = zeros(n, 3);
for k = 1:n
    wgt = abs(t(k));
    if t(k) < 0, cm(k,:) = (1-wgt)*[1 1 1] + wgt*lo;
    else,        cm(k,:) = (1-wgt)*[1 1 1] + wgt*hi;
    end
end
end

% =========================================================================
%  FIGURE 6 -- rho0 sensitivity against the simulation
% =========================================================================
function figRho0SensitivityFn(S, outDir)
mc = S.mc;
[x, ix] = sort(S.rho0Sweep(:));
y = S.sweepRatio(:); y = y(ix);
g = S.sweepGroups(:); g = g(ix);
iOp = find(abs(x - 0.7) < 1e-9, 1);

xLim = [0.27 1.045];
yLim = [0.55 7.9];
unrel = 0.95;                     % beyond this the curve is steep and unstable

f  = newFigFn(8.4, 6.2);
ax = axes('Parent', f, 'Position', [0.135 0.145 0.845 0.835]); hold(ax, 'on');
styleAxFn(ax);

% unreliable region
patch(ax, 'XData', [unrel xLim(2) xLim(2) unrel], 'YData', [yLim(1) yLim(1) yLim(2) yLim(2)], ...
    'FaceColor', [0.90 0.90 0.90], 'EdgeColor', 'none');

% simulation reference with its CI band
rMC = mc.Pf/S.Pf_min; rLo = mc.ciLo/S.Pf_min; rHi = mc.ciHi/S.Pf_min;
% Solid, not FaceAlpha: exportgraphics rasterises a figure that contains
% transparency, and the PDF has to stay genuinely vector.
patch(ax, 'XData', [xLim(1) xLim(2) xLim(2) xLim(1)], 'YData', [rLo rLo rHi rHi], ...
    'FaceColor', [0.78 0.78 0.78], 'EdgeColor', 'none');
plot(ax, xLim, rMC*[1 1], '-', 'Color', 'k', 'LineWidth', 1.1);
% Two significant figures on the ratio; the sample count stays, since section
% 3.3 still states it.
text(ax, 0.30, rMC + 0.13, sprintf('simulation, 10^{8} samples (%.1f\\times)', rMC), ...
    'FontName', 'Times New Roman', 'FontSize', 7.5, 'VerticalAlignment', 'bottom');

% lower bound
plot(ax, xLim, [1 1], '--', 'Color', [0.35 0.35 0.35], 'LineWidth', 0.9);
text(ax, 0.30, 1.12, 'lower bound: P_{f,sys} \geq P_{f,min}', ...
    'FontName', 'Times New Roman', 'FontSize', 7.5, 'VerticalAlignment', 'bottom');

% the PNET curve
plot(ax, x, y, '-', 'Color', 'k', 'LineWidth', 0.9);
plot(ax, x, y, 'o', 'MarkerSize', 3.8, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'w', 'LineWidth', 0.8);
plot(ax, x(iOp), y(iOp), 'o', 'MarkerSize', 5.5, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k');

% Group counts sit below their marker on the flat part of the curve, but to
% the right of it on the steep tail, where "below" lands on the curve itself.
for k = 1:numel(x)
    if x(k) > unrel
        text(ax, x(k) - 0.012, y(k), sprintf('%d', g(k)), 'FontName', 'Times New Roman', ...
            'FontSize', 6.5, 'Color', [0.35 0.35 0.35], 'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'middle');
    else
        text(ax, x(k), y(k) - 0.20, sprintf('%d', g(k)), 'FontName', 'Times New Roman', ...
            'FontSize', 6.5, 'Color', [0.35 0.35 0.35], 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'top');
    end
end

text(ax, x(iOp) - 0.02, y(iOp) + 0.28, sprintf('\\rho_0 = 0.7:  %.1f\\times', y(iOp)), ...
    'FontName', 'Times New Roman', 'FontSize', 8, 'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'bottom');
% Inside the shaded band but clear of both the curve (which enters it at
% 3.66) and the lower-bound line at 1.0.
text(ax, (unrel + xLim(2))/2, 2.3, sprintf('unstable\n\\rho_0 > %.2f', unrel), ...
    'FontName', 'Times New Roman', 'FontSize', 6.5, 'Color', [0.30 0.30 0.30], ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');

xlim(ax, xLim); ylim(ax, yLim);
set(ax, 'XTick', 0.3:0.1:1.0, 'YTick', 1:1:7);
xlabel(ax, '\rho_0  [-]', 'FontName', 'Times New Roman', 'FontSize', 8);
ylabel(ax, 'P_{f} / P_{f,min}  [-]', 'FontName', 'Times New Roman', 'FontSize', 8);

fprintf('  [fig6] curve crosses the simulation line between rho0 = %.2f and %.2f\n', ...
    x(find(y < rMC, 1, 'last')), x(find(y > rMC, 1, 'first')));

exportFn(f, outDir, 'fig_rho0_sensitivity');
end

% =========================================================================
%  FIGURE 7 -- where PNET goes wrong, per failure path
% =========================================================================
function figPnetVsMcFn(S, outDir)
mc = S.mc;
if ~mc.available, fprintf('  fig_pnet_vs_mc SKIPPED (no MC data)\n'); return; end

nR   = 4;
aPf  = S.gPf(1:nR);
mPf  = mc.groupPf(1:nR);
lbl  = S.gLabel(1:nR);

% Hue and lightness. Two cues, not three: the hatch that used to sit on the
% simulation series was a leftover from the greyscale-only design and came
% off in round 4. At luminance 0.33 against 0.77 the pair already separates
% by more than a factor of two in print, and the vertical hatch rules read
% too much like the segment boundaries in fig_accumulation -- where they do
% divide meaningful pieces, which here they would not.
C_PNET = [0.20 0.36 0.60];
C_MC   = [0.98 0.78 0.50];

% Group 3's MC probability is 7.5e-07, so the axis must start well below
% 1e-06 or its bar would be drawn backwards off the left edge.
xLo = 2.5e-7; xHi = 2.6e-4;
f  = newFigFn(8.4, 5.4);
ax = axes('Parent', f, 'Position', [0.245 0.175 0.725 0.795]); hold(ax, 'on');
styleAxFn(ax);
set(ax, 'XScale', 'log');

bh = 0.30;
for k = 1:nR
    yA = k - 0.17; yM = k + 0.17;
    patch(ax, 'XData', [xLo aPf(k) aPf(k) xLo], 'YData', yA + bh/2*[-1 -1 1 1], ...
        'FaceColor', C_PNET, 'EdgeColor', 'k', 'LineWidth', 0.6);
    if mPf(k) > 0
        patch(ax, 'XData', [xLo mPf(k) mPf(k) xLo], 'YData', yM + bh/2*[-1 -1 1 1], ...
            'FaceColor', C_MC, 'EdgeColor', 'k', 'LineWidth', 0.6);
    else
        % exactly zero -- an explicit marker at the axis edge, never a fake
        % epsilon bar that the reader would mistake for a measurement
        % the tick label already says "never observed", so just the marker
        plot(ax, xLo*1.5, yM, 'x', 'MarkerSize', 5, 'Color', 'k', 'LineWidth', 1.0);
    end
end

% Ratios ride in the tick labels rather than floating in the plot: bar 1
% reaches 1.3e-04, which leaves no clear space to the right of it.
tickLbl = cell(nR, 1);
for k = 1:nR
    if mPf(k) > 0
        r = mPf(k)/aPf(k);
        % Two significant figures. The "over" branch already had them (39x);
        % the "under" branch printed 2.82 and 1.94, and the body text quotes
        % 2.8 for the first group.
        if r >= 1, rt = sprintf('%.1f\\times under', r); else, rt = sprintf('%.0f\\times over', 1/r); end
    else
        rt = 'never observed';
    end
    tickLbl{k} = sprintf('%s\\newline\\fontsize{6.5}%s', texBracesFn(lbl{k}), rt);
end
set(ax, 'YDir', 'reverse', 'YTick', 1:nR, 'YTickLabel', tickLbl);
ax.YAxis.TickLabelInterpreter = 'tex';
xlim(ax, [xLo xHi]); ylim(ax, [0.45 nR + 0.55]);
set(ax, 'XTick', [1e-6 1e-5 1e-4], 'XMinorTick', 'on');
xlabel(ax, 'failure probability of the group  [-]', 'FontName', 'Times New Roman', 'FontSize', 8);
ylabel(ax, 'PNET group', 'FontName', 'Times New Roman', 'FontSize', 8);

hKey = legendKeysColFn(ax, [C_PNET; C_MC], xLo);
lg = legend(ax, hKey, {'cut-set analysis', 'simulation'}, 'Box', 'on', 'Location', 'southeast');
styleLegendFn(lg, 6.5);

for k = 1:nR
    fprintf('  [fig7] %-12s PNET %.4e   MC %.4e\n', lbl{k}, aPf(k), mPf(k));
end

exportFn(f, outDir, 'fig_pnet_vs_mc');
end

