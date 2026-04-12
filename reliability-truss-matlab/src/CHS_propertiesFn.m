function [A, i_radius] = CHS_propertiesFn(d, t)
% CHS_propertiesFn  Compute CHS cross-section properties from diameter and thickness.
%
% INPUTS:
%   d  - (1×n or n×1) outer diameters [m]
%   t  - (1×n or n×1) wall thicknesses [m]
%
% OUTPUTS:
%   A        - (1×n) cross-sectional areas [m²]
%   i_radius - (1×n) radii of gyration [m]
%
% (c) S. Glanc, 2026

d = d(:)';
t = t(:)';

d_i = d - 2*t;
A = pi/4 * (d.^2 - d_i.^2);
I = pi/64 * (d.^4 - d_i.^4);
i_radius = sqrt(I ./ A);

end
