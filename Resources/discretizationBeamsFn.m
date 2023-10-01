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
function [elements]=discretizationBeamsFn(beams,nodes)
cislonezname=max(max(beams.codeNumbers))+1;
for p=1:beams.nbeams
    c=beams.disc(p);
    for s=1:c
    elemVector(s+c*p-c,1)=beams.vertex(p,1)/c;
    elemVector(s+c*p-c,2)=beams.vertex(p,2)/c;
    elemVector(s+c*p-c,3)=beams.vertex(p,3)/c;
    end
end
for p=1:beams.nbeams
%doplneni pozice zacatku prutu--------------------------------------------    
    for f=1:6
        elementsCodeNumber(1+c*(p-1),f)=beams.codeNumbers(p,f);
    end
    if c>1
    for f=7:12
        elementsCodeNumber(1+c*(p-1),f)=cislonezname;
        cislonezname=cislonezname+1;
    end
    end
%-------------------------------------------------------------------------
%doplneni pozice pomocnych neznamych--------------------------------------------
    if c>1
    for h=2:c-1
        for f=1:6
            elementsCodeNumber(h+c*(p-1),f)= elementsCodeNumber(h-1+c*(p-1),f+6);
        end
        for f=7:12
            elementsCodeNumber(h+c*(p-1),f)=cislonezname;
            cislonezname=cislonezname+1;
        end
    end
    end
%-------------------------------------------------------------------------
%doplneni pozice konce prutu--------------------------------------------
    if c>1
    for f=1:6
        elementsCodeNumber(c+c*(p-1),f)=elementsCodeNumber(c-1+c*(p-1),f+6);
    end
    end
    for f=7:12
        elementsCodeNumber(c+c*(p-1),f)=beams.codeNumbers(p,f);
    end
%-------------------------------------------------------------------------
end
elements.codeNumbers = elementsCodeNumber
elements.vertex = elemVector
[elements.nelement,~] = size(elemVector)
end
