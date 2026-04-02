function vertex = beamVertexFn(beams, nodes)
% beamVertexFn  Compute direction vectors (Δx, Δz) for each beam.
%
% INPUTS:
%   beams.nodesHead  - (nbeams x 1) start node indices
%   beams.nodesEnd   - (nbeams x 1) end node indices
%   nodes.x, nodes.z - node coordinates [m]
%
% OUTPUTS:
%   vertex  - (nbeams x 2) [Δx, Δz] for each beam
%
% (c) S. Glanc, 2026

vertex = zeros(beams.nbeams, 2);
for i = 1:beams.nbeams
    vertex(i, 1) = nodes.x(beams.nodesEnd(i)) - nodes.x(beams.nodesHead(i));
    vertex(i, 2) = nodes.z(beams.nodesEnd(i)) - nodes.z(beams.nodesHead(i));
end
end
