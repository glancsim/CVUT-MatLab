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

function [outputSections]=sectionToBeamFn(sections,beams)
    for k = 1:beams.nbeams 
        outputSections.A(k) = sections.A(beams.sections.id(k));
    end
    for k = 1:beams.nbeams 
        outputSections.E(k) = sections.E(beams.sections.id(k));
    end
    outputSections.id = beams.sections.id;
end
