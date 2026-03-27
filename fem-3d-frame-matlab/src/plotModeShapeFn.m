function plotModeShapeFn(nodes, beams, kinematic, Results, modeNum)
% plotModeShapeFn  Animated 3D visualization of the critical buckling mode.
%
% Displays the critical buckling mode shape as a smooth animated curve over
% the undeformed structure. The deformed shape is colour-coded by transverse
% displacement magnitude (green = zero → yellow → red = maximum).
% The animation oscillates sinusoidally until the figure is closed.
%
% INPUTS:
%   nodes     - (struct) Node geometry
%     .x, .y, .z  - [m]  Node coordinates       (nnodes×1 each)
%
%   beams     - (struct) Beam topology
%     .nodesHead  - Start node index             (nbeams×1)
%     .nodesEnd   - End node index               (nbeams×1)
%     .angles     - [deg] Cross-section roll     (nbeams×1, optional)
%
%   kinematic - (struct) Kinematic boundary conditions
%     .x.nodes, .y.nodes, .z.nodes   - Fixed translation node indices
%     .rx.nodes, .ry.nodes, .rz.nodes - Fixed rotation node indices
%
%   Results   - (struct) Output of stabilitySolverFn
%     .values           - Critical load multipliers (sorted)  (10×1)
%     .vectors          - Buckling mode shapes                (ndofs×10)
% 
%   modeNum   - (optional) Index into Results.values/vectors (1-based).
%               Default: mode with smallest absolute eigenvalue.
%
% USAGE:
%   Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads);
%   plotModeShapeFn(nodes, beams, kinematic, Results);
%   % Press Ctrl+C or close the figure to stop the animation.
%
% See also: stabilitySolverFn, plotStructureFn
%
% (c) S. Glanc, 2025

N_PLOT   = 30;   % interpolation points per beam
N_FRAMES = 40;   % animation frames per full oscillation cycle
FPS      = 25;   % target playback frame rate [Hz]

%--------------------------------------------------------------------------
% 1. SETUP — reconstruct nodes.dofs and beam geometry
%--------------------------------------------------------------------------
nnodes     = numel(nodes.x);
nodes.dofs = true(nnodes, 6);
nodes.dofs(kinematic.x.nodes,  1) = false;
nodes.dofs(kinematic.y.nodes,  2) = false;
nodes.dofs(kinematic.z.nodes,  3) = false;
nodes.dofs(kinematic.rx.nodes, 4) = false;
nodes.dofs(kinematic.ry.nodes, 5) = false;
nodes.dofs(kinematic.rz.nodes, 6) = false;
nodes.nnodes = nnodes;

nbeams           = numel(beams.nodesHead);
beams.nbeams     = nbeams;
beams.vertex     = beamVertexFn(beams, nodes);
beams.codeNumbers = codeNumbersFn(beams, nodes);

if ~isfield(beams, 'angles')
    beams.angles = zeros(nbeams, 1);
end
beams.XY = XYtoRotBeamsFn(beams, beams.angles);

%--------------------------------------------------------------------------
% 2. SELECT critical mode — eigenvalue with smallest absolute value
%--------------------------------------------------------------------------
if nargin < 5 || isempty(modeNum)
    [~, modeNum] = min(abs(Results.values));
end
lambda_cr   = Results.values(modeNum);
eigvec    = full(Results.vectors(:, modeNum));

%--------------------------------------------------------------------------
% 3. MAP eigenvector entries → nodal displacements (nnodes × 6)
%--------------------------------------------------------------------------
u_nodes = zeros(nnodes, 6);
for b = 1:nbeams
    hn = beams.nodesHead(b);
    en = beams.nodesEnd(b);
    for d = 1:6
        k = beams.codeNumbers(b, d);
        if k > 0,  u_nodes(hn, d) = eigvec(k);  end
        k = beams.codeNumbers(b, d + 6);
        if k > 0,  u_nodes(en, d) = eigvec(k);  end
    end
end

%--------------------------------------------------------------------------
% 4. AUTO-SCALE — max nodal translation = 15 % of bounding box
%--------------------------------------------------------------------------
L_char = max([max(nodes.x)-min(nodes.x), ...
              max(nodes.y)-min(nodes.y), ...
              max(nodes.z)-min(nodes.z), 1]);

u_mag = sqrt(u_nodes(:,1).^2 + u_nodes(:,2).^2 + u_nodes(:,3).^2);
u_max = max(u_mag);
if u_max < eps
    warning('plotModeShapeFn: mode shape has zero displacement.');
    scaleFactor = 1;
else
    scaleFactor = 0.15 * L_char / u_max;
end

%--------------------------------------------------------------------------
% 5. HERMITIAN INTERPOLATION along each beam
%
% For each beam, compute:
%   coords_undef (3 × N_PLOT) — undeformed centreline
%   disp_unit    (3 × N_PLOT) — displacement at scale = 1
%   transv_mag   (1 × N_PLOT) — local transverse magnitude (for colour)
%--------------------------------------------------------------------------
xi = linspace(0, 1, N_PLOT);   % parametric coordinate along beam
N1 = 1 - 3*xi.^2 + 2*xi.^3;   % Hermite shape functions
N2 = xi .* (1 - xi).^2;
N3 = 3*xi.^2 - 2*xi.^3;
N4 = xi.^2 .* (xi - 1);

