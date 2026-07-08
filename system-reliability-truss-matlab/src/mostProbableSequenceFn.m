function [bestSeq, bestBetaP, allBetaP, allPerms] = mostProbableSequenceFn( ...
    nodes, members, kinematic, sections, cutSet, rvSpec, eta)
% mostProbableSequenceFn  Representative (lowest-beta_p) failure mode of a
% minimal cut-set (metodika.md section 4: "the one with the lowest beta_p
% in those failure modes corresponding to the same minimal cut set can be
% determined").
%
% Brute-forces all permutations of `cutSet` (all possible failure orders),
% computes the sequence reliability index beta_p for each via
% sequenceLimitStateFn + cornellIndexFn, and returns the minimum. This is
% only affordable because gH (hence max cut-set size gH+1) is small in
% practice (metodika.md 2.1 / the reference examples: gH<=4, so at most
% 5!=120 permutations) -- NOT suitable as-is for cut-sets much larger than
% ~8 elements (8!=40320 already borderline); a smarter approach (e.g.
% greedy/branch-and-bound on beta_p) would be needed there but is out of
% scope here.
%
% INPUTS:
%   nodes, members, kinematic, sections, rvSpec, eta - see sequenceLimitStateFn
%   cutSet - (1 x k) unordered minimal cut-set (member indices)
%
% OUTPUTS:
%   bestSeq   - (1 x k) the permutation of cutSet with lowest beta_p
%   bestBetaP - (scalar) that beta_p
%   allBetaP  - (nPerms x 1) beta_p for every permutation tried
%   allPerms  - (nPerms x k) the permutations tried (rows), same order as allBetaP
%
% See also: sequenceLimitStateFn, cornellIndexFn, equivalentPlaneFn
%
% (c) S. Glanc, 2026

if nargin < 7, eta = 0; end

cutSet  = cutSet(:)';
k       = numel(cutSet);
allPerms = perms(cutSet);          % (k! x k)
nPerms   = size(allPerms, 1);
allBetaP = zeros(nPerms, 1);

for p = 1:nPerms
    seq = sequenceLimitStateFn(nodes, members, kinematic, sections, allPerms(p, :), rvSpec, eta);
    alpha = zeros(k, size(seq(1).coeffU, 2));
    betaVec = zeros(k, 1);
    for i = 1:k
        sd = sqrt(seq(i).varG);
        alpha(i, :) = -seq(i).coeffU / sd;    % alpha_ij = -(dg_i/dX_j)*sigma_j/sqrt(Var[g_i]); coeffU already carries the (dg_i/dX_j)*sigma_j product (chain rule via standardized U)
        betaVec(i)  = seq(i).meanG / sd;
    end
    allBetaP(p) = cornellIndexFn(alpha, betaVec);
end

[bestBetaP, idx] = min(allBetaP);
bestSeq = allPerms(idx, :);

end
