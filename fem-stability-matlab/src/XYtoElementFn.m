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
    XY = zeros(sum(beams.disc), 3);
    pos = 0;
for p=1:beams.nbeams        
    for s=1:beams.disc(p)
        XY(pos + s,1)=beams.XY(p,1);
        XY(pos + s,2)=beams.XY(p,2);
        XY(pos + s,3)=beams.XY(p,3);
    end
    pos = pos + s ;
end
end