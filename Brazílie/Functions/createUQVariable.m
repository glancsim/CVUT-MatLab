function UQVar = createUQVariable(model, varName)
% createUQVariable - Vytvoří UQLab proměnnou na základě modelu
%
% Syntax:
%   UQVar = createUQVariable(model, varName)
%
% Inputs:
%   model   - struktura obsahující definici modelu s poli:
%             - nominal: nominální hodnota
%             - V_x: variační koeficient (v desetinném formátu)
%             - ratio: poměr
%             - Dist: typ rozdělení ('N' pro normální, 'LN' pro log-normální, 'Gumbel')
%   varName - název proměnné (string)
%
% Output:
%   UQVar   - struktura proměnné pro UQLab

% Výpočet parametrů
mean_value = model.nominal * model.ratio;
std_dev = mean_value * model.V_x;

% Vytvoření UQLab proměnné
UQVar = struct();
UQVar.Name = varName;

% Nastavení typu rozdělení a parametrů
switch model.Dist
    case 'Gaussian'  % Normální rozdělení
        UQVar.Type = 'Gaussian';
        UQVar.Parameters = [mean_value, std_dev];
        
    case 'Lognormal'  % Log-normální rozdělení
        UQVar.Type = 'Lognormal';
        
        % Přepočet parametrů pro log-normální rozdělení
        COV = model.V_x;
        mu_ln = log(mean_value / sqrt(1 + COV^2));
        sigma_ln = sqrt(log(1 + COV^2));
        
        UQVar.Parameters = [mu_ln, sigma_ln];
        
    case 'Gumbel'  % Gumbelovo rozdělení
        UQVar.Type = 'Gumbel';
        
        % Výpočet parametrů Gumbelova rozdělení
        % Gumbelovo rozdělení je charakterizováno dvěma parametry:
        % 1. μ (mu) - poloha (location parameter)
        % 2. β (beta) - měřítko (scale parameter)
        
        % Přibližný výpočet parametrů
        % Pro Gumbelovo rozdělení: 
        % μ (mu) = mean_value - 0.5772 * (std_dev * sqrt(6) / pi)
        % β (beta) = std_dev * sqrt(6) / pi
        mu_gumbel = mean_value - 0.5772 * (std_dev * sqrt(6) / pi);
        beta_gumbel = std_dev * sqrt(6) / pi;
        
        UQVar.Parameters = [mu_gumbel, beta_gumbel];
        
    otherwise
        error('Nepodporovaný typ rozdělení: %s', model.Dist);
end

end