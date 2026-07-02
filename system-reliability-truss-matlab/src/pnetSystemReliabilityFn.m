function [beta_sys, Pf_sys, groups] = pnetSystemReliabilityFn(betaTilde, alphaTilde, rho0)
% pnetSystemReliabilityFn  PNET (Probabilistic NETwork) system reliability
% combination across minimal cut-sets (metodika.md section 5, eq. 48-49).
%
% Each of the q minimal cut-sets contributes ONE equivalent linear
% performance function (betaTilde_k, alphaTilde_k) from equivalentPlaneFn.
% PNET groups highly-correlated cut-sets (assumed perfectly correlated,
% rho>=rho0) under a single representative (the worst/lowest-beta in the
% group), then combines the w representative groups assuming INDEPENDENCE
% between groups:
%   Pf_sys = 1 - prod_{i=1}^{w} (1 - Pf_i),   beta_sys = -Phi^-1(Pf_sys)
%
% INPUTS:
%   betaTilde  - (q x 1) equivalent beta per cut-set
%   alphaTilde - (q x n) equivalent unit-norm sensitivity vectors (rows)
%   rho0       - (scalar, default 0.7) correlation threshold for grouping
%                (Wei & Deng's own worked example value, metodika.md sec.5)
%
% OUTPUTS:
%   beta_sys - (scalar) system reliability index
%   Pf_sys   - (scalar) system probability of failure
%   groups   - (struct array) one entry per representative group, with:
%       .repIdx    - index (into input order) of the representative cut-set
%       .members   - indices (into input order) of all cut-sets absorbed
%                    into this group (including the representative)
%       .beta      - betaTilde of the representative
%
% ALGORITHM (eq. 48-49): sort ascending by betaTilde (worst = most likely
% to fail = lowest beta first). Take the current worst remaining as a new
% representative; compute rho_1k = alphaTilde_1' * alphaTilde_k against
% every remaining (not yet grouped) cut-set k; any k with rho_1k >= rho0
% is folded into this group (assumed fully correlated -> redundant, not
% counted again). Repeat on what remains until none left.
%
% See also: equivalentPlaneFn, systemReliabilityFn
%
% (c) S. Glanc, 2026

if nargin < 3 || isempty(rho0), rho0 = 0.7; end

q = numel(betaTilde);
betaTilde = betaTilde(:);

[betaSorted, order] = sort(betaTilde, 'ascend');
alphaSorted = alphaTilde(order, :);

remaining = true(q, 1);
groups = struct('repIdx', {}, 'members', {}, 'beta', {});

while any(remaining)
    idxRemaining = find(remaining);
    rep = idxRemaining(1);          % worst (lowest beta) among remaining

    rho1k = alphaSorted(rep, :) * alphaSorted(idxRemaining, :)';   % 1 x numel(idxRemaining)
    absorbedLocal = idxRemaining(rho1k >= rho0);

    g.repIdx  = order(rep);
    g.members = order(absorbedLocal);
    g.beta    = betaSorted(rep);
    groups(end+1) = g; %#ok<AGROW>

    remaining(absorbedLocal) = false;
end

Pf_i = normcdf(-[groups.beta]);
Pf_sys = 1 - prod(1 - Pf_i);
Pf_sys = min(max(Pf_sys, 0), 1);

if Pf_sys <= 0
    beta_sys = Inf;
elseif Pf_sys >= 1
    beta_sys = -Inf;
else
    beta_sys = -norminv(Pf_sys);
end

end
