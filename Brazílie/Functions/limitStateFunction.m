function g = limitStateFunction(X)
% limitStateFunction - Limitní funkce pro pravděpodobnostní analýzu spolehlivosti
%   g = limitStateFunction(X)
%
% Inputs:
%   X - matice vstupních hodnot, kde každý řádek představuje jeden vzorek
%       a sloupce odpovídají jednotlivým proměnným v tomto pořadí:
%       [f_y, A, G, Q, theta_R, theta_E]
%
% Output:
%   g - hodnota limitní funkce, kde g < 0 znamená poruchu

% Extrakce hodnot z matice X
f_y = X(:,1);     % Mez kluzu
A = X(:,2);       % Průřezová plocha
G_s = X(:,3);       % Stálé zatížení
G_p = X(:,4);       % Stálé zatížení
Q = X(:,5);       % Proměnné zatížení (sníh)
theta_R = X(:,6); % Nejistota modelu únosnosti
theta_E = X(:,7); % Nejistota modelu zatížení

% Výpočet únosnosti
R = f_y .* A;

% Výpočet účinků zatížení
G = G_s + G_p;
E = G + Q;

% Limitní funkce
% g(x) = θ_R * R - θ_E * E
g = theta_R .* R - theta_E .* E;
end