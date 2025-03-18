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
num_people = 4; % Počet mužů ve výtahu

% Generování vzorků pro muže
X_men = uq_getSample(myInput, N * num_people, 'MC');  
X_men = reshape(X_men, N, num_people); 

% Určení 90. percentilu (extrémní hmotnosti)
high_weight_threshold = quantile(X_men(:), 0.90);

% Filtrace pouze mužů, kteří jsou nad tímto limitem (extrémní vzorek)
X_extreme = X_men;
X_extreme(X_extreme < high_weight_threshold) = high_weight_threshold;

% Výpočet celkové hmotnosti ve výtahu v extrémním případě
TotalWeightExtreme = sum(X_extreme, 2);

% Kritická mez přetížení
critical_weight = 420; % Například 350 kg jako maximální nosnost

% Výpočet pravděpodobnosti přetížení v extrémním případě
prob_overload_extreme = mean(TotalWeightExtreme > critical_weight) * 100;

% Histogram celkové hmotnosti v extrémních případech
figure;
histogram(TotalWeightExtreme, 'Normalization', 'pdf', 'FaceColor', 'r'); hold on;
xline(critical_weight, 'b', 'LineWidth', 2, 'Label', 'Max nosnost 420 kg', 'FontSize', 12);
title('Extrémní přetížení výtahu - 90. percentil hmotností')
xlabel('Hmotnost [kg]'); ylabel('Pravděpodobnostní hustota')
legend('Distribuce extrémních hmotností', 'Kritická mez')

% Výpis výsledku
fprintf('Pravděpodobnost přetížení výtahu v extrémním případě (nad %.2f kg): %.2f%%\n', critical_weight, prob_overload_extreme);
fprintf('Minimální hmotnost muže v této simulaci: %.2f kg\n', high_weight_threshold);
