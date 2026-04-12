function InputOpts = defineRandomVariablesFn(loadParams, sections, opts)
% defineRandomVariablesFn  Define random variables for UQLab reliability analysis.
%
% Random variables based on JRC TR "Reliability background of the Eurocodes"
% (2024), Table 3.7, Annex A, and EN 1991-1-3:2025.
%
% Variable ordering in UQLab vector X (nDim = nGroups + 10):
%   X(1)              = R1       — yield strength multiplier (Lognormal)
%   X(2 .. nG+1)      = d_1..d_nG — CHS outer diameters per section group [m]
%   X(nG+2)           = G_s      — self-weight multiplier (Normal)
%   X(nG+3)           = G_P      — permanent load multiplier (Normal)
%   X(nG+4)           = Q1       — ground snow 50-yr max, normalized (Gumbel)
%   X(nG+5)           = theta_Q2 — snow time-invariant model uncert. (Lognormal)
%   X(nG+6)           = mu1      — snow shape factor (Lognormal)
%   X(nG+7)           = Ce       — exposure coefficient (Lognormal)
%   X(nG+8)           = theta_R  — resistance model uncert. tension (Lognormal)
%   X(nG+9)           = theta_b  — resistance model uncert. buckling (Lognormal)
%   X(nG+10)          = theta_E  — load effect model uncert. (Lognormal)
%
% INPUTS:
%   loadParams - struct from trussHallInputFn
%   sections   - struct with .D (nGroups x 1) nominal diameters [m]
%   opts       - (optional) struct to override default parameters:
%     .R1_cov                 (default: 0.05, mean auto-computed: 5%-fraktil=1)
%     .d_cov                  (default: 0.005)
%     .G_s_mean, .G_s_cov     (default: 1.00, 0.025)
%     .G_P_mean, .G_P_cov     (default: 1.00, 0.10)
%     .Q1_cov                 (default: 0.20, mean auto-computed: 98%-fraktil=1)
%     .tQ2_mean, .tQ2_cov     (default: 0.81, 0.26)
%     .mu1_mean, .mu1_cov     (default: 0.8*Ce_mean, 0.20)
%     .Ce_mean, .Ce_cov       (default: 1.00, 0.15)
%     .tR_mean, .tR_cov       (default: 1.15, 0.05)
%     .tb_mean, .tb_cov       (default: 1.00, 0.10)
%     .tE_mean, .tE_cov       (default: 1.00, 0.05)
%
% OUTPUTS:
%   InputOpts - UQLab input options struct (pass to uq_createInput)
%
% Reference: JRC TR Table 3.7, Annex A (Tab. A.4), EN 1991-1-3:2025 Eq. 7.3
%
% (c) S. Glanc, 2026

if nargin < 3, opts = struct(); end

nG = loadParams.sectionGroups.nGroups;

% Default parameters (JRC TR Table 3.7)
def = struct( ...
    'R1_cov',   0.05, ...
    'R1_dist',  'Lognormal', ...
    'd_cov',    0.005, ...
    'd_dist',   'Gaussian', ...
    'G_s_mean', 1.00,  'G_s_cov', 0.025, ...
    'G_s_dist', 'Gaussian', ...
    'G_P_mean', 1.00,  'G_P_cov', 0.10, ...
    'G_P_dist', 'Gaussian', ...
    'Q1_cov',   0.20, ...
    'Q1_dist',  'Gumbel', ...
    'tQ2_mean', 0.81,  'tQ2_cov', 0.26, ...
    'tQ2_dist', 'Lognormal', ...
    'mu1_mean', 0.80,  'mu1_cov', 0.20, ...
    'mu1_dist', 'Lognormal', ...
    'Ce_mean',  1.00,  'Ce_cov',  0.15, ...
    'Ce_dist',  'Lognormal', ...
    'tR_mean',  1.15,  'tR_cov',  0.05, ...
    'tR_dist',  'Lognormal', ...
    'tb_mean',  1.00,  'tb_cov',  0.10, ...
    'tb_dist',  'Lognormal', ...
    'tE_mean',  1.00,  'tE_cov',  0.05, ...
    'tE_dist',  'Lognormal');

% Merge user overrides
fnames = fieldnames(opts);
for k = 1:numel(fnames)
    def.(fnames{k}) = opts.(fnames{k});
