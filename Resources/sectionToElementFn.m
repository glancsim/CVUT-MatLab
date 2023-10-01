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

function [sections]=sectionToElementFn(sections,beams)

    for p=1:beams.nbeams
            for s=1:beams.disc
                sections.A(s+beams.disc*(p-1))=sections.A(beams.sections(p));   
            end
    end
    for p=1:beams.nbeams
            for s=1:beams.disc
                sections.Iy(s+beams.disc*(p-1))=sections.Iy(beams.sections(p));   
            end
    end
    for p=1:beams.nbeams
            for s=1:beams.disc
                sections.Iz(s+beams.disc*(p-1))=sections.Iz(beams.sections(p));   
            end
    end
    for p=1:beams.nbeams
            for s=1:beams.disc
                sections.Ix(s+beams.disc*(p-1))=sections.Ix(beams.sections(p));   
            end
    end
    for p=1:beams.nbeams
            for s=1:beams.disc
                sections.E(s+beams.disc*(p-1))=sections.E(beams.sections(p));   
            end
    end
    for p=1:beams.nbeams
            for s=1:beams.disc
                sections.v(s+beams.disc*(p-1))=sections.v(beams.sections(p));   
            end
    end
end
