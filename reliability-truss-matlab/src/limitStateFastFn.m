function g_sys = limitStateFastFn(X, params)
% limitStateFastFn  Vectorized system LSF using precomputed influence coefficients.
%
% Instead of calling linearSolverFn for every MC sample, this function
% uses the superposition principle for linear analysis:
%
%   N_Ed = G_P · N_perm  +  s_roof · N_snow  +  G_s · N_sw
%
% where N_perm, N_snow, N_sw are precomputed from 3 unit-load FEM solves.
% This reduces each MC evaluation from a full FEM solve (~0.5 ms) to
% a few vector operations (~0.001 ms) — roughly 500× speedup.
%
% Validity: exact for statically determinate trusses. For indeterminate
% trusses, neglects the tiny effect of EA variation (d COV=0.005) on
% force distribution — error < 0.01%.
%
% Per-member tracking: identical to limitStateFn — uses persistent storage.
% Call limitStateFastFn('get_store') / limitStateFastFn('reset').
%
% INPUTS:
%   X      - (N × nDim) matrix of RV realizations
%   params - struct (same as limitStateFn) with extra precomputed fields:
%     .N_perm   (nmembers×1) member forces [N] for unit permanent load
%     .N_snow   (nmembers×1) member forces [N] for unit snow load (1 kN/m²)
%     .N_sw     (nmembers×1) member forces [N] for unit self-weight
%
% (c) S. Glanc, 2026

persistent store;

if ischar(X)
    switch X
        case 'get_store'
            g_sys = store;
            return;
        case 'reset'
            store = [];
            g_sys = [];
            return;
    end
end

N_samples = size(X, 1);
nG        = params.nGroups;
nmem      = params.nmembers;
f_y_nom   = params.f_y_nom;
s_k       = params.s_k;
t_nom     = params.t_nom(:)';
alpha_imp = params.alpha_imp;
Lcr       = params.Lcr;
E_steel   = params.E;
secIdx    = params.members.sections;   % (nmem×1) section index per member

% Precomputed influence vectors
N_perm = params.N_perm;   % (nmem×1) [N]
N_snow = params.N_snow;   % (nmem×1) [N]
N_sw   = params.N_sw;     % (nmem×1) [N]

% --- Unpack all RV columns at once (N_samples × 1 each) ---
R1    = X(:, 1);
d_all = X(:, 2:nG+1);             % (N×nG) diameters [m]
G_s   = X(:, nG+2);
G_P   = X(:, nG+3);
Q1    = X(:, nG+4);
tQ2   = X(:, nG+5);
mu1   = X(:, nG+6);
% Ce  = X(:, nG+7);               % not used directly
tR    = X(:, nG+8);
tb    = X(:, nG+9);
tE    = X(:, nG+10);

% --- Derived quantities (vectorized over samples) ---
f_y = R1 * f_y_nom;                              % (N×1) R1 norm: 5%-fraktil = 1.0
s_g = Q1 * s_k;                                  % (N×1) ground snow [kN/m²]
s_roof = tQ2 .* mu1 .* s_g;                     % (N×1) roof snow [kN/m²]

% --- CHS properties per sample per group ---
% A(k,sg) = pi/4 * (d^2 - (d-2t)^2) = pi * t * (d - t)
% Vectorized: (N×nG)
d_inner = d_all - 2 * t_nom;                    % (N×nG)
A_all = pi/4 * (d_all.^2 - d_inner.^2);         % (N×nG)
I_all = pi/64 * (d_all.^4 - d_inner.^4);        % (N×nG)
i_all = sqrt(I_all ./ A_all);                   % (N×nG)

% --- Member forces via superposition (N × nmem) ---
N_Ed_all = G_P .* N_perm' + s_roof .* N_snow' + G_s .* N_sw';   % (N×nmem)

% --- Limit state evaluation (vectorized over samples, loop over members) ---
g_sys = zeros(N_samples, 1);
g_member_batch   = zeros(N_samples, nmem);
fail_mode_batch  = zeros(N_samples, nmem);
crit_member_batch = zeros(N_samples, 1);

% Precompute lambda_1 per sample
lam1 = pi * sqrt(E_steel ./ f_y);               % (N×1)

for p = 1:nmem
    si = secIdx(p);
    N_Ed_p = N_Ed_all(:, p);                     % (N×1)
    A_p    = A_all(:, si);                       % (N×1)
    i_p    = i_all(:, si);                       % (N×1)
    alpha_p = alpha_imp(si);
    Lcr_p   = Lcr(p);

    is_tension = N_Ed_p >= 0;

    % Tension members
    g_member_batch(is_tension, p) = ...
        tR(is_tension) .* f_y(is_tension) .* A_p(is_tension) ...
        - tE(is_tension) .* N_Ed_p(is_tension);

    % Compression members — buckling
    is_comp = ~is_tension;
    if any(is_comp)
        lam_bar = (Lcr_p ./ i_p(is_comp)) ./ lam1(is_comp);
        Phi = 0.5 * (1 + alpha_p * (lam_bar - 0.2) + lam_bar.^2);
        chi = min(1 ./ (Phi + sqrt(Phi.^2 - lam_bar.^2)), 1.0);

        g_member_batch(is_comp, p) = ...
            tb(is_comp) .* chi .* f_y(is_comp) .* A_p(is_comp) ...
            - tE(is_comp) .* abs(N_Ed_p(is_comp));
    end

    % Failure mode tracking
    failed = g_member_batch(:, p) <= 0;
    fail_mode_batch(failed & is_tension, p)  = 1;
    fail_mode_batch(failed & is_comp, p)     = 2;
end

% Series system: min over all members
[g_sys, crit_member_batch] = min(g_member_batch, [], 2);

% Append to persistent store
if isempty(store)
    store.g_member        = g_member_batch;
    store.fail_mode       = fail_mode_batch;
    store.critical_member = crit_member_batch;
else
    store.g_member        = [store.g_member;        g_member_batch];
    store.fail_mode       = [store.fail_mode;       fail_mode_batch];
    store.critical_member = [store.critical_member;  crit_member_batch];
end

end
