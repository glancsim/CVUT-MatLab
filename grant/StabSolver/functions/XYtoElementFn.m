% Prirazeni vektoruXY jednotlivým elementům prutu
%
% In: 
%   beams   .nbeams         - počet prutů
%           .disc           - počet elementů na prutu
%           .XY             - vektor určující rovinu prutu XY
%
% Out:
%   XY                      - vektor určující rovinu elementu XY
%
% (c) S. Glanc, 2022


function [XY]=XYtoElementFn(beams)
for p=1:beams.nbeams        
    for s=1:beams.disc
    XY(s+beams.disc*p-beams.disc,1)=beams.XY(p,1);
    XY(s+beams.disc*p-beams.disc,2)=beams.XY(p,2);
    XY(s+beams.disc*p-beams.disc,3)=beams.XY(p,3);
    end
end
end