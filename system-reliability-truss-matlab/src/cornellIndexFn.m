function [beta_p, rho] = cornellIndexFn(alpha, betaVec)
% cornellIndexFn  Multivariate (Cornell/PNET) reliability index of a
% parallel subsystem (Wei & Deng 2022, eq. 36-39, metodika.md section 4).
%
% A failure sequence is a parallel subsystem: ALL m elements must fail
% simultaneously (Z_i = g_i standardized). Each g_i is already expressed
% (by sequenceLimitStateFn) as a linear combination of the SAME underlying
% standard-normal RV vector U = [U_1..U_n]:
%   Z_i = alpha(i,:)*U + beta(i)      (eq. 37)
% so the elements are correlated through shared U components (shared
% resistance RVs of the same section type, shared load RVs).
%
% INPUTS:
%   alpha   - (m x n) standardized sensitivity coefficients, row i = alpha_i
%             (alpha_ij = -(dg_i/dX_j)*sigma_j / sqrt(Var[g_i]), see
%             sequenceLimitStateFn header for sign derivation)
%   betaVec - (m x 1) single-element reliability indices beta_i =
%             E[g_i]/sqrt(Var[g_i])  (so P(g_i<0) = Phi(-beta_i))
%
% OUTPUT:
%   beta_p - (scalar) system (sequence) reliability index,
%            beta_p = -Phi^-1( Phi_m(-beta; rho) )     (eq. 39)
%   rho    - (m x m) correlation matrix between the m elements,
%            rho_ij = alpha_i' * alpha_j                (eq. 38)
%
% SIGN CHECK (single-variable case): m=1, g = R - S, standardized so
% Z = alpha*U + beta with beta = E[g]/sqrt(Var[g]) > 0 when the mean margin
% is positive (safe). Phi_m collapses to normcdf, so
% beta_p = -norminv(normcdf(-beta)) = beta exactly, and
% P(g<0) = Phi(-beta) as required. Verified numerically below in the
% "self-test" used during development (see example_3story_truss.m).
%
% mvncdf CALL: MATLAB's mvncdf(X, mu, SIGMA) with X a 1xm ROW vector
% returns P(Y_1<=X_1, ..., Y_m<=X_m) for Y~N(mu,SIGMA). We want
% P(all Z_i < 0) = P(all alpha_i*U < -beta_i); with U standardized and
% rho the covariance of Z (since Var[Z_i]=1 by construction), this is
% exactly mvncdf((-beta)', zeros(1,m), rho) -- confirmed against the
% independent-case product-of-marginals identity during development.
%
% See also: sequenceLimitStateFn, mostProbableSequenceFn
%
% (c) S. Glanc, 2026

m = numel(betaVec);
betaVec = betaVec(:);

rho = alpha * alpha';
rho = (rho + rho') / 2;              % kill asymmetric round-off
rho(1:m+1:end) = 1;                  % diagonal must be exactly 1 by construction

if m == 1
    Pf_p = normcdf(-betaVec);
else
    % Regularize against a near-singular rho (elements sharing ALL RVs,
    % e.g. two sequence positions driven by identical coefficients) --
    % mvncdf tolerates mild ill-conditioning but a tiny ridge avoids
    % occasional numerical warnings without measurably changing the result.
    rhoReg = rho + 1e-10 * eye(m);
    d = sqrt(diag(rhoReg));
    rhoReg = rhoReg ./ (d * d');      % renormalize to unit diagonal

    % Sequence elements routinely share ALL underlying RVs (e.g. two
    % positions driven by the same section type and same loads) -> rho
    % near +-1 is an EXPECTED, not exceptional, case here (not a modeling
    % error), so mvncdf's "highly correlated" advisory is silenced locally.
    warnState = warning('off', 'stats:mvtcdfqmc:HighCorr');
    Pf_p = mvncdf((-betaVec)', zeros(1, m), rhoReg);
    warning(warnState);
end

Pf_p = max(Pf_p, 0);   % guard against tiny negative numerical noise
if Pf_p <= 0
    beta_p = Inf;
elseif Pf_p >= 1
    beta_p = -Inf;
else
    beta_p = -norminv(Pf_p);
end

end
