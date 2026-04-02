function oofem = oofemInputFn(nodes, beams, loads, kinematic, sections, filename)
% oofemInputFn  Generate input.mat for the 2D frame OOFEM Python runner.
%
% Uses one Beam2d element per physical beam (ndisc = 1) so no interior
% discretisation nodes are needed.  The 2D frame lives in the XZ plane;
% our z-coordinate maps to OOFEM's y-axis (2dBeam domain is in XY plane).
%
% INPUTS:
%   nodes, beams, loads, kinematic, sections  — standard 2D frame structs
%   filename   — full path to the output .mat file (e.g. '.../oofem/input.mat')
%
% OUTPUT:
%   oofem struct (also saved to filename):
%     .nodes       - (nnodes × 2)   [x, z]  original node coordinates
%     .beams       - (nbeams × 2)   [headNode, endNode]
%     .sectionProp - struct with A, Iz, E (each nbeams × 1)
%     .releases    - (nbeams × 2)   col1=hinge at head, col2=hinge at end
%     .loads.X     - (n × 2) [node, Fx]
%     .loads.Z     - (n × 2) [node, Fz]
%     .loads.RY    - (n × 2) [node, Mry]
%     .kinematic.x.nodes, .z.nodes, .ry.nodes
%
% (c) S. Glanc, 2026

nbeams = numel(beams.nodesHead);
nsec   = nbeams;   % one cross-section per beam

% --- nodes ---
oofem.nodes = [nodes.x(:), nodes.z(:)];   % (nnodes × 2)

% --- beam connectivity (1-based node indices) ---
oofem.beams = [beams.nodesHead(:), beams.nodesEnd(:)];   % (nbeams × 2)

% --- section properties (per-beam) ---
for p = 1:nbeams
    idx = beams.sections(p);
    oofem.sectionProp.A( p, 1) = sections.A(idx);
    oofem.sectionProp.Iz(p, 1) = sections.Iz(idx);
    oofem.sectionProp.E( p, 1) = sections.E(idx);
end

% --- hinge releases (per beam) ---
oofem.releases = zeros(nbeams, 2);
if isfield(beams, 'releases')
    oofem.releases = double(beams.releases);
end

% --- loads — pre-initialise as (0×2) so Python never gets missing keys ---
oofem.loads.X  = zeros(0, 2);
oofem.loads.Z  = zeros(0, 2);
oofem.loads.RY = zeros(0, 2);

if ~isempty(loads.x.nodes)
    oofem.loads.X  = [loads.x.nodes(:),  loads.x.value(:)];
end
if ~isempty(loads.z.nodes)
    oofem.loads.Z  = [loads.z.nodes(:),  loads.z.value(:)];
end
if isfield(loads, 'ry') && ~isempty(loads.ry.nodes)
    oofem.loads.RY = [loads.ry.nodes(:), loads.ry.value(:)];
end

% --- kinematic boundary conditions ---
oofem.kinematic.x.nodes  = kinematic.x.nodes(:);
oofem.kinematic.z.nodes  = kinematic.z.nodes(:);
if isfield(kinematic, 'ry') && ~isempty(kinematic.ry.nodes)
    oofem.kinematic.ry.nodes = kinematic.ry.nodes(:);
else
    oofem.kinematic.ry.nodes = zeros(0, 1);
end

% --- save ---
save(filename, 'oofem');
end
