clearvars;
uqlab;

% Definice hmotnosti mužů (normální rozdělení)
InputOpts.Marginals(1).Type = 'Gaussian';     % Normální rozdělení
InputOpts.Marginals(1).Parameters = [85, 12]; % Průměr = 85 kg, Směrodatná odchylka = 12 kg

% Definice hmotnosti žen (normální rozdělení)
InputOpts.Marginals(2).Type = 'Gaussian';
InputOpts.Marginals(2).Parameters = [70, 10]; % Průměr = 70 kg, Směrodatná odchylka = 10 kg

% Nastavení vzorkovací metody
InputOpts.Sampling.Method = 'MC';

% Vytvoření vstupního modelu
myInput = uq_createInput(InputOpts);

% Počet simulací
N = 1000;
num_people = 4; % Počet lidí ve výtahu

% Generování hmotností mužů a žen
X_men = uq_getSample(myInput, N * num_people, 'MC'); % 1000x4 vzorků pro muže i ženy
X_women = uq_getSample(myInput, N * num_people, 'MC');

% Matice rozměru (N, 4) pro muže a ženy
X_men = reshape(X_men(:,1), N, num_people);   % První sloupec jsou muži
X_women = reshape(X_women(:,2), N, num_people); % Druhý sloupec jsou ženy

% Náhodné rozhodnutí, zda je osoba muž (1) nebo žena (0)
randomSelection = rand(N, num_people) < 0.5; % 50% šance být muž nebo žena

% Sestavení matice hmotností
X = X_men .* randomSelection + X_women .* (~randomSelection);

% Sečteme váhy osob ve výtahu
TotalWeight = sum(X, 2);

% Histogram celkové hmotnosti
figure;
histogram(TotalWeight, 'Normalization', 'pdf');
title('Celková hmotnost 4 osob ve výtahu (muži + ženy)')
xlabel('Hmotnost [kg]'); ylabel('Pravděpodobnostní hustota')

% Výpočet 99% kvantilu (bezpečná nosnost výtahu)
LiftCapacity = quantile(TotalWeight, 0.99);

fprintf('Doporučená nosnost výtahu pro 4 osoby (muži i ženy): %.2f kg\n', LiftCapacity);
