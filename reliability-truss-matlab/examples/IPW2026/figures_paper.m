% figures_paper.m
%
% Generování 4 publikačních figur pro konferenční paper IPW 2026.
%
% Požadavky IPW 2026:
%   Formát:     TIF, 600 dpi
%   Font:       Times New Roman, 10 pt
%   Šířka:      17 cm (celá šířka)
%
% Spuštění:  run('examples/IPW2026/figures_paper.m')   (z kořene repozitáře)
%
% (c) S. Glanc, 2026

clear; close all;

%% ── Cesty k modulům ──────────────────────────────────────────────────
% thisDir = adresář tohoto souboru (examples/IPW2026/)
thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end          % fallback: CWD
% 2 úrovně nahoru: IPW2026/ → examples/ → reliability-truss-matlab/
root      = fileparts(fileparts(thisDir));
srcDir    = fullfile(root, 'src');
designDir = fullfile(root, '..', 'en-truss-design-matlab', 'src');
femDir    = fullfile(root, '..', 'fem-2d-truss-matlab', 'src');

addpath(srcDir);
addpath(designDir);
addpath(femDir);

%% ── Výstupní složka ──────────────────────────────────────────────────
exDir  = thisDir;   % examples/IPW2026/
outDir = fullfile(exDir, 'figures');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

generated = {};
skipped   = {};

%% ── Inicializace UQLab (potřeba pro Figure 4) ───────────────────────
uqlab_core = 'C:\Install\UQLab\core';
if exist(uqlab_core, 'dir') && isempty(which('uqlab'))
    addpath(uqlab_core);
end
try
    uqlab;
    has_uqlab = true;
catch ME_uq
    has_uqlab = false;
    fprintf('Upozornění: UQLab selhal: %s\n', ME_uq.message);
    fprintf('  → Figure 4 bude přeskočena.\n');
end

%% ── Referenční hodnoty (použity ve Fig 3 i Fig 4) ───────────────────
beta_EC   = 4.7;   % Eurocode: referenční prvek, 1 rok
beta_JCSS = 4.1;   % JCSS: sériový systém, ocel + sníh, 1 rok
% beta_final — načte z reliability_results.mat pokud existuje, jinak fallback
mat_beta = fullfile(exDir, 'reliability_results.mat');
if exist(mat_beta, 'file')
    tmp = load(mat_beta, 'results');
    beta_final = tmp.results.beta;
    N_final    = tmp.results.nSamples;
    clear tmp;
else
    beta_final = NaN;
    N_final    = 1e8;
end
N_final    = 1e8;

% =====================================================================
%% Figure 1 — Topologie příhradoviny s kritickými pruty
% =====================================================================
fprintf('\n─── Figure 1: Topologie + kritičnost prutů ───\n');

src1_tif = fullfile(exDir, 'plotTrussBeta.tif');
src1_fig = fullfile(exDir, 'critical_members.fig');
out1     = fullfile(outDir, 'fig1_truss_beta.tif');

% Preferuj .fig (umožní opravit osy a font); .tif jen jako nouzový fallback
if exist(src1_fig, 'file')
    hF1  = openfig(src1_fig, 'invisible');
    ax1  = findobj(hF1, 'Type', 'Axes');
    % Odstraň prázdný prostor pod příhradovinou — y jde jen na -1.2
    for ia = 1:numel(ax1)
        yl = ylim(ax1(ia));
        if yl(1) < -1
            ylim(ax1(ia), [-1.2, yl(2)]);
        end
    end
    set(hF1, 'Renderer', 'painters');
    applyPaperStyle(hF1, 17, 8);
    exportgraphics(hF1, out1, 'ContentType', 'image', 'Resolution', 600);
    close(hF1);
    fprintf('  Exportováno z critical_members.fig\n');
    generated{end+1} = 'examples/figures/fig1_truss_beta.tif';
elseif exist(src1_tif, 'file')
    copyfile(src1_tif, out1);   % fallback — bez opravy stylu
    fprintf('  Zkopírováno: plotTrussBeta.tif → fig1_truss_beta.tif (fallback)\n');
    generated{end+1} = 'examples/figures/fig1_truss_beta.tif';
