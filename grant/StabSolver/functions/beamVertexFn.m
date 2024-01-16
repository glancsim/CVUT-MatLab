% Vyvtoření vektoru X jednotlivým prutům
%
% In: 
%   beams   .nbeams         - počet prutů
%           .nodesHead      - počáteční uzel(id)
%           .nodesEnd       - koncový uzel(id)
%   nodes   .x              - souřadnice uzlu
%           .y              - souřadnice uzlu
%           .z              - souřadnice uzlu
%
% Out:
%   vertex                  - směrový vektor pro jednotlivé pruty     
%
% (c) S. Glanc, 2022

function [vertex]=beamVertexFn(beams,nodes)
    vertex = zeros(beams.nbeams,3);
    for i = 1:beams.nbeams
        vertex(i,1) = nodes.x(beams.nodesEnd(i)) - nodes.x(beams.nodesHead(i));
        vertex(i,2) = nodes.y(beams.nodesEnd(i)) - nodes.y(beams.nodesHead(i));
        vertex(i,3) = nodes.z(beams.nodesEnd(i)) - nodes.z(beams.nodesHead(i));
    end
end