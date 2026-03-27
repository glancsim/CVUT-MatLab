function h = plotTrussFn(nodes, members, loads, kinematic)
% plotTrussFn  2D visualization of a truss structure with supports and loads.
%
% INPUTS:
%   nodes    - struct with .x, .z (nnodes x 1)
%   members  - struct with .nodesHead, .nodesEnd, .nmembers
%   loads    - struct with .x/.z nodes/value
%   kinematic - (optional) struct with .x.nodes, .z.nodes
%
% OUTPUT:
%   h  - figure handle
%
% (c) S. Glanc, 2025

h = figure;
hold on;  axis equal;  grid on;
xlabel('x [m]');  ylabel('z [m]');
title('Truss — Geometry, Supports & Loads');

% Characteristic length for arrow scaling
xrange = max(nodes.x) - min(nodes.x);
zrange = max(nodes.z) - min(nodes.z);
L_char = max([xrange, zrange, 1]);
arrow_len = 0.12 * L_char;

%-- Members (black lines) -----------------------------------------------
for p = 1:members.nmembers
    h_node = members.nodesHead(p);
    e_node = members.nodesEnd(p);
    plot([nodes.x(h_node), nodes.x(e_node)], ...
         [nodes.z(h_node), nodes.z(e_node)], 'k-', 'LineWidth', 1.5);
end

%-- Nodes (filled circles) ----------------------------------------------
h_nodes = plot(nodes.x, nodes.z, 'ko', ...
               'MarkerFaceColor', 'k', 'MarkerSize', 6);

%-- Supports ------------------------------------------------------------
leg_h = h_nodes;
leg_l = {'Uzel'};

if nargin >= 4
    % Determine which nodes are pinned (both x and z fixed) vs rollers
    allFixed  = intersect(kinematic.x.nodes, kinematic.z.nodes);
    xOnlyFixed = setdiff(kinematic.x.nodes, kinematic.z.nodes);
    zOnlyFixed = setdiff(kinematic.z.nodes, kinematic.x.nodes);

    % Pinned supports — filled triangle pointing down
    if ~isempty(allFixed)
        for n = allFixed'
            plotSupport(nodes.x(n), nodes.z(n), L_char, 'pin');
        end
        h_pin = plot(nodes.x(allFixed(1)), nodes.z(allFixed(1)), 'b^', ...
                     'MarkerFaceColor', 'b', 'MarkerSize', 8);
        leg_h(end+1) = h_pin;  leg_l{end+1} = 'Vetknutí / kloub';
    end

    % Roller in x (only z fixed) — horizontal roller
    for n = zOnlyFixed'
        plotSupport(nodes.x(n), nodes.z(n), L_char, 'roller_z');
    end
    % Roller in z (only x fixed) — vertical roller
    for n = xOnlyFixed'
        plotSupport(nodes.x(n), nodes.z(n), L_char, 'roller_x');
    end
    if ~isempty([zOnlyFixed; xOnlyFixed])
        h_rol = plot(nodes.x(zOnlyFixed(1)), nodes.z(zOnlyFixed(1)), 'bs', ...
                     'MarkerFaceColor', 'b', 'MarkerSize', 8);
        leg_h(end+1) = h_rol;  leg_l{end+1} = 'Posuvná podpora';
    end
end

%-- Loads ---------------------------------------------------------------
allLoadNodes = [loads.x.nodes(:); loads.z.nodes(:)];
allLoadVals  = [loads.x.value(:); loads.z.value(:)];
allLoadDirs  = [ones(numel(loads.x.nodes), 1); 2*ones(numel(loads.z.nodes), 1)];

if ~isempty(allLoadVals)
    maxLoad = max(abs(allLoadVals));
    for i = 1:numel(allLoadVals)
        n   = allLoadNodes(i);
        val = allLoadVals(i);
        dir = allLoadDirs(i);
        scale = (val / maxLoad) * arrow_len;
        if dir == 1  % x direction
            quiver(nodes.x(n) - sign(val)*arrow_len, nodes.z(n), scale, 0, 0, ...
                   'r', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
            text(nodes.x(n) - sign(val)*arrow_len*1.1, nodes.z(n), ...
                 sprintf('%.0f N', val), 'Color', 'r', ...
                 'HorizontalAlignment', 'center', 'FontSize', 8);
        else  % z direction
            quiver(nodes.x(n), nodes.z(n) - sign(val)*arrow_len, 0, scale, 0, ...
                   'r', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
            text(nodes.x(n), nodes.z(n) - sign(val)*arrow_len*1.3, ...
                 sprintf('%.0f N', val), 'Color', 'r', ...
                 'HorizontalAlignment', 'center', 'FontSize', 8);
        end
    end
    h_load = quiver(0, 0, 0, 0, 'r', 'LineWidth', 1.5);  % dummy for legend
    leg_h(end+1) = h_load;  leg_l{end+1} = 'Zatížení';
end

legend(leg_h, leg_l, 'Location', 'best');
hold off;
end

%--------------------------------------------------------------------------
function plotSupport(x, z, L_char, type)
% Draw a support symbol at (x, z)
sz = 0.06 * L_char;
switch type
    case 'pin'
        % Downward triangle
        patch([x-sz, x+sz, x], [z-sz, z-sz, z], 'b', ...
              'FaceColor', [0.6 0.8 1], 'EdgeColor', 'b', 'LineWidth', 1.2);
    case 'roller_z'
        % Triangle + horizontal line underneath
        patch([x-sz, x+sz, x], [z-sz, z-sz, z], 'b', ...
              'FaceColor', [0.6 0.8 1], 'EdgeColor', 'b', 'LineWidth', 1.2);
        line([x-sz*1.2, x+sz*1.2], [z-sz, z-sz], 'Color', 'b', 'LineWidth', 2);
    case 'roller_x'
        % Triangle rotated 90° + vertical line
        patch([x-sz, x-sz, x], [z-sz, z+sz, z], 'b', ...
              'FaceColor', [0.6 0.8 1], 'EdgeColor', 'b', 'LineWidth', 1.2);
        line([x-sz, x-sz], [z-sz*1.2, z+sz*1.2], 'Color', 'b', 'LineWidth', 2);
end
end
