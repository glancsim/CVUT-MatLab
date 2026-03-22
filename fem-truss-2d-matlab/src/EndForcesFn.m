function [endForces, displacements] = EndForcesFn(stiffnesMatrix, endForces, transformationMatrix, elements)
% EndForcesFn  Solve K*u=f and compute member axial forces.
%
% Solves the global system K * u = f for nodal displacements, then
% computes the axial force in each member from elongation.
%
% Sign convention:  N > 0 = TENSION,  N < 0 = COMPRESSION.
%
% INPUTS:
%   stiffnesMatrix.global   - sparse (ndofs x ndofs) global stiffness matrix K
%   endForces.global        - (ndofs x 1) global load vector f
%   transformationMatrix.matrices  - cell of 4x4 T matrices
%   transformationMatrix.lengths   - (1 x nelement) element lengths [m]
%   elements.codeNumbers    - (nelement x 4) global DOF code numbers
%   elements.sections.A, .E - cross-section properties per element
%   elements.nelement       - number of elements
%
% OUTPUTS:
%   endForces
%     .global  - (ndofs x 1) load vector (unchanged)
%     .local   - (4 x nelement) element forces in local coordinates
%                Row 1: N [N]  axial force at head (positive = tension)
%                Row 2: 0      (no transverse force in a truss)
%                Row 3: -N [N] axial force at end  (equilibrium)
%                Row 4: 0
%   displacements
%     .global  - (ndofs x 1) free-DOF displacements [m]
%     .local   - (2 x nelement) axial displacements [u1_axial; u2_axial] [m]
%
% (c) S. Glanc, 2025

% Solve K * u = f
K = stiffnesMatrix.global;
f = endForces.global;
u = K \ f;

displacements.global = u;

ne = elements.nelement;
d_local = zeros(2, ne);
f_local = zeros(4, ne);

for cp = 1:ne
    T      = transformationMatrix.matrices{cp};
    L      = transformationMatrix.lengths(cp);
    E      = elements.sections.E(cp);
    A      = elements.sections.A(cp);
    kcisla = elements.codeNumbers(cp, :);

    % Extract global displacements for this element (0 for constrained DOFs)
    u_elem = zeros(4, 1);
    for i = 1:4
        if kcisla(i) > 0
            u_elem(i) = u(kcisla(i));
        end
    end

    % Transform to local (axial/transverse) coordinates
    u_loc = T * u_elem;
    d_local(:, cp) = [u_loc(1); u_loc(3)];  % axial displacements

    % Axial force: N = EA/L * (u_end_axial - u_head_axial)
    % Positive = tension (member elongated)
    N = (E * A / L) * (u_loc(3) - u_loc(1));

    f_local(:, cp) = [N; 0; -N; 0];
end

displacements.local = d_local;
endForces.local     = f_local;
end
