function h = plotTrussTopologyFn(nodes, members, kinematic, varargin)
% plotTrussTopology
% Clean visualization of truss topology (NO LOADS)
%
% INPUTS:
%   nodes     - struct with .x, .z
%   members   - struct with .nodesHead, .nodesEnd
%   kinematic - optional struct with supports (.x.nodes, .z.nodes)
%   'Labels'  - optional true/false
%
% OUTPUT:
%   h - figure handle

% -------------------------
% OPTIONS
% -------------------------
showLabels = false;
axis equal
for k = 1:2:numel(varargin)
    if strcmpi(varargin{k}, 'Labels')
        showLabels = logical(varargin{k+1});
    end
end

% -------------------------
% FIGURE STYLE (paper look)
% -------------------------
h = figure;
xlabel('X axis', 'FontName', 'Garamond')
ylabel('Y axis', 'FontName', 'Garamond')

set(gca, 'FontName', 'Garamond')

xlabel('X', 'FontSize', 10)
ylabel('Y', 'FontSize', 10)

set(gca, 'FontSize', 10)

set(gcf, 'Units', 'centimeters');
set(gcf, 'Position', [2 2 17 8]); % [x y width height]

set(gcf, 'Color', 'w');

hold on;
axis equal;
grid on;

box on;
set(gca, 'FontSize', 10);
set(gca, 'TickDir', 'out');
set(gca, 'LineWidth', 1);

ax = gca;
ax.GridAlpha = 0.15;

xlabel('x [m]');
ylabel('z [m]');
% title('Truss topology');

% -------------------------
% GEOMETRY SCALE
% -------------------------
L_char = max([range(nodes.x), range(nodes.z), 1]);
margin = 0.15 * L_char;

% -------------------------
% COLOR PALETTE (engineering style)
% -------------------------
memberColor = [0.20 0.20 0.20];
nodeFace    = [1 1 1];
nodeEdge    = [0 0 0];
supportColor = [0.15 0.35 0.85];

% -------------------------
% MEMBERS
% -------------------------
nm = numel(members.nodesHead);

h_members = plot( ...
    [nodes.x(members.nodesHead)'; nodes.x(members.nodesEnd)'], ...
    [nodes.z(members.nodesHead)'; nodes.z(members.nodesEnd)'], ...
    '-', ...
    'Color', memberColor, ...
    'LineWidth', 3, ...
    'LineJoin', 'round');

% -------------------------
% NODES
% -------------------------
h_nodes = scatter(nodes.x, nodes.z, 25, ...
    'filled', ...
    'MarkerFaceColor', nodeFace, ...
    'MarkerEdgeColor', nodeEdge, ...
    'LineWidth', 1.2);

% -------------------------
% SUPPORTS (clean symbols)
% -------------------------
h_sup = [];
if nargin >= 4 && ~isempty(kinematic)

    if isfield(kinematic,'z')
        nds = kinematic.z.nodes;

        for i = 1:numel(nds)
            x = nodes.x(nds(i));
            z = nodes.z(nds(i)) - 0.75;

            plot(x, z, '^', ...
                'MarkerSize', 8, ...
                'MarkerFaceColor', 'b', ...
                'MarkerEdgeColor', 'b');

        end

    if isfield(kinematic,'x')
        nds = kinematic.x.nodes;

        for i = 1:numel(nds)
            % x = nodes.x(nds(i));
            % z = nodes.z(nds(i)) - 0.5;
            % 
            % plot(x, z, '^', ...
            %     'MarkerSize', 8, ...
            %     'MarkerFaceColor','b', ...
            %     'MarkerEdgeColor', 'b');

            plot([x-0.5 x+0.5], ...
                 [z-0.5 z-0.5], ...
                 'b', 'LineWidth', 2);
        end
    end
    end
end


% -------------------------
% LABELS (optional)
% -------------------------
if showLabels

    dx = 0.01 * L_char;
    dz = 0.02 * L_char;
    % 
    % % node labels
    % for i = 1:numel(nodes.x)
    %     text(nodes.x(i)+dx, nodes.z(i)+dz, sprintf('%d', i), ...
    %         'FontSize', 8, ...
    %         'Color', [0.1 0.2 0.8], ...
    %         'FontWeight', 'bold');
    % end

    % member labels
    for i = 1:nm
        x1 = nodes.x(members.nodesHead(i));
        x2 = nodes.x(members.nodesEnd(i));
        z1 = nodes.z(members.nodesHead(i));
        z2 = nodes.z(members.nodesEnd(i));

        text((x1+x2)/2, (z1+z2)/2, sprintf('%d', i), ...
            'FontSize', 8, ...
            'Color', [0.6 0 0], ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'BackgroundColor', 'w', ...
            'Margin', 0.1);
    end
end

% -------------------------
% LIMITS
% -------------------------
xlim([min(nodes.x)-margin, max(nodes.x)+margin]);
ylim([min(nodes.z)-margin, max(nodes.z)+margin]);

% -------------------------
% LEGEND
% -------------------------
leg_h = [h_members(1), h_nodes];
leg_l = {'Members', 'Nodes'};

if ~isempty(h_sup)
    leg_h(end+1) = h_sup;
    leg_l{end+1} = 'Supports';
end

% legend(leg_h, leg_l, 'Location', 'best');
exportgraphics(gcf, 'truss_topology.tif', 'Resolution', 600)

hold off;

end