else
    fprintf('  POZOR: ani critical_members.fig ani plotTrussBeta.tif neexistuje.\n');
    skipped{end+1} = '[SKIPPED] fig1_truss_beta.tif — chybí zdrojový .fig / .tif';
end

% =====================================================================
%% Figure 2 — Fit Gumbelova rozdělení na sněhová data
% =====================================================================
fprintf('\n─── Figure 2: Gumbelovo rozdělení sněhu ───\n');

% Reálná roční maxima sněhové pokrývky — Ostrava-Mošnov (Letiště Leoše Janáčka)
% Sezony 1961/62 – 2021/22  (n = 61),  jednotky: cm → kN/m²
snow_cm = [26.6; 74.3; 21.8; 52.4; 28.6; 17.2; 28.0; 21.3; 51.7; 36.5; ...
           30.4; 24.5; 15.0; 22.5; 21.2; 24.0; 25.9; 53.3; 18.3; 33.4; ...
           57.4; 52.0; 16.0; 40.2; 47.2; 57.9; 16.0; 13.8;  6.6; 19.9; ...
           16.4; 24.8; 38.0; 14.0; 61.6; 56.3;  4.6; 19.6; 18.0; 29.3; ...
           29.5; 15.7; 59.4; 49.8; 92.5; 31.5;  7.6; 34.4; 71.4; 30.9; ...
           19.4; 32.2;  8.0; 28.4;  8.4; 26.2; 20.0; 14.8;  4.0; 25.5; ...
           29.2];
data = snow_cm / 100;   % [kN/m²]

% Gumbel parametry — method of moments z reálných dat
beta_g = std(data) * sqrt(6) / pi;
u_g    = mean(data) - 0.5772 * beta_g;

s_k = 1.0;   % [kN/m²] charakteristická hodnota

% Gumbel PDF — x od 0 do 1.1 (data: 0.013–0.767 kN/m², s_k=1.0 přesahuje)
x_pdf = linspace(0, 1.1, 300);
pdf_gumbel = (1/beta_g) .* exp(-(x_pdf - u_g)./beta_g) .* exp(-exp(-(x_pdf - u_g)./beta_g));

hF2 = figure('Renderer', 'painters', 'Color', 'w');
applyPaperStyle(hF2, 17, 8);

% Histogram — jen kladné hodnoty
histogram(data(data >= 0), 20, ...
    'Normalization', 'pdf', ...
    'FaceColor', [0.80 0.80 0.80], ...
    'EdgeColor', [0.30 0.30 0.30], ...
    'LineWidth', 0.8);
hold on;

hPdf = plot(x_pdf, pdf_gumbel, 'k-', 'LineWidth', 1.5);

