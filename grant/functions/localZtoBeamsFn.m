% Prirazeni vektoruXY jednotlivým elementům prutu
%
% In: 
%   beams           .nbeams         - počet prutů
%                   .vertex         - směrový vektor pro jednotlivé pruty
%   beams.disc - diskretizace prutu
%   numberOfBeam - pocet prutu
%   beamVectorXY - vektor v rovině XY pro jednotlivé pruty   
%
% Out:
%   elementVectorXY - vektor v rovině XY pro jednotlivé elementy     
%
% (c) S. Glanc, 2022


function [localZ]=localZtoBeamsFn(beams)
    for b = 1:beams.nbeams
        if beams.vertex(b,2) == 0 && beams.vertex(b,1) == 0
            localZ(b,:) = [1 0 0];
        else
            localZ(b,:) = [0 0 1];
        end
    end
end