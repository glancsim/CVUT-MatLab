clearvars;
uqlab;

% Definice hmotnosti mužů v ČR (normální rozdělení)
InputOpts.Marginals(1).Type = 'Gaussian';     % Normální rozdělení
InputOpts.Marginals(1).Parameters = [85, 12]; % Průměr = 85 kg, Směrodatná odchylka = 12 kg

% Nastavení vzorkovací metody pro celý model
InputOpts.Sampling.Method = 'MC'; % Použití Monte Carlo vzorkování

% Vytvoření vstupního modelu
myInput = uq_createInput(InputOpts);

% Generování 1000 vzorků pro 4 osoby
X = uq_getSample(myInput, 1000*4, 'MC'); % Tady je klíčové přidat 'MC'
X = reshape(X(:,1), 1000, 4);

% Sečteme váhy osob ve výtahu
TotalWeight = sum(X, 2);

% Vykreslení histogramu celkových hmotností
figure;
histogram(TotalWeight, 'Normalization', 'pdf');
title('Celková hmotnost 4 mužů ve výtahu')
xlabel('Hmotnost [kg]'); ylabel('Pravděpodobnostní hustota')

% Výpočet 99% kvantilu (max očekávané zatížení pro bezpečný návrh)
LiftCapacity = quantile(TotalWeight, 0.99);

fprintf('Doporučená nosnost výtahu pro 4 muže: %.2f kg\n', LiftCapacity);
