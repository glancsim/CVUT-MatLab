function transformationMatrix = transformationMatrixFn(elements)
% transformationMatrixFn  Build 6x6 transformation matrices for 2D frame elements.
%
% Each element has 6 DOFs: [ux, uz, ry]_head  [ux, uz, ry]_end  (global)
% mapped to local [u_axial, u_transverse, ry]_head  [...] _end.
%
% The 6x6 transformation matrix T is block-diagonal with two 3x3 blocks:
%
%   t = [ c   s   0;
%        -s   c   0;
%         0   0   1]
%
% where c = Δx/L, s = Δz/L.
%
% INPUTS:
%   elements.vertex   - (nelement x 2) [Δx, Δz] per element
%
% OUTPUTS:
%   transformationMatrix.matrices  - cell(1, nelement), each 6x6 T
%   transformationMatrix.lengths   - (1 x nelement) lengths [m]
%
% (c) S. Glanc, 2026

ne = elements.nelement;
transformationMatrix.matrices = cell(1, ne);
transformationMatrix.lengths  = zeros(1, ne);

for cp = 1:ne
    dx = elements.vertex(cp, 1);
    dz = elements.vertex(cp, 2);
    L  = sqrt(dx^2 + dz^2);
    c  = dx / L;
    s  = dz / L;

    t = [ c,  s,  0;
         -s,  c,  0;
          0,  0,  1];

    T = zeros(6, 6);
    T(1:3, 1:3) = t;
    T(4:6, 4:6) = t;

    transformationMatrix.matrices{cp} = T;
    transformationMatrix.lengths(cp)  = L;
end
end
