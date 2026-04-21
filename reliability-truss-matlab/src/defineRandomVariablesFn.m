function InputOpts = defineRandomVariablesFn(loadParams, sections, opts)
% defineRandomVariablesFn  Define random variables for UQLab reliability analysis.
%
% Random variables based on JRC TR "Reliability background of the Eurocodes"
% (2024), Table 3.7, Annex A, and EN 1991-1-3:2025.
%
% Variable ordering in UQLab vector X (nDim = nGroups + 7):
%   X(1)              = R1       — yield strength multiplier (Lognormal)
%   X(2 .. nG+1)      = d_1..d_nG — CHS outer diameters per section group [m]
%   X(nG+2)           = G_s      — self-weight multiplier (Normal)
%   X(nG+3)           = G_P      — permanent load multiplier (Normal)
%   X(nG+4)           = Q1       — ground snow annual max, normalized (Gumbel)
%   X(nG+5)           = theta_Q2 — snow time-invariant model uncert. (Lognormal)
%   X(nG+6)           = theta_b  — resistance model uncert. buckling (Lognormal)
%   X(nG+7)           = theta_E  — load effect model uncert. (Lognormal)
%
% NOTE: mu1 (snow shape factor) and Ce (exposure coefficient) are NOT random
% variables — their variability is already included in theta_Q2 per JRC TR 2024
% Annex A, Tab. A.8. They are treated deterministically per prEN 1991-1-3
% (Tab. 5.2 and Tab. 5.1 respectively) and passed via params.mu1 / params.Ce.
%
% NOTE: theta_R (tension resistance model uncertainty) is NOT a separate RV.
% Per JRC TR 2024 Annex A, Tab. A.25 note (4), model uncertainty for axial
% force yielding is already covered in R1 (yield strength) and d_sg (diameter).
% It is treated deterministically as 1.0 in the limit state function.
%
% INPUTS:
%   loadParams - struct from trussHallInputFn
%   sections   - struct with .D (nGroups x 1) nominal diameters [m]
%   opts       - (optional) struct to override default parameters:
%     .R1_cov                 (default: 0.05, mean = 1+4·V dle JRC TR Tab. A.16)
%     .d_cov                  (default: 0.005)
%     .G_s_mean, .G_s_cov     (default: 0.995, 0.025) — JRC TR 2024 Annex A, Tab. A.2
%     .G_P_mean, .G_P_cov     (default: 1.00, 0.10)  — JRC TR 2024 Annex A, Tab. A.5
%     .Q1_mean                (default: 0.308 kN/m²) — Letiště Ostrava, 1961–2022: μ=31.4 mm w.e.
%     .Q1_cov                 (default: 0.61) — COV z výběrového vzorku (n=62 let)
%     .tQ2_mean, .tQ2_cov     (default: 0.81, 0.26)  — JRC TR 2024 Annex A, Tab. A.8
%     .tb_mean, .tb_cov       (default: 1.15, 0.05)  — JRC TR 2024 Annex A, Tab. A.25
%     .tE_mean, .tE_cov       (default: 1.00, 0.05)  — JRC TR 2024 Annex A, Tab. A.22
%
% NOTE: mu1 and Ce are NOT configurable here — they are deterministic and
% passed to the LSF via lsParams.mu1 / lsParams.Ce (see systemReliabilityFn).
%
% OUTPUTS:
%   InputOpts - UQLab input options struct (pass to uq_createInput)
%
% Reference: JRC TR 2024 Annex A (Tab. A.2, A.5, A.16, A.22, A.25); EN 1991-1-3 Eq. 7.3, odd. 7.3 a 7.5
%
% (c) S. Glanc, 2026

if nargin < 3, opts = struct(); end

nG = loadParams.sectionGroups.nGroups;

