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

% rho0 is a correlation threshold, so a value above 1 is not merely
% unusual, it is meaningless -- and it would silently return q singleton
% groups (see the grouping loop below). Reject it rather than answer it.
if ~(isscalar(rho0) && isreal(rho0) && rho0 <= 1)
    error('pnetSystemReliabilityFn:badRho0', ...
        'rho0 is a correlation threshold and must be a real scalar <= 1; got %s.', ...
        mat2str(rho0));
end

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

    % A group always contains its own representative -- that is definitional,
    % not a correlation test. Asserting it here also makes termination
    % structural: every iteration clears at least one entry of `remaining`.
    % Relying on rho1k(1) >= rho0 instead is unsafe, because the alphaTilde
    % rows are unit-norm only to floating-point accuracy and a self-correlation
    % can evaluate just below 1 (32 of 91 do so for the Warren X-brace
    % example), which at rho0 = 1 leaves the representative ungrouped and the
    % loop spinning.
    rho1k(1) = 1;                       % idxRemaining(1) == rep by construction

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
