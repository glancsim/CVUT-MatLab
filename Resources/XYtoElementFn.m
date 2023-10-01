% Prirazeni vektoruXY jednotlivým elementům prutu
%
% In: 
%   beams
%
% Out:
%   XY - vektor v rovině XY pro jednotlivé elementy     
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