function result = sectionCheckFn(N_Ed, A, i_radius, f_y, L_cr, curve, D, t)
% sectionCheckFn  EN 1993-1-1 cross-section and buckling resistance check.
%
% Performs:
%   - Cross-section class check (CHS, EN 1993-1-1 Tab. 5.2)
%   - Cross-section tension resistance  (Cl. 6.2.3) — plastic, Class 1/2
%   - Flexural buckling resistance      (Cl. 6.3.1) — includes χ reduction
%
% For compression the buckling check (N_b,Rd = χ·A·f_y/γ_M1) always governs
% over the cross-section check (N_c,Rd = A·f_y/γ_M0) because χ ≤ 1.
%
% INPUTS:
%   N_Ed      [N]   Design axial force (positive = tension, negative = compression)
%   A         [m²]  Cross-sectional area
%   i_radius  [m]   Radius of gyration (minimum, for CHS: iy = iz)
%   f_y       [Pa]  Yield strength
%   L_cr      [m]   Governing buckling length (max of in-plane / out-of-plane)
%   curve     char  Buckling curve: 'a', 'b', 'c', or 'd'
%                   (hot-finished CHS → 'a', α = 0.21)
%   D         [m]   (optional) CHS outer diameter — used for class check
%   t         [m]   (optional) CHS wall thickness — used for class check
%
% OUTPUTS:
%   result - struct with fields:
%     .N_pl_Rd    [kN]  Plastic cross-section resistance
%     .N_b_Rd     [kN]  Buckling resistance (compression only)
%     .chi              Reduction factor χ (1.0 for tension)
%     .lambda_bar       Relative slenderness λ̄
%     .util_tension     Utilization ratio (tension check)
%     .util_buckling    Utilization ratio (buckling check, 0 for tension)
%     .util_max         max(util_tension, util_buckling)
%     .status           'OK' or 'FAIL'
%
% Reference: EN 1993-1-1:2005, Cl. 6.2.4, 6.3.1
%
% (c) S. Glanc, 2026

E      = 210e9;   % [Pa] Young's modulus
gM0    = 1.0;     % γ_M0 per Czech NA
gM1    = 1.0;     % γ_M1 per Czech NA

%% Cross-section class (CHS, EN 1993-1-1 Tab. 5.2 — compressed element)
% Only checked when D and t are provided.
section_class = NaN;   % unknown if geometry not provided
if nargin >= 8 && ~isempty(D) && ~isempty(t)
    epsilon = sqrt(235e6 / f_y);           % ε = √(235/f_y)  [-]
    dt = D / t;                             % D/t ratio
    if dt <= 50 * epsilon^2
        section_class = 1;
    elseif dt <= 70 * epsilon^2
        section_class = 2;
    elseif dt <= 90 * epsilon^2
        section_class = 3;
    else
        section_class = 4;
        warning('sectionCheckFn: průřez CHS D/t=%.1f je třída 4 — posudek N_eff nutný!', dt);
    end
    if section_class >= 3
        warning('sectionCheckFn: průřez CHS D/t=%.1f → třída %d, N_pl,Rd není platné.', ...
            dt, section_class);
    end
end

% Cross-section resistance (plastic → valid for Class 1 and 2)
N_pl_Rd = A * f_y / gM0;   % [N]

% Imperfection factor α per Tab. 6.1
switch lower(curve)
    case 'a0', alpha = 0.13;
    case 'a',  alpha = 0.21;
    case 'b',  alpha = 0.34;
    case 'c',  alpha = 0.49;
    case 'd',  alpha = 0.76;
    otherwise, error('sectionCheckFn: unknown buckling curve ''%s''', curve);
end

% Relative slenderness λ̄ = (L_cr / i) / λ_1,  λ_1 = π√(E/f_y)
lambda_1   = pi * sqrt(E / f_y);
lambda_bar = (L_cr / i_radius) / lambda_1;

% Buckling reduction factor χ (EN 1993-1-1 Eq. 6.49)
Phi = 0.5 * (1 + alpha * (lambda_bar - 0.2) + lambda_bar^2);
chi = min(1.0 / (Phi + sqrt(Phi^2 - lambda_bar^2)), 1.0);

% Buckling resistance
N_b_Rd = chi * A * f_y / gM1;   % [N]

% Utilization ratios
if N_Ed >= 0
    % Tension
    util_tension  = N_Ed / N_pl_Rd;
    util_buckling = 0;
else
    % Compression — check cross-section AND buckling
    util_tension  = 0;
    util_buckling = abs(N_Ed) / N_b_Rd;
end

util_max = max(util_tension, util_buckling);

result.N_pl_Rd       = N_pl_Rd / 1e3;   % store as [kN]
result.N_b_Rd        = N_b_Rd  / 1e3;   % store as [kN]
result.chi           = chi;
result.lambda_bar    = lambda_bar;
result.section_class = section_class;    % 1/2/3/4 or NaN if unknown
result.util_tension  = util_tension;
result.util_buckling = util_buckling;
result.util_max      = util_max;
result.status        = 'OK';
if util_max > 1.0
    result.status = 'FAIL';
end

end
