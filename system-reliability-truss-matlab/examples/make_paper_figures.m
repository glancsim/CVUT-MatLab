function make_paper_figures(outDir, whichFigs)
% make_paper_figures  Export the NNM 2026 / Acta Polytechnica figures for the
% Warren X-brace example as vector PDFs (plus PNG previews at final size).
%
%   make_paper_figures()             % all seven -> C:\GitHub\ctu-nnm-2026\figures
%   make_paper_figures(outDir)       % custom directory
%   make_paper_figures([], 3)        % just figure 3, default directory
%   make_paper_figures([], [3 7])    % figures 3 and 7
%
% The whichFigs argument exists because MATLAB's figure rendering is fragile
% on the development machines here: exporting one figure at a time isolates
% which one is at fault, and makes iterating on a single layout cheap.
%
% FIGURES
%   fig_geometry.pdf            truss, supports, mean loads, numbering
%   fig_component_beta.pdf      per-member beta_i, sorted, with the
%                               [beta_min, beta_min+0.2] band
%   fig_accumulation.pdf        Pf_min vs Pf_sys (PNET) vs Pf_MC, stacked
%   fig_failure_paths.pdf       the five dominant MC mechanisms on the truss
%   fig_cutset_correlation.pdf  (a) top cut-sets vs (b) PNET representatives
%   fig_rho0_sensitivity.pdf    ratio against rho0, vs the simulation line
%   fig_pnet_vs_mc.pdf          per-group PNET Pf vs MC Pf, log axis
%
% MONTE CARLO: figures 3, 4, 6 and 7 consume
% tests/mc_neptun/mc_neptun_result.mat (10^8 samples, 18 820 failures). The
% mechanism tally and the per-PNET-group MC probabilities are derived from
% out.failSequences rather than transcribed, so they track the raw data.
%
% STYLE: single-column Acta Polytechnica figures -- 8.4 cm wide, serif 8 pt,
% no titles (captions live in the LaTeX source), greyscale-safe (series are
% separated by lightness, marker, hatch or line style, never by hue alone),
% lines >= 0.75 pt, margins trimmed to the drawing.
%
% DATA: reuses examples/warren_xbrace_paper_results.mat if it exists (written
% by example_warren_xbrace_paper.m). Otherwise it recomputes -- the headline
% run plus the eight-point rho0 sweep, each under rng(42); nine
% systemReliabilityFn calls, so roughly 1 to 5 minutes.
%
% See also: warrenXbraceModelFn, example_warren_xbrace_paper
%
% (c) S. Glanc, 2026

if nargin < 1 || isempty(outDir)
    outDir = 'C:\GitHub\ctu-nnm-2026\figures';
end
if nargin < 2 || isempty(whichFigs), whichFigs = 1:7; end
if ~exist(outDir, 'dir'), mkdir(outDir); end

exDir = fileparts(mfilename('fullpath'));
addpath(exDir);
addpath(fullfile(exDir, '..', 'src'));
addpath(fullfile(exDir, '..', 'tests'));
addpath(fullfile(exDir, '..', '..', 'fem-2d-truss-matlab', 'src'));

fprintf('=== make_paper_figures -> %s ===\n', outDir);
fprintf('figures requested: %s\n', mat2str(whichFigs));
S = loadOrComputeFn(exDir);

makers = {@figGeometryFn, @figComponentBetaFn, @figAccumulationFn, ...
          @figFailurePathsFn, @figCutsetCorrelationFn, @figRho0SensitivityFn, ...
          @figPnetVsMcFn};
for k = whichFigs(:)'
    fprintf('-- figure %d\n', k);
    makers{k}(S, outDir);
