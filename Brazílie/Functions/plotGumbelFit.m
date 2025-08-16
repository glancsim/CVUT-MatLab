function plotGumbelFit(roky, rocni_maxima, mu, beta)
    % PLOTGUMBELFIT Vizualizuje fitování Gumbelova rozdělení na roční maxima
    %
    % Vstupy:
    %   roky - vektor s roky
    %   rocni_maxima - vektor s maximálními hodnotami
    %   mu - lokační parametr Gumbelova rozdělení
    %   beta - škálový parametr Gumbelova rozdělení
    %
    % Příklad použití:
    %   plotGumbelFit(roky, rocni_maxima, mu, beta);
    
    % Color scheme definition
    colors = struct();
    colors.primary = [178/255, 197/255, 249/255]; % B2C5F9 - main blue
    colors.secondary = [178/255, 234/255, 249/255]; % B2EAF9 - lighter blue
    colors.accent = [212/255, 239/255, 244/255]; % D4EFF4 - lightest blue
    colors.background = [243/255, 243/255, 243/255]; % F3F3F3 - light gray
    colors.text = [50/255, 50/255, 70/255]; % Darker text
    colors.grid = [220/255, 220/255, 230/255]; % Soft grid
    colors.plotReal = [100/255, 143/255, 255/255]; % Vibrant blue
    colors.plotModel = [13/255, 71/255, 161/255]; % Dark blue
    colors.plotHighlight = [255/255, 71/255, 71/255]; % Red highlight
    
    % Font settings
    fontName = 'Helvetica';
    fontSize = 11;
    titleSize = 13;
    mainTitleSize = 16;
           
    % 3. Výpočet charakteristické hodnoty (98% fraktil)
    fraktil_98 = icdf('Extreme Value', 0.98, mu, beta);
    
    % 4. Výpočet charakteristické hodnoty (střední hodnota ročních maxim)
    char_hodnota = 0.7;
    
    % 5. Statistické ukazatele
    sk = skewness(rocni_maxima);
    CoV = std(rocni_maxima) / mean(rocni_maxima);
    
    % Výpočet hodnot pro vykreslení PDF
    x = linspace(0, max(rocni_maxima), 100);
    y = pdf('ExtremeValue', x, mu, beta);
    
    % Nastavení výchozích vlastností grafů
    set(groot, 'defaultAxesFontName', fontName);
    set(groot, 'defaultAxesFontSize', fontSize);
    set(groot, 'defaultTextFontName', fontName);
    set(groot, 'defaultTextFontSize', fontSize);
    
    % 6.1 Histogram a PDF - samostatný graf
    figure('Position', [100, 100, 600, 500], 'Color', colors.background);
    histogram(rocni_maxima, 'Normalization', 'pdf', 'FaceColor', colors.primary, 'EdgeColor', colors.plotReal, 'FaceAlpha', 0.7);
    hold on;
    plot(x, y, 'Color', colors.plotModel, 'LineWidth', 2);
    xline(char_hodnota, 'Color', colors.plotHighlight, 'LineWidth', 1.5, 'LineStyle', '--');
    xline(fraktil_98, 'Color', colors.plotModel, 'LineWidth', 1.5, 'LineStyle', '--');
    hold off;
    
    title('Histogram ročních maxim a Gumbelovo rozdělení', 'FontSize', titleSize, 'Color', colors.text);
    xlabel('Zatížení sněhem [kN/m^2]', 'FontSize', fontSize, 'Color', colors.text);
    ylabel('Hustota pravděpodobnosti', 'FontSize', fontSize, 'Color', colors.text);
    legend('Histogram dat', 'Gumbelovo rozdělení', 'Char. hodnota', '98% fraktil', 'FontName', fontName, 'Location', 'northeast');
    
    ax = gca;
    ax.Color = colors.background;
    ax.GridColor = colors.grid;
    ax.GridAlpha = 0.6;
    ax.Box = 'on';
    ax.XColor = colors.text;
    ax.YColor = colors.text;
    grid on;
    
    % 6.2 QQ-plot - samostatný graf
    figure('Position', [710, 100, 600, 500], 'Color', colors.background);
    qqplot = probplot('extreme value', rocni_maxima);
    
    % Upravení stylu QQ-plotu
    for i = 1:length(qqplot)
        if isprop(qqplot(i), 'Color') && strcmp(get(qqplot(i), 'Type'), 'line')
            set(qqplot(i), 'Color', colors.plotModel, 'LineWidth', 1.5);
        elseif strcmp(get(qqplot(i), 'Type'), 'scatter')
            set(qqplot(i), 'MarkerEdgeColor', colors.plotReal, 'MarkerFaceColor', colors.primary, 'LineWidth', 1);
        end
    end
    
    title('QQ-plot pro Gumbelovo rozdělení', 'FontSize', titleSize, 'Color', colors.text);
    ax = gca;
    ax.Color = colors.background;
    ax.GridColor = colors.grid;
    ax.GridAlpha = 0.6;
    ax.Box = 'on';
    ax.XColor = colors.text;
    ax.YColor = colors.text;
    grid on;
    
    % 7. Výstup parametrů do konzole
    fprintf('Výsledky fitování Gumbelova rozdělení:\n');
    fprintf('Location parametr (mu): %.4f\n', mu);
    fprintf('Scale parametr (beta): %.4f\n', beta);
    fprintf('98%% fraktil: %.4f kN/m^2\n', fraktil_98);
    fprintf('Charakteristická hodnota z mapy: %.4f kN/m^2\n', char_hodnota);
    fprintf('Koeficient variace: %.4f\n', CoV);
    fprintf('Šikmost: %.4f\n', sk);
end