cu  = zeros(3, N_PLOT, nbeams);   % undeformed
cd  = zeros(3, N_PLOT, nbeams);   % unit displacement (global)
ct  = zeros(1, N_PLOT, nbeams);   % transverse magnitude

for b = 1:nbeams
    hn = beams.nodesHead(b);
    en = beams.nodesEnd(b);

    P1 = [nodes.x(hn); nodes.y(hn); nodes.z(hn)];
    P2 = [nodes.x(en); nodes.y(en); nodes.z(en)];
    dP = P2 - P1;
    L  = norm(dP);

    % Local coordinate system (same logic as transformationMatrixFn)
    e1  = dP / L;
    XYv = beams.XY(b, :)';
    e2  = XYv - dot(XYv, e1) * e1;
    e2  = e2 / norm(e2);
    e3  = cross(e1, e2);
    T3  = [e1, e2, e3]';    % 3×3: rows are local basis vectors

    % Nodal quantities in local coordinates
    u1  = T3 * u_nodes(hn, 1:3)';   % head translation [ux, uy, uz] local
    u2  = T3 * u_nodes(en, 1:3)';   % end  translation
    r1  = T3 * u_nodes(hn, 4:6)';   % head rotation    [rx, ry, rz] local
    r2  = T3 * u_nodes(en, 4:6)';   % end  rotation

    % Interpolate displacement at each xi in LOCAL coordinates
    %   axial:         linear interpolation
    %   transverse y:  cubic Hermite (bending about local z, rotation = rz)
    %   transverse z:  cubic Hermite (bending about local y, rotation = ry)
    ux_loc = (1 - xi) * u1(1)  + xi * u2(1);
    uy_loc = N1 * u1(2)  + N2 * r1(3) * L  + N3 * u2(2)  + N4 * r2(3) * L;
    uz_loc = N1 * u1(3)  - N2 * r1(2) * L  + N3 * u2(3)  - N4 * r2(2) * L;

    % Transform back to global
    u_glob = T3' * [ux_loc; uy_loc; uz_loc];   % 3 × N_PLOT

    % Store
    cu(:, :, b) = P1 + dP * xi;       % undeformed positions
    cd(:, :, b) = u_glob;              % global displacement (unit scale)
    ct(:, :, b) = sqrt(uy_loc.^2 + uz_loc.^2);   % transverse magnitude
end

% Normalise colour data to [0, 1]
ct_max = max(ct(:));
if ct_max < eps, ct_max = 1; end
C_norm = ct / ct_max;   % 1 × N_PLOT × nbeams

%--------------------------------------------------------------------------
% 6. FIGURE — static elements
%--------------------------------------------------------------------------
fig = figure('Name', 'Vlastní tvar stability', 'NumberTitle', 'off');
ax  = axes('Parent', fig);
hold(ax, 'on');
axis(ax, 'equal');
grid(ax, 'on');
xlabel(ax, 'x [m]');
ylabel(ax, 'y [m]');
zlabel(ax, 'z [m]');
title(ax, sprintf('Kritický vlastní tvar  |  \\lambda_{cr} = %.4g', lambda_cr));
view(ax, 3);

% Colormap: green (0) → yellow (0.5) → red (1)
nColors = 128;
cmap = [linspace(0,   1, nColors)', ...
        linspace(0.75, 0, nColors)', ...
        zeros(nColors, 1)];
colormap(ax, cmap);
cb = colorbar(ax);
cb.Label.String = 'Příčný posun [normalizovaný]';
clim(ax, [0, 1]);

% Undeformed structure — thin grey lines
for b = 1:nbeams
    plot3(ax, cu(1,:,b), cu(2,:,b), cu(3,:,b), ...
        '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.8);
end

% Deformed shape — coloured surface-line objects (one per beam)
surf_h = gobjects(nbeams, 1);
for b = 1:nbeams
    Xd = cu(1,:,b) + scaleFactor * cd(1,:,b);
    Yd = cu(2,:,b) + scaleFactor * cd(2,:,b);
    Zd = cu(3,:,b) + scaleFactor * cd(3,:,b);
    C  = squeeze(C_norm(1,:,b));
    surf_h(b) = surface(ax, [Xd; Xd], [Yd; Yd], [Zd; Zd], [C; C], ...
        'EdgeColor', 'interp', 'FaceColor', 'none', 'LineWidth', 2);
end

drawnow;

%--------------------------------------------------------------------------
% 7. ANIMATION — sinusoidal oscillation (stops when figure is closed)
%--------------------------------------------------------------------------
fprintf('plotModeShapeFn: animace spuštěna. Zavřete okno nebo stiskněte Ctrl+C.\n');
try
    while ishandle(fig)
        for frame = 1:N_FRAMES
            if ~ishandle(fig), break; end
            phase = sin(2 * pi * (frame - 1) / N_FRAMES);   % -1 … +1

            for b = 1:nbeams
                Xd = cu(1,:,b) + scaleFactor * phase * cd(1,:,b);
                Yd = cu(2,:,b) + scaleFactor * phase * cd(2,:,b);
                Zd = cu(3,:,b) + scaleFactor * phase * cd(3,:,b);
                set(surf_h(b), ...
                    'XData', [Xd; Xd], ...
                    'YData', [Yd; Yd], ...
                    'ZData', [Zd; Zd]);
            end
            drawnow;
            pause(1 / FPS);
        end
    end
catch ME
    if ~strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
        rethrow(ME);
    end
    % Figure was closed — exit cleanly
end

end
