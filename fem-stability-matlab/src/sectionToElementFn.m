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

function [outSections]=sectionToElementFn(sections,beams)
    pos = 0;
    for p=1:beams.nbeams
            disc = beams.disc(p);
            for s=1:disc
                outSections.A(pos + s)=sections.A(beams.sections(p));   
            end
            for s=1:disc
                outSections.Iy(pos + s)=sections.Iy(beams.sections(p));   
            end
            for s=1:disc
                outSections.Iz(pos + s)=sections.Iz(beams.sections(p));   
            end
            for s=1:disc
                outSections.Ix(pos + s)=sections.Ix(beams.sections(p));   
            end
            for s=1:disc
                outSections.E(pos + s)=sections.E(beams.sections(p));   
            end
            for s=1:disc
                outSections.v(pos + s)=sections.v(beams.sections(p));   
            end
            pos = pos + s ;   
    end
end
