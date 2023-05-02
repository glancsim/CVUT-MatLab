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


function [elementVectorXY]=XYtoel(numberOfBeam,dicretizationOfBeam,beamVectorXY)
for p=1:numberOfBeam        
    for s=1:dicretizationOfBeam
    elementVectorXY(s+dicretizationOfBeam*p-dicretizationOfBeam,1)=beamVectorXY(p,1);
    elementVectorXY(s+dicretizationOfBeam*p-dicretizationOfBeam,2)=beamVectorXY(p,2);
    elementVectorXY(s+dicretizationOfBeam*p-dicretizationOfBeam,3)=beamVectorXY(p,3);
    end
end
end