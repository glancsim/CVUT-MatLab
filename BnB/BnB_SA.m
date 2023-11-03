clc;clear

%%%%%%%%%%%%%%%%%
% Definice lineárních omezení
linear_constraints = @(x) [-20*x(1) - 10*x(2) + 75; 12*x(1) + 7*x(2) - 55; 25*x(1) + 10*x(2) - 90];

% Definice cílové funkce
objective_function = @(x) -20*x(1) -10*x(2) + sum(linear_constraints(x) > 0) * 1000;

% Počáteční řešení
initial_solution = [0,0];

% Rozsah hodnot proměnných (lower_bound a upper_bound jsou vektory o stejné délce jako počet proměnných)
lower_bound = [2,0];
upper_bound = [2,6];

% Počáteční teplota
initial_temperature = 1000;

% Nastavení simulovaného žíhání
options = optimoptions('simulannealbnd', 'TolFun', 1e-6);

% Volání funkce simulannealbnd
[x_optimal, fval] = simulannealbnd(objective_function, initial_solution, lower_bound, upper_bound, options);

x_optimal
% fval

fvalObj = -20*x_optimal(1) -10*x_optimal(2)
linear_constraints(x_optimal)

