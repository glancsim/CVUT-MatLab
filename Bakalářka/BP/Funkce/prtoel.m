% Prirazeni prurezovych charakteristik jednotlivym elementum kazdeho prutu 
%
% In: 
%   sections - jednotlive prurezove charakteristiky prutu
%   numberOfBeam - pocet prutu
%   dicretizationOfBeam - diskretizace prutu
%   indexOfSection - prirazeni charakteristik k prutu  
%
% Out:
%   charElem - jednotlive prurezove charakteristiky elementu    
%
% (c) S. Glanc, 2022

function [charElem]=prtoel(sections,numberOfBeam,disretizationOfBeam,indexOfSection)

    for p=1:numberOfBeam
            for s=1:disretizationOfBeam
                charElem(s+disretizationOfBeam*(p-1))=sections(indexOfSection(p));   
            end
    end
end