end

% --- Build marginals ---
idx = 0;

% 1. Yield strength multiplier R1
%   R1 normalized so that 5% fractile = 1.0 (→ f_y at 5% = f_y_k)
%   For Lognormal: x_0.05 = μ · exp(-1.645·σ_ln) ≈ μ · exp(-1.645·COV) for small COV
R1_mean = 1.0 / exp(-1.645 * def.R1_cov);   % ≈ 1.086 for COV=0.05
R1_std  = R1_mean * def.R1_cov;
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'R1';
InputOpts.Marginals(idx).Type = def.R1_dist;
InputOpts.Marginals(idx).Moments = [R1_mean, R1_std];

% 2..nG+1. CHS diameters per section group
for sg = 1:nG
    idx = idx + 1;
    InputOpts.Marginals(idx).Name = sprintf('d_%d', sg);
    InputOpts.Marginals(idx).Type = def.d_dist;
    d_nom = sections.D(sg);
    InputOpts.Marginals(idx).Moments = [d_nom, d_nom * def.d_cov];
end

% nG+2. Self-weight multiplier G_s
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'G_s';
InputOpts.Marginals(idx).Type = def.G_s_dist;
InputOpts.Marginals(idx).Moments = [def.G_s_mean, def.G_s_mean * def.G_s_cov];

% nG+3. Permanent load multiplier G_P
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'G_P';
InputOpts.Marginals(idx).Type = def.G_P_dist;
InputOpts.Marginals(idx).Moments = [def.G_P_mean, def.G_P_mean * def.G_P_cov];

% nG+4. Ground snow 50-yr max Q1 (normalized Gumbel)
%   Q1 is normalized so that its 98% fractile = 1.0 (= s_k when multiplied).
%   For Gumbel: x_0.98 = μ·(1 + K98·V), where K98 = (√6/π)·(γ + ln(-ln(0.98))) = 2.593
%   → μ = 1 / (1 + K98·V)
K98_gumbel = (sqrt(6)/pi) * (0.5772 + abs(log(-log(0.98))));  % ≈ 2.593
Q1_mean = 1.0 / (1 + K98_gumbel * def.Q1_cov);
Q1_std  = Q1_mean * def.Q1_cov;
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'Q1';
InputOpts.Marginals(idx).Type = def.Q1_dist;
InputOpts.Marginals(idx).Moments = [Q1_mean, Q1_std];
fprintf('  Q1 (Gumbel): mean = %.4f, COV = %.2f, 98%%-fraktil ≈ 1.0\n', Q1_mean, def.Q1_cov);

% nG+5. Snow time-invariant model uncertainty theta_Q2
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'theta_Q2';
InputOpts.Marginals(idx).Type = def.tQ2_dist;
InputOpts.Marginals(idx).Moments = [def.tQ2_mean, def.tQ2_mean * def.tQ2_cov];

% nG+6. Snow shape factor mu1
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'mu1';
InputOpts.Marginals(idx).Type = def.mu1_dist;
InputOpts.Marginals(idx).Moments = [def.mu1_mean, def.mu1_mean * def.mu1_cov];

% nG+7. Exposure coefficient Ce
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'Ce';
InputOpts.Marginals(idx).Type = def.Ce_dist;
InputOpts.Marginals(idx).Moments = [def.Ce_mean, def.Ce_mean * def.Ce_cov];

% nG+8. Resistance model uncertainty (tension) theta_R
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'theta_R';
InputOpts.Marginals(idx).Type = def.tR_dist;
InputOpts.Marginals(idx).Moments = [def.tR_mean, def.tR_mean * def.tR_cov];

% nG+9. Resistance model uncertainty (buckling) theta_b
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'theta_b';
InputOpts.Marginals(idx).Type = def.tb_dist;
InputOpts.Marginals(idx).Moments = [def.tb_mean, def.tb_mean * def.tb_cov];

% nG+10. Load effect model uncertainty theta_E
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'theta_E';
InputOpts.Marginals(idx).Type = def.tE_dist;
InputOpts.Marginals(idx).Moments = [def.tE_mean, def.tE_mean * def.tE_cov];

fprintf('Reliability RV: %d náhodných veličin (%d průřez. skupin + 10 modelových)\n', idx, nG);

end