% Default parameters
def = struct( ...
    'R1_cov',   0.05, ...                           % JRC TR Tab. A.16
    'R1_dist',  'Lognormal', ...
    'd_cov',    0.005, ...                          % JCSS PMC Part 3.02 / EN 10210-2
    'd_dist',   'Gaussian', ...
    'G_s_mean', 0.995,  'G_s_cov', 0.025, ...      % JRC TR 2024 Annex A, Tab. A.2
    'G_s_dist', 'Gaussian', ...
    'G_P_mean', 1.00,  'G_P_cov', 0.10, ...        % JRC TR 2024 Annex A, Tab. A.5
    'G_P_dist', 'Gaussian', ...
    'Q1_mean',  0.31,  'Q1_cov', 0.61, ...          % Letiště Ostrava Mošnov 1961–2022: μ=0.31 kN/m², COV=0.61, šikmost=1.09 (n=61, Gumbel)
    'Q1_dist',  'Gumbel', ...
    'tQ2_mean', 0.81,  'tQ2_cov', 0.26, ...        % JRC TR 2024 Annex A, Tab. A.8 (zahrnuje var. mu1, Ce, Ct)
    'tQ2_dist', 'Lognormal', ...
    'tb_mean',  1.15,  'tb_cov',  0.05, ...        % JRC TR 2024 Annex A, Tab. A.25 — column/buckling
    'tb_dist',  'Lognormal', ...
    'tE_mean',  1.00,  'tE_cov',  0.05, ...        % JRC TR 2024 Annex A, Tab. A.22 — axial forces
    'tE_dist',  'Lognormal');

% Merge user overrides
fnames = fieldnames(opts);
for k = 1:numel(fnames)
    def.(fnames{k}) = opts.(fnames{k});
end

% --- Build marginals ---
idx = 0;

% 1. Yield strength multiplier R1
%   Bias factor dle JRC TR 2024 Annex A, Tab. A.16 (ocel S235–S420):
%   f_ym/f_yk = 1 + 4·V_fy, kde f_yk je "minimum guaranteed value" (~0.1%-fraktil).
%   → R1_mean = 1 + 4·V  (= 1.20 pro V = 0.05)
R1_mean = 1 + 4 * def.R1_cov;   % = 1.20 for COV=0.05  (JRC TR Tab. A.16)
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

% nG+4. Ground snow annual maximum Q1 — skutečná data stanice
%   Q1 je přímo ve fyzikálních jednotkách [kN/m²] — bez normalizace přes s_k.
%   Parametry ze skutečných měření ročních maxim vodní hodnoty sněhu.
%   Stanice: Letiště Leoše Janáčka Ostrava, 1961–2022 (n=62 let)
%   μ = 31.4 mm w.e. = 0.308 kN/m²; COV = σ/μ = 0.61; σ = 0.188 kN/m²
%   Šikmost výběru = 0.86 (Gumbel: teor. ~1.14 — přijato Gumbel rozdělení).
Q1_mean = def.Q1_mean;
Q1_std  = Q1_mean * def.Q1_cov;
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'Q1';
InputOpts.Marginals(idx).Type = def.Q1_dist;
InputOpts.Marginals(idx).Moments = [Q1_mean, Q1_std];
fprintf('  Q1 (Gumbel, skutečná data): mean = %.4f kN/m², COV = %.2f, σ = %.4f kN/m²\n', Q1_mean, def.Q1_cov, Q1_std);

% nG+5. Snow time-invariant model uncertainty theta_Q2
%   JRC TR 2024 Annex A, Tab. A.8 — zahrnuje variabilitu mu1, Ce i Ct
%   mu1 a Ce jsou proto deterministické (viz params.mu1, params.Ce)
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'theta_Q2';
InputOpts.Marginals(idx).Type = def.tQ2_dist;
InputOpts.Marginals(idx).Moments = [def.tQ2_mean, def.tQ2_mean * def.tQ2_cov];

% nG+6. Resistance model uncertainty (buckling) theta_b
%   JRC TR 2024 Annex A, Tab. A.25 — Column / compression member buckling
%   NOTE: theta_R (tension) is NOT a separate RV — covered by R1 and d_sg per Tab. A.25 note (4)
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'theta_b';
InputOpts.Marginals(idx).Type = def.tb_dist;
InputOpts.Marginals(idx).Moments = [def.tb_mean, def.tb_mean * def.tb_cov];

% nG+7. Load effect model uncertainty theta_E
%   JRC TR 2024 Annex A, Tab. A.22 — Axial forces in frames
idx = idx + 1;
InputOpts.Marginals(idx).Name = 'theta_E';
InputOpts.Marginals(idx).Type = def.tE_dist;
InputOpts.Marginals(idx).Moments = [def.tE_mean, def.tE_mean * def.tE_cov];

fprintf('Reliability RV: %d náhodných veličin (%d průřez. skupin + 7 modelových)\n', idx, nG);

end
