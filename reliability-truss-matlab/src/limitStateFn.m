function g_sys = limitStateFn(X, params)
% limitStateFn  System limit state function for UQLab Monte Carlo simulation.
%
% Evaluates the series system reliability of a 2D truss under gravity + snow.
% For each MC sample: assembles loads from RV realizations, solves FEM,
% checks tension and buckling for every member, returns min(g) as system LSF.
%
% Series system: g_sys <= 0  ⟺  any member fails  ⟺  system collapses
% (statically determinate truss — no redundancy).
%
% Per-member tracking: stores g values and failure mode for every member
% in every sample via persistent variable. Call limitStateFn('get_store')
% to retrieve, or limitStateFn('reset') to clear.
%
% INPUTS:
%   X      - (N × nDim) matrix of RV realizations from UQLab (nDim = nG + 7)
%            Order: [R1, d_1..d_nG, G_s, G_P, Q1, θ_Q2, θ_b, θ_E]
%            NOTE: θ_R is NOT a RV — deterministically 1.0 (JRC TR Tab. A.25 note 4)
%            NOTE: μ₁ and C_e are NOT RVs — deterministic per prEN 1991-1-3
%            (their variability included in θ_Q2 per JRC TR Annex A, Tab. A.8)
%   params - struct with pre-computed deterministic parameters:
%     .nGroups      number of section groups
%     .nmembers     number of truss members
%     .f_y_nom      [Pa] nominal yield strength
%     .s_k          [kN/m²] characteristic snow on ground
%     .t_nom        (nGroups×1) [m] nominal CHS wall thicknesses
%     .alpha_imp    (nGroups×1) imperfection factors per section group
%     .Lcr          (nmembers×1) [m] governing buckling lengths
%     .nodes        nodes struct
%     .members      members struct
%     .sections     sections struct (template — A will be overwritten)
%     .kinematic    kinematic struct
%     .loadParams   loadParams struct
%     .E            [Pa] Young's modulus (210e9)
%
% OUTPUTS:
%   g_sys  - (N × 1) system limit state values
%            g_sys > 0: safe,  g_sys <= 0: failure
%
% PERSISTENT STORAGE (retrieve via limitStateFn('get_store')):
%   .g_member      (totalSamples × nmembers) per-member g values
%   .fail_mode     (totalSamples × nmembers) 0=safe, 1=tension fail, 2=buckling fail
%   .critical_member (totalSamples × 1)      index of member with min(g)
%
% Reference:
%   EN 1993-1-1:2005 Cl. 6.2.3 (tension), Cl. 6.3.1 (buckling)
%   JRC TR Table 3.7 (RV normalization)
%
% (c) S. Glanc, 2026

persistent store;

% --- Command interface for retrieving/resetting stored data ---
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
g_sys = zeros(N_samples, 1);

nG        = params.nGroups;
nmem      = params.nmembers;
f_y_nom   = params.f_y_nom;
s_k       = params.s_k;
t_nom     = params.t_nom;
alpha_imp = params.alpha_imp;
Lcr       = params.Lcr;
E_steel   = params.E;

% Per-member storage
g_member_batch   = zeros(N_samples, nmem);
fail_mode_batch  = zeros(N_samples, nmem);   % 0=safe, 1=tension, 2=buckling
crit_member_batch = zeros(N_samples, 1);

for k = 1:N_samples
    % --- 1. Unpack RV realizations ---
    R1_k    = X(k, 1);
    d_k     = X(k, 2:nG+1);            % [m] CHS diameters per group
    G_s_k   = X(k, nG+2);
    G_P_k   = X(k, nG+3);
    Q1_k    = X(k, nG+4);
    tQ2_k   = X(k, nG+5);
    % mu1 a Ce jsou deterministické — variabilita zahrnuta v tQ2 (JRC TR Tab. A.8)
    % tR_k = 1.0  (θ_R není samostatná RV — pokryto R1 a d_sg, JRC TR Tab. A.25 pozn. 4)
    tb_k    = X(k, nG+6);
    tE_k    = X(k, nG+7);

    % --- 2. Derive physical quantities ---
    % Yield strength: R1_mean = 1+4·V (bias dle JRC TR Tab. A.16), f_yk = min. guaranteed value
    f_y_k = R1_k * f_y_nom;            % [Pa]

    % CHS geometry: A and i from random diameter d and deterministic t
    [A_k, i_k] = CHS_propertiesFn(d_k, t_nom');

    % Snow on ground → roof (EN 1991-1-3 Eq. 7.3, C_t = 1.0)
    s_g_k  = Q1_k;                     % [kN/m²] ground snow ze staničních dat
    s_roof = tQ2_k * params.mu1 * params.Ce * s_g_k;  % mu1, Ce deterministicky dle prEN; C_t = 1.0

    % --- 3. Update sections for FEM ---
    sec_k   = params.sections;
    sec_k.A = A_k(:);                  % column vector

    % --- 4. Assemble loads and solve FEM ---
    loads_k = reliabilityLoadsFn(params.loadParams, G_s_k, G_P_k, s_roof);
    [~, endForces] = linearSolverFn(sec_k, params.nodes, ...
                                     params.kinematic, params.members, loads_k);
    N_Ed = endForces.local(1, :)';     % [N], positive = tension

    % --- 5. Limit state for each member ---
    g_all = zeros(nmem, 1);
    for p = 1:nmem
        si = params.members.sections(p);

        if N_Ed(p) >= 0
            % TENSION: g = f_y · A  −  θ_E · N_Ed  (θ_R = 1.0, JRC TR Tab. A.25 pozn. 4)
            g_all(p) = 1.0 * f_y_k * A_k(si) - tE_k * N_Ed(p);
        else
            % BUCKLING: EN 1993-1-1 Cl. 6.3.1
            lam1    = pi * sqrt(E_steel / f_y_k);
            lam_bar = (Lcr(p) / i_k(si)) / lam1;
            alpha   = alpha_imp(si);
            Phi     = 0.5 * (1 + alpha * (lam_bar - 0.2) + lam_bar^2);
            chi     = min(1 / (Phi + sqrt(Phi^2 - lam_bar^2)), 1.0);

            g_all(p) = tb_k * chi * f_y_k * A_k(si) - tE_k * abs(N_Ed(p));
        end
    end

    % --- 6. Store per-member results ---
    g_member_batch(k, :) = g_all';
    for p = 1:nmem
        if g_all(p) <= 0
            if N_Ed(p) >= 0
                fail_mode_batch(k, p) = 1;   % tension failure
            else
                fail_mode_batch(k, p) = 2;   % buckling failure
            end
        end
    end

    % --- 7. Series system: min over all members ---
    [g_sys(k), crit_member_batch(k)] = min(g_all);
end

% --- 8. Append to persistent store ---
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
