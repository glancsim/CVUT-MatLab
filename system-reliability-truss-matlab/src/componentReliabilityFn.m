function results = componentReliabilityFn(nodes, members, kinematic, sections, rvSpec)
% componentReliabilityFn  Per-member ("component") reliability index on the
% INTACT structure, ignoring system redundancy/redistribution entirely --
% the classical g_i = R_i - S_i check applied independently to every
% member, as if it were a statically determinate series system
% (reliability-truss-matlab's g_sys = min_p g_p world view).
%
% Reuses sequenceLimitStateFn with a SINGLETON sequence [i] for each member
% i in turn: with removedSoFar empty, b_ij is evaluated on the full,
% undamaged structure, and pos=1 means the a_il/eta residual-redistribution
% term never applies (aRow is empty regardless of eta) -- so this is exactly
% the single-member g_i = R_i - S_i, independent of the ductile/brittle
% modeling choice used elsewhere in this module. beta_i = meanG_i/sqrt(varG_i)
% is EXACT (not a first-order approximation): g_i is already an exact linear
% Gaussian combination by construction (see sequenceLimitStateFn header),
% same identity cornellIndexFn's own header verifies for its m=1 case.
%
% Intended use: contrast against systemReliabilityFn's beta_sys. Component
% reliability answers "how safe is bar i in isolation"; system reliability
% answers "how safe is the structure", crediting redundancy that keeps it
% standing after individual bar failures. The gap between min(beta) here
% and beta_sys is the redundancy benefit -- exactly what a paper comparing
% "pure component" vs "system" reliability wants to show.
%
% INPUTS: nodes, members, kinematic, sections, rvSpec -- see
%   sequenceLimitStateFn (same rvSpec.resGroup/resMean/resStd/loadCases/
%   loadMean/loadStd format).
%
% OUTPUT: results - struct
%   .member  - (nmembers x 1) member index, 1:nmembers
%   .beta    - (nmembers x 1) component reliability index beta_i
%   .Pf      - (nmembers x 1) component failure probability Phi(-beta_i)
%   .sortIdx - (nmembers x 1) member indices sorted by ascending beta
%              (most critical / weakest-link-first)
%
% See also: sequenceLimitStateFn, systemReliabilityFn, cornellIndexFn
%
% (c) S. Glanc, 2026

nmembers = members.nmembers;
if isempty(nmembers), nmembers = numel(members.nodesHead); end

beta = zeros(nmembers, 1);
for i = 1:nmembers
    seq = sequenceLimitStateFn(nodes, members, kinematic, sections, i, rvSpec, 0);
    beta(i) = seq.meanG / sqrt(seq.varG);
end
Pf = normcdf(-beta);

[~, sortIdx] = sort(beta, 'ascend');

results.member  = (1:nmembers)';
results.beta    = beta;
results.Pf      = Pf;
results.sortIdx = sortIdx;

end
