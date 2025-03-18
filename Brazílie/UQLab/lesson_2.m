clearvars;
uqlab;

% Definice různých rozdělení
InputOpts.Marginals(1).Type = 'Gaussian';    % Normální
InputOpts.Marginals(1).Parameters = [0, 1];  % [střední hodnota, směrodatná odchylka]

InputOpts.Marginals(2).Type = 'Uniform';     % Rovnoměrné
InputOpts.Marginals(2).Parameters = [5, 10]; % [min, max]

InputOpts.Marginals(3).Type = 'Exponential'; % Exponenciální
InputOpts.Marginals(3).Parameters = 2;       % Lambda (1/průměr)

InputOpts.Marginals(4).Type = 'Lognormal';   % Lognormální
InputOpts.Marginals(4).Parameters = [0, 1];  % [log-průměr, log-směrodatná odchylka]

InputOpts.Marginals(5).Type = 'Beta';        % Beta rozdělení
InputOpts.Marginals(5).Parameters = [2, 5];  % [alpha, beta]

InputOpts.Marginals(6).Type = 'Weibull';     % Weibull
InputOpts.Marginals(6).Parameters = [2, 1];  % [shape, scale]

% Vytvoření modelu vstupních proměnných
myInput = uq_createInput(InputOpts);

% Generování 1000 vzorků pro každé rozdělení
X = uq_getSample(100000);

% Vykreslení histogramů vedle sebe
figure;
distributionNames = {'Normální', 'Rovnoměrné', 'Exponenciální', 'Lognormální', 'Beta', 'Weibull'};

for i = 1:6
    subplot(2,3,i);
    histogram(X(:,i), 'Normalization', 'pdf');
    title(distributionNames{i});
end
