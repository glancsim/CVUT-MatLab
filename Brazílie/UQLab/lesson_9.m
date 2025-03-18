clearvars;
uqlab;

% Definice hmotnosti mužů (normální rozdělení)
InputOpts.Marginals(1).Type = 'Gaussian';     
InputOpts.Marginals(1).Parameters = [85, 12]; % Průměr = 85 kg, Směrodatná odchylka = 12 kg

% Nastavení vzorkovací metody
InputOpts.Sampling.Method = 'MC';

% Vytvoření vstupního modelu
myInput = uq_createInput(InputOpts);

% Počet simulací
N = 100000;
num_people = 4; % Počet lidí ve výtahu

% Generování vzorků pro muže
X_men = uq_getSample(myInput, N * num_people, 'MC');  
X_men = reshape(X_men, N, num_people); 

% Výpočet celkové hmotnosti ve výtahu
TotalWeight = sum(X_men, 2);

% Testované varianty nosnosti výtahu (300 až 500 kg po 25 kg krocích)
lift_capacities = 350:25:700;
overload_probs = zeros(size(lift_capacities)); % Pole pro pravděpodobnosti přetížení
lift_costs = zeros(size(lift_capacities)); % Pole pro ceny výtahů

% Výpočet pravděpodobnosti přetížení a ceny výtahu pro každou nosnost
for i = 1:length(lift_capacities)
    critical_weight = lift_capacities(i);
    overload_probs(i) = mean(TotalWeight > critical_weight) * 100; % Přetížení v %
    
    % Výpočet ceny výtahu
    lift_costs(i) = 500000 * (1 + ((critical_weight - 300) / 10));
end

% Graf: Pravděpodobnost přetížení vs. Nosnost
figure;
yyaxis left
plot(lift_capacities, overload_probs, '-o', 'LineWidth', 2, 'MarkerSize', 8);
ylabel('Pravděpodobnost přetížení [%]')
xlabel('Nosnost výtahu [kg]')
title('Analýza návrhu výtahu: Přetížení vs. Náklady')
grid on

% Graf: Cena výtahu vs. Nosnost
yyaxis right
plot(lift_capacities, lift_costs / 1000, '-s', 'LineWidth', 2, 'MarkerSize', 8);
ylabel('Cena výtahu [tisíce Kč]')

legend('Pravděpodobnost přetížení', 'Cena výtahu')

% Výpis optimální nosnosti
[~, opt_index] = min(lift_costs(overload_probs < 1)); % Nejnižší cena při <1% přetížení
opt_capacity = lift_capacities(opt_index);
opt_price = lift_costs(opt_index);

fprintf('Optimální nosnost výtahu pro méně než 1%% přetížení: %d kg\n', opt_capacity);
fprintf('Cena tohoto výtahu: %.2f Kč\n', opt_price);
