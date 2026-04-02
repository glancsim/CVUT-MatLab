function [localEndForces, displacements] = EndForcesFn(stiffnesMatrix, endForces, transformationMatrix, elements)
% EndForcesFn  Solve K*u = f and compute internal element forces.
%
% INPUTS:
%   stiffnesMatrix.global  - (ndofs x ndofs) assembled K
%   stiffnesMatrix.local   - cell(1,ne) local 6x6 K per element
%   endForces.global       - (ndofs x 1) global force vector
%   transformationMatrix.matrices - cell of 6x6 T matrices
%   elements.codeNumbers   - (nelement x 6)
%   elements.nelement, .ndofs
%
% OUTPUTS:
%   localEndForces  - (6 x nelement) internal forces in local coords
%                     row 1: N   (axial force, + = tension)
%                     row 2: Vy  (shear, transverse in local y—here z plane)
%                     row 3: My  (bending moment at head)
%                     row 4: N   at end
%                     row 5: Vy  at end
%                     row 6: My  at end
%   displacements.global  - (ndofs x 1) free-DOF displacements
%   displacements.local   - (6 x nelement) local element displacements
%
% (c) S. Glanc, 2026

ne    = elements.nelement;
ndofs = elements.ndofs;

% Solve global system
r_global = stiffnesMatrix.global \ endForces.global;
displacements.global = r_global;

% Gather per-element global displacements, transform to local
r_local = zeros(6, ne);
for j = 1:ne
    kcisla = elements.codeNumbers(j, :);
    r_e    = zeros(6, 1);
    for i = 1:6
        if kcisla(i) > 0
            r_e(i) = r_global(kcisla(i));
        end
    end
    T        = transformationMatrix.matrices{j};
    r_local(:, j) = T * r_e;
end
displacements.local = r_local;

% Compute local internal forces: f_local = K_local * u_local
localEndForces = zeros(6, ne);
for i = 1:ne
    localEndForces(:, i) = stiffnesMatrix.local{i} * r_local(:, i);
end
end
