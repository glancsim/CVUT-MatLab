function plotMarginals(InputOpts)
    % Funkce pro vykreslení grafů pro všechny marginality v InputOpts.Marginals
    
    num_marginals = length(InputOpts.Marginals); % Počet proměnných
    figure;
    
    for i = 1:num_marginals
        % Získání parametrů
        marg = InputOpts.Marginals(i);
        dist_type = marg.Type; % Typ rozdělení ('LN' nebo 'N')
        params = marg.Parameters; % Parametry (mu, sigma, atd.)
        
        subplot(2, 3, i); % Vykreslí grafy v mřížce 2x3
        
        % Podmínky pro vykreslení
        if strcmp(dist_type, 'LN') % Log-normální rozdělení
            % Vykreslíme log-normální rozdělení
            x = linspace(0, 3 * params(1), 1000); % Rozsah pro vykreslení
            y = lognpdf(x, params(1), params(2)); % Hustota pravděpodobnosti
            plot(x, y, 'LineWidth', 2);
            title(sprintf('Log-Normal Distribution: %s', marg.Name));
        elseif strcmp(dist_type, 'N') % Normální rozdělení
            % Vykreslíme normální rozdělení
            x = linspace(params(1) - 3*params(2), params(1) + 3*params(2), 1000); % Rozsah pro vykreslení
            y = normpdf(x, params(1), params(2)); % Hustota pravděpodobnosti
            plot(x, y, 'LineWidth', 2);
            title(sprintf('Normal Distribution: %s', marg.Name));
        else
            error('Unsupported distribution type: %s', dist_type);
        end
        
        xlabel('Value');
        ylabel('Probability Density');
        grid on;
    end
end