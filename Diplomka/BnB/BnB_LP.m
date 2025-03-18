clc;clear

yalmip('clear')

% Define variables
x = sdpvar(2,1);

% Define constraints 
Constraints = [ -20*x(1) - 10*x(2) <= -75      ;...
                12*x(1) + 7*x(2) <= 55      ;...
                25*x(1) + 10*x(2) <= 90     ;...
                2 <= x(1)<=2                ;...
                0 <= x(2)<=6                ];
                
    
% Definice cílové funkce
Objective = -20*x(1) - 10*x(2);

% Řešení lineárního programu
options = sdpsettings('solver', 'linprog');
optimize(Constraints, Objective, options);

% Získání optimálního řešení
optimal_solution = value(x);
optimal_value = value(Objective);

optimal_solution
optimal_value

constraints =[ -20*optimal_solution(1) - 10*optimal_solution(2) + 75      ;...
                12*optimal_solution(1) + 7*optimal_solution(2) - 55      ;...
                25*optimal_solution(1) + 10*optimal_solution(2) - 90     ]

