clc;clear;startup
% It's good practice to start by clearing YALMIPs internal database 
% Every time you call sdpvar etc, an internal database grows larger
yalmip('clear')

 profile on
% Define variables
x = intvar(1,1);
y = intvar(1,1);

% Define constraints 
Constraints = [-20*x - 10*y + 75 <= 0   ,...
                12*x +  7*y - 55 <= 0   ,...
                25*x + 10*y - 90 <= 0   ,...
                0 <= x <= 3             ,...
                0 <= x <= 6             ];

% Define an objective
Objective = -20*x -10*y;

% Set some options for YALMIP and solver
options = sdpsettings('solver','gurobi');
options.gurobi.Method = 1;

% Solve the problem
sol = optimize(Constraints,Objective,options);

% Analyze error flags
if sol.problem == 0
 % Extract and display value
 solutionX = value(x)
 solutionX = value(y)
else
 display('Hmm, something went wrong!');
 sol.info
 yalmiperror(sol.problem)
end

profile off
profile viewer
