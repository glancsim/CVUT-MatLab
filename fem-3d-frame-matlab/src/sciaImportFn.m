function [scia_phi, node_map] = sciaImportFn(csvFile, nodes, kinematic, varargin)
% sciaImportFn  Import buckling mode shapes exported from Scia Engineer.
%
% Reads a CSV file exported from Scia Engineer containing nodal displacements
% for each buckling mode, matches Scia nodes to MATLAB nodes by coordinates,
% and returns a mode shape matrix in MATLAB's DOF ordering.
%
% NODE MATCHING:  Scia and MATLAB use independent node numbering.  Nodes are
% matched by their spatial coordinates (Euclidean distance < tolerance).
%
% DOF ORDERING:  The output scia_phi uses the same DOF ordering as MATLAB's
% stabilitySolverFn: for each node in order, free DOFs only, sequence
% [ux, uy, uz, rx, ry, rz].  Fixed DOFs (from kinematic) are set to 0 and
% excluded from the output vector (same as Results.vectors).
%
% EXPECTED CSV FORMAT:
%   mode,node_id,x,y,z,ux,uy,uz,rx,ry,rz
%   1,1,0.000,0.000,0.000,0.0,0.0,0.0,0.0,0.0,0.0
%   1,2,1.000,0.000,0.000,0.012,-0.003,0.098,0.001,0.002,0.0005
%   ...
%   2,1,0.000,...
%
%   Columns:
%     mode    - mode number (1-based integer)
%     node_id - Scia node ID (used only for diagnostics; not for matching)
%     x,y,z   - node coordinates [m]  — used for spatial matching
%     ux,uy,uz - translational displacements [m or normalised]
%     rx,ry,rz - rotational displacements [rad or normalised]
%
% INPUTS:
%   csvFile   - (char) Path to the CSV file exported from Scia Engineer.
%   nodes     - (struct) MATLAB node geometry.
%     .x      - (nnodes x 1) x-coordinates [m]
%     .y      - (nnodes x 1) y-coordinates [m]
%     .z      - (nnodes x 1) z-coordinates [m]
%   kinematic - (struct) MATLAB kinematic boundary conditions (supports).
%               Used to identify which DOFs are fixed (= excluded from phi).
%     .x.nodes, .y.nodes, .z.nodes,
%     .rx.nodes, .ry.nodes, .rz.nodes
%
% OPTIONAL NAME-VALUE ARGUMENTS:
%   'Tolerance'  - (scalar) Max coordinate distance [m] for node matching.
%                  Default: 1e-3  (1 mm).
%   'CoordScale' - (scalar) Scale factor applied to Scia coordinates before
%                  matching.  Use 1e-3 if Scia exports coordinates in mm.
%                  Default: 1  (coordinates in metres).
%   'DofOrder'   - (1x6 int) Permutation of Scia DOF columns [ux uy uz rx ry rz]
%                  to MATLAB DOF order [1 2 3 4 5 6].
%                  Example: [1 3 2 4 6 5] if Scia uses [ux uz uy rx rz ry].
%                  Default: [1 2 3 4 5 6]  (no reordering).
%
% OUTPUTS:
%   scia_phi  - (ndofs_orig x nmodes)  Mode shape matrix in MATLAB DOF order.
%               Each column is one buckling mode, normalised to unit length.
%               Only free DOFs are included (same structure as Results.vectors
%               rows 1:ndofs_orig from stabilitySolverFn).
%   node_map  - (nnodes x 1)  For each MATLAB node i: the row index in the
%               Scia data table that was matched.  0 = no match found.
%
% EXAMPLE:
%   [scia_phi, node_map] = sciaImportFn('scia_modes.csv', nodes, kinematic);
%   Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads);
%   [mac, ok] = macComparisonFn(nodes, beams, kinematic, Results, scia_phi);
%
% See also: macCriterionFn, macComparisonFn
%
% (c) S. Glanc, 2026

%--------------------------------------------------------------------------
% Parse optional arguments
%--------------------------------------------------------------------------
p = inputParser;
addParameter(p, 'Tolerance',  1e-3,          @(x) isscalar(x) && x > 0);
addParameter(p, 'CoordScale', 1,              @(x) isscalar(x) && x > 0);
addParameter(p, 'DofOrder',   [1 2 3 4 5 6], @(x) isequal(sort(x), 1:6));
parse(p, varargin{:});
tolerance  = p.Results.Tolerance;
coordScale = p.Results.CoordScale;
dofOrder   = p.Results.DofOrder;