% s_k čára bez legendy
xline(s_k, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');

xlim([0, 1.1]);
ax2   = gca;
ylim2 = ylim(ax2);

% Popisek s_k — vpravo od čáry, ve spodní části (nepřekrývá legendu)
text(s_k + 0.02, ylim2(2) * 0.30, ...
    '$s_k = 1.0$ kN/m$^2$', ...
    'Interpreter', 'latex', ...
    'FontSize', 9, ...
    'FontName', 'Garamond', ...
    'VerticalAlignment', 'bottom');

xlabel('$s_0$ [kN/m$^2$]', 'Interpreter', 'latex');
ylabel('Probability density [m$^2$/kN]', 'Interpreter', 'latex');

legend(hPdf, ...
    sprintf('Gumbel fit ($\\mu_u = %.3f$ kN/m$^2$, $\\sigma = %.3f$ kN/m$^2$)', u_g, beta_g), ...
    'Interpreter', 'latex', ...
    'Location', 'northeast', ...
    'Box', 'off');

grid on; box on; hold off;

out2 = fullfile(outDir, 'fig2_gumbel.tif');
exportgraphics(hF2, out2, 'ContentType', 'image', 'Resolution', 600);
close(hF2);
generated{end+1} = 'examples/figures/fig2_gumbel.tif';
fprintf('  Exportováno: fig2_gumbel.tif\n');

% =====================================================================
%% Figure 3 — Konvergence Monte Carlo
% =====================================================================
fprintf('\n─── Figure 3: Konvergence Monte Carlo ───\n');

src3 = fullfile(exDir, 'convergence.fig');
out3 = fullfile(outDir, 'fig3_convergence.tif');

hF3 = figure('Renderer', 'painters', 'Color', 'w');
applyPaperStyle(hF3, 17, 8);
hold on;

if exist(src3, 'file')
    fprintf('  Načítám convergence.fig (může chvíli trvat) ...\n');
    hSrc3 = openfig(src3, 'invisible');

    % convergence.fig má 2 subploty: (1) β vs. N, (2) histogram g_sys
    % gca ukazuje na poslední aktivní subplot → nepoužívat, projít všechny Line objekty
    allLines3 = findobj(hSrc3, 'Type', 'Line');
    x_conv = []; y_conv = [];
    for il = 1:numel(allLines3)
        xd = get(allLines3(il), 'XData');
        yd = get(allLines3(il), 'YData');
        % Hledáme: ≥3 bodů, X > 0 (počty vzorků), Y v rozsahu β (1–15)
        if numel(xd) >= 3 && all(xd > 0) && min(yd) > 1 && max(yd) < 15
            if numel(xd) > numel(x_conv)
                x_conv = xd;
                y_conv = yd;
            end
        end
    end
    close(hSrc3);

    if ~isempty(x_conv)
        valid3 = isfinite(x_conv) & isfinite(y_conv);
        x_conv = x_conv(valid3);
        y_conv = y_conv(valid3);
    end

    if ~isempty(x_conv)
        plot(x_conv, y_conv, 'k-', 'LineWidth', 1.5);
        conv_loaded = true;
    else
        conv_loaded = false;
        fprintf('  convergence.fig načten, ale β-křivka nenalezena — placeholder.\n');
    end
else
    % TODO: doplnit data z results.beta_convergence pokud convergence.fig chybí
    conv_loaded = false;
    fprintf('  convergence.fig nenalezen — placeholder s referenčními čarami.\n');
end

ax3 = gca;
hEC3   = yline(beta_EC,   'k--', 'LineWidth', 1.0);
hJCSS3 = yline(beta_JCSS, 'k:',  'LineWidth', 1.0);

set(ax3, 'XScale', 'log');
% Začni od prvního datového bodu (= batchSize, ne pevně 1e4)
if conv_loaded && ~isempty(x_conv)
    x_start = 10^floor(log10(min(x_conv)));   % zaokrouhli dolů na mocninu 10
else
    x_start = 1e4;
end
xlim3 = [x_start, 1e8];
xlim(xlim3);

% Popisky referenčních čar
text(xlim3(2)*0.85, beta_EC   + 0.08, 'Eurocode target ($\beta_t = 4.7$)', ...
    'Interpreter', 'latex', 'FontSize', 9, 'FontName', 'Garamond', 'HorizontalAlignment', 'right');
text(xlim3(2)*0.85, beta_JCSS - 0.12, 'JCSS system target ($\beta_t = 4.1$)', ...
    'Interpreter', 'latex', 'FontSize', 9, 'FontName', 'Garamond', 'HorizontalAlignment', 'right');

% Výsledný bod
plot(N_final, beta_final, 'ko', 'MarkerSize', 7, 'MarkerFaceColor', 'k');
text(N_final * 0.55, beta_final + 0.12, ...
    sprintf('$\\beta = %.1f$', beta_final), ...
    'Interpreter', 'latex', 'FontSize', 9, 'FontName', 'Garamond');

if ~conv_loaded
    text(0.5, 0.5, 'TODO: doplnit convergence data', ...
        'Units', 'normalized', 'HorizontalAlignment', 'center', ...
        'FontSize', 9, 'Color', [0.6 0.6 0.6]);
    ylim([3.5, 5.5]);
else
    ylim([min([y_conv, beta_JCSS]) - 0.3, max([y_conv, beta_EC]) + 0.4]);
end

xlabel('Number of samples $N$ [-]', 'Interpreter', 'latex');
ylabel('Reliability index $\beta$ [-]', 'Interpreter', 'latex');
grid on; box on; hold off;

exportgraphics(hF3, out3, 'ContentType', 'image', 'Resolution', 600);
close(hF3);

if conv_loaded
    generated{end+1} = 'examples/figures/fig3_convergence.tif';
    fprintf('  Exportováno: fig3_convergence.tif\n');
else
    skipped{end+1} = '[SKIPPED] fig3_convergence.tif — viz TODO komentář ve skriptu';
    fprintf('  Placeholder uložen jako fig3_convergence.tif\n');
end

% =====================================================================
%% Geometrie + deterministický posudek (sdíleno pro Fig 4 a Fig 5)
% =====================================================================
CHS_fn = @(D, t) struct( ...
    'D', D, 't', t, ...
    'A', pi/4*(D^2 - (D-2*t)^2), ...
    'I', pi/64*(D^4 - (D-2*t)^4), ...
    'i', sqrt( (pi/64*(D^4-(D-2*t)^4)) / (pi/4*(D^2-(D-2*t)^2)) ));

profs_det = [CHS_fn(0.108,  0.005);
             CHS_fn(0.159,  0.005);
             CHS_fn(0.0825, 0.0036);
             CHS_fn(0.0445, 0.0032);
             CHS_fn(0.038,  0.0036)];
nP_det = numel(profs_det);
sec_det.A        = [profs_det.A]';
sec_det.E        = 210e9 * ones(nP_det, 1);
sec_det.I        = [profs_det.I]';
sec_det.i_radius = [profs_det.i]';
sec_det.curve    = repmat({'a'}, nP_det, 1);
sec_det.D        = [profs_det.D]';
sec_det.t        = [profs_det.t]';

par_det.span            = 24;      par_det.slope           = 0.05;
par_det.purlin_spacing  = 3;       par_det.h_support       = 1.8;
par_det.truss_spacing   = 6.6;     par_det.f_y             = 355e6;
par_det.E               = 210e9;   par_det.g_roof           = 0.23;
par_det.g_purlins       = 0.09;    par_det.s_k              = 1.0;
par_det.w_suction       = 0.48;    par_det.sections         = sec_det;
par_det.topology        = 'warren_inverted';
par_det.warren_verticals = true;
par_det.diag_sections   = [3 3 4 4];
par_det.vert_sections   = 5;
par_det.support         = 'top';

[nd_det, mb_det, sec_det_exp, ki_det, lp_det] = trussHallInputFn(par_det);
detResults_det = designCheckFn(nd_det, mb_det, sec_det_exp, ki_det, lp_det);
clf_det        = memberClassificationFn(mb_det, nd_det);
nmem_det       = numel(mb_det.nodesHead);

% =====================================================================
%% Figure 4 — Component reliability β per member, colored by utilization
% =====================================================================
fprintf('\n─── Figure 4: Component β — sloupcový graf ───\n');

mat4 = fullfile(exDir, 'reliability_results.mat');
out4 = fullfile(outDir, 'fig4_component_beta.tif');

if ~exist(mat4, 'file')
    fprintf('  POZOR: reliability_results.mat neexistuje.\n');
    fprintf('  Spusť nejprve example_reliability_24m.m, pak regeneruj figury.\n');
    skipped{end+1} = '[SKIPPED] fig4_component_beta.tif — chybí reliability_results.mat';
else
    load(mat4, 'results');

    % Component β z per-member failure counts (MCS — nestranné vzorky)
    n_comp   = results.member.n_tension_fail + results.member.n_buckling_fail;
    Pf_min   = 0.5 / results.nSamples;
    Pf_comp  = max(n_comp / results.nSamples, Pf_min);
    beta_comp = -norminv(Pf_comp);   % (nmem×1)

    util4 = detResults_det.util_max;   % (nmem×1) využití dle EC

    % Colormap pro barvy sloupků: zelená→žlutá→oranžová→červená (stejná jako Fig 5)
    cmap4_pts = [0.20, 0.70, 0.20;
                 0.65, 0.85, 0.20;
                 1.00, 0.85, 0.00;
                 1.00, 0.45, 0.00;
                 0.85, 0.00, 0.00];
    cmap4 = interp1(linspace(0,1,size(cmap4_pts,1)), cmap4_pts, linspace(0,1,256));

    % Barva každého sloupku dle util (clamp na [0,1])
    ci4 = max(1, round(min(util4, 1.0) * 255) + 1);
    bar_clr4 = cmap4(ci4, :);   % (nmem×3)

    hF4 = figure('Renderer', 'painters', 'Color', 'w');
    applyPaperStyle(hF4, 17, 8);
    ax4 = axes(hF4);
    hold(ax4, 'on');

    % Sloupce — každý prut zvlášť kvůli individuální barvě
    for k = 1:nmem_det
        bar(ax4, k, beta_comp(k), 1, ...
            'FaceColor', bar_clr4(k,:), ...
            'EdgeColor', 'none');
    end

    % Referenční čára — cílový index spolehlivosti pro prvek dle EN 1990
    yline(ax4, beta_EC, 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    text(1, beta_EC + 0.05, '$\beta_t = 4.7$', ...
        'Parent', ax4, 'Interpreter', 'latex', 'FontSize', 8, ...
        'FontName', 'Garamond', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

    xlim(ax4, [0, nmem_det + 1]);

    % Čísla prutů dole u každého sloupce
    yl4 = ylim(ax4);
    for k = 1:nmem_det
        text(ax4, k, yl4(1) + 0.05, num2str(k), ...
            'FontSize', 6, 'FontName', 'Garamond', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'Color', 'k');
    end
    set(ax4, 'XTick', []);   % skryj původní x-ticky — čísla jsou přímo na sloupcích

    xlabel(ax4, 'Member ID [-]', 'Interpreter', 'latex');
    ylabel(ax4, 'Component reliability index $\beta$ [-]', 'Interpreter', 'latex');

    % Colorbar jako legenda pro využití
    colormap(ax4, cmap4);
    clim(ax4, [0, 1]);
    cb4 = colorbar(ax4, 'eastoutside');
    cb4.Label.String   = 'Utilization ratio \eta [-]';
    cb4.Label.FontName = 'Garamond';
    cb4.Label.FontSize = 10;
    cb4.FontName       = 'Garamond';
    cb4.FontSize       = 9;
    cb4.Ticks          = [0, 0.25, 0.5, 0.75, 1.0];

    grid(ax4, 'on'); box(ax4, 'on'); hold(ax4, 'off');

    exportgraphics(hF4, out4, 'ContentType', 'image', 'Resolution', 600);
    close(hF4);
    generated{end+1} = 'examples/figures/fig4_component_beta.tif';
    fprintf('  Exportováno: fig4_component_beta.tif\n');
end

% =====================================================================
%% Figure 5 — Utilization of truss members (deterministický posudek EN 1993-1-1)
% =====================================================================
fprintf('\n─── Figure 5: Využití průřezů prutů ───\n');

out5 = fullfile(outDir, 'fig5_utilization.tif');

% Sdílené proměnné z bloku "Geometrie + deterministický posudek" výše
nd5      = nd_det;
mb5      = mb_det;
ki5      = ki_det;
nmem5    = nmem_det;
util5    = detResults_det.util_max;

% Colormap: zelená → žlutá → oranžová → červená (0 → 1)
cmap5 = [
    0.20, 0.70, 0.20;   % zelená   (0.0)
    0.65, 0.85, 0.20;   % žlutozel (0.25)
    1.00, 0.85, 0.00;   % žlutá    (0.50)
    1.00, 0.45, 0.00;   % oranžová (0.75)
    0.85, 0.00, 0.00;   % červená  (1.0+)
];
cmap5_fine = interp1(linspace(0, 1, size(cmap5,1)), cmap5, linspace(0, 1, 256));

% Mapování util → barva (clamp na [0,1] pro colormap; >1 = červená)
util_clamp = min(util5, 1.0);

hF5 = figure('Renderer', 'painters', 'Color', 'w');
applyPaperStyle(hF5, 17, 7);

ax5 = axes(hF5);
hold(ax5, 'on');
axis(ax5, 'equal');
box(ax5, 'on');
grid(ax5, 'on');
ax5.GridAlpha = 0.15;
set(ax5, 'TickDir', 'out');

% Pruty — obarvené dle využití
for k = 1:nmem5
    x_seg = [nd5.x(mb5.nodesHead(k)); nd5.x(mb5.nodesEnd(k))];
    z_seg = [nd5.z(mb5.nodesHead(k)); nd5.z(mb5.nodesEnd(k))];
    ci = max(1, round(util_clamp(k) * 255) + 1);
    plot(ax5, x_seg, z_seg, '-', ...
        'Color',     cmap5_fine(ci, :), ...
        'LineWidth', 3, ...
        'LineJoin',  'round');
end

% Čísla prutů — uprostřed každého prutu
for k = 1:nmem5
    xm = (nd5.x(mb5.nodesHead(k)) + nd5.x(mb5.nodesEnd(k))) / 2;
    zm = (nd5.z(mb5.nodesHead(k)) + nd5.z(mb5.nodesEnd(k))) / 2;
    text(ax5, xm, zm, num2str(k), ...
        'FontSize', 7, 'FontName', 'Garamond', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'Color', 'k', 'FontWeight', 'bold', ...
        'BackgroundColor', [1 1 1], 'Margin', 1);
end

% Uzly
scatter(ax5, nd5.x, nd5.z, 20, ...
    'filled', 'MarkerFaceColor', [1 1 1], 'MarkerEdgeColor', [0 0 0], 'LineWidth', 1.0);

% Podpory
if isfield(ki5, 'z') && ~isempty(ki5.z.nodes)
    for k = 1:numel(ki5.z.nodes)
        xs = nd5.x(ki5.z.nodes(k));
        zs = nd5.z(ki5.z.nodes(k));
        plot(ax5, xs, zs - 0.6, 'k^', 'MarkerSize', 7, 'MarkerFaceColor', 'k');
    end
end

L5 = max(nd5.x) - min(nd5.x);
mg5 = 0.08 * L5;
xlim(ax5, [min(nd5.x) - mg5, max(nd5.x) + mg5]);
ylim(ax5, [min(nd5.z) - 1.2, max(nd5.z) + mg5]);

xlabel(ax5, '$x$ [m]', 'Interpreter', 'latex');
ylabel(ax5, '$z$ [m]', 'Interpreter', 'latex');

% Colorbar
colormap(ax5, cmap5_fine);
clim(ax5, [0, 1]);
cb5 = colorbar(ax5, 'eastoutside');
cb5.Label.String     = 'Utilization ratio [-]';
cb5.Label.FontName   = 'Garamond';
cb5.Label.FontSize   = 10;
cb5.FontName         = 'Garamond';
cb5.FontSize         = 9;
cb5.Ticks            = [0, 0.25, 0.5, 0.75, 1.0];
cb5.TickLabels       = {'0.00','0.25','0.50','0.75','1.00'};

set(ax5, 'FontName', 'Garamond', 'FontSize', 10);
hold(ax5, 'off');

exportgraphics(hF5, out5, 'ContentType', 'image', 'Resolution', 600);
close(hF5);
generated{end+1} = 'examples/figures/fig5_utilization.tif';
fprintf('  Exportováno: fig5_utilization.tif\n');

% =====================================================================
%% Souhrn
% =====================================================================
fprintf('\nGenerated figures:\n');
for k = 1:numel(generated)
    fprintf('  %s\n', generated{k});
end
for k = 1:numel(skipped)
    fprintf('  %s\n', skipped{k});
end

% =====================================================================
%% Lokální funkce (musí být na konci MATLAB skriptu, R2016b+)
% =====================================================================

function applyPaperStyle(fig, widthCm, heightCm)
% applyPaperStyle  Nastav velikost a font figury dle požadavků IPW 2026.
    set(fig, 'Units', 'centimeters');
    pos = get(fig, 'Position');
    set(fig, 'Position', [pos(1), pos(2), widthCm, heightCm]);
    set(findall(fig, '-property', 'FontName'), 'FontName', 'Garamond');
    set(findall(fig, '-property', 'FontSize'), 'FontSize', 10);
end
