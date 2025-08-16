function visualize_snow_load_data(rocni_maxima, roky, pd)
% VISUALIZE_SNOW_LOAD_DATA Visualization of snow data and fitted Gumbel distribution
%   visualize_snow_load_data(rocni_maxima, roky, pd)
%
%   Parameters:
%       rocni_maxima - vector of annual maximum snow amounts in mm/m²
%       roky - vector of corresponding years
%       pd - fitted distribution object from fitdist

    % Color scheme definition
    colors = struct();
    colors.primary = [178/255, 197/255, 249/255];    % B2C5F9 - main blue
    colors.secondary = [178/255, 234/255, 249/255];  % B2EAF9 - lighter blue
    colors.accent = [212/255, 239/255, 244/255];     % D4EFF4 - lightest blue
    colors.background = [243/255, 243/255, 243/255]; % F3F3F3 - light gray
    colors.text = [50/255, 50/255, 70/255];          % Darker text
    colors.grid = [220/255, 220/255, 230/255];       % Soft grid
    colors.plotReal = [100/255, 143/255, 255/255];   % Vibrant blue
    colors.plotModel = [13/255, 71/255, 161/255];    % Dark blue
    colors.plotHighlight = [255/255, 71/255, 71/255]; % Red highlight

    % Font settings
    fontName = 'Helvetica';
    fontSize = 11;
    titleSize = 13;
    mainTitleSize = 16;
    
    % Gumbel parameters
    mu = pd.mu;
    beta = pd.sigma;
    
    % Create figure for distribution analysis
    figure('Name', 'Snow Amount Analysis', 'NumberTitle', 'off', 'Position', [100, 100, 1000, 550]);
    set(gcf, 'Color', colors.background);
    
    % 1.1 Histogram and fitted distribution
    subplot(2,2,1);
    h = histogram(rocni_maxima, 'Normalization', 'pdf', 'FaceColor', colors.accent, 'EdgeColor', colors.primary);
    hold on;
    
    x_values = linspace(min(rocni_maxima)*0.8, max(rocni_maxima)*1.2, 1000);
    y_values = pdf(pd, x_values);
    plotModel = plot(x_values, y_values, '-', 'LineWidth', 2.5, 'Color', colors.plotModel);
    
    title('Histogram and Fitted Gumbel Distribution', ...
        'FontWeight', 'bold', 'FontName', fontName, 'FontSize', titleSize, 'Color', colors.text);
    legend([h, plotModel], {'Real Data', 'Gumbel Distribution'}, ...
        'Location', 'best', 'FontName', fontName, 'FontSize', fontSize, 'TextColor', colors.text, ...
        'EdgeColor', colors.primary, 'Box', 'on');
    xlabel('Snow Amount [mm/m²]', 'FontWeight', 'bold', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    ylabel('Probability Density', 'FontWeight', 'bold', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    grid on;
    set(gca, 'GridColor', colors.grid, 'GridAlpha', 0.5, 'Box', 'on', 'LineWidth', 1.2);
    set(gca, 'FontName', fontName, 'FontSize', fontSize, 'XColor', colors.text, 'YColor', colors.text);
    
    % 1.2 Empirical CDF vs. Fitted Gumbel CDF
    subplot(2,2,2);
    [f, x] = ecdf(rocni_maxima);
    ecdfPlot = stairs(x, f, 'LineWidth', 2, 'Color', colors.plotReal);
    hold on;
    cdfPlot = plot(x_values, cdf(pd, x_values), '-', 'LineWidth', 2.5, 'Color', colors.plotModel);
    
    title('Empirical vs. Theoretical CDF', ...
        'FontWeight', 'bold', 'FontName', fontName, 'FontSize', titleSize, 'Color', colors.text);
    legend([ecdfPlot, cdfPlot], {'Empirical CDF', 'Gumbel CDF'}, ...
        'Location', 'best', 'FontName', fontName, 'FontSize', fontSize, 'TextColor', colors.text, ...
        'EdgeColor', colors.primary, 'Box', 'on');
    xlabel('Snow Amount [mm/m²]', 'FontWeight', 'bold', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    ylabel('Cumulative Probability', 'FontWeight', 'bold', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    grid on;
    set(gca, 'GridColor', colors.grid, 'GridAlpha', 0.5, 'Box', 'on', 'LineWidth', 1.2);
    set(gca, 'FontName', fontName, 'FontSize', fontSize, 'XColor', colors.text, 'YColor', colors.text);
    
    % 1.3 Time series of annual maxima
    subplot(2,2,[3,4]);
    timeSeriesPlot = plot(roky, rocni_maxima, '-o', 'LineWidth', 2, 'Color', colors.plotReal, ...
        'MarkerFaceColor', colors.plotReal, 'MarkerEdgeColor', 'white', 'MarkerSize', 6);
    hold on;
    
    % Add mean value line
    meanValue = mean(rocni_maxima);
    meanLine = line([min(roky), max(roky)], [meanValue, meanValue], ...
                    'Color', colors.plotModel, 'LineStyle', '--', 'LineWidth', 1.8);
    
    % Add characteristic value (98% quantile)
    char_value = quantile(rocni_maxima, 0.98);
    charLine = line([min(roky), max(roky)], [char_value, char_value], ...
                    'Color', colors.plotHighlight, 'LineStyle', '--', 'LineWidth', 1.8);
    
    title('Time Series of Annual Maximum Snow Amounts', ...
        'FontWeight', 'bold', 'FontName', fontName, 'FontSize', titleSize, 'Color', colors.text);
    legend([timeSeriesPlot, meanLine, charLine], {'Annual Maxima', 'Mean Value', 'Characteristic Value (98%)'}, ...
        'Location', 'best', 'FontName', fontName, 'FontSize', fontSize, 'TextColor', colors.text, ...
        'EdgeColor', colors.primary, 'Box', 'on');
    xlabel('Year', 'FontWeight', 'bold', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    ylabel('Snow Amount [mm/m²]', 'FontWeight', 'bold', 'FontName', fontName, 'FontSize', fontSize, 'Color', colors.text);
    grid on;
    set(gca, 'GridColor', colors.grid, 'GridAlpha', 0.5, 'Box', 'on', 'LineWidth', 1.2);
    set(gca, 'FontName', fontName, 'FontSize', fontSize, 'XColor', colors.text, 'YColor', colors.text);
    
    % Add main title
    sgtitle('Snow Amount Analysis: Historical Data and Gumbel Model', ...
        'FontWeight', 'bold', 'FontSize', mainTitleSize, 'FontName', fontName, 'Color', colors.text);
    % Save figures
    figure(1);
    saveas(gcf, 'Plots/snow_amount_analysis.png');

end