end
fprintf('done.\n');

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
n  = numel(greys);
hL = gobjects(n, 1);
for g = 1:n
    % multiplicative width so the same helper works on a log x axis too
    hL(g) = patch(ax, 'XData', xAnchor * [1 1.05 1.05 1], 'YData', [-9 -9 -8 -8], ...
        'FaceColor', greys(g)*[1 1 1], 'EdgeColor', 'k', 'LineWidth', 0.6);
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
pdf = fullfile(outDir, [name '.pdf']);
png = fullfile(outDir, [name '.png']);
exportgraphics(f, pdf, 'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(f, png, 'Resolution', 300, 'BackgroundColor', 'white');
close(f);
d = dir(pdf);
fprintf('  %-28s %6.1f kB   +preview\n', [name '.pdf'], d.bytes/1024);
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
%  SEGMENT FILLS shared by figures 3 and 7
% =========================================================================
function st = segStyleFn(label)
% One (grey, hatch) pair per cut-set identity, used consistently wherever
% that identity appears -- so {11,14} is recognisably the same block in the
% analytical stack and in the simulated stack of figure 3, and the cut-sets
% that appear in only one of them are visibly unique.
%
% Hatching is VERTICAL rather than diagonal on purpose: the bars are tall
% and narrow, so a diagonal at a fixed data-space slope would look like a
% different angle in every segment.
tbl = { ...
    '{11,14}',    0.32, true ; ...
    '{1,2,8}',    0.55, false; ...
    '{5,12}',     0.75, false; ...
    '{4,8,9,16}', 0.92, false; ...
    '{2,5}',      0.44, false; ...
    '{13,16}',    0.66, true ; ...
    '{7,11}',     0.84, true ; ...
    '{10,16}',    0.97, true ; ...
    'others',     1.00, false};
idx = find(strcmp(tbl(:,1), label), 1);
if isempty(idx), idx = size(tbl, 1); end
st.grey  = tbl{idx, 2};
st.hatch = tbl{idx, 3};
end

function hatchRectFn(ax, xc, bw, y0, y1, col)
% Vertical hatch lines inside an axis-aligned rectangle.
n = 5;
xs = linspace(xc - bw/2, xc + bw/2, n + 2);
for k = 2:n+1
    plot(ax, [xs(k) xs(k)], [y0 y1], '-', 'Color', col, 'LineWidth', 0.4);
end
end

function h = stackBarFn(ax, xc, bw, vals, labels)
% Stacked bar at xc; returns one handle per segment (for the legend).
h = gobjects(numel(vals), 1);
cum = 0;
for k = 1:numel(vals)
    st = segStyleFn(labels{k});
    h(k) = patch(ax, 'XData', xc + bw/2*[-1 1 1 -1], ...
        'YData', [cum cum cum+vals(k) cum+vals(k)], ...
        'FaceColor', st.grey*[1 1 1], 'EdgeColor', 'k', 'LineWidth', 0.7);
    if st.hatch
        hatchRectFn(ax, xc, bw, cum, cum+vals(k), [0.15 0.15 0.15]);
    end
    cum = cum + vals(k);
end
end

% =========================================================================
%  FIGURE 3 -- Pf_min vs PNET vs simulation, both stacked
% =========================================================================
function figAccumulationFn(S, outDir)
mc = S.mc;
if ~mc.available, fprintf('  fig_accumulation SKIPPED (no MC data)\n'); return; end

% --- analytical stack: the four groups that carry the total -----------
aVals = S.gPf(1:4);
aLbls = S.gLabel(1:4);
aRest = sum(S.gPf(5:end));
if aRest > 0.02*S.Pf_sys, aVals(end+1) = aRest; aLbls{end+1} = 'others'; end

% --- simulated stack: mechanisms above 2 %, remainder pooled ----------
keep  = mc.mechPf >= 0.02 * mc.Pf;
mVals = mc.mechPf(keep);
mLbls = mc.mechLabel(keep);
mRest = sum(mc.mechPf(~keep));
if mRest > 0, mVals(end+1) = mRest; mLbls{end+1} = 'others'; end

f  = newFigFn(8.4, 6.6);
ax = axes('Parent', f, 'Position', [0.155 0.235 0.475 0.715]); hold(ax, 'on');
styleAxFn(ax);

xs = [1 2 3]; bw = 0.5;
yMax = 2.12e-4;

patch(ax, 'XData', xs(1) + bw/2*[-1 1 1 -1], 'YData', [0 0 S.Pf_min S.Pf_min], ...
    'FaceColor', 0.32*[1 1 1], 'EdgeColor', 'k', 'LineWidth', 0.7);
hA = stackBarFn(ax, xs(2), bw, aVals, aLbls);
hM = stackBarFn(ax, xs(3), bw, mVals, mLbls);

% 95 % CI on the simulated total
plot(ax, xs(3)*[1 1], [mc.ciLo mc.ciHi], 'k-', 'LineWidth', 0.9);
plot(ax, xs(3) + 0.11*[-1 1], mc.ciLo*[1 1], 'k-', 'LineWidth', 0.9);
plot(ax, xs(3) + 0.11*[-1 1], mc.ciHi*[1 1], 'k-', 'LineWidth', 0.9);

% lower bound: the first analytical segment alone equals Pf_min
plot(ax, [0.5 3.62], S.Pf_min*[1 1], 'k--', 'LineWidth', 0.8);
text(ax, 0.58, S.Pf_min + 0.10e-4, sprintf('lower bound:\nP_{f,sys} \\geq P_{f,min}'), ...
    'FontName', 'Times New Roman', 'FontSize', 6.5, 'VerticalAlignment', 'bottom');

% headline ratio, Pf_min -> Pf_MC
xa = 3.50;
arrowPairFn(ax, xa, S.Pf_min, mc.Pf, 0.045, 0.05e-4, 'k');
% Above the arrow, not beside it: beside it the label runs past the axes and
% under the legend box, which silently ate the "x" of "4.07x".
text(ax, xa, mc.Pf + 0.06e-4, sprintf('%.2f\\times', mc.Pf/S.Pf_min), ...
    'FontName', 'Times New Roman', 'FontSize', 8.5, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom');
% and the discreet one, PNET -> simulation
xb = 2.60;
arrowPairFn(ax, xb, S.Pf_sys, mc.Pf, 0.035, 0.04e-4, [0.4 0.4 0.4]);
text(ax, xb - 0.05, (S.Pf_sys + mc.Pf)/2, sprintf('%.2f\\times', mc.Pf/S.Pf_sys), ...
    'FontName', 'Times New Roman', 'FontSize', 6.5, 'Color', [0.4 0.4 0.4], ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');

xlim(ax, [0.5 3.75]); ylim(ax, [0 yMax]);
set(ax, 'XTick', xs, 'XTickLabel', { ...
    'P_{f,min}\newline\fontsize{6.5}weakest\newlinemember', ...
    'P_{f,sys}\newline\fontsize{6.5}cut-set\newlineanalysis', ...
    'P_{f,MC}\newline\fontsize{6.5}simulation,\newline10^{8} samples'});
ax.XAxis.TickLabelInterpreter = 'tex';
ylabel(ax, 'failure probability  [-]', 'FontName', 'Times New Roman', 'FontSize', 8);
ax.YAxis.Exponent = -4;

% one legend, keyed by cut-set identity across both stacks
[uLbl, ia] = unique([aLbls, mLbls], 'stable');
hAll = [hA(:); hM(:)];
lg = legend(ax, hAll(ia), uLbl, 'Box', 'on');
styleLegendFn(lg, 6.5);
lg.Interpreter = 'none';        % keep the braces of {11,14}; tex eats them
lg.Units = 'normalized';
lg.Position = [0.675 0.30 0.30 0.60];

exportFn(f, outDir, 'fig_accumulation');
end

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

    drawTrussFn(ax, model, mech, 0.5, 1.9, 0.72*[1 1 1], 'k');
    drawSupportFn(ax, model.nodes.x(1), model.nodes.z(1), 'pin',    0.55, 0.72*[1 1 1]);
    drawSupportFn(ax, model.nodes.x(4), model.nodes.z(4), 'roller', 0.55, 0.72*[1 1 1]);

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
plot(ax, [1.2 4.6], yk(1)*[1 1], '-', 'Color', 'k', 'LineWidth', 1.9);
text(ax, 5.4, yk(1), 'failed member', 'FontName', 'Times New Roman', 'FontSize', 7.5, ...
    'VerticalAlignment', 'middle');
plot(ax, [1.2 4.6], yk(2)*[1 1], '-', 'Color', 0.72*[1 1 1], 'LineWidth', 0.5);
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
%  FIGURE 5 -- correlation, cut-sets (a) vs PNET representatives (b)
% =========================================================================
function figCutsetCorrelationFn(S, outDir)
% Panel (a) is the diagnostic: the most critical CUT-SETS are all mutually
% correlated at or above rho0, so PNET collapses them into a single group --
% including four cut-sets the simulation shows to be genuinely distinct,
% mutually exclusive mechanisms. Panel (b) is the complement: once grouped,
% the surviving representatives really are near-independent. The defect is
% in what gets absorbed, not in how the survivors are combined.
%
% n = 8 rather than 10: two labelled 10x10 grids with in-cell numerals do
% not fit a single 8.4 cm column without collisions, and the addendum
% permits dropping to eight.
rho0 = 0.7;
n    = 8;

[~, ordC] = sort(S.res.betaTilde, 'ascend');
selC = ordC(1:n);
RC   = symFn(S.res.alphaTilde(selC, :) * S.res.alphaTilde(selC, :)', n);
lblC = cellfun(@(c) setLabelFn(c), S.res.cutSets(selC), 'UniformOutput', false);

selG = S.gRepIdx(1:n);
RG   = symFn(S.res.alphaTilde(selG, :) * S.res.alphaTilde(selG, :)', n);
lblG = S.gLabel(1:n);

msk = triu(true(n), 1);
reportCorrFn('cut-sets',        RC, msk, rho0);
reportCorrFn('representatives', RG, msk, rho0);

% Layout, top-down in cm: 0.70 margin+tag | 3.90 panel (a) | 0.85 gap+tag |
% 3.90 panel (b) | 0.50 note | 0.05 margin. Square panels of 3.90 cm give
% 0.4875 cm cells, which the 6 pt numerals clear.
%
% The tags need more clearance than looks necessary. heatPanelFn draws each
% at y = -0.1 in data units, but the axis top is y = 0.5, not 0, so the
% baseline sits 0.6 rows (~0.29 cm) above the panel and the glyphs rise
% ~0.28 cm further. Two earlier attempts undershot: a 0.25 cm gap put panel
% (b)'s tag inside panel (a), and a 0.45 cm top margin clipped panel (a)'s
% tag off the top of the figure altogether.
%
% The result is a 9.9 cm tall figure, well over the 6.5 cm guidance -- but
% two labelled 8x8 matrices with in-cell values cannot be had for less in a
% single column.
w = 8.4;  h = 9.90;
pan = 3.90;  labW = 1.55;
f = newFigFn(w, h);
gridW = pan / w;
gridH = pan / h;
x0    = labW / w;
yA    = (h - 0.70 - pan) / h;
yB    = (h - 0.70 - pan - 0.85 - pan) / h;
axA = axes('Parent', f, 'Position', [x0 yA gridW gridH]);
axB = axes('Parent', f, 'Position', [x0 yB gridW gridH]);

heatPanelFn(axA, RC, lblC, rho0, '(a) most critical cut-sets', []);
heatPanelFn(axB, RG, lblG, rho0, '(b) PNET group representatives', [1 4]);

cb = colorbar(axB, 'eastoutside');
cb.Units = 'normalized';
cb.Position = [(labW + pan + 0.15)/w, yB, 0.35/w, (yA + gridH) - yB];
set(cb, 'FontName', 'Times New Roman', 'FontSize', 7, 'LineWidth', 0.5, ...
    'Ticks', [-1 -0.5 0 0.5 0.7 1], 'TickLabels', {'-1', '-0.5', '0', '0.5', '\rho_0=0.7', '1'});
cb.TickLabelInterpreter = 'tex';

annotation(f, 'textbox', [0.02 0.002 0.96 0.048], 'String', ...
    sprintf(['(a) %d/%d pairs \\geq \\rho_0, mean %.2f    ' ...
             '(b) %d/%d, mean %.2f;  boxed cell straddles \\rho_0'], ...
    sum(RC(msk) >= rho0), sum(msk(:)), mean(RC(msk)), ...
    sum(RG(msk) >= rho0), sum(msk(:)), mean(RG(msk))), ...
    'FontName', 'Times New Roman', 'FontSize', 6.5, 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Interpreter', 'tex');

exportFn(f, outDir, 'fig_cutset_correlation');
end

function R = symFn(R, n)
R = (R + R')/2;
R(1:n+1:end) = 1;
end

function reportCorrFn(name, R, msk, rho0)
fprintf('  [fig5] %-16s %d/%d off-diagonal pairs >= %.2f  (min %.3f, max %.3f, mean %.3f)\n', ...
    name, sum(R(msk) >= rho0), sum(msk(:)), rho0, min(R(msk)), max(R(msk)), mean(R(msk)));
end

function heatPanelFn(ax, R, lbl, rho0, tag, flagCell)
% One correlation panel. Row and column order are identical, so only the row
% labels are drawn -- two sets of rotated column labels would not fit.
n = size(R, 1);
hold(ax, 'on');
imagesc(ax, R); colormap(ax, divergingMapFn(255)); clim(ax, [-1 1]);
axis(ax, 'ij'); axis(ax, 'tight');
styleAxFn(ax);
set(ax, 'XTick', [], 'YTick', 1:n, 'YTickLabel', lbl, 'TickLength', [0 0], ...
    'FontSize', 6.5, 'Box', 'on');
ax.YAxis.TickLabelInterpreter = 'none';

for i = 1:n
    for j = 1:n
        v = R(i, j);
        if abs(v) > 0.55, tc = 'w'; else, tc = 'k'; end
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
text(ax, 0.5, -0.1, tag, 'FontName', 'Times New Roman', 'FontSize', 7.5, ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Clipping', 'off');
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
text(ax, 0.30, rMC + 0.13, sprintf('simulation, 10^{8} samples (%.2f\\times)', rMC), ...
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

text(ax, x(iOp) - 0.02, y(iOp) + 0.28, sprintf('\\rho_0 = 0.7:  %.2f\\times', y(iOp)), ...
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
        'FaceColor', 0.45*[1 1 1], 'EdgeColor', 'k', 'LineWidth', 0.6);
    if mPf(k) > 0
        patch(ax, 'XData', [xLo mPf(k) mPf(k) xLo], 'YData', yM + bh/2*[-1 -1 1 1], ...
            'FaceColor', 0.92*[1 1 1], 'EdgeColor', 'k', 'LineWidth', 0.6);
        hatchRectHFn(ax, xLo, mPf(k), yM, bh, [0.2 0.2 0.2]);
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
        if r >= 1, rt = sprintf('%.2f\\times under', r); else, rt = sprintf('%.0f\\times over', 1/r); end
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

hKey = legendKeysFn(ax, [0.45 0.92], xLo);
lg = legend(ax, hKey, {'cut-set analysis', 'simulation'}, 'Box', 'on', 'Location', 'southeast');
styleLegendFn(lg, 6.5);

for k = 1:nR
    fprintf('  [fig7] %-12s PNET %.4e   MC %.4e\n', lbl{k}, aPf(k), mPf(k));
end

exportFn(f, outDir, 'fig_pnet_vs_mc');
end

function hatchRectHFn(ax, x0, x1, yc, bh, col)
% Horizontal hatch inside a log-x bar: lines evenly spaced in log space.
xs = logspace(log10(x0), log10(x1), 9);
for k = 2:numel(xs)-1
    plot(ax, [xs(k) xs(k)], yc + bh/2*[-1 1], '-', 'Color', col, 'LineWidth', 0.35);
end
end
