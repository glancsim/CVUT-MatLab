function transformationMatrix = transformationMatrixFn(elements)
% transformationMatrixFn  Build 4x4 transformation matrices for 2D truss elements.
%
% For each element the transformation matrix T maps local (axial) DOFs
% to global (x, z) DOFs:
%
%   u_local = T * u_global_element
%
% where the local DOF ordering is [u_axial_head, u_trans_head, u_axial_end, u_trans_end]
% and the global DOF ordering is [ux_head, uz_head, ux_end, uz_end].
%
%   T = [c,  s,  0,  0;
%       -s,  c,  0,  0;
%        0,  0,  c,  s;
%        0,  0, -s,  c]
%
% where c = Δx/L, s = Δz/L (direction cosines of member axis).
%
% INPUTS:
%   elements.vertex    - (nelement x 2) [Δx, Δz] per element
%
% OUTPUTS:
%   transformationMatrix.matrices  - cell(1, nelement), each 4x4 matrix T
%   transformationMatrix.lengths   - (1 x nelement) element lengths [m]
%
% (c) S. Glanc, 2025

ne = elements.nelement;
transformationMatrix.matrices = cell(1, ne);
transformationMatrix.lengths  = zeros(1, ne);

for cp = 1:ne
    dx = elements.vertex(cp, 1);
    dz = elements.vertex(cp, 2);
    L  = sqrt(dx^2 + dz^2);
    c  = dx / L;
    s  = dz / L;

    T = [c,  s,  0,  0;
        -s,  c,  0,  0;
         0,  0,  c,  s;
         0,  0, -s,  c];

    transformationMatrix.matrices{cp} = T;
    transformationMatrix.lengths(cp)  = L;
end
end
