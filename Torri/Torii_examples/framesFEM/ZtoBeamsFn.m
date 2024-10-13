% Prirazeni vektoruXY jednotlivým elementům prutu
%
% In: 
%   beams   .nbeams         - počet prutů
%           .vertex         - směrový vektor prutu
%   localZ                  - vektor lokální osy Z
%
% Out:
%   XY                      - vektor v rovině XY pro jednotlivé pruty     
%
% (c) S. Glanc, 2024


function [XY]=ZtoBeamsFn(beams,localZ)
    XY = zeros(beams.nbeams,3);
    for b = 1:beams.nbeams
            XY(b,:) = cross(localZ(b,:),beams.vertex(b,:));
    end
end