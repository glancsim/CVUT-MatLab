function plotReliabilityForPoster(reliability, outputPath)
    % PLOTRELIABILITYFORPOSTER Vykreslí grafy analýzy reliability ve stylu kompatibilním s posterem
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
    %   reliability.Results.Pf - Pravděpodobnost selhání
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

    % Vytvoření figure
    figure('Name', 'Reliability Key Parameters', 'NumberTitle', 'off', 'Position', [100, 100, 1000, 600]);
    set(gcf, 'Color', colors.background);

    % Společné vlastnosti os - přidán padding pomocí 'XLim' a 'YLim'
    axesProperties = @(xdata, ydata) set(gca, ...
        'FontName', fontName, ...
        'FontSize', fontSize, ...
        'XColor', colors.text, ...
        'YColor', colors.text, ...
        'GridColor', colors.grid, ...
        'Box', 'on', ...
        'LineWidth', 1.2, ...
        'GridAlpha', 0.3, ...
        'Color', [1, 1, 1], ...
        'XLim', [min(xdata)-0.1, max(xdata)+0.1], ... % Přidáno padding na ose X
        'YLim', [min(ydata)-0.1*range(ydata), max(ydata)+0.25*range(ydata)]); % Přidáno padding na ose Y

    % 1. Reliability Index (Beta)
    subplot(2,2,1);
    xdata1 = 1:length(results.History.BetaHL);
    ydata1 = results.History.BetaHL;
    p1 = plot(xdata1, ydata1, '-', 'LineWidth', 2, 'Color', colors.plot1);
    hold on;
    scatter(xdata1, ydata1, 60, colors.plot1, 'filled', 'MarkerEdgeColor', 'white', 'LineWidth', 1);
    title('Reliability Index β', 'FontWeight', 'bold', 'FontSize', titleSize, 'FontName', fontName, 'Color', colors.text);
    xlabel('Iterations', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    ylabel('β Value', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    grid on;
    axesProperties(xdata1, ydata1);
    box on;

    % 2. Limit State G
    subplot(2,2,2);
    xdata2 = 1:length(results.History.G);
    ydata2 = results.History.G;
    p2 = plot(xdata2, ydata2, '-', 'LineWidth', 2, 'Color', colors.plot2);
    hold on;
    scatter(xdata2, ydata2, 60, colors.plot2, 'filled', 'MarkerEdgeColor', 'white', 'LineWidth', 1);
    title('Limit State G', 'FontWeight', 'bold', 'FontSize', titleSize, 'FontName', fontName, 'Color', colors.text);
    xlabel('Iterations', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    ylabel('Limit State Value', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    grid on;
    axesProperties(xdata2, ydata2);
    box on;

    % 3. Sensitivity Indices
    subplot(2,2,3);
    xdata3 = 1:length(results.Importance);
    ydata3 = results.Importance;
    b = bar(xdata3, ydata3, 'FaceColor', 'flat');
    for k = 1:length(results.Importance)
        b.CData(k,:) = colors.bars(mod(k-1, size(colors.bars, 1))+1, :);
    end
    title('Sensitivity Indices', 'FontWeight', 'bold', 'FontSize', titleSize, 'FontName', fontName, 'Color', colors.text);
    xlabel('Variables', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    ylabel('Importance', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    xticklabels({'Yield Strength', 'Geometry', 'Self weight load','Permanent Load', 'Snow Load', 'Resistance Model', 'Load Effect Model'});
    xtickangle(45);
    grid on;
    axesProperties(xdata3, ydata3);  % Začít od nuly pro bar chart
    xlim([0.5 (0.5 + length(results.Importance))]);
    % ylim([-0.10 1.00]);
    box on;

    % 4. Summary of Key Results - opraveno pro správné zobrazení
    subplot(2,2,4);
    % Nastavíme limity na 0-1 pro použití normalizovaných souřadnic
    axis([0 1 0 1]);
    
    % Vytvořit pozadí pro textový panel - upraveno na souřadnice v rámci osy
    rectangle('Position', [0.0, 0.0, 1.0, 1.0], 'FaceColor', [1, 1, 1], 'EdgeColor', colors.primary, 'LineWidth', 1.5);

    text(0.5, 0.85, sprintf('Key Results:'), 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'FontSize', titleSize, 'FontName', fontName, 'Color', colors.text);
    text(0.5, 0.7, sprintf('Failure Probability: %e', results.Pf), 'HorizontalAlignment', 'center', 'FontSize', fontSize, 'FontName', fontName, 'Color', colors.text);
    text(0.5, 0.55, sprintf('Reliability Index: %.4f', results.BetaHL), 'HorizontalAlignment', 'center', 'FontSize', fontSize, 'FontName', fontName, 'Color', colors.text);
    text(0.5, 0.4, sprintf('Number of Iterations: %d', results.Iterations), 'HorizontalAlignment', 'center', 'FontSize', fontSize, 'FontName', fontName, 'Color', colors.text);
    text(0.5, 0.25, sprintf('Model Evaluations: %d', results.ModelEvaluations), 'HorizontalAlignment', 'center', 'FontSize', fontSize, 'FontName', fontName, 'Color', colors.text);
    axis off; % Vypnout osy pro textový panel
    
    % Overall title
    sgtitle('Reliability Analysis using FORM Method', 'FontWeight', 'bold', 'FontSize', mainTitleSize, 'FontName', fontName, 'Color', colors.text);

    % Úprava rozestupů mezi grafy
    set(gcf, 'Units', 'normalized');
    p = get(gcf, 'Position');
    set(gcf, 'Position', [p(1), p(2), p(3), p(4)]);

    % Export, pokud byla zadána cesta
    if nargin > 1 && ~isempty(outputPath)
        % Odstranění přípony, pokud byla zadána
        [folder, baseFilename, ~] = fileparts(outputPath);
        
        % Vytvoření složky, pokud neexistuje
        if ~isempty(folder) && ~exist(folder, 'dir')
            mkdir(folder);
        end
        
        % Sestavení cest k souborům
        fullPath = fullfile(folder, baseFilename);
        
        % Export ve vysokém rozlišení
        print([fullPath '.png'], '-dpng', '-r300');
        saveas(gcf, [fullPath '.fig']);
        
        % Pokud je dostupný export do SVG, použít ho
        try
            saveas(gcf, [fullPath '.svg']);
        catch
            warning('SVG export není k dispozici. Soubor byl uložen pouze jako PNG a FIG.');
        end
        
        fprintf('Grafy byly uloženy do: %s\n', fullPath);
    end
end