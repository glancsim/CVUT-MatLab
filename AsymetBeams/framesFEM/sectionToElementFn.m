% Prirazeni prurezovych charakteristik jednotlivym elementum kazdeho prutu 
%
% In: 
%   beams           .sections           - id průřezu z proměnné sections
%                   .disc               - počet elementů na prutu
%   sections        .A                  - plocha průřezu
%                   .Iy                 - Moment setrvačnosti okolo osy Y
%                   .Iz                 - Moment setrvačnosti okolo osy Z
%                   .Ix                 - Moment setrvačnosti okolo osy X
%                   .E                  - Youngův modul pružnosti elementu
%                   .v                  - Poissunův součinitel elementu
%
% Out:
%   elemSections 	.A                  - plocha průřezu
%                   .Iy                 - Moment setrvačnosti okolo osy Y
%                   .Iz                 - Moment setrvačnosti okolo osy Z
%                   .Ix                 - Moment setrvačnosti okolo osy X
%                   .E                  - Youngův modul pružnosti elementu
%                   .v                  - Poissunův součinitel elementu
%
% (c) S. Glanc, 2022

function [elemSections]=sectionToElementFn(sections,beams)

    for p=1:beams.nbeams
            for s=1:beams.disc
                elemSections.A(s+beams.disc*(p-1))=sections.A(beams.sections(p));   
            end
    end
    for p=1:beams.nbeams
            for s=1:beams.disc
                elemSections.Iy(s+beams.disc*(p-1))=sections.Iy(beams.sections(p));   
            end
    end
    for p=1:beams.nbeams
            for s=1:beams.disc
                elemSections.Iz(s+beams.disc*(p-1))=sections.Iz(beams.sections(p));   
            end
    end
    for p=1:beams.nbeams
            for s=1:beams.disc
                elemSections.Ix(s+beams.disc*(p-1))=sections.Ix(beams.sections(p));   
            end
    end
    for p=1:beams.nbeams
            for s=1:beams.disc
                elemSections.E(s+beams.disc*(p-1))=sections.E(beams.sections(p));   
            end
    end
    for p=1:beams.nbeams
            for s=1:beams.disc
                elemSections.v(s+beams.disc*(p-1))=sections.v(beams.sections(p));   
            end
    end
end
