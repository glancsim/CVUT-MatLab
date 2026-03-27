function plotModeShapeFn(nodes, beams, kinematic, Results, modeNum)
% plotModeShapeFn  Animate a buckling mode shape from stabilitySolverFn.
%
% Displays the selected mode shape as an animated oscillation overlaid on
% the original (undeformed) structure. The deformed shape is colour-coded
% by transverse displacement magnitude (green → yellow → red).
% The animation stops automatically after 10 seconds.
%
% USAGE:
%   plotModeShapeFn(nodes, beams, kinematic, Results)
%   plotModeShapeFn(nodes, beams, kinematic, Results, modeNum)
%
% INPUTS:
%   nodes     - Node geometry struct (.x, .y, .z)
%   beams     - Beam topology struct (.nodesHead, .nodesEnd, .angles, ...)
%   kinematic - Boundary conditions struct (.x.nodes, .y.nodes, ...)
%   Results   - Output of stabilitySolverFn (.values, .vectors)
%   modeNum   - (optional) Index into Results.values/vectors (1-based).
%               Default: mode with smallest absolute eigenvalue.
%
% NOTES:
%   - Animation runs for up to 10 s then stops automatically.
%   - Press Ctrl+C to stop early.
%   - Displacement is scaled so the maximum transverse deformation is
%     15 % of the characteristic length of the structure.
%
% See also: stabilitySolverFn, plotStructureFn
%
% (c) S. Glanc, 2026

%--------------------------------------------------------------------------
% 1. Mode selection
%--------------------------------------------------------------------------
if nargin < 5 || isempty(modeNum)
    [~, modeNum] = min(abs(Results.values));
end

lambda = Results.values(modeNum);
phi    = Results.vectors(:, modeNum);

%--------------------------------------------------------------------------
% 2. Reconstruct nodes.dofs from kinematic
%--------------------------------------------------------------------------
nnodes     = numel(nodes.x);
nodes.dofs = true(nnodes, 6);
if ~isempty(kinematic.x.nodes),  nodes.dofs(kinematic.x.nodes,  1) = false; end
if ~isempty(kinematic.y.nodes),  nodes.dofs(kinematic.y.nodes,  2) = false; end
if ~isempty(kinematic.z.nodes),  nodes.dofs(kinematic.z.nodes,  3) = false; end
if ~isempty(kinematic.rx.nodes), nodes.dofs(kinematic.rx.nodes, 4) = false; end
if ~isempty(kinematic.ry.nodes), nodes.dofs(kinematic.ry.nodes, 5) = false; end
if ~isempty(kinematic.rz.nodes), nodes.dofs(kinematic.rz.nodes, 6) = false; end
nodes.ndofs  = sum(nodes.dofs(:));
nodes.nnodes = nnodes;

%--------------------------------------------------------------------------
% 3. Beam properties
%--------------------------------------------------------------------------
beams.nbeams      = numel(beams.nodesHead);
beams.vertex      = beamVertexFn(beams, nodes);
beams.codeNumbers = codeNumbersFn(beams, nodes);
beams.XY          = XYtoRotBeamsFn(beams, beams.angles);

%--------------------------------------------------------------------------
% 4. Auto-scale factor (15 % of characteristic length)
%--------------------------------------------------------------------------
L_char = max([range(nodes.x), range(nodes.y), range(nodes.z), 1]);

trans_codes = beams.codeNumbers(:, [1,2,3,7,8,9]);
trans_codes = trans_codes(trans_codes > 0);
if isempty(trans_codes)
    maxDisp = 1;
else
    maxDisp = max(abs(phi(trans_codes)));
end
if maxDisp < eps, maxDisp = 1; end
scaleFactor = 0.15 * L_char / maxDisp;

%--------------------------------------------------------------------------
% 5. Pre-compute Hermite-interpolated mode shape for each beam
%--------------------------------------------------------------------------
N_PTS = 30;
xi = linspace(0, 1, N_PTS);
H1 = 1 - 3*xi.^2 + 2*xi.^3;
H3 = 3*xi.^2 - 2*xi.^3;

x0_all = zeros(beams.nbeams, N_PTS);
y0_all = zeros(beams.nbeams, N_PTS);
z0_all = zeros(beams.nbeams, N_PTS);
du_all = zeros(3, N_PTS, beams.nbeams);
c_all  = zeros(beams.nbeams, N_PTS);

