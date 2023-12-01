% cd 'C:\GitHub\CVUT-MatLab\BnB'
clear;clc;startup;yalmip('clear')
%% 
% 

crossSectionsSet = [ 1.62; 1.80; 1.99; 2.13; 2.38; 2.62; 2.63; 2.88;...
                     2.93; 3.09; 3.13; 3.38; 3.47; 3.55; 3.63; 3.84;...
                     3.87; 3.88; 4.18; 4.22; 4.49; 4.59; 4.80; 4.97;...
                     5.12; 5.74; 7.22; 7.97; 11.50; 13.50; 13.90; 14.20;...
                     15.50; 16.00; 16.90; 18.80; 19.90; 22.00; 22.90;...
                     26.50; 30.00; 33.50];
na = numel(crossSectionsSet);
%% 
% 
%% Ground structure
% Nodes

nodes.x = [720; 720; 360; 360; 0; 0];                       % x coordinates of nodes
nodes.y = [360; 0; 360; 0; 360; 0];                       % y coordinates of nodes
nodes.z = [0;0;0;0;0;0];                       % z coordinates of nodes
nnodes  = numel(nodes.x);                           % number of nodes
% Elements

elements.nodes1 = [5;3;6;4;4;2;5;6;3;4];   % elements starting nodes
elements.nodes2 = [3;1;4;2;3;1;4;3;2;1];   % elements ending nodes
nelem = numel(elements.nodes1);  % number of elements  
nr = nelem;

plot([nodes.x(elements.nodes1) nodes.x(elements.nodes2)]', ...
     [nodes.y(elements.nodes1) nodes.y(elements.nodes2)]', ...
     'k','LineWidth',1);
hold on;
scatter(nodes.x, nodes.y, 'blue', 'filled', 'o');
axis equal;
xlim([min(nodes.x)-1,max(nodes.x)+1]);  % to avoid tight limits
ylim([min(nodes.y)-1,max(nodes.y)+1]);  % to avoid tight limits
hold off;
% Material and cross-section

elements.E = 10^4 ;    % Young moduli of individual elements
elements.Rho = 0.1 ;    
%% Boundary conditions
% Restricted displacements

kinematic.x.nodes = [5; 6];             % node indices with restricted x-direction displacements
kinematic.y.nodes = [5; 6];             % node indices with restricted y-direction displacements
kinematic.z.nodes = [1;2;3;4;5;6];          % node indices with restricted z-direction displacements
% Load

loads.x.nodes = [];             % node indices with x-direction forces
loads.x.value = [];             % magnitude of the x-direction forces
loads.y.nodes = [2;4];          % node indices with y-direction forces
loads.y.value = [-100;-100];          % magnitude of the y-direction forces 
loads.z.nodes = [];             % node indices with z-direction forces
loads.z.value = [];             % magnitude of the z-direction forces 
% Boundary conditions

