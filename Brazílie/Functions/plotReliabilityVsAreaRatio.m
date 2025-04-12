function plotReliabilityVsAreaRatio(ratio_range, beta_values, rd_ed_ratio, original_ratio, outputPath)
    % PLOTRELIABILITYVSAREARATIO Vykreslí kombinovaný graf analýzy spolehlivosti v závislosti na poměru ploch
    %
    % Syntax:
    %   plotReliabilityVsAreaRatio(ratio_range, beta_values, rd_ed_ratio, original_ratio)
    %   plotReliabilityVsAreaRatio(ratio_range, beta_values, rd_ed_ratio, original_ratio, outputPath)
    %
    % Vstupní parametry:
    %   ratio_range - Rozsah poměrů ploch (A_g / A_{s,EN})
    %   beta_values - Hodnoty indexu spolehlivosti beta
    %   rd_ed_ratio - Hodnoty poměru R_d/E_d
    %   original_ratio - Původní poměr ploch použitý v analýze
    %   outputPath - (Volitelné) Cesta pro uložení grafů, např. 'Plots/reliability_vs_area'
    %
    % Příklad:
    %   plotReliabilityVsAreaRatio(ratio_range, beta_values, rd_ed_ratio, original_ratio)
    %   plotReliabilityVsAreaRatio(ratio_range, beta_values, rd_ed_ratio, original_ratio, 'Plots/reliability_vs_area')
    
    % Definice barevného schématu dle posteru
    colors = struct();
    colors.primary = [178/255, 197/255, 249/255];    % B2C5F9 - hlavní modrá
    colors.secondary = [178/255, 234/255, 249/255];  % B2EAF9 - světlejší modrá
    colors.accent = [212/255, 239/255, 244/255];     % D4EFF4 - nejsvětlejší modrá
    colors.background = [243/255, 243/255, 243/255]; % F3F3F3 - světle šedá
    colors.text = [50/255, 50/255, 70/255];          % Tmavší text pro lepší čitelnost
    colors.grid = [220/255, 220/255, 230/255];       % Jemná mřížka

    % Komplementární barvy pro grafy
    colors.plotBeta = [100/255, 143/255, 255/255];   % Sytější modrá pro beta hodnoty
    colors.plotRatio = [13/255, 71/255, 161/255];    % Tmavší modrá pro poměr R_d/E_d
    colors.plotHighlight = [255/255, 71/255, 71/255]; % Červená pro zdůraznění

    % Nastavení fontu
    fontName = 'Helvetica';
    fontSize = 11;
    titleSize = 13;
    mainTitleSize = 16;
    
    % Cílová hodnota spolehlivosti
    target_beta = 4.7; % Cílová spolehlivost pro ULS
    
    % Vytvoření figure
    figure('Name', 'Reliability Analysis vs. Area Ratio', 'NumberTitle', 'off', 'Position', [100, 100, 800, 600]);
    set(gcf, 'Color', colors.background);

    % Vytvoření levé osy y pro hodnoty beta
    yyaxis left
    betaPlot = plot(ratio_range, beta_values, '-', 'LineWidth', 2.5, 'Color', colors.plotBeta);
    hold on;
    
    % Přidání cílové hodnoty spolehlivosti
    targetLine = line([min(ratio_range), max(ratio_range)], [target_beta, target_beta], ...
                      'Color', colors.plotBeta, 'LineStyle', '--', 'LineWidth', 1.8);
    targetText = text(min(ratio_range) + 0.1*(max(ratio_range)-min(ratio_range)), ...
                     target_beta + 0.14, ...
                     ['Target \beta = ', num2str(target_beta)], ...
                     'Color', colors.plotBeta, 'FontName', fontName, 'FontSize', fontSize);
    
    % Formátování levé osy
    ylabel('Reliability Index \beta', 'FontWeight', 'bold', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.plotBeta);
    ax1 = gca;
    ax1.YColor = colors.plotBeta;
    ylim([2, 7]); % Nastavení osy y pro začátek od 0 s malým paddingem
    
    % Vytvoření pravé osy y pro poměr R_d/E_d
    yyaxis right
    ratioPlot = plot(ratio_range, rd_ed_ratio, '-', 'LineWidth', 2.5, 'Color', colors.plotRatio);
    
    % Přidání čáry pro R_d/E_d = 1 (limit state)
    limitLine = line([min(ratio_range), max(ratio_range)], [1, 1], ...
                    'Color', colors.plotRatio, 'LineStyle', '--', 'LineWidth', 1.8);
    limitText = text(min(ratio_range) + 0.1*(max(ratio_range)-min(ratio_range)), ...
                    1.04, 'R_d / E_d = 1', ...
                    'Color', colors.plotRatio, 'FontName', fontName, 'FontSize', fontSize);
    
    % Formátování pravé osy
    ylabel('R_d / E_d Ratio', 'FontWeight', 'bold', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.plotRatio);
    ax2 = gca;
    ax2.YColor = colors.plotRatio;
    ylim([0, max(rd_ed_ratio)*1.15]); % Nastavení osy y pro začátek od 0 s malým paddingem
    
    % Označení původního poměru v obou grafech
    yyaxis left
    beta_at_original = interp1(ratio_range, beta_values, original_ratio);
    originalBetaPoint = scatter(original_ratio, beta_at_original, 100, colors.plotBeta, 'filled', ...
                              'MarkerEdgeColor', 'white', 'LineWidth', 1.5);
    originalBetaText = text(original_ratio + 0.03*(max(ratio_range)-min(ratio_range)), ...
                           beta_at_original, ...
                           ['Original \beta = ', num2str(beta_at_original, '%.2f')], ...
                           'FontName', fontName, 'FontSize', fontSize, 'Color', colors.plotBeta);
    
    yyaxis right
    rd_ed_at_original = interp1(ratio_range, rd_ed_ratio, original_ratio);
    originalRatioPoint = scatter(original_ratio, rd_ed_at_original, 100, colors.plotRatio, 'filled', ...
                              'MarkerEdgeColor', 'white', 'LineWidth', 1.5);
    originalRatioText = text(original_ratio + 0.03*(max(ratio_range)-min(ratio_range)), ...
                           rd_ed_at_original, ...
                           ['Original R_d/E_d = ', num2str(rd_ed_at_original, '%.2f')], ...
                           'FontName', fontName, 'FontSize', fontSize, 'Color', colors.plotRatio);
    
    % Přidání vertikální čáry na původním poměru
    originalLine = line([original_ratio, original_ratio], ...
                      [0, max([max(beta_values), max(rd_ed_ratio)])*1.15], ...
                      'Color', colors.plotHighlight, 'LineStyle', '-', 'LineWidth', 2);

    % Celkové formátování grafu
    grid on;
    set(gca, 'GridColor', colors.grid, 'GridAlpha', 0.5, 'Box', 'on', 'LineWidth', 1.2);
    set(gca, 'FontName', fontName, 'FontSize', fontSize, 'XColor', colors.text);
    
    xlabel('A_g / A_{s,EN} Ratio', 'FontWeight', 'bold', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    title('Reliability Index and Resistance-to-Load Ratio vs. Area Ratio', ...
         'FontWeight', 'bold', 'FontSize', mainTitleSize, 'FontName', fontName, 'Color', colors.text);
    
    % Přidání legendy
    legend([betaPlot, targetLine, ratioPlot, limitLine, originalBetaPoint, originalRatioPoint, originalLine], ...
          {'Reliability Index \beta', 'Target \beta', 'R_d / E_d Ratio', 'R_d / E_d = 1', ...
           'Original \beta', 'Original R_d/E_d', 'Original Ratio'}, ...
          'Location', 'best', 'FontName', fontName, 'FontSize', fontSize, 'TextColor', colors.text, ...
          'EdgeColor', colors.primary, 'Box', 'on');
    
    % Export grafu, pokud byla zadána cesta
    if nargin > 4 && ~isempty(outputPath)
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
        
        % Pokus o export do SVG, pokud je dostupný
        try
            saveas(gcf, [fullPath '.svg']);
        catch
            warning('SVG export není k dispozici. Soubor byl uložen pouze jako PNG a FIG.');
        end
        
        fprintf('Graf byl uložen do: %s\n', fullPath);
    else
        % Kontrola, zda existuje složka Plots, a vytvoření, pokud ne
        if ~exist('Plots', 'dir')
            mkdir('Plots');
        end
        % Uložení grafu do výchozí cesty
        saveas(gcf, 'Plots/combined_area_ratio_analysis.png');
        saveas(gcf, 'Plots/combined_area_ratio_analysis.fig');
        fprintf('Graf byl uložen do: %s\n', 'Plots/combined_area_ratio_analysis.png');
    end
    % Display original beta and R_d/E_d values
    fprintf('\nSafety at original cross-section area:\n');
    beta_at_original = interp1(ratio_range, beta_values, original_ratio);
    fprintf('   Reliability index (β) at original area: %.4f\n', beta_at_original);
    fprintf('   R_d/E_d ratio at original area: %.4f\n', rd_ed_at_original);
    
    % Display the minimum area ratio needed to achieve target reliability
    [~, idx] = min(abs(beta_values - target_beta));
    min_ratio_for_target = ratio_range(idx);
    fprintf('\nMinimum A_g/A_s,EN ratio needed to achieve target reliability (β = %.1f): %.3f\n', target_beta, min_ratio_for_target);
    
    % Display the minimum area ratio needed for R_d/E_d ≥ 1
    [~, idx] = min(abs(rd_ed_ratio - 1));
    min_ratio_for_safety = ratio_range(idx);
    fprintf('Minimum A_g/A_s,EN ratio needed for R_d/E_d ≥ 1: %.3f\n', min_ratio_for_safety);
end