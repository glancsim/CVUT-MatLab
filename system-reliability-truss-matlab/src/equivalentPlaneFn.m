function [betaTilde, alphaTilde] = equivalentPlaneFn(alpha, betaVec)
% equivalentPlaneFn  Equivalent (linearized) performance function for a
% failure sequence's representative (lowest-beta_p) failure mode
% (metodika.md section 4, Wei & Deng eq. 40-47).
%
% A failure sequence's true system event {all Z_i<0} is NOT itself linear
% in U, so it cannot be directly correlated (via a simple alpha'*alpha
% inner product) against another cut-set's representative sequence. Wei &
% Deng's fix: replace it with ONE equivalent linear performance function
%   Z~_k = alphaTilde_k' * U + betaTilde_k
% matching (a) the same beta (eq. 45: betaTilde_k = beta_p) and (b) the
% same FIRST-ORDER sensitivity of beta_p to a small perturbation of each
% U_j (eq. 46-47), i.e. alphaTilde_kj = (d beta_p(eps)/d eps_j)|_{eps=0},
% normalized to unit length.
%
% IMPLEMENTATION: analytic differentiation of beta_p = -Phi^-1(Phi_m(-beta;
% rho)) w.r.t. a mean-shift eps_j of U_j is awkward (rho itself does not
% depend on eps, only the integration limits -beta shift by
% eps_j*alpha(:,j) via the chain rule of "perturbing U_j's mean" -- eq.
% 41-44 -- but MATLAB has no closed-form gradient of mvncdf w.r.t. its
% integration limits beyond univariate Genz-algorithm internals). Falls
% back to a CENTRAL finite difference, as the task brief explicitly
% allows: perturb U_j's effective mean by +-h, which shifts every
% sequence element's standardized margin by mp*alpha_i(j) (a mean-shift of
% U_j by h moves Z_i's mean by h*alpha_i(j) with everything else fixed),
% recompute beta_p via cornellIndexFn on the shifted beta vector, and
% central-difference over h.
%
% INPUTS:
%   alpha   - (m x n) standardized sensitivities of the sequence's m
%             elements (rows) to the shared U vector (n components) --
%             same convention as cornellIndexFn's `alpha` input
%   betaVec - (m x 1) single-element beta_i (same convention as cornellIndexFn)
%
% OUTPUTS:
%   betaTilde  - (scalar) = beta_p of the sequence (eq. 45)
%   alphaTilde - (1 x n) unit-norm equivalent sensitivity vector (eq. 46-47)
%
% STEP SIZE: h=1e-3 (perturbation of a standard-normal mean) -- small
% enough for a good local-linear approximation, large enough to avoid
% cancellation error in the central difference of beta_p (which is itself
% obtained from mvncdf, accurate to ~1e-8 in typical use).
%
% See also: cornellIndexFn, mostProbableSequenceFn, pnetSystemReliabilityFn
%
% (c) S. Glanc, 2026

[m, n] = size(alpha);
betaVec = betaVec(:);

betaTilde = cornellIndexFn(alpha, betaVec);

h = 1e-3;
grad = zeros(1, n);
for j = 1:n
    % Perturbing U_j's mean by +h shifts every Z_i's mean by +h*alpha_i(j)
    % (Z_i = alpha_i*U + beta_i; a mean-shift E[U_j]=h with everything
    % else fixed adds h*alpha_i(j) to E[Z_i], i.e. to beta_i since
    % beta_i = E[Z_i] when Var[Z_i]=1).
    betaPlus  = cornellIndexFn(alpha, betaVec + h * alpha(:, j));
    betaMinus = cornellIndexFn(alpha, betaVec - h * alpha(:, j));
    grad(j) = (betaPlus - betaMinus) / (2 * h);
end

normGrad = norm(grad);
if normGrad > 0
    alphaTilde = grad / normGrad;
else
    alphaTilde = zeros(1, n);
end

end
