function convergencePlotFn(results)
% convergencePlotFn  Plot convergence of reliability index β vs. sample count.
%
% Creates a figure with two subplots:
%   1. β convergence with target β = 4.7 reference line
%   2. Histogram of system limit state function g_sys
%
% INPUTS:
%   results - output of systemReliabilityFn
%
% (c) S. Glanc, 2026

figure('Name', 'Konvergence spolehlivosti', 'Position', [100 100 900 450]);

%% Subplot 1: β convergence
subplot(1, 2, 1);
n_vec  = results.n_convergence;
b_vec  = results.beta_convergence;

% Filter out Inf values for plotting
valid = isfinite(b_vec);
if any(valid)
    plot(n_vec(valid), b_vec(valid), 'b-', 'LineWidth', 1.5);
    hold on;
    yline(4.7, 'r--', 'LineWidth', 1.2, 'Label', '\beta_{target} = 4.7');
    yline(results.beta, 'k:', 'LineWidth', 1.0, ...
        'Label', sprintf('\\beta_{final} = %.2f', results.beta));
    hold off;
end

xlabel('Počet vzorků N');
ylabel('\beta = -\Phi^{-1}(P_f)');
title('Konvergence indexu spolehlivosti');
grid on;
set(gca, 'XScale', 'log');

% Reasonable y-axis limits
if any(valid)
    b_finite = b_vec(valid);
    ylim([max(0, min(b_finite) - 0.5), max(b_finite) + 0.5]);
end

%% Subplot 2: Histogram of g_sys
subplot(1, 2, 2);
if ~isempty(results.g_sys)
    g = results.g_sys;
    histogram(g, 100, 'Normalization', 'pdf', 'FaceColor', [0.3 0.6 1], ...
        'EdgeColor', 'none', 'FaceAlpha', 0.7);
    hold on;
    xline(0, 'r-', 'LineWidth', 2, 'Label', 'g = 0 (selhání)');
    hold off;

    xlabel('g_{sys}');
    ylabel('Hustota pravděpodobnosti');
    title(sprintf('Histogram LSF  (P_f = %.2e)', results.Pf));
    grid on;
end

end
