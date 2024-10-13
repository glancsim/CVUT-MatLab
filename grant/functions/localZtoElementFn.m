% Prirazeni lokální osy Z jednotlivým elementům prutu
%
% In: 
%   beams   .nbeams         - počet prutů
%           .disc           - počet elementů na prutu
%           .localZ         - vektor určující lokální osu Z
%
% Out:
%   localZ                  - vektor určující lokální osu Z elementu
%
% (c) S. Glanc, 2022


function [localZ]=localZtoElementFn(beams)
    for p=1:beams.nbeams        
        for s=1:beams.disc
            localZ(s+beams.disc*p-beams.disc,1)=beams.localZ(p,1);
            localZ(s+beams.disc*p-beams.disc,2)=beams.localZ(p,2);
            localZ(s+beams.disc*p-beams.disc,3)=beams.localZ(p,3);
        end
    end
end