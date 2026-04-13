function reliabilityReportFn(results, sections, loadParams)
% reliabilityReportFn  Print reliability analysis results to console.
%
% Outputs:
%   1. Summary of random variables
%   2. System reliability results (Pf, beta, CoV)
%   3. Per-member failure probability table (estimated from MC)
%   4. Comparison with target beta
%
% INPUTS:
%   results    - output of systemReliabilityFn
%   sections   - sections struct (for member labeling)
%   loadParams - loadParams struct (for context)
%
% (c) S. Glanc, 2026

nG = results.params.nGroups;
nmem = results.params.nmembers;
classification = results.classification;

%% 1. Header
fprintf('\n');
fprintf('╔══════════════════════════════════════════════════════════════════╗\n');
fprintf('║  SPOLEHLIVOSTNÍ ANALÝZA — Monte Carlo                          ║\n');
fprintf('║  Sériový systém (příhradový vazník)                            ║\n');
fprintf('╠══════════════════════════════════════════════════════════════════╣\n');
fprintf('║  Zatížení:     G + S (gravitace + sníh)                        ║\n');
fprintf('║  Norma:        EN 1993-1-1, JRC TR Tab. 3.7                    ║\n');
fprintf('║  Cílový β:     3.8 (CC2, 50 let)                               ║\n');
fprintf('╚══════════════════════════════════════════════════════════════════╝\n');

%% 2. Random variables
fprintf('\n── Náhodné veličiny (%d) ──────────────────────\n', nG + 10);
fprintf('  %-12s  %-12s  %8s  %8s\n', 'Proměnná', 'Distribuce', 'Střed', 'COV');
fprintf('  %-12s  %-12s  %8s  %8s\n', '--------', '----------', '-----', '---');
fprintf('  %-12s  %-12s  %8.3f  %8.3f\n', 'R1 (f_y)',    'Lognormal', 1.00, 0.05);
for sg = 1:nG
    fprintf('  d_%d (D=%.0fmm) %-8s  %8.4f  %8.3f\n', ...
        sg, sections.D(sg)*1e3, 'Normal', sections.D(sg), 0.005);
end
fprintf('  %-12s  %-12s  %8.3f  %8.3f\n', 'G_s',       'Normal',    1.00, 0.025);
fprintf('  %-12s  %-12s  %8.3f  %8.3f\n', 'G_P',       'Normal',    1.00, 0.10);
fprintf('  %-12s  %-12s  %8.3f  %8.3f\n', 'Q1 (sníh)', 'Gumbel',    1.00, 0.20);
fprintf('  %-12s  %-12s  %8.3f  %8.3f\n', 'θ_Q2',      'Lognormal', 0.81, 0.26);
fprintf('  %-12s  %-12s  %8.3f  %8.3f\n', 'μ₁',        'Lognormal', 0.80, 0.20);
fprintf('  %-12s  %-12s  %8.3f  %8.3f\n', 'C_e',       'Lognormal', 1.00, 0.15);
fprintf('  %-12s  %-12s  %8.3f  %8.3f\n', 'θ_R',       'Lognormal', 1.15, 0.05);
fprintf('  %-12s  %-12s  %8.3f  %8.3f\n', 'θ_b',       'Lognormal', 1.00, 0.10);
fprintf('  %-12s  %-12s  %8.3f  %8.3f\n', 'θ_E',       'Lognormal', 1.00, 0.05);

%% 3. System results
fprintf('\n── Systémová spolehlivost ─────────────────────\n');
fprintf('  P_f          = %.4e\n', results.Pf);
fprintf('  β            = %.3f\n', results.beta);
fprintf('  CoV(P_f)     = %.1f %%\n', results.Pf_CoV * 100);
fprintf('  Vzorky       = %.0e\n', results.nSamples);
fprintf('  Selhání      = %d\n', results.nFailures);
fprintf('  Čas výpočtu  = %.1f s\n', results.elapsed);

if results.beta >= 3.8
    fprintf('  Posudek:     VYHOVUJE  (β = %.2f ≥ 3.8)\n', results.beta);
else
    fprintf('  Posudek:     NEVYHOVUJE  (β = %.2f < 3.8)\n', results.beta);
end

%% 4. Cross-check with JRC Table 3.8
fprintf('\n── Srovnání s JRC TR Tab. 3.8 ─────────────────\n');
fprintf('  JRC průměr (ocel + sníh, 1 prut): β ≈ 3.17\n');
fprintf('  Systémové β (sériový systém):     β = %.2f\n', results.beta);
if results.beta < 3.17
    fprintf('  → Systémové β < JRC prut → konzistentní (sériový systém snižuje β)\n');
else
    fprintf('  → Systémové β ≥ JRC prut → konstrukce má rezervu\n');
end

fprintf('\n');

end
