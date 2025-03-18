clearvars;
uqlab;

% Definice hmotnosti mužů (normální rozdělení)
InputOpts.Marginals(1).Type = 'Gaussian';     
InputOpts.Marginals(1).Parameters = [85, 12]; % Průměr = 85 kg, Směrodatná odchylka = 12 kg

% Nastavení vzorkovací metody
InputOpts.Sampling.Method = 'MC';

% Vytvoření vstupního modelu
myInput = uq_createInput(InputOpts);

% Počet simulací (větší vzorek pro vyšší přesnost)
N = 100000;
num_people = 1; % Počet mužů ve výtahu

% Generování vzorků pro muže
X_men = uq_getSample(myInput, N * num_people, 'MC');  
X_men = reshape(X_men, N, num_people); 

% Výpočet celkové hmotnosti ve výtahu
TotalWeight = sum(X_men, 2);

% Výpočet bezpečné nosnosti výtahu pro 99,9% bezpečnost
safe_weight_999 = quantile(TotalWeight, 0.999);

% Histogram celkové hmotnosti s vyznačením bezpečné nosnosti
figure;
histogram(TotalWeight, 'Normalization', 'pdf', 'FaceColor', 'b'); hold on;
xline(safe_weight_999, 'r', 'LineWidth', 2, 'Label', 'Bezpečná nosnost pro 99.9%', 'FontSize', 12);
title('Celková hmotnost 4 mužů ve výtahu')
xlabel('Hmotnost [kg]'); ylabel('Pravděpodobnostní hustota')
legend('Distribuce hmotnosti', 'Bezpečná nosnost')

% Výpis výsledku
fprintf('Optimální nosnost výtahu pro 99,9%% bezpečnost: %.2f kg\n', safe_weight_999);
