function [displacements, reactions, element_forces] = frame2D_FEM(nodes, elements, constraints, loads)
    % 2D Frame Structure Finite Element Analysis with multiple load cases
    % Input:
    %   nodes: [node_id, x, y] - Node coordinates
    %   elements: [elem_id, node1, node2, E, A, I] - Element properties
    %   constraints: [node_id, ux, uy, theta] - Boundary conditions (1=fixed, 0=free)
    %   loads: {loadcase1, loadcase2, ...} - Cell array of load cases
    %          Each loadcase is a matrix [node_id, Fx, Fy, M]
    
    % Initialize global stiffness matrix
    ndof = size(nodes,1) * 3;  % 3 DOFs per node (ux, uy, theta)
    K = zeros(ndof);
    
    % Assemble global stiffness matrix
    for i = 1:size(elements,1)
        % Extract element properties
        n1 = elements(i,2);
        n2 = elements(i,3);
        E = elements(i,4);
        A = elements(i,5);
        I = elements(i,6);
        
        % Calculate element length and orientation
        x1 = nodes(n1,2); y1 = nodes(n1,3);
        x2 = nodes(n2,2); y2 = nodes(n2,3);
        L = sqrt((x2-x1)^2 + (y2-y1)^2);
        c = (x2-x1)/L;  % cos(theta)
        s = (y2-y1)/L;  % sin(theta)
        
        % Element stiffness matrix in local coordinates
        k11 = E*A/L;
        k22 = 12*E*I/(L^3);
        k23 = 6*E*I/(L^2);
        k33 = 4*E*I/L;
        k44 = k11;
        k55 = k22;
        k66 = k33;
        
        ke = [
            k11  0    0    -k11  0     0;
            0    k22  k23  0    -k22   k23;
            0    k23  k33  0    -k23   k33/2;
            -k11 0    0    k44   0     0;
            0   -k22 -k23  0     k55  -k23;
            0    k23  k33/2 0   -k23   k66
        ];
        
        % Transformation matrix
        T = [
            c  s  0  0  0  0;
           -s  c  0  0  0  0;
            0  0  1  0  0  0;
            0  0  0  c  s  0;
            0  0  0 -s  c  0;
            0  0  0  0  0  1
        ];
        
        % Transform to global coordinates
        ke_global = T' * ke * T;
        
        % Assembly
        dof = [3*n1-2:3*n1, 3*n2-2:3*n2];
        K(dof,dof) = K(dof,dof) + ke_global;
    end
    
    % Identify constrained DOFs
    fixed_dofs = [];
    for i = 1:size(constraints,1)
        node = constraints(i,1);
        if constraints(i,2) == 1  % ux fixed
            fixed_dofs = [fixed_dofs, 3*node-2];
        end
        if constraints(i,3) == 1  % uy fixed
            fixed_dofs = [fixed_dofs, 3*node-1];
        end
        if constraints(i,4) == 1  % theta fixed
            fixed_dofs = [fixed_dofs, 3*node];
        end
    end
    free_dofs = setdiff(1:ndof, fixed_dofs);
    
    % Check if loads is a cell array (multiple load cases)
    if ~iscell(loads)
        loads = {loads};  % Convert single load case to cell array
    end
    
    num_load_cases = length(loads);
    
    % Initialize result arrays for each load case
    all_displacements = cell(num_load_cases, 1);
    all_reactions = cell(num_load_cases, 1);
    all_element_forces = cell(num_load_cases, 1);
    
    % Solve for each load case
    for lc = 1:num_load_cases
        % Apply loads for this load case
        F = zeros(ndof, 1);
        for i = 1:size(loads{lc}, 1)
            node = loads{lc}(i, 1);
            F(3*node-2:3*node) = loads{lc}(i, 2:4)';
        end
        
        % Solve system
        U = zeros(ndof, 1);
        U(free_dofs) = K(free_dofs, free_dofs) \ F(free_dofs);
        
        % Calculate reactions
        R = K * U - F;
        
        % Calculate element forces
        element_forces_lc = zeros(size(elements, 1), 6);  % [N1 V1 M1 N2 V2 M2]
        for i = 1:size(elements, 1)
            n1 = elements(i, 2);
            n2 = elements(i, 3);
            dof = [3*n1-2:3*n1, 3*n2-2:3*n2];
            u_e = U(dof);
            
            % Element properties and transformation
            x1 = nodes(n1, 2); y1 = nodes(n1, 3);
            x2 = nodes(n2, 2); y2 = nodes(n2, 3);
            L = sqrt((x2-x1)^2 + (y2-y1)^2);
            c = (x2-x1)/L;
            s = (y2-y1)/L;
            
            T = [
                c  s  0  0  0  0;
               -s  c  0  0  0  0;
                0  0  1  0  0  0;
                0  0  0  c  s  0;
                0  0  0 -s  c  0;
                0  0  0  0  0  1
            ];
            
            u_local = T * u_e;
            element_forces_lc(i, :) = (ke * u_local)';
        end
        
        % Reshape displacements for easier understanding
        disp_table = zeros(size(nodes, 1), 3);
        for i = 1:size(nodes, 1)
            disp_table(i, :) = U(3*i-2:3*i)';
        end
        
        % Store results for this load case
        all_displacements{lc} = disp_table;
        all_reactions{lc} = R;
        all_element_forces{lc} = element_forces_lc;
    end
    
    % Return results
    displacements = all_displacements;
    reactions = all_reactions;
    element_forces = all_element_forces;
end