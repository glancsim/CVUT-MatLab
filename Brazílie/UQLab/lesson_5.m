clearvars;
uqlab;

% Definice hmotnosti mužů (normální rozdělení)
InputOpts.Marginals(1).Type = 'Gaussian';     
InputOpts.Marginals(1).Parameters = [85, 12]; % Průměr = 85 kg, Směrodatná odchylka = 12 kg

% Definice hmotnosti žen (normální rozdělení)
InputOpts.Marginals(2).Type = 'Gaussian';
InputOpts.Marginals(2).Parameters = [70, 10]; % Průměr = 70 kg, Směrodatná odchylka = 10 kg

% Definice hmotnosti dětí (lognormální rozdělení)
InputOpts.Marginals(3).Type = 'Lognormal';
InputOpts.Marginals(3).Parameters = [log(35), 0.3]; % Průměr 35 kg, směrodatná odchylka ≈ 10 kg

% Nastavení vzorkovací metody
InputOpts.Sampling.Method = 'MC';

% Vytvoření vstupního modelu
myInput = uq_createInput(InputOpts);

% Počet simulací
N = 1000;
num_people = 4; % Počet lidí ve výtahu

% Generování hmotností pro všechny tři skupiny
X_men = uq_getSample(myInput, N * num_people, 'MC');   % Muži
X_women = uq_getSample(myInput, N * num_people, 'MC'); % Ženy
X_children = uq_getSample(myInput, N * num_people, 'MC'); % Děti

% Převod na matice rozměru (N, 4) pro každý typ cestujícího
X_men = reshape(X_men(:,1), N, num_people);
X_women = reshape(X_women(:,2), N, num_people);
X_children = reshape(X_children(:,3), N, num_people);

% Pravděpodobnost skupin (např. 40% mužů, 40% žen, 20% dětí)
menFraction = 0.45;  
womenFraction = 0.45;  
childrenFraction = 1 - (menFraction + womenFraction); % Zbytek jsou děti

% Náhodné přiřazení skupiny osobám ve výtahu
randomValues = rand(N, num_people);
menMask = randomValues < menFraction;
womenMask = (randomValues >= menFraction) & (randomValues < menFraction + womenFraction);
childrenMask = randomValues >= menFraction + womenFraction;

% Sestavení matice hmotností
X = X_men .* menMask + X_women .* womenMask + X_children .* childrenMask;

% Sečteme váhy osob ve výtahu
TotalWeight = sum(X, 2);

% Histogram celkové hmotnosti
figure;
histogram(TotalWeight, 'Normalization', 'pdf');
title('Celková hmotnost 4 osob ve výtahu (muži + ženy + děti)')
xlabel('Hmotnost [kg]'); ylabel('Pravděpodobnostní hustota')

% Výpočet 99% kvantilu (bezpečná nosnost výtahu)
LiftCapacity = quantile(TotalWeight, 0.99);

fprintf('Doporučená nosnost výtahu pro 4 osoby (muži, ženy, děti): %.2f kg\n', LiftCapacity);
