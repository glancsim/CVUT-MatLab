function stiffnesMatrix = stiffnessMatrixFn(elements, transformationMatrix)
% stiffnessMatrixFn  Assemble global stiffness matrix for a 2D frame.
%
% 2D Euler-Bernoulli beam element in the XZ plane.
% Each element has 6 DOFs (per node: ux, uz, ry):
%
%   Local DOF order: [u1, w1, θ1,  u2, w2, θ2]
%
% Local stiffness matrix (6x6):
%
%   K_local = E * [A/L             ...
%                       12Iz/L³  ±6Iz/L²  ...
%                             4Iz/L    ...  2Iz/L]  (Euler-Bernoulli)
%
% Hinges are handled via static condensation (releaseCondenseFn) before
% the local matrix is stored and transformed to global coordinates.
%
% INPUTS:
%   elements.sections.A, .Iz, .E   - section properties per element
%   elements.codeNumbers           - (nelement x 6)
%   elements.ndofs                 - total free DOFs
%   elements.releases              - (nelement x 2) logical/int
%                                    col 1 = hinge at head, col 2 = hinge at end
%   transformationMatrix.matrices  - cell of 6x6 T matrices
%   transformationMatrix.lengths   - element lengths
%
% OUTPUTS:
%   stiffnesMatrix.global  - sparse (ndofs x ndofs)
%   stiffnesMatrix.local   - cell(1, nelement) 6x6 local K (after condensation)
%
% (c) S. Glanc, 2026

ne      = elements.nelement;
ndofs   = elements.ndofs;
K_global = sparse(ndofs, ndofs);
K_local  = cell(1, ne);

for cp = 1:ne
    L   = transformationMatrix.lengths(cp);
    T   = transformationMatrix.matrices{cp};
    E   = elements.sections.E(cp);
    A   = elements.sections.A(cp);
    Iz  = elements.sections.Iz(cp);

    EA_L  = E * A  / L;
    EI_L3 = E * Iz / L^3;
    EI_L2 = E * Iz / L^2;
    EI_L  = E * Iz / L;

    % Local 6x6 stiffness matrix [u1, w1, θ1, u2, w2, θ2]
    K = [ EA_L,        0,          0,  -EA_L,       0,          0;
             0,  12*EI_L3,   6*EI_L2,      0, -12*EI_L3,   6*EI_L2;
             0,   6*EI_L2,    4*EI_L,      0,  -6*EI_L2,    2*EI_L;
         -EA_L,        0,          0,   EA_L,       0,          0;
             0, -12*EI_L3,  -6*EI_L2,     0,  12*EI_L3,  -6*EI_L2;
             0,   6*EI_L2,    2*EI_L,     0,  -6*EI_L2,    4*EI_L];

    % Apply hinge condensation if needed
    if isfield(elements, 'releases') && any(elements.releases(cp, :))
        K = releaseCondenseFn(K, elements.releases(cp, :));
    end

    K_local{cp} = K;

    % Transform to global and assemble
    Kg     = T' * K * T;
    kcisla = elements.codeNumbers(cp, :);
    for i = 1:6
        if kcisla(i) > 0
            for j = 1:6
                if kcisla(j) > 0
                    K_global(kcisla(i), kcisla(j)) = ...
                        K_global(kcisla(i), kcisla(j)) + Kg(i, j);
                end
            end
        end
    end
end

stiffnesMatrix.global = K_global;
stiffnesMatrix.local  = K_local;
end

% -------------------------------------------------------------------------
function K = releaseCondenseFn(K, rel)
% Static condensation of moment DOF at hinged ends.
%   rel(1) = hinge at head node → condense out DOF 3 (ry at head)
%   rel(2) = hinge at end  node → condense out DOF 6 (ry at end)
%
% The condensed rows/cols are zeroed so that EndForcesFn returns 0 moment.

    r = [];
    if rel(1), r = [r, 3]; end
    if rel(2), r = [r, 6]; end
    s = setdiff(1:6, r);
    K_cond     = K(s, s) - K(s, r) * (K(r, r) \ K(r, s));
    K          = zeros(6, 6);
    K(s, s)    = K_cond;
end
