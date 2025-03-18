clearvars
uqlab % zajištění, že je UQLab spuštěný

% Definice náhodné proměnné (normální rozdělení)
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Parameters = [0, 1]; % Střední hodnota = 0, směrodatná odchylka = 1

% Vytvoření modelu vstupních proměnných
myInput = uq_createInput(InputOpts);

% Generování 5 náhodných vzorků
X = uq_getSample(500000)

% Zobrazení histogramu
histogram(X)
title('Histogram generovaných vzorků')
