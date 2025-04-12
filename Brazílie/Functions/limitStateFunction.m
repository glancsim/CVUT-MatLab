function g = limitStateFunction(X)
% limitStateFunction - Limitní funkce pro pravděpodobnostní analýzu spolehlivosti
%   g = limitStateFunction(X)
%
% Inputs:
%   X - matice vstupních hodnot, kde každý řádek představuje jeden vzorek
%       a sloupce odpovídají jednotlivým proměnným
%
% Output:
%   g - hodnota limitní funkce, kde g < 0 znamená poruchu

% Extrakce hodnot z matice X
f_y = X(:,1);     % Yeild strength
f_u = X(:,2);     % Ultimate tensile strength
A_s = X(:,3);       % Průřezová plocha
G_s = X(:,4);       % Stálé zatížení
G_p = X(:,5);       % Stálé zatížení
Q = X(:,6);       % Proměnné zatížení (sníh)
theta_Ry = X(:,7); % Nejistota modelu únosnosti fy
theta_Ru = X(:,8); % Nejistota modelu únosnosti fu
theta_E = X(:,9); % Nejistota modelu zatížení

% Redukce plochy
A_u = A_s .* 0.8;

% Výpočet únosnosti
R(:,1) = theta_Ry .* f_y .* A_s;
R(:,2) = theta_Ru .* f_u .* A_u;

R = min(R, [], 2);

% Výpočet účinků zatížení
G = G_s + G_p;
E = G + Q;

% Limitní funkce
% g(x) = θ_R * R - θ_E * E
g = R - theta_E .* E;
end