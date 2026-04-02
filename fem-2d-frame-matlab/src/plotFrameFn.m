function plotFrameFn(nodes, beams, loads, kinematic, varargin)
% plotFrameFn  2D visualization of a frame structure, supports, and loads.
%
%   plotFrameFn(nodes, beams, loads)
%   plotFrameFn(nodes, beams, loads, kinematic)
%   plotFrameFn(nodes, beams, loads, kinematic, 'Labels', true)
%
% INPUTS:
%   nodes     - struct: x, z  (nnodes x 1 each)
%   beams     - struct: nodesHead, nodesEnd ([nbeams x 1])
%               Optional: beams.releases (nbeams x 2) for hinge symbols
%   loads     - struct: x/z.nodes, x/z.value (forces [N])
%                       ry.nodes, ry.value (moments [N·m])
%   kinematic - (optional) struct: x/z/ry.nodes
%   'Labels'  - (optional) true/false — show node/beam labels (default: false)
%
% Colour code:
%   Black          — beams and nodes
%   Open circle ○  — hinge (moment release)
%   Blue  arrow    — fixed translation support (towards node)
%   Green arrow    — fixed rotation support (towards node, dashed)
%   Red   arrow    — applied force  (away from node) + label [N]
%   Purple arrows  — applied moment (double arrow) + label [N·m]
%
% (c) S. Glanc, 2026

% --- parse optional 'Labels' parameter ---
showLabels = false;
if nargin >= 5
    for k = 1:2:numel(varargin)
        if strcmpi(varargin{k}, 'Labels')
            showLabels = logical(varargin{k+1});
        end
    end
end

figure; hold on; axis equal;

% --- characteristic length for arrow scaling ---
L_char    = max([range(nodes.x); range(nodes.z); 1]);
arrow_len = 0.15 * L_char;
margin    = 0.15 * L_char;

% =========================================================
%  BEAMS AND NODES
% =========================================================
for b = 1:numel(beams.nodesHead)
    xb = [nodes.x(beams.nodesHead(b)), nodes.x(beams.nodesEnd(b))];
    zb = [nodes.z(beams.nodesHead(b)), nodes.z(beams.nodesEnd(b))];
    plot(xb, zb, 'k', 'LineWidth', 1.5);
end
scatter(nodes.x, nodes.z, 40, 'k', 'filled');

% =========================================================
%  LABELS
% =========================================================
if showLabels
    lbl_off = 0.06 * L_char;
    for n = 1:numel(nodes.x)
        text(nodes.x(n) + lbl_off, nodes.z(n) + lbl_off, ...
             sprintf('%d', n), ...
             'Color', [0.1 0.3 0.9], 'FontSize', 8, 'FontWeight', 'bold');
    end
    for b = 1:numel(beams.nodesHead)
        mx = (nodes.x(beams.nodesHead(b)) + nodes.x(beams.nodesEnd(b))) / 2;
        mz = (nodes.z(beams.nodesHead(b)) + nodes.z(beams.nodesEnd(b))) / 2;
        text(mx, mz, sprintf('%d', b), ...
             'Color', [0.85 0.1 0.1], 'FontSize', 8, 'FontWeight', 'bold', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
             'BackgroundColor', 'w', 'EdgeColor', [0.85 0.1 0.1], 'Margin', 1);
    end
end

% =========================================================
%  HINGES — open circles ○ at released ends
% =========================================================
if isfield(beams, 'releases') && any(beams.releases(:))
    for p = 1:size(beams.nodesHead, 1)
        if beams.releases(p, 1)
            scatter(nodes.x(beams.nodesHead(p)), nodes.z(beams.nodesHead(p)), ...
                    100, 'w', 'filled');
            scatter(nodes.x(beams.nodesHead(p)), nodes.z(beams.nodesHead(p)), ...
                    100, 'k', 'o', 'LineWidth', 2);
        end
        if beams.releases(p, 2)
            scatter(nodes.x(beams.nodesEnd(p)), nodes.z(beams.nodesEnd(p)), ...
                    100, 'w', 'filled');
            scatter(nodes.x(beams.nodesEnd(p)), nodes.z(beams.nodesEnd(p)), ...
                    100, 'k', 'o', 'LineWidth', 2);
        end
    end
end

% =========================================================
%  SUPPORTS
% =========================================================
if nargin >= 4 && isstruct(kinematic)
    dirs2d = {kinematic.x,  [1 0];
              kinematic.z,  [0 1]};
    for d = 1:2
        bc  = dirs2d{d, 1};
        vec = dirs2d{d, 2};
        for i = 1:numel(bc.nodes)
            ni = bc.nodes(i);
            p  = [nodes.x(ni), nodes.z(ni)];
            annotation_arrow2d(p, -vec * arrow_len, 'b', false);
        end
    end
    % rotation support
    if isfield(kinematic, 'ry')
        for i = 1:numel(kinematic.ry.nodes)
            ni = kinematic.ry.nodes(i);
            p  = [nodes.x(ni), nodes.z(ni)];
            annotation_arrow2d(p, [0, -arrow_len], 'g', true);
            annotation_arrow2d(p, [0, -arrow_len]*0.8, 'g', true);
        end
    end
end

% =========================================================
%  FORCES
% =========================================================
forceFields = {'x', [1 0]; 'z', [0 1]};
for d = 1:2
    fname = forceFields{d, 1};
    fvec  = forceFields{d, 2};
    if isfield(loads, fname) && ~isempty(loads.(fname).nodes)
        for i = 1:numel(loads.(fname).nodes)
            ni  = loads.(fname).nodes(i);
            val = loads.(fname).value(i);
            p   = [nodes.x(ni), nodes.z(ni)];
            dir = sign(val) * fvec;
            quiver(p(1), p(2), dir(1)*arrow_len, dir(2)*arrow_len, 0, ...
                   'r', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
            text(p(1) + dir(1)*arrow_len*1.1, p(2) + dir(2)*arrow_len*1.1, ...
                 sprintf('%.4g N', val), 'Color', 'r', 'FontSize', 7, ...
                 'HorizontalAlignment', 'center');
        end
    end
end

% =========================================================
%  MOMENTS
% =========================================================
if isfield(loads, 'ry') && ~isempty(loads.ry.nodes)
    col = [0.5 0 0.8];
    for i = 1:numel(loads.ry.nodes)
        ni  = loads.ry.nodes(i);
        val = loads.ry.value(i);
        p   = [nodes.x(ni), nodes.z(ni)];
        off = arrow_len * 0.15;
        for k = [-1, 1]
            quiver(p(1), p(2) + k*off, 0, sign(val)*arrow_len, 0, ...
                   'Color', col, 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
        end
        text(p(1) + arrow_len*0.6, p(2), sprintf('%.4g N·m', val), ...
             'Color', col, 'FontSize', 7);
    end
end

% --- axis formatting ---
xlabel('x [m]'); ylabel('z [m]');
grid on; box on;
ax = gca;
ax.XLim = [min(nodes.x) - margin, max(nodes.x) + margin];
ax.YLim = [min(nodes.z) - margin, max(nodes.z) + margin];
title('2D Frame structure');
end

% -------------------------------------------------------------------------
function annotation_arrow2d(p, vec, color, dashed)
% Draw a 2D arrow from p+vec to p (pointing towards p).
style = '-';
if dashed, style = '--'; end
x0 = p(1) + vec(1);
z0 = p(2) + vec(2);
quiver(x0, z0, -vec(1), -vec(2), 0, 'Color', color, ...
       'LineStyle', style, 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
end
