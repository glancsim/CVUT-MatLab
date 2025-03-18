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
%             - Dist: typ rozdělení ('N' pro normální, 'LN' pro log-normální)
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
        % V UQLab se používají parametry mu a sigma, které jsou parametry 
        % související s logaritmem proměnné
        COV = model.V_x;
        mu_ln = log(mean_value / sqrt(1 + COV^2));
        sigma_ln = sqrt(log(1 + COV^2));
        
        UQVar.Parameters = [mu_ln, sigma_ln];
        
    otherwise
        error('Nepodporovaný typ rozdělení: %s', model.Dist);
end

end