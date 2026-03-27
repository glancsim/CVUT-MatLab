function stiffnesMatrix = stiffnessMatrixFn(elements, transformationMatrix)
% stiffnessMatrixFn  Assemble global stiffness matrix for a 2D truss.
%
% Each element contributes a 4x4 local stiffness matrix:
%
%   k_local = EA/L * [1, 0, -1, 0;
%                     0, 0,  0, 0;
%                    -1, 0,  1, 0;
%                     0, 0,  0, 0]
%
% Transformed to global coordinates: k_global = T' * k_local * T
% then assembled into the global stiffness matrix using code numbers.
% DOFs with code number 0 (constrained) are skipped.
%
% INPUTS:
%   elements.sections.A, .E  - section properties per element
%   elements.codeNumbers     - (nelement x 4) global DOF numbers
%   elements.ndofs           - total number of free DOFs
%   transformationMatrix.matrices  - cell of 4x4 T matrices
%   transformationMatrix.lengths   - element lengths
%
% OUTPUTS:
%   stiffnesMatrix.global  - sparse (ndofs x ndofs) global K
%   stiffnesMatrix.local   - cell(1, nelement) local 4x4 K matrices
%
% (c) S. Glanc, 2025

ne     = elements.nelement;
ndofs  = elements.ndofs;
K_global = sparse(ndofs, ndofs);
K_local  = cell(1, ne);

for cp = 1:ne
    L   = transformationMatrix.lengths(cp);
    T   = transformationMatrix.matrices{cp};
    E   = elements.sections.E(cp);
    A   = elements.sections.A(cp);

    % Local stiffness matrix (4x4, axial only)
    EA_L = E * A / L;
    k = EA_L * [1, 0, -1, 0;
                0, 0,  0, 0;
               -1, 0,  1, 0;
                0, 0,  0, 0];

    % Transform to global coordinates
    k_g = T' * k * T;
    K_local{cp} = k_g;

    % Assemble into global matrix
    kcisla = elements.codeNumbers(cp, :);
    for i = 1:4
        if kcisla(i) > 0
            for j = 1:4
                if kcisla(j) > 0
                    K_global(kcisla(i), kcisla(j)) = ...
                        K_global(kcisla(i), kcisla(j)) + k_g(i, j);
                end
            end
        end
    end
end

stiffnesMatrix.global = K_global;
stiffnesMatrix.local  = K_local;
end
