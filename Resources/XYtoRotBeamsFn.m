% Prirazeni vektoruXY jednotlivým elementům prutu
%
% In: 
%   beams.disc - diskretizace prutu
%   numberOfBeam - pocet prutu
%   beamVectorXY - vektor v rovině XY pro jednotlivé pruty   
%
% Out:
%   elementVectorXY - vektor v rovině XY pro jednotlivé elementy     
%
% (c) S. Glanc, 2022


function [XY]=XYtoBeamsFn(beams,angles)
    for b = 1:beams.nbeams
        theta = deg2rad(angles(b));
        Rx = [1, 0, 0; 0, cos(theta), -sin(theta); 0, sin(theta), cos(theta)];
        if beams.vertex(b,1) == 0 && beams.vertex(b,3) == 0 
            XY(b,:) = Rx * [0 0 1]';
        else
            XY(b,:) = Rx * [0 1 0]';
        end
    end
end