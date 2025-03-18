clearvars;
uqlab;

% Definice hmotnosti mužů (normální rozdělení)
InputOpts.Marginals(1).Type = 'Gaussian';     
InputOpts.Marginals(1).Parameters = [85, 12]; % Průměr = 85 kg, Směrodatná odchylka = 12 kg

% Nastavení vzorkovací metody
InputOpts.Sampling.Method = 'MC';

% Vytvoření vstupního modelu
myInput = uq_createInput(InputOpts);

% Počet simulací (větší vzorek pro lepší přesnost)
N = 100000;
num_people = 4; % Počet mužů ve výtahu

% Generování vzorků pro muže
X_men = uq_getSample(myInput, N * num_people, 'MC');  
X_men = reshape(X_men, N, num_people); 

% Výpočet celkové hmotnosti ve výtahu
TotalWeight = sum(X_men, 2);

% Nastavení kritické nosnosti výtahu
critical_weight = 400; % Například 350 kg jako maximální bezpečná nosnost

% Výpočet pravděpodobnosti přetížení
prob_overload = mean(TotalWeight > critical_weight) * 100;

% Histogram celkové hmotnosti s vyznačenou hranicí přetížení
figure;
histogram(TotalWeight, 'Normalization', 'pdf', 'FaceColor', 'b'); hold on;
xline(critical_weight, 'r', 'LineWidth', 2, 'Label', 'Max nosnost 400 kg', 'FontSize', 12);
title('Celková hmotnost 4 mužů ve výtahu')
xlabel('Hmotnost [kg]'); ylabel('Pravděpodobnostní hustota')
legend('Distribuce hmotnosti', 'Kritická mez')

% Výpis pravděpodobnosti přetížení
fprintf('Pravděpodobnost, že výtah bude přetížen (více než %.0f kg): %.2f%%\n', critical_weight, prob_overload);