for b = 1:beams.nbeams
    % DOF extraction (0-code → constrained → zero displacement)
    codes    = beams.codeNumbers(b, :);
    u_global = zeros(12, 1);
    for k = 1:12
        if codes(k) > 0, u_global(k) = phi(codes(k)); end
    end

    % Local rotation matrix (same logic as transformationMatrixFn)
    vx = beams.vertex(b, :);
    Lb = norm(vx);
    Cx = vx / Lb;
    Cz_r = cross(Cx, beams.XY(b, :));
    Cz   = Cz_r / norm(Cz_r);
    Cy_r = cross(Cz, Cx);
    Cy   = Cy_r / norm(Cy_r);
    t    = [Cx; Cy; Cz];          % 3×3
    T    = blkdiag(t, t, t, t);   % 12×12

    % Local displacements
    u_loc = T * u_global;
    ux1=u_loc(1); uy1=u_loc(2); uz1=u_loc(3);
    thy1=u_loc(5); thz1=u_loc(6);
    ux2=u_loc(7); uy2=u_loc(8); uz2=u_loc(9);
    thy2=u_loc(11); thz2=u_loc(12);

    % Hermite shape functions
    H2 = Lb*(xi - 2*xi.^2 + xi.^3);
    H4 = Lb*(-xi.^2 + xi.^3);

    ux_loc = (1-xi)*ux1 + xi*ux2;
    uy_loc = H1*uy1 + H2*thz1 + H3*uy2 + H4*thz2;
    uz_loc = H1*uz1 - H2*thy1 + H3*uz2 - H4*thy2;

    % Back to global coordinates (translation only)
    u_interp = t' * [ux_loc; uy_loc; uz_loc];   % 3×N_PTS

    % Base positions along undeformed beam
    hn = beams.nodesHead(b);
    x0_all(b,:) = nodes.x(hn) + xi * vx(1);
    y0_all(b,:) = nodes.y(hn) + xi * vx(2);
    z0_all(b,:) = nodes.z(hn) + xi * vx(3);

    du_all(:,:,b) = u_interp;
    c_all(b,:)    = sqrt(uy_loc.^2 + uz_loc.^2);
end

% Normalise colour values to [0, 1]
c_min      = min(c_all(:));
c_max      = max(c_all(:)) + eps;
c_norm_all = (c_all - c_min) / (c_max - c_min);

%--------------------------------------------------------------------------
% 6. Set up figure
%--------------------------------------------------------------------------
fig = figure('Name', sprintf('Mode %d  —  λ = %.4g', modeNum, lambda), ...
             'Color', 'w');
ax  = axes('Parent', fig);
hold(ax, 'on');
axis(ax, 'equal');
grid(ax, 'on');
view(ax, 3);
xlabel(ax, 'x [m]');  ylabel(ax, 'y [m]');  zlabel(ax, 'z [m]');
title(ax, sprintf('Mode %d  —  \\lambda_{cr} = %.4g', modeNum, lambda));

% Green → yellow → red colormap
n_col = 64;
cmap  = [linspace(0,1,n_col)', linspace(1,0.5,n_col)', zeros(n_col,1)];
colormap(ax, cmap);
cb = colorbar(ax);
cb.Label.String = 'Transverse displacement (rel.)';

% Undeformed structure (thin dashed grey)
for b = 1:beams.nbeams
    hn = beams.nodesHead(b);  en = beams.nodesEnd(b);
    plot3(ax, [nodes.x(hn), nodes.x(en)], ...
              [nodes.y(hn), nodes.y(en)], ...
              [nodes.z(hn), nodes.z(en)], ...
          '--', 'Color', [0.65 0.65 0.65], 'LineWidth', 0.8);
end

% Preallocate surface handles for the animated deformed shape
surf_h = gobjects(beams.nbeams, 1);
for b = 1:beams.nbeams
    c2 = [c_norm_all(b,:); c_norm_all(b,:)];
    x2 = [x0_all(b,:); x0_all(b,:)];
    y2 = [y0_all(b,:); y0_all(b,:)];
    z2 = [z0_all(b,:); z0_all(b,:)];
    surf_h(b) = surface(ax, x2, y2, z2, c2, ...
        'EdgeColor', 'interp', 'FaceColor', 'none', 'LineWidth', 2.5);
end
drawnow;

%--------------------------------------------------------------------------
% 7. Animate (max 10 s, 25 fps)
%--------------------------------------------------------------------------
fps       = 25;
duration  = 10;
n_frames  = fps * duration;
frame_dur = 1 / fps;

t_start = tic;
for frame = 1:n_frames
    if toc(t_start) >= duration, break; end
    if ~ishandle(fig), break; end   % figure was closed

    sf = sin(2*pi * (frame-1) / n_frames) * scaleFactor;

    for b = 1:beams.nbeams
        du = du_all(:,:,b);
        xd = x0_all(b,:) + sf * du(1,:);
        yd = y0_all(b,:) + sf * du(2,:);
        zd = z0_all(b,:) + sf * du(3,:);
        set(surf_h(b), 'XData', [xd; xd], 'YData', [yd; yd], 'ZData', [zd; zd]);
    end
    drawnow;
    pause(frame_dur);
end

end
