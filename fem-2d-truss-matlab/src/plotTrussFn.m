function h = plotTrussFn(nodes, members, loads, kinematic, varargin)
% plotTrussFn  2D visualization of a truss structure with supports and loads.
%
%   plotTrussFn(nodes, members, loads)
%   plotTrussFn(nodes, members, loads, kinematic)
%   plotTrussFn(nodes, members, loads, kinematic, 'Labels', true)
%
% INPUTS:
%   nodes     - struct with .x, .z (nnodes x 1)
%   members   - struct with .nodesHead, .nodesEnd, .nmembers
%   loads     - struct with .x/.z .nodes/.value
%   kinematic - (optional) struct with .x.nodes, .z.nodes
%   'Labels'  - (optional) true/false — show node and member numbers (default: false)
%
% OUTPUT:
%   h  - figure handle
%
% Colour code (consistent with plotStructureFn):
%   Black          — members and nodes
%   Blue  arrow    — support (translation fixed), arrow points TO node
%   Red   arrow    — force load, arrow points FROM node + label [N]
%
% (c) S. Glanc, 2025

% --- Parse optional 'Labels' parameter ---
showLabels = false;
for k = 1:2:numel(varargin)
    if strcmpi(varargin{k}, 'Labels')
        showLabels = logical(varargin{k+1});
    end
end

h = figure;
hold on;  axis equal;  grid on;
xlabel('x [m]');  ylabel('z [m]');
title('Truss — Geometry, Supports & Loads');

% Characteristic length for arrow scaling
L_char    = max([range(nodes.x), range(nodes.z), 1]);
arrow_len = 0.15 * L_char;
margin    = 0.15 * L_char;

uvecs = {[1 0], [0 1]};   % x, z unit vectors

% =========================================================
%  MEMBERS AND NODES
% =========================================================
nm = numel(members.nodesHead);
h_members = plot([nodes.x(members.nodesHead)'; nodes.x(members.nodesEnd)'], ...
                 [nodes.z(members.nodesHead)'; nodes.z(members.nodesEnd)'], ...
                 'k-', 'LineWidth', 1.5);

h_nodes = plot(nodes.x, nodes.z, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6);

% =========================================================
%  NODE AND MEMBER LABELS (only if 'Labels', true)
% =========================================================
if showLabels
    lbl_x = 0.015 * max(range(nodes.x), 1);
    lbl_z = 0.06  * max(range(nodes.z), 0.5);
    for n = 1:numel(nodes.x)
        text(nodes.x(n) + lbl_x, nodes.z(n) + lbl_z, ...
             sprintf('%d', n), ...
             'Color', [0.1 0.3 0.9], 'FontSize', 8, 'FontWeight', 'bold');
    end
    for p = 1:nm
        mx = (nodes.x(members.nodesHead(p)) + nodes.x(members.nodesEnd(p))) / 2;
        mz = (nodes.z(members.nodesHead(p)) + nodes.z(members.nodesEnd(p))) / 2;
        text(mx, mz, sprintf('%d', p), ...
             'Color', [0.85 0.1 0.1], 'FontSize', 8, 'FontWeight', 'bold', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
             'BackgroundColor', 'w', 'EdgeColor', [0.85 0.1 0.1], 'Margin', 1);
    end
end

% =========================================================
%  SUPPORTS — blue quiver arrows pointing TO the node
% =========================================================
h_sup = [];

if nargin >= 4 && ~isempty(kinematic)
    dirs = {'x', 'z'};
    for d = 1:2
        nds = kinematic.(dirs{d}).nodes;
        if isempty(nds), continue; end
        u  = uvecs{d};
        xn = nodes.x(nds);
        zn = nodes.z(nds);
        hh = quiver(xn - u(1)*arrow_len, zn - u(2)*arrow_len, ...
                    repmat(u(1)*arrow_len, size(nds)), ...
                    repmat(u(2)*arrow_len, size(nds)), ...
                    0, 'b', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
        if isempty(h_sup), h_sup = hh; end
    end
end

% =========================================================
%  LOADS — red quiver arrows pointing FROM the node + labels
% =========================================================
allF = [loads.x.value(:); loads.z.value(:)];
h_forces = [];

if ~isempty(allF) && max(abs(allF)) > 0
    scale_f = arrow_len / max(abs(allF));
    dirs_f  = {'x', 'z'};
    for d = 1:2
        nds = loads.(dirs_f{d}).nodes;
        if isempty(nds), continue; end
        val = loads.(dirs_f{d}).value(:);
        u   = uvecs{d};
        xn  = nodes.x(nds);
        zn  = nodes.z(nds);
        hh  = quiver(xn, zn, val*scale_f*u(1), val*scale_f*u(2), ...
                     0, 'r', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
        if isempty(h_forces), h_forces = hh; end
        for k = 1:numel(nds)
            text(xn(k) + val(k)*scale_f*u(1), ...
                 zn(k) + val(k)*scale_f*u(2), ...
                 sprintf('%.4g N', val(k)), 'Color', 'r', 'FontSize', 8);
        end
    end
end

% =========================================================
%  FORMATTING
% =========================================================
xlim([min(nodes.x) - margin, max(nodes.x) + margin]);
ylim([min(nodes.z) - margin, max(nodes.z) + margin]);

leg_h = [h_members(1), h_nodes];
leg_l = {'Prut', 'Uzel'};
if ~isempty(h_sup),    leg_h(end+1) = h_sup;    leg_l{end+1} = 'Podpora';  end
if ~isempty(h_forces), leg_h(end+1) = h_forces; leg_l{end+1} = 'Síla';     end
legend(leg_h, leg_l, 'Location', 'best');

hold off;
end
