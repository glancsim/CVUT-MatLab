%% Reliability Analysis vs. Cross-Sectional Area Ratio
% This section analyzes how reliability index (beta) and resistance-to-load ratio (R_d/E_d) 
% change based on the ratio of actual cross-sectional area (A_g) to Eurocode required area (A_s_EN)

% Display original area values from the file
fprintf('\nOriginal cross-sectional area values:\n');
fprintf('Original section area (A_s): %.6f m² (%.2f mm²)\n', section.A_s, section.A_s * 10^6);
fprintf('Eurocode required area (A_s_EN): %.6f m² (%.2f mm²)\n', EN.A_s_en, EN.A_s_en * 10^6);
fprintf('Original ratio (A_s/A_s_EN): %.4f\n', section.A_s / EN.A_s_en);

% Define the range of ratios A_g/A_s_EN to analyze
ratio_range = linspace(0.5, 2.0, 50);  % Ratio from 0.5 to 2.0 times A_s_EN
beta_values = zeros(size(ratio_range));
rd_ed_ratio = zeros(size(ratio_range));

% Store original section area for reference
original_area = section.A_s;
original_EN_area = EN.A_s_en;
original_ratio = original_area / original_EN_area;

% Loop through each ratio value
for i = 1:length(ratio_range)
    % Calculate new section area based on the ratio
    section.A_s = original_EN_area * ratio_range(i);
    
    % Update the geometry variable in the probabilistic model
    model.a.nominal = section.A_s;
    model.a.variable = createUQVariable(model.a, 'A');
    InputOpts.Marginals(2) = model.a.variable;
    
    % Update input object
    inputOpts.Marginals = InputOpts.Marginals;
    input = uq_createInput(inputOpts);
    
    % Run reliability analysis
    reliability = uq_createAnalysis(SimOpts);
    
    % Store the reliability index for this ratio
    beta_values(i) = reliability.Results.BetaHL;
    
    % Calculate and store R_d/E_d ratio
    EN.R_d = section.A_s * section.f_y / EN.gamma_M0;
    rd_ed_ratio(i) = EN.R_d / EN.E_d;
end

% Reset section area to original value after analysis
section.A_s = original_area;

% Create figure with two y-axes
figure('Name', 'Reliability Analysis vs. Area Ratio', 'Position', [100, 100, 800, 600]);

% Create left y-axis for beta values
yyaxis left
plot(ratio_range, beta_values, 'b-', 'LineWidth', 2);
ylabel('Reliability Index \beta', 'Color', 'b', 'FontWeight', 'bold');
ax = gca;
ax.YColor = 'b';
ylim([0, max(beta_values)*1.1]); % Set y-axis to start at 0

% Add target reliability level
target_beta = 3.8;  % Example target reliability for ULS (adjust as needed)
hold on;
line([min(ratio_range), max(ratio_range)], [target_beta, target_beta], 'Color', 'b', 'LineStyle', '--', 'LineWidth', 1.5);
text(min(ratio_range)+0.1, target_beta+0.1, ['Target \beta = ', num2str(target_beta)], 'Color', 'b');

% Create right y-axis for R_d/E_d ratio
yyaxis right
plot(ratio_range, rd_ed_ratio, 'r-', 'LineWidth', 2);
ylabel('R_d / E_d Ratio', 'Color', 'r', 'FontWeight', 'bold');
ax = gca;
ax.YColor = 'r';
ylim([0, max(rd_ed_ratio)*1.1]); % Set y-axis to start at 0

% Add line at R_d/E_d = 1 (limit state)
hold on;
line([min(ratio_range), max(ratio_range)], [1, 1], 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);
text(min(ratio_range)+0.1, 1.05, 'R_d / E_d = 1', 'Color', 'r');

% Mark the original ratio on both plots
yyaxis left
beta_at_original = interp1(ratio_range, beta_values, original_ratio);
plot(original_ratio, beta_at_original, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
text(original_ratio+0.05, beta_at_original, ['Original \beta = ', num2str(beta_at_original, '%.2f')]);

yyaxis right
rd_ed_at_original = interp1(ratio_range, rd_ed_ratio, original_ratio);
plot(original_ratio, rd_ed_at_original, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
text(original_ratio+0.05, rd_ed_at_original, ['Original R_d/E_d = ', num2str(rd_ed_at_original, '%.2f')]);

% Add vertical line at original ratio
line([original_ratio, original_ratio], [0, max([max(beta_values), max(rd_ed_ratio)])*1.1], 'Color', 'k', 'LineStyle', '-', 'LineWidth', 1.5);
% text(original_ratio, get(gca, 'YLim')*[0.1; 0.9], ['Original A_s/A_s_EN = ', num2str(original_ratio, '%.2f')], ...
%     'Color', 'k', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Rotation', 90);

% Add overall formatting
grid on;
xlabel('A_g / A_{s,EN} Ratio', 'FontWeight', 'bold');
title('Reliability Index and Resistance-to-Load Ratio vs. Area Ratio', 'FontSize', 14);
legend('Reliability Index \beta', 'Target \beta', 'R_d / E_d Ratio', 'R_d / E_d = 1', ...
    'Original \beta', 'Original R_d/E_d', 'Original Ratio', 'Location', 'best');

% Save graph to Plots directory
if ~exist('Plots', 'dir')
   mkdir('Plots')
end
saveas(gcf, 'Plots/combined_area_ratio_analysis.png');

% Display original beta and R_d/E_d values
fprintf('\nSafety at original cross-section area:\n');
fprintf('Reliability index (β) at original area: %.4f\n', beta_at_original);
fprintf('R_d/E_d ratio at original area: %.4f\n', rd_ed_at_original);

% Display the minimum area ratio needed to achieve target reliability
[~, idx] = min(abs(beta_values - target_beta));
min_ratio_for_target = ratio_range(idx);
fprintf('\nMinimum A_g/A_s,EN ratio needed to achieve target reliability (β = %.1f): %.3f\n', target_beta, min_ratio_for_target);

% Display the minimum area ratio needed for R_d/E_d ≥ 1
[~, idx] = min(abs(rd_ed_ratio - 1));
min_ratio_for_safety = ratio_range(idx);
fprintf('Minimum A_g/A_s,EN ratio needed for R_d/E_d ≥ 1: %.3f\n', min_ratio_for_safety);