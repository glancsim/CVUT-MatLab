% figures_pm47.m
%
% Publikacni figura — iteracni historie G_PM4.7.
% Vystup: examples/IPW2026/figures/fig_pm47_iterations.tif
%
% IPW 2026: 17x8 cm, 600 dpi, Times New Roman 10 pt
%
% (c) S. Glanc, 2026

thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end

outDir  = fullfile(thisDir, 'figures');
if ~exist(outDir, 'dir'), mkdir(outDir); end
outPath = fullfile(outDir, 'fig_pm47_iterations.tif');

%% ── Data ──────────────────────────────────────────────────────────────
matFile = fullfile(thisDir, 'reliability_results_PM47.mat');

beta_fallback = [4.238, 4.238, 4.471, 4.592, 4.240, 4.775];

if exist(matFile, 'file')
    d = load(matFile, 'history');
    if isfield(d, 'history') && ~isempty(d.history)
        beta_vals = [4.238, [d.history.beta]];
    else
        beta_vals = beta_fallback;
    end
else
    beta_vals = beta_fallback;
end

x         = 0:(numel(beta_vals)-1);
beta_prac = beta_vals(1);
beta_tgt  = 4.7;

upgrade_labels = {
    'Group 5 (vert.): TR\,38\times3.2 \rightarrow TR\,38\times3.6'
    'Group 5 (vert.): TR\,38\times3.6 \rightarrow TR\,42.4\times3.2'
    'Group 3 (diag.): TR\,82.5\times3.6 \rightarrow TR\,76.1\times4.0'
    'Group 3 (diag.): TR\,76.1\times4.0 \rightarrow TR\,88.9\times4.0'
};

%% ── Figure ────────────────────────────────────────────────────────────
fig = figure('Visible', 'off', 'Units', 'centimeters', 'Position', [0 0 17 8]);

ax = axes(fig, 'Units', 'normalized', 'Position', [0.13 0.18 0.82 0.74]);

% Krivka beta
plot(ax, x, beta_vals, '-o', ...
    'Color',           [0 0 0], ...
    'LineWidth',       1.5, ...
    'MarkerSize',      6, ...
    'MarkerFaceColor', [0 0 0], ...
    'MarkerEdgeColor', [1 1 1]);
hold(ax, 'on');

% Posledni bod (G_PM4.7)
plot(ax, x(end), beta_vals(end), 'o', ...
    'MarkerSize',      8, ...
    'MarkerFaceColor', [0 0 0], ...
    'MarkerEdgeColor', [0 0 0]);

% Referencni cary
yline(ax, beta_tgt,  '--k', 'LineWidth', 1.0);
yline(ax, beta_prac, ':k',  'LineWidth', 0.8);

% Popisky referencnich car
text(ax, x(2), beta_tgt + 0.03, '$\beta_t = 4.7$', ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'right', ...
    'FontName', 'Times New Roman', 'FontSize', 9);

% text(ax, 0.05, beta_prac - 0.035, '$G_\mathrm{practice}$', ...
%     'Interpreter', 'latex', ...
%     'VerticalAlignment', 'top', ...
%     'FontName', 'Times New Roman', 'FontSize', 9);

% Popisky bodu x=0 a x=5
text(ax, 0, beta_vals(1) + 0.04, '$G_\mathrm{practice}$', ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom', ...
    'FontName', 'Times New Roman', 'FontSize', 9);

text(ax, x(end), beta_vals(end) + 0.04, '$G_\mathrm{PM4.7}$', ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom', ...
    'FontName', 'Times New Roman', 'FontSize', 9);

% Osy
ax.XTick      = x;
ax.XTickLabel = {'0','1','2','3','4','5'};
ax.FontName   = 'Times New Roman';
ax.FontSize   = 10;

xlabel(ax, 'Iteration $[-]$',            'Interpreter', 'latex', 'FontSize', 10);
ylabel(ax, 'Reliability index $\beta\;[-]$', 'Interpreter', 'latex', 'FontSize', 10);

ylim(ax, [4.10, 4.92]);
xlim(ax, [-0.4, x(end)+0.4]);
grid(ax, 'on');
ax.GridAlpha = 0.25;
box(ax, 'on');


%% ── Export ────────────────────────────────────────────────────────────
set(fig, 'Renderer', 'painters');
exportgraphics(fig, outPath, 'ContentType', 'image', 'Resolution', 600);
fprintf('Saved: %s\n', outPath);
close(fig);
