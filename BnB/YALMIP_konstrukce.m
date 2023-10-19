clc; clear; startup;
% It's good practice to start by clearing YALMIPs internal database 
% Every time you call sdpvar etc, an internal database grows larger
yalmip('clear')

%  profile on
% Define variables
x = intvar(1, 2);

% Define constraints 
Constraints = [Truss01Fn(x,1),...
               Truss01Fn(x,2),...
               x(1) >= 0.1           ,...
               x(2) >= 0.1           ];
% Constraints = [conFn(x,1) >= 0]

% Define an objective
Objective = sum(x);

% Set some options for YALMIP and solver
options = sdpsettings('solver','gurobi');
% options.gurobi.Method = 1;

% Solve the problem
sol = optimize(Constraints,Objective,options);

% Analyze error flags
if sol.problem == 0
 % Extract and display value
 solutionX = value(x)
else
 display('Hmm, something went wrong!');
 sol.info
 yalmiperror(sol.problem)
end

