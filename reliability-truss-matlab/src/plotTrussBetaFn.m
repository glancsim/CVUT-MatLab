function h = plotTrussBetaFn(nodes, members, results, kinematic)
% plotTrussBetaFn
% Truss visualization with members color-coded by system criticality index.
%
% Metric: results.member.critical_pct — fraction of system failures in
% which each member was the weakest link (minimum g value).
%
% Color bands (relative to the most critical member = 100%):
%   Green        :   0 %          — never critical (downsize candidate)
%   Light green  :   0–10 %
%   Yellow-green :  10–20 %
%   Yellow       :  20–30 %
%   Yellow-orange:  30–40 %
%   Orange       :  40–50 %
%   Dark orange  :  50–60 %
%   Orange-red   :  60–70 %
%   Light red    :  70–80 %
%   Red          :  80–90 %
%   Dark red     :  90–100 %     — most critical (upsize candidate)
%
% INPUTS:
%   nodes     - struct with .x, .z
%   members   - struct with .nodesHead, .nodesEnd
%   results   - output of systemReliabilityFn (needs .member.critical_pct)
%   kinematic - optional struct with supports (.x.nodes, .z.nodes)
%
% OUTPUT:
%   h - figure handle

% -------------------------
% INPUT VALIDATION
% -------------------------
if ~isfield(results, 'member') || ~isfield(results.member, 'critical_pct')
    error('plotTrussBetaFn: results.member.critical_pct is required.');
end

% -------------------------
% BAND ASSIGNMENT (20 % steps, relative to most critical member)
% -------------------------
all_band_labels = {
    'Not critical (0 %)';
    '0–20 %';
    '20–40 %';
    '40–60 %';
    '60–80 %';
    '80–100 % (most critical)';
};

crit     = results.member.critical_pct;   % (nmembers×1) [%]
crit_max = max(crit);
nm       = numel(members.nodesHead);

band_idx = zeros(nm, 1);   % 0 = never critical
for i = 1:nm
    if crit(i) > 0 && crit_max > 0
        pct_of_max = crit(i) / crit_max * 100;
        band_idx(i) = min(ceil(pct_of_max / 20), 5);
    end
end

% -------------------------
% ADAPTIVE COLORS
% -------------------------
% Band 0 (0 %)         → fixed green
% Highest present band → fixed red
% Intermediate bands   → interpolated through light-green/yellow/orange
color_zero = [0.00, 0.60, 0.00];
color_max  = [1.00, 0.00, 0.00];

% Palette for interpolation across non-zero bands
palette = [
    0.60, 0.85, 0.40;   % light green
    1.00, 0.85, 0.00;   % yellow
    1.00, 0.50, 0.00;   % orange
    0.90, 0.20, 0.00;   % dark orange
    1.00, 0.00, 0.00;   % red
];

used_nonzero = sort(unique(band_idx(band_idx > 0)));
n_nz = numel(used_nonzero);

band_colors = zeros(6, 3);
band_colors(1, :) = color_zero;   % band 0 always green

if n_nz == 1
    band_colors(used_nonzero + 1, :) = color_max;
elseif n_nz == 2
    band_colors(used_nonzero(1) + 1, :) = [1.00, 0.85, 0.00];   % yellow
    band_colors(used_nonzero(2) + 1, :) = color_max;             % red
else
    t = linspace(0, 1, n_nz);
    interp_colors = interp1(linspace(0, 1, 5), palette, t);
    for k = 1:n_nz
        band_colors(used_nonzero(k) + 1, :) = interp_colors(k, :);
    end
end

% -------------------------
% FIGURE STYLE (paper look)
% -------------------------
h = figure;

set(gcf, 'Units', 'centimeters');
set(gcf, 'Position', [2 2 22 8]);
set(gcf, 'Color', 'w');

hold on;
axis equal;
grid on;
box on;

ax = gca;
set(ax, 'FontName', 'Garamond');
set(ax, 'FontSize', 10);
set(ax, 'TickDir', 'out');
set(ax, 'LineWidth', 1);
ax.GridAlpha = 0.15;

xlabel('x [m]', 'FontName', 'Garamond', 'FontSize', 10);
ylabel('z [m]', 'FontName', 'Garamond', 'FontSize', 10);

% -------------------------
% GEOMETRY SCALE
% -------------------------
L_char = max([range(nodes.x), range(nodes.z), 1]);
margin = 0.15 * L_char;

% -------------------------
% MEMBERS
% -------------------------
for i = 1:nm
    x_seg = [nodes.x(members.nodesHead(i)); nodes.x(members.nodesEnd(i))];
    z_seg = [nodes.z(members.nodesHead(i)); nodes.z(members.nodesEnd(i))];
    plot(x_seg, z_seg, '-', ...
        'Color', band_colors(band_idx(i)+1, :), ...
        'LineWidth', 3, ...
        'LineJoin', 'round');
end

% -------------------------
% NODES
% -------------------------
scatter(nodes.x, nodes.z, 25, ...
    'filled', ...
    'MarkerFaceColor', [1 1 1], ...
    'MarkerEdgeColor', [0 0 0], ...
    'LineWidth', 1.2);

% -------------------------
% SUPPORTS
% -------------------------
if nargin >= 3 && ~isempty(kinematic)

    if isfield(kinematic,'z')
        nds = kinematic.z.nodes;

        for i = 1:numel(nds)
            x = nodes.x(nds(i));
            z = nodes.z(nds(i)) - 0.75;

            plot(x, z, '^', ...
                'MarkerSize', 8, ...
                'MarkerFaceColor', 'k', ...
                'MarkerEdgeColor', 'k');

        end

    if isfield(kinematic,'x')
        nds = kinematic.x.nodes;

        for i = 1:numel(nds)
            plot([x-0.5 x+0.5], ...
                 [z-0.5 z-0.5], ...
                 'k', 'LineWidth', 2);
        end
    end
    end
end

% -------------------------
% LEGEND (only bands present in data)
% -------------------------
used = unique(band_idx);
leg_h = gobjects(numel(used), 1);
leg_l = cell(numel(used), 1);
for k = 1:numel(used)
    b = used(k);
    leg_h(k) = plot(NaN, NaN, '-', ...
        'Color', band_colors(b+1, :), 'LineWidth', 3);
    leg_l{k} = all_band_labels{b+1};
end
legend(leg_h, leg_l, ...
    'Location', 'eastoutside', ...
    'FontName', 'Garamond', ...
    'FontSize', 8, ...
    'Box', 'off');

% -------------------------
% LIMITS
% -------------------------
xlim([min(nodes.x)-margin, max(nodes.x)+margin]);
ylim([min(nodes.z)-margin, max(nodes.z)+margin]);

% -------------------------
% EXPORT
% -------------------------
exportgraphics(gcf, 'plotTrussBeta.tif', 'Resolution', 600);

hold off;

end
