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


function [XY]=XYtoBeamsFn(beams)
    for b = 1:beams.nbeams
        if beams.vertex(b,3) == 0
            XY(b,:) = [0 0 1];
        else
            XY(b,:) = [0 1 0];
        end
    end
end