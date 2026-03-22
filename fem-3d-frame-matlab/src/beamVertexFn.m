% Prirazeni vektoruXY jednotlivým elementům prutu
%
% In: 
%   dicretizationOfBeam - diskretizace prutu
%   numberOfBeam - pocet prutu
%   beamVectorXY - vektor v rovině XY pro jednotlivé pruty   
%
% Out:
%   elementVectorXY - vektor v rovině XY pro jednotlivé elementy     
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