function [beta_sys, Pf_sys, groups] = pnetTieBreakFn(betaTilde, alphaTilde, rho0, tol)
% Variant of pnetSystemReliabilityFn with a DETERMINISTIC tie-break.
% Identical except: betaTilde is rounded to `tol` for ORDERING purposes
% only, so cut-sets whose betas differ merely by mvncdf QMC noise (~1e-4)
% are ordered by their original index via sort's stability, not by noise.
% Pf still uses the unrounded beta of the representative.
if nargin < 3 || isempty(rho0), rho0 = 0.7; end
if nargin < 4 || isempty(tol),  tol  = 1e-3; end

q = numel(betaTilde);
betaTilde = betaTilde(:);

betaKey = round(betaTilde / tol) * tol;
[~, order] = sortrows([betaKey, (1:q)']);     % stable, deterministic
betaSorted  = betaTilde(order);
alphaSorted = alphaTilde(order, :);

remaining = true(q,1);
groups = struct('repIdx', {}, 'members', {}, 'beta', {});
while any(remaining)
    idxRem = find(remaining);
    rep = idxRem(1);
    rho1k = alphaSorted(rep,:) * alphaSorted(idxRem,:)';
    absorbed = idxRem(rho1k >= rho0);
    g.repIdx = order(rep); g.members = order(absorbed); g.beta = betaSorted(rep);
    groups(end+1) = g; %#ok<AGROW>
    remaining(absorbed) = false;
end
Pf_i = normcdf(-[groups.beta]);
Pf_sys = min(max(1 - prod(1 - Pf_i), 0), 1);
if Pf_sys <= 0, beta_sys = Inf; elseif Pf_sys >= 1, beta_sys = -Inf;
else, beta_sys = -norminv(Pf_sys); end
end