dofs = true(nnodes,3);                % no kinematic boundary conditions
dofs(kinematic.x.nodes,1) = false;    % mark prevented movement in x-direction
dofs(kinematic.y.nodes,2) = false;    % mark prevented movement in y-direction
dofs(kinematic.z.nodes,3) = false;    % mark prevented movement in z-direction
dofs = reshape(dofs.',[],1);
nd = sum(dofs,"all");
%% Optimization parameters

maximumStress = 25;
minimumStress = -25;
maximumDisplacement = 2;
minimumDisplacement = -2;
% Design variables

x = binvar(nelem * na,1);
s = sdpvar(nelem*na,1);
u = sdpvar(nd,1);  
%% FEM

deltaX = nodes.x(elements.nodes2) - nodes.x(elements.nodes1);
deltaY = nodes.y(elements.nodes2) - nodes.y(elements.nodes1);
deltaZ = nodes.z(elements.nodes2) - nodes.z(elements.nodes1);
lengths = sqrt(deltaX.^2 + deltaY.^2 + deltaZ.^2);
cosinus = [deltaX./lengths deltaY./lengths deltaZ./lengths];
codeNumbers = [repmat(elements.nodes1,1,3) repmat(elements.nodes2,1,3)]*3-2 + repmat([0 1 2 0 1 2], nelem, 1);
staticMatrix = sparse(codeNumbers(:), ...
                      repmat(1:nelem,1,6), ...
                      [-cosinus(:,1); -cosinus(:,2); -cosinus(:,3); cosinus(:,1); cosinus(:,2); cosinus(:,3);], ...
                      nnodes*3, nelem);
matrixB = full (staticMatrix(dofs,:) );
%% Optimization problem formulation and solution

Fmin =  minimumStress * diag ( kron( ones(nr,1) , crossSectionsSet) );
Fmax =  maximumStress * diag ( kron( ones( nr,1) , crossSectionsSet) );
cmin = reshape((kron(elements.E*crossSectionsSet', 1 ./ lengths) .* (sum(((matrixB > 0) .* matrixB) .* minimumDisplacement)' + sum(((matrixB < 0) .* matrixB) .* maximumDisplacement)'))', 1, []);
Cmin = diag(cmin);
cmax = reshape((kron(elements.E*crossSectionsSet', 1 ./ lengths) .* (sum(((matrixB > 0) .* matrixB) .* maximumDisplacement)' + sum(((matrixB < 0) .* matrixB) .* minimumDisplacement)'))', 1, []);
Cmax = diag(cmax);
I = eye(nelem * na);
B = kron(matrixB, ones(1, na));
K = kron ( kron ((elements.E./lengths), crossSectionsSet), ones(nd,1)') .* B';

forceVector = sparse([loads.x.nodes*3-2; loads.y.nodes*3-1; loads.z.nodes*3], ...
                     1, ...
                     [loads.x.value; loads.y.value; loads.z.value ], ...
                     nnodes*3, 1);
f = forceVector(reshape(dofs.', 1, [])');
IM = zeros(nr, na * nr);
for j = 1:nr
        IM(j, na*(j-1)+1:na*(j)) = 1;
end
% Constraints

y = double2sdpvar(zeros(2*na*nr+ nd,1));
y(1:nr*na,1) = x;
y(1+nr*na:nr*na+nd,1) = u;
y(1+nr*na+nd:2*nr*na+nd,1) = s;
% Constraint 1: Inequality
% $$A_{ineq} y \leq b$$
% 
% *Matrix* $A_{ineq}$

Aineq = zeros(4*na*nr,2*nr*na+nd);
%% 
% _First collumn_

Aineq(1:nr*na,1:nr*na)              =  Fmin;
Aineq(1+nr*na:2*nr*na,1:nr*na)      = -Fmax;
Aineq(1+2*nr*na:3*nr*na,1:nr*na)    = -Cmin;
Aineq(1+3*nr*na:4*nr*na,1:nr*na)    =  Cmax;
%% 
% _Second collumn_

Aineq(1+2*nr*na:3*nr*na,1+nr*na:nr*na+nd)    =  K;
Aineq(1+3*nr*na:4*nr*na,1+nr*na:nr*na+nd)    = -K;
%% 
% _Third collumn_

Aineq(1:nr*na,1+nr*na+nd:2*nr*na+nd)              = -I;
Aineq(1+nr*na:2*nr*na,1+nr*na+nd:2*nr*na+nd)      =  I;
Aineq(1+2*nr*na:3*nr*na,1+nr*na+nd:2*nr*na+nd)    =  I;
Aineq(1+3*nr*na:4*nr*na,1+nr*na+nd:2*nr*na+nd)    = -I;
%% 
% *Vector* $b$

b = zeros(4*na*nr,1);
b(1+2*nr*na:3*nr*na,1) = -diag(Cmin);
b(1+3*nr*na:4*nr*na,1) =  diag(Cmax);
constIneq = [Aineq * y <= b]:'Nerovnost';
% Constraint 2: Equality
% $$A_{eq} y = b_{eq}$$
% 
% *Matrix* $A_{eq}$

Aeq = zeros(nd + nr,2*nr*na+nd);
Aeq(nd+1:nd+nr,1:nr*na) = IM;
Aeq(1:nd,nr*na+nd+1:nr*na+nd+nr*na) = B;

%% 
% *Vector* $b_{eq}$

beq = zeros(nd + nr,1);
beq(1:nd,1) = f;
beq(nd+1:nd+nr,1) = ones(nr,1);
constEq = [Aeq * y == beq]:'Rovnost';
% Constraint 3: Box constraints
% _*Lower bound*_

lb = zeros(nr*na*2+nd,1);
lb(1:nr*na) = 0;
lb(nr*na+1:nr*na + nd) = minimumDisplacement;
lb(nr*na+nd+1:nr*na*2+nd) = kron(minimumStress*ones(nr,1),crossSectionsSet);

%% 
% *Upper bound*

ub = zeros(nr*na*2+nd,1);
ub(1:nr*na) = 1;
ub(nr*na+1:nr*na + nd) = maximumDisplacement;
ub(nr*na+nd+1:nr*na*2+nd) = kron(maximumStress*ones(nr,1),crossSectionsSet);
%% 
% _*Box constraint*_

constBox = [(lb <= y)]:'Dolní mez' & [(y <= ub)]:'Horní mez';
% Objective function

m = elements.Rho * kron(lengths,ones(na,1))' .* kron(ones(nr,1),crossSectionsSet)';
M = sparse(1,nr*na*2 + nd);
M(1:nr*na) = m;
objective = M * y;
% Solution

ops = sdpsettings('solver', 'gurobi');  % Nastavení Gurobi solveru s metodou BnB
ops = sdpsettings(ops,'verbose',1,'debug',1);
constraints = [constIneq, constEq, constBox];  % Kombinace všech omezení
result = optimize(constraints, objective, ops)
%% Post-procesing
% Write solution

fprintf('Optimized objective: %f\n', value(objective));
vector = value(x) .* repmat(1:na, 1, nr)';
vector(value(x)==1)
% Plotting
% Plot the optimal design. Note that the dimensions are scaled.

crossSections = reshape(value(x), 10, 5)'*crossSectionsSet;
nonzeroAreas = value(crossSections)>0;
p = plot([nodes.x(elements.nodes1(nonzeroAreas)) nodes.x(elements.nodes2(nonzeroAreas))]',...
         [nodes.y(elements.nodes1(nonzeroAreas)) nodes.y(elements.nodes2(nonzeroAreas))]','k');
set(p, {'LineWidth'}, num2cell(10*value(crossSections(nonzeroAreas))/max(value(crossSections))));
hold on
scatter(nodes.x, nodes.y, 'blue', 'filled', 'o');
axis equal;
xlim([min(nodes.x)-1,max(nodes.x)+1]);  % to avoid tight limits
ylim([min(nodes.y)-1,max(nodes.y)+1]);  % to avoid tight limits

%% Basic FEM

crossSections = reshape(value(x), na, nr)'*crossSectionsSet
% 
% staticMatrix(dofs,:)*diag(elements.E.*crossSections./lengths) *staticMatrix(dofs,:)';
% 
% stiffnessMatrix= staticMatrix(dofs,:)* diag(elements.E.*crossSections./lengths) *staticMatrix(dofs,:)';
% displacements = stiffnessMatrix\f;