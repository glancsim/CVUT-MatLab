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

% Discretization — needed to access internal node DOFs
if isfield(Results, 'ndisc')
    ndisc = Results.ndisc;
else
    ndisc = 1;
end
beams.disc = ndisc * ones(nbeams, 1);
elements   = discretizationBeamsFn(beams, nodes);
nelement   = elements.nelement;

% Adaptive interpolation points per element (~30 total per beam)
N_PLOT = max(10, round(30 / ndisc));

%--------------------------------------------------------------------------
% 2. SELECT critical mode — eigenvalue with smallest absolute value
%--------------------------------------------------------------------------
if nargin < 5 || isempty(modeNum)
    [~, modeNum] = min(abs(Results.values));
end
lambda_cr   = Results.values(modeNum);
eigvec    = full(Results.vectors(:, modeNum));

%--------------------------------------------------------------------------
% 3. HERMITIAN INTERPOLATION along each element
%
% Iterates over beams → elements (segments). For each element, extracts
% DOFs from the eigenvector via elements.codeNumbers (including internal
% discretisation nodes), then applies cubic Hermite interpolation.
%--------------------------------------------------------------------------
xi = linspace(0, 1, N_PLOT);
N1 = 1 - 3*xi.^2 + 2*xi.^3;   % Hermite shape functions
N2 = xi .* (1 - xi).^2;
N3 = 3*xi.^2 - 2*xi.^3;
N4 = xi.^2 .* (xi - 1);

cu = zeros(3, N_PLOT, nelement);   % undeformed positions
cd = zeros(3, N_PLOT, nelement);   % unit displacement (global)
ct = zeros(1, N_PLOT, nelement);   % transverse magnitude

elem_idx = 0;
for b = 1:nbeams
    c  = beams.disc(b);
    hn = beams.nodesHead(b);
    P_start = [nodes.x(hn); nodes.y(hn); nodes.z(hn)];
    dP_elem = beams.vertex(b,:)' / c;
    L_elem  = norm(dP_elem);

    % Local coordinate system (same for all elements of this beam)
    e1  = dP_elem / L_elem;
    XYv = beams.XY(b,:)';
    e2  = XYv - dot(XYv, e1) * e1;
    e2  = e2 / norm(e2);
    e3  = cross(e1, e2);
    T3  = [e1, e2, e3]';   % 3×3: rows are local basis vectors

    for s = 1:c
        elem_idx = elem_idx + 1;
        P1 = P_start + dP_elem * (s - 1);

        % Extract head (cols 1-6) and tail (cols 7-12) DOFs from eigenvector
        u_head = zeros(6, 1);
        u_tail = zeros(6, 1);
        for d = 1:6
            k = elements.codeNumbers(elem_idx, d);
            if k > 0, u_head(d) = eigvec(k); end
            k = elements.codeNumbers(elem_idx, d + 6);
            if k > 0, u_tail(d) = eigvec(k); end
        end

        % Transform to local coordinates
        u1 = T3 * u_head(1:3);   % head translation local
        u2 = T3 * u_tail(1:3);   % tail translation local
        r1 = T3 * u_head(4:6);   % head rotation local
        r2 = T3 * u_tail(4:6);   % tail rotation local

        % Hermite interpolation in local coords
        ux_loc = (1 - xi) * u1(1) + xi * u2(1);
        uy_loc = N1*u1(2) + N2*r1(3)*L_elem + N3*u2(2) + N4*r2(3)*L_elem;
        uz_loc = N1*u1(3) - N2*r1(2)*L_elem + N3*u2(3) - N4*r2(2)*L_elem;

        % Transform back to global
        u_glob = T3' * [ux_loc; uy_loc; uz_loc];

        cu(:, :, elem_idx) = P1 + dP_elem * xi;
        cd(:, :, elem_idx) = u_glob;
        ct(:, :, elem_idx) = sqrt(uy_loc.^2 + uz_loc.^2);
    end
end

%--------------------------------------------------------------------------
% 4. AUTO-SCALE — max displacement across ALL interpolated points
%--------------------------------------------------------------------------
L_char = max([max(nodes.x)-min(nodes.x), ...
              max(nodes.y)-min(nodes.y), ...
              max(nodes.z)-min(nodes.z), 1]);

u_mag_all = sqrt(cd(1,:,:).^2 + cd(2,:,:).^2 + cd(3,:,:).^2);
u_max = max(u_mag_all(:));
if u_max < eps
    warning('plotModeShapeFn: mode shape has zero displacement.');
    scaleFactor = 1;
else
    scaleFactor = 0.15 * L_char / u_max;
end

% Normalise colour data to [0, 1]
ct_max = max(ct(:));
if ct_max < eps, ct_max = 1; end
C_norm = ct / ct_max;

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
for e = 1:nelement
    plot3(ax, cu(1,:,e), cu(2,:,e), cu(3,:,e), ...
        '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.8);
end

% Deformed shape — coloured surface-line objects (one per element)
surf_h = gobjects(nelement, 1);
for e = 1:nelement
    Xd = cu(1,:,e) + scaleFactor * cd(1,:,e);
    Yd = cu(2,:,e) + scaleFactor * cd(2,:,e);
    Zd = cu(3,:,e) + scaleFactor * cd(3,:,e);
    C  = squeeze(C_norm(1,:,e));
    surf_h(e) = surface(ax, [Xd; Xd], [Yd; Yd], [Zd; Zd], [C; C], ...
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

            for e = 1:nelement
                Xd = cu(1,:,e) + scaleFactor * phase * cd(1,:,e);
                Yd = cu(2,:,e) + scaleFactor * phase * cd(2,:,e);
                Zd = cu(3,:,e) + scaleFactor * phase * cd(3,:,e);
                set(surf_h(e), ...
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
