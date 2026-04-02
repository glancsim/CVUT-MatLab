function sectionToElementFn_out = sectionToElementFn(sections, beams)
% sectionToElementFn  Expand per-beam section properties to per-element.
%
% INPUTS:
%   sections  - struct with fields A, Iz, E (each nsec x 1)
%   beams     - struct with fields: nbeams, disc, sections (index)
%
% OUTPUTS:
%   out.A, .Iz, .E  - (1 x nelement) section properties per element
%
% (c) S. Glanc, 2026

pos = 0;
for p = 1:beams.nbeams
    disc = beams.disc(p);
    idx  = beams.sections(p);
    for s = 1:disc
        sectionToElementFn_out.A( pos + s)  = sections.A(idx);
        sectionToElementFn_out.Iz(pos + s)  = sections.Iz(idx);
        sectionToElementFn_out.E( pos + s)  = sections.E(idx);
    end
    pos = pos + disc;
end
end
