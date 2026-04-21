function convergencePlotFn(results)
% convergencePlotFn  Plot convergence of reliability index β vs. sample count.
%
% Creates a figure with two subplots:
%   1. β convergence with target β = 4.1 reference line (JCSS, series system)
%   2. Histogram of system limit state function g_sys
%
% INPUTS:
%   results - output of systemReliabilityFn
%
% (c) S. Glanc, 2026

figure('Name', 'Konvergence spolehlivosti', 'Position', [100 100 900 450]);

%% Subplot 1: β convergence
subplot(1, 2, 1);

isMCS = ~isfield(results, 'method') || strcmpi(results.method, 'MCS');

if isMCS
    n_vec = results.n_convergence;
    b_vec = results.beta_convergence;
    valid = isfinite(b_vec);
    if any(valid)
        plot(n_vec(valid), b_vec(valid), 'b-', 'LineWidth', 1.5);
        hold on;
    end
    yline(4.1, 'r--', 'LineWidth', 1.2, 'Label', '\beta_{target} = 4.1 (JRC TR Tab. B.2)');
    yline(results.beta, 'k:', 'LineWidth', 1.0, ...
        'Label', sprintf('\\beta_{final} = %.2f', results.beta));
    if any(valid)
        hold off;
        b_finite = b_vec(valid);
        ylim([max(0, min(b_finite) - 0.5), max(b_finite) + 0.5]);
    end
    xlabel('Počet vzorků N');
    set(gca, 'XScale', 'log');
else
    % Subset / IS: průběhový odhad ze seřazených podmíněných vzorků nedává smysl
    yline(4.1, 'r--', 'LineWidth', 1.2, 'Label', '\beta_{target} = 4.1 (JRC TR Tab. B.2)');
    yline(results.beta, 'k-', 'LineWidth', 1.8, ...
        'Label', sprintf('\\beta = %.2f  (%s)', results.beta, results.method));
    text(0.5, 0.5, sprintf('Metoda: %s\n\\beta = %.3f\nP_f = %.2e', ...
        results.method, results.beta, results.Pf), ...
        'Units', 'normalized', 'HorizontalAlignment', 'center', ...
        'FontSize', 10, 'Color', [0.2 0.2 0.2]);
    xlabel('—');
end
ylabel('\beta = -\Phi^{-1}(P_f)');
title('Index spolehlivosti \beta');
grid on;

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