%--------------------------------------------------------------------------
% Load CSV
%--------------------------------------------------------------------------
opts = detectImportOptions(csvFile);
opts.VariableNamesLine = 1;
T = readtable(csvFile, opts);

% Expected columns: mode, node_id, x, y, z, ux, uy, uz, rx, ry, rz
required = {'mode','node_id','x','y','z','ux','uy','uz','rx','ry','rz'};
for c = required
    if ~any(strcmpi(T.Properties.VariableNames, c{1}))
        error('sciaImportFn: CSV is missing column "%s".\nExpected columns: %s', ...
              c{1}, strjoin(required, ', '));
    end
end

modes   = unique(T.mode, 'sorted');
nmodes  = numel(modes);
nnodes  = numel(nodes.x);

%--------------------------------------------------------------------------
% Build MATLAB DOF map: nodeDofMap(n,d) = global DOF index (0 = fixed)
%--------------------------------------------------------------------------
dofs_free = true(nnodes, 6);
dofs_free(kinematic.x.nodes,  1) = false;
dofs_free(kinematic.y.nodes,  2) = false;
dofs_free(kinematic.z.nodes,  3) = false;
dofs_free(kinematic.rx.nodes, 4) = false;
dofs_free(kinematic.ry.nodes, 5) = false;
dofs_free(kinematic.rz.nodes, 6) = false;

nodeDofMap = zeros(nnodes, 6);
dof_counter = 0;
for n = 1:nnodes
    for d = 1:6
        if dofs_free(n, d)
            dof_counter = dof_counter + 1;
            nodeDofMap(n, d) = dof_counter;
        end
    end
end
ndofs_orig = dof_counter;

%--------------------------------------------------------------------------
% Match MATLAB nodes to Scia nodes by coordinates (first mode data)
%--------------------------------------------------------------------------
T1      = T(T.mode == modes(1), :);
scia_x  = T1.x * coordScale;
scia_y  = T1.y * coordScale;
scia_z  = T1.z * coordScale;

node_map = zeros(nnodes, 1);
for i = 1:nnodes
    dists = sqrt((scia_x - nodes.x(i)).^2 + ...
                 (scia_y - nodes.y(i)).^2 + ...
                 (scia_z - nodes.z(i)).^2);
    [minDist, idx] = min(dists);
    if minDist <= tolerance
        node_map(i) = idx;
    else
        warning('sciaImportFn: MATLAB node %d (%.3f, %.3f, %.3f) has no Scia match (min dist = %.4f m).', ...
                i, nodes.x(i), nodes.y(i), nodes.z(i), minDist);
    end
end

nmatch = sum(node_map > 0);
fprintf('sciaImportFn: matched %d / %d MATLAB nodes to Scia nodes.\n', nmatch, nnodes);

%--------------------------------------------------------------------------
% Build scia_phi (ndofs_orig x nmodes)
%--------------------------------------------------------------------------
dof_names_scia = {'ux','uy','uz','rx','ry','rz'};  % Scia column names in order
dof_names_ml   = dof_names_scia(dofOrder);          % reordered to MATLAB order

scia_phi = zeros(ndofs_orig, nmodes);

for m = 1:nmodes
    Tm = T(T.mode == modes(m), :);

    for n = 1:nnodes
        si = node_map(n);
        if si == 0, continue; end       % no match — leave as 0

        for d = 1:6
            dof_idx = nodeDofMap(n, d);
            if dof_idx == 0, continue; end   % fixed DOF

            col_name = dof_names_ml{d};
            scia_val = Tm.(col_name)(si);
            scia_phi(dof_idx, m) = scia_val;
        end
    end

    % Normalise to unit length
    nrm = norm(scia_phi(:, m));
    if nrm > 0
        scia_phi(:, m) = scia_phi(:, m) / nrm;
    else
        warning('sciaImportFn: mode %d has zero norm after assembly — check CSV data.', modes(m));
    end
end

end
