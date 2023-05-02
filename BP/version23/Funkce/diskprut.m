% Diskretizace prutů - vytvoreni vektorů jednotlivých prutu a vytvoreni   
%   neznamych na mezilehlých elemntech
%
% In: 
%   numberOfUnknownForcesInJoints = počet neznámých vnitřních sil/posunů
%   beamVector =                    vektor jednoltivých prutů
%   beamCodeNumbers =               kódová čísla prutů
%   dicretizationOfBeam =           diskretizace prutu
%   numberOfBeam =                  pocet prutu
%
% Out:
%   elementsCodeNumbers =           kódová čísla elementů
%   elementVector =                 směrový vektor jednotlivých elementů
%
% (c) S. Glanc, 2022
function [elemntsCodeNumber,elemVector]=diskprut(numberOfUnknownForcesInJoints,beamVector,beamCodeNumbers,discretizationOfBeam,numberOfBeam)

cislonezname=numberOfUnknownForcesInJoints+1;
for p=1:numberOfBeam
    c=beamVector(p,4);
    for s=1:discretizationOfBeam
    elemVector(s+discretizationOfBeam*p-discretizationOfBeam,1)=beamVector(p,1)/c;
    elemVector(s+discretizationOfBeam*p-discretizationOfBeam,2)=beamVector(p,2)/c;
    elemVector(s+discretizationOfBeam*p-discretizationOfBeam,3)=beamVector(p,3)/c;
    end
end
for p=1:numberOfBeam
%doplneni pozice zacatku prutu--------------------------------------------    
    for f=1:6
        elemntsCodeNumber(1+discretizationOfBeam*(p-1),f)=beamCodeNumbers(p,f);
    end
    if discretizationOfBeam>1
    for f=7:12
        elemntsCodeNumber(1+discretizationOfBeam*(p-1),f)=cislonezname;
        cislonezname=cislonezname+1;
    end
    end
%-------------------------------------------------------------------------
%doplneni pozice pomocnych neznamych--------------------------------------------
    if discretizationOfBeam>1
    for h=2:discretizationOfBeam-1
        for f=1:6
            elemntsCodeNumber(h+discretizationOfBeam*(p-1),f)= elemntsCodeNumber(h-1+discretizationOfBeam*(p-1),f+6);
        end
        for f=7:12
            elemntsCodeNumber(h+discretizationOfBeam*(p-1),f)=cislonezname;
            cislonezname=cislonezname+1;
        end
    end
    end
%-------------------------------------------------------------------------
%doplneni pozice konce prutu--------------------------------------------
    if discretizationOfBeam>1
    for f=1:6
        elemntsCodeNumber(discretizationOfBeam+discretizationOfBeam*(p-1),f)=elemntsCodeNumber(discretizationOfBeam-1+discretizationOfBeam*(p-1),f+6);
    end
    end
    for f=7:12
        elemntsCodeNumber(discretizationOfBeam+discretizationOfBeam*(p-1),f)=beamCodeNumbers(p,f);
    end
%-------------------------------------------------------------------------
end
end
