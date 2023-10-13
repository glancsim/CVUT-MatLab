clc 
clear
% Účelová funkce
f = @(x1, x2) -20*x1 - 10*x2;

% Omezující podmínky
g1 = @(x1, x2) -20*x1 - 10*x2 + 75;
g2 = @(x1, x2) 12*x1 + 7*x2 - 55;
g3 = @(x1, x2) 25*x1 + 10*x2 - 90;

% Diskrétní proměnné
x1_values = [0, 1, 2, 3];
x2_values = [0, 1, 2, 3, 4, 5, 6];

% Připravené prohledávání stromové struktury
best_solution = Inf;
best_x1 = 0;
best_x2 = 0;

branch_and_bound(f, g1, g2, g3, x1_values, x2_values, best_solution, 0, 0);

function branch_and_bound(f, g1, g2, g3, x1_values, x2_values, best_solution, depth, current_cost)
    if depth == length(x1_values)
        for i = length(x1_values):-1:1
            for j = length(x2_values):-1:1
                iter = iter + 1 
                x1 = x1_values(i);
                x2 = x2_values(j);
%                 G1  = g1(x1, x2) 
%                 G2  = g2(x1, x2)
%                 G3  = g3(x1, x2)
%                 F   =   f(x1, x2)
%                 disp('====================')
                if g1(x1, x2) <= 0 && g2(x1, x2) <= 0 && g3(x1, x2) <= 0
                    current_cost = f(x1, x2);
                    if current_cost < best_solution
                        best_solution = current_cost; % Uložení nejlepšího řešení
                        best_x1 = x1; % Uložení x1 pro nejlepší řešení
                        best_x2 = x2; % Uložení x2 pro nejlepší řešení
                    end
                end
            end
        end
    else
        for i = length(x1_values):-1:1
            for j = length(x2_values):-1:1
                x1 = x1_values(i);
                x2 = x2_values(j);
                if g1(x1, x2) <= 0 && g2(x1, x2) <= 0 && g3(x1, x2) <= 0
                    branch_and_bound(f, g1, g2, g3, x1_values, x2_values, best_solution, depth + 1, current_cost + f(x1, x2));
                end
            end
        end
    end
end
