clc;clear;startup
% It's good practice to start by clearing YALMIPs internal database 
% Every time you call sdpvar etc, an internal database grows larger
yalmip('clear')

% Define variables
x = intvar(2,1);

% Define constraints 
Constraints = [-20*x(1) - 10*x(2) + 75 <= 0   ,...
                12*x(1) +  7*x(2) - 55 <= 0   ,...
                25*x(1) + 10*x(2) - 90 <= 0   ,...
                0 <= x(1) <= 3             ,...
                0 <= x(2) <= 6             ];

% Define an objective
Objective = -20*x(1) -10*x(2);

% Set some options for YALMIP and solver
options = sdpsettings('solver', 'gurobi', 'gurobi.MIPFocus', 0);


% Register the callback function
options.gurobi.Callback = @(Model, opts, info) myCallback(Model, opts, info);

% Solve the problem
sol = optimize(Constraints, Objective, options);

% Analyze error flags
if sol.problem == 0
    % Extract and display values
    solutionX = value(x)
else
    display('Hmm, something went wrong!');
    sol.info
    yalmiperror(sol.problem)
end

% Define the callback function
function myCallback(Model, options, info)
    if info.MIPNODES > 0
        disp(['MIP node count: ' num2str(info.MIPNODES)]);
        disp(['MIP relative gap: ' num2str(info.MIPRELATIVEGAP)]);
    end
end

