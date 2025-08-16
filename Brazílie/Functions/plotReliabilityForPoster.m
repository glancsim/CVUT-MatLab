function plotReliabilityForPoster(reliability, outputPath, paramNames)
    % PLOTRELIABILITYFORPOSTER Vykreslí čtyři samostatné grafy analýzy reliability pro poster
    %
    % Syntax:
    %   plotReliabilityForPoster(reliability)
    %   plotReliabilityForPoster(reliability, outputPath)
    %
    % Vstupní parametry:
    %   reliability - Struktura obsahující výsledky reliability analýzy
    %   outputPath - (Volitelné) Cesta pro uložení grafů, např. 'cesta/reliability_graphs'
    %
    % Příklad:
    %   plotReliabilityForPoster(reliability)
    %   plotReliabilityForPoster(reliability, 'images/reliability_poster')
    %
    % Požadované pole ve struktuře reliability:
    %   reliability.Results.History.BetaHL - Historie beta hodnot
    %   reliability.Results.History.G - Historie limit state hodnot
    %   reliability.Results.Importance - Důležitost jednotlivých proměnných
    %   reliability.Results.Pf - Pravděpodobnost selhání;
    %   reliability.Results.BetaHL - Konečná beta hodnota
    %   reliability.Results.Iterations - Počet iterací
    %   reliability.Results.ModelEvaluations - Počet evaluací modelu
    
    % Extrakce výsledků
    results = reliability.Results;

    % Definice barevného schématu dle posteru
    colors = struct();
    colors.primary = [178/255, 197/255, 249/255];    % B2C5F9 - hlavní modrá
    colors.secondary = [178/255, 234/255, 249/255];  % B2EAF9 - světlejší modrá
    colors.accent = [212/255, 239/255, 244/255];     % D4EFF4 - nejsvětlejší modrá
    colors.background = [243/255, 243/255, 243/255]; % F3F3F3 - světle šedá
    colors.text = [50/255, 50/255, 70/255];          % Tmavší text pro lepší čitelnost
    colors.grid = [220/255, 220/255, 230/255];       % Jemná mřížka

    % Komplementární barvy pro grafy
    colors.plot1 = [100/255, 143/255, 255/255];      % Sytější modrá pro první graf
    colors.plot2 = [13/255, 71/255, 161/255];        % Tmavší modrá pro druhý graf
    colors.bars = [178/255, 197/255, 249/255; 
                   128/255, 172/255, 234/255; 
                   79/255, 129/255, 189/255; 
                   13/255, 71/255, 161/255;
                   100/255, 143/255, 255/255;
                   178/255, 216/255, 231/255];       % Odstíny modré pro sloupce

    % Nastavení fontu
    fontName = 'Helvetica';
    fontSize = 11;
    titleSize = 13;
    mainTitleSize = 16;
    
    % Nastavení figury - společné vlastnosti
    figProperties = {'Color', colors.background, 'Position', [100, 100, 700, 400]};
    
    % Společné vlastnosti os
    function setupAxes(xdata, ydata)
        set(gca, ...
            'FontName', fontName, ...
            'FontSize', fontSize, ...
            'XColor', colors.text, ...
            'YColor', colors.text, ...
            'GridColor', colors.grid, ...
            'Box', 'on', ...
            'LineWidth', 1.2, ...
            'GridAlpha', 0.3, ...
            'Color', [1, 1, 1], ...
            'XLim', [min(xdata)-0.1, max(xdata)+0.1], ...
            'YLim', [min(ydata)-0.1*range(ydata), max(ydata)+0.25*range(ydata)]);
    end

    % Funkce pro uložení grafu
    function saveGraph(figHandle, graphName)
        if nargin > 1 && ~isempty(outputPath)
            % Vytvoření složky, pokud neexistuje
            [folder, ~, ~] = fileparts(outputPath);
            if ~isempty(folder) && ~exist(folder, 'dir')
                mkdir(folder);
            end
            
            % Sestavení cesty k souboru
            fullPath = fullfile(outputPath, graphName);
            
            % Export ve vysokém rozlišení
            print(figHandle, [fullPath '.png'], '-dpng', '-r300');
            saveas(figHandle, [fullPath '.fig']);
            
            % Pokud je dostupný export do SVG, použít ho
            try
                saveas(figHandle, [fullPath '.svg']);
            catch
                warning('SVG export není k dispozici. Soubor byl uložen pouze jako PNG a FIG.');
            end
            
            fprintf('Graf "%s" byl uložen do: %s\n', graphName, fullPath);
        end
    end

    % 1. Reliability Index (Beta)
    fig1 = figure('Name', 'Reliability Index', 'NumberTitle', 'off', figProperties{:});
    xdata1 = 1:length(results.History.BetaHL);
    ydata1 = results.History.BetaHL;
    plot(xdata1, ydata1, '-', 'LineWidth', 2, 'Color', colors.plot1);
    hold on;
    scatter(xdata1, ydata1, 60, colors.plot1, 'filled', 'MarkerEdgeColor', 'white', 'LineWidth', 1);
    title('Reliability Index β', 'FontWeight', 'bold', 'FontSize', titleSize, 'FontName', fontName, 'Color', colors.text);
    xlabel('Iterations', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    ylabel('β Value', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    grid on;
    setupAxes(xdata1, ydata1);
    box on;
    saveGraph(fig1, 'reliability_index');

    % 2. Limit State G
    fig2 = figure('Name', 'Limit State', 'NumberTitle', 'off', figProperties{:});
    xdata2 = 1:length(results.History.G);
    ydata2 = results.History.G;
    plot(xdata2, ydata2, '-', 'LineWidth', 2, 'Color', colors.plot2);
    hold on;
    scatter(xdata2, ydata2, 60, colors.plot2, 'filled', 'MarkerEdgeColor', 'white', 'LineWidth', 1);
    title('Limit State G', 'FontWeight', 'bold', 'FontSize', titleSize, 'FontName', fontName, 'Color', colors.text);
    xlabel('Iterations', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    ylabel('Limit State Value', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    grid on;
    setupAxes(xdata2, ydata2);
    box on;
    saveGraph(fig2, 'limit_state');

    % 3. Sensitivity Indices
    fig3 = figure('Name', 'Sensitivity Indices', 'NumberTitle', 'off', figProperties{:});
    xdata3 = 1:length(results.Importance);
    ydata3 = results.Importance;
    b = bar(xdata3, ydata3, 'FaceColor', 'flat');
    for k = 1:length(results.Importance)
        b.CData(k,:) = colors.bars(mod(k-1, size(colors.bars, 1))+1, :);
    end
    title('Sensitivity Indices', 'FontWeight', 'bold', 'FontSize', titleSize, 'FontName', fontName, 'Color', colors.text);
    xlabel('Variables', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    ylabel('Importance', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    if exist('paramNames', 'var') && ~isempty(paramNames)
        xticklabels(paramNames);
        xtickangle(45);
    end
    grid on;
    setupAxes(xdata3, ydata3);
    xlim([0.5 (0.5 + length(results.Importance))]);
    box on;
    saveGraph(fig3, 'sensitivity_indices');

    % 4. Summary of Key Results
    fig4 = figure('Name', 'Key Results', 'NumberTitle', 'off', figProperties{:});
    % Nastavení osy pro textový panel
    axis([0 1 0 1]);
    
    % Vytvoření pozadí pro textový panel
    rectangle('Position', [0.0, 0.0, 1.0, 1.0], 'FaceColor', [1 1 1], 'EdgeColor', colors.primary, 'LineWidth', 1.5);

    % Nadpis panelu s výsledky
    text(0.5, 0.85, 'Reliability Analysis: Key Results', 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'FontSize', mainTitleSize, 'FontName', fontName, 'Color', colors.text);
    
    % Textové informace s výsledky
    text(0.5, 0.7, sprintf('Failure Probability: %e', results.Pf), 'HorizontalAlignment', 'center', 'FontSize', fontSize, 'FontName', fontName, 'Color', colors.text);
    text(0.5, 0.55, sprintf('Reliability Index: %.4f', results.BetaHL), 'HorizontalAlignment', 'center', 'FontSize', fontSize, 'FontName', fontName, 'Color', colors.text);
    text(0.5, 0.4, sprintf('Number of Iterations: %d', results.Iterations), 'HorizontalAlignment', 'center', 'FontSize', fontSize, 'FontName', fontName, 'Color', colors.text);
    text(0.5, 0.25, sprintf('Model Evaluations: %d', results.ModelEvaluations), 'HorizontalAlignment', 'center', 'FontSize', fontSize, 'FontName', fontName, 'Color', colors.text);
    
    % Vypnutí os pro textový panel
    axis off;
    saveGraph(fig4, 'key_results');
    
    fprintf('Všechny grafy byly úspěšně vykresleny.\n');
end