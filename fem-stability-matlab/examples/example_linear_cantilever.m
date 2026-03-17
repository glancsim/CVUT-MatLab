%% example_linear_cantilever.m
% ==========================================================================
%  EXAMPLE 1 — Linear static analysis of a 3D cantilever beam
% ==========================================================================
%
% A cantilever beam of length L = 5 m, fixed at node 1, free at node 2.
% A transverse load P = 10 000 N is applied in the -y direction at the tip.
%
%                    P (downward)
%                    |
%   [fixed]===========================[ ]
%   node 1                            node 2
%   <------------ L = 5 m ----------->
%
% Analytical tip deflection (Euler-Bernoulli):
%   delta_y = P * L^3 / (3 * E * Iz)
%
% Running this example:
%   1. Make sure  src/  is on the MATLAB path, e.g.:
%        addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'))
%   2. Run the script:  example_linear_cantilever
% ==========================================================================

clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% CROSS-SECTION PROPERTIES (HEA 200 profile, steel)
% --------------------------------------------------------------------------
sections.A  = 53.83e-4;    % [m^2]  cross-sectional area
sections.Iy = 1943e-8;     % [m^4]  moment of inertia about y-axis
sections.Iz = 388.6e-8;    % [m^4]  moment of inertia about z-axis
sections.Ix = 20.98e-8;    % [m^4]  torsional moment
sections.E  = 210e9;       % [Pa]   Young's modulus (steel)
sections.v  = 0.3;         % [-]    Poisson's ratio

%% NODES
% --------------------------------------------------------------------------
nodes.x = [0; 5];   % [m]  x-coordinates
nodes.y = [0; 0];   % [m]  y-coordinates
nodes.z = [0; 0];   % [m]  z-coordinates

%% DISCRETIZATION
% --------------------------------------------------------------------------
ndisc = 10;   % number of finite elements per beam

%% BOUNDARY CONDITIONS (supports)
% --------------------------------------------------------------------------
% Node 1 is fully fixed (cantilever root) — all 6 DOFs constrained.
kinematic.x.nodes  = [1];
kinematic.y.nodes  = [1];
kinematic.z.nodes  = [1];
kinematic.rx.nodes = [1];
kinematic.ry.nodes = [1];
kinematic.rz.nodes = [1];

%% BEAMS
% --------------------------------------------------------------------------
beams.nodesHead = [1];   % start node index
beams.nodesEnd  = [2];   % end node index
beams.sections  = [1];   % section index (1 = the only section defined above)
beams.angles    = [0];   % [deg] no cross-section rotation

%% LOADS
% --------------------------------------------------------------------------
% Transverse load P = 10 000 N in the -y direction at the free end (node 2).
P = -10000;   % [N]

loads.x.nodes  = [];  loads.x.value  = [];
loads.y.nodes  = [2]; loads.y.value  = [P];
loads.z.nodes  = [];  loads.z.value  = [];
loads.rx.nodes = [];  loads.rx.value = [];
loads.ry.nodes = [];  loads.ry.value = [];
loads.rz.nodes = [];  loads.rz.value = [];

%% LINEAR ANALYSIS
% --------------------------------------------------------------------------
[displacements, endForces] = linearSolverFn(sections, nodes, ndisc, kinematic, beams, loads);

%% RESULTS
% --------------------------------------------------------------------------
% Node 1 is fully fixed → 0 free DOFs.
% Node 2 is fully free → 6 free DOFs in order [ux, uy, uz, rx, ry, rz].
% displacements.global contains the free DOFs in this code-number order.

% Tip displacement in y (uy of node 2 = 2nd free DOF)
% The code numbers for node 2 free DOFs start immediately (node 1 has 0 free DOFs).
delta_y_FEM = displacements.global(2);   % second free DOF = uy of node 2


% Analytical solution (Euler-Bernoulli cantilever, load in global y → bending about z)
delta_y_exact = abs(P) * 5^3 / (3 * sections.E * sections.Iz);

fprintf('\n');
fprintf('=== Cantilever Beam — Linear Analysis Results ===\n\n');
fprintf('  Tip deflection (FEM)      : %+.6e m\n', delta_y_FEM);
fprintf('  Tip deflection (exact)    : %+.6e m\n', -delta_y_exact);
fprintf('  Relative error            : %.4f %%\n\n', ...
        abs(delta_y_FEM + delta_y_exact) / delta_y_exact * 100);

fprintf('  First element end-forces (local coordinates):\n');
fprintf('    N   (axial)    = %+.3e N\n',   endForces.local(1,1));
fprintf('    Vy  (shear y)  = %+.3e N\n',   endForces.local(2,1));
fprintf('    Mz  (moment z) = %+.3e N*m\n', endForces.local(6,1));

%% DEFORMED SHAPE PLOT
% --------------------------------------------------------------------------
figure('Name', 'Cantilever — Deformed shape (y-z plane)', 'Position', [100 100 800 350]);

% Sample node positions along the beam axis
nplot  = ndisc + 1;
xBeam  = linspace(0, 5, nplot);

% Extract y-displacement at each internal + end node from displacements.global
% The free DOFs are numbered sequentially for node 2..end of each element.
% For a quick visualisation, collect uy from every element end node (code numbers).
yDisp = zeros(1, nplot);
yDisp(end) = delta_y_FEM;   % only tip known analytically; others from global vector

% Full deformed shape from internal DOF vector
% Elements are ordered beam1: elem1..10 (ndisc=10)
% Code numbers for intermediate nodes are available via discretization
for elIdx = 1:ndisc
    codes = [1 + (elIdx-1)*5, 1 + elIdx*5];   % approximate: uy DOF spacing
end
% (A detailed extraction requires running discretizationBeamsFn — omitted here
%  for brevity. The plot below shows a simplified representation.)

plot([0 5], [0 delta_y_FEM*1e3], 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('x  [m]');
ylabel('y-displacement  [mm]');
title('Cantilever beam — tip deflection');
grid on;
legend('FEM (linear)', 'Location', 'northwest');
yline(0, 'k--');
