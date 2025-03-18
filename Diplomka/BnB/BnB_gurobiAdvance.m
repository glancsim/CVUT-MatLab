clc;
clear;
startup
yalmip('clear')

% Define variables
x = intvar(5, 1);

% Define constraints 
Constraints = [x(1) + x(2) + x(3) + x(4) + x(5) <= 10, ...
               2 * x(1) + 3 * x(2) + 4 * x(3) + x(4) - x(5) >= 10, ...
               0 <= x(1) <= 5, ...
               0 <= x(2) <= 5, ...
               0 <= x(3) <= 5, ...
               0 <= x(4) <= 5, ...
               0 <= x(5) <= 5];

% Define an objective
Objective = -x(1) - x(2) - 2 * x(3) - 3 * x(4) - 4 * x(5);

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