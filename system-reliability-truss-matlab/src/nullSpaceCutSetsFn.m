function [cutSets, gH, V] = nullSpaceCutSetsFn(A)
% nullSpaceCutSetsFn  Enumerate all minimal cut-sets of a pin-jointed truss
% via the null-space method of Wei & Deng (2022), Structural Safety 95:102175.
%
% A minimal cut-set is a minimal set of members whose SIMULTANEOUS removal
% turns the truss into a mechanism (rank-deficient equilibrium matrix), while
% no proper subset of it does. See metodika.md section 2 for the full
% derivation (Lemma 1, Lemma 2).
%
% INPUT:
%   A  - (N x nel) equilibrium matrix (see equilibriumMatrixFn), N = free DOFs
%
% OUTPUTS:
%   cutSets - cell array, each entry a 1xk row vector of member indices
%             (ascending, minimal cut-set)
%   gH      - (scalar) degree of static indeterminacy = nel - rank(A)
%             = dimension of the null space (number of independent states
%             of self-stress)
%   V       - (nel x gH) null-space basis of A (AV = 0), PRE-reduction
%             (i.e. before removing necessary-bar rows) — kept for Phase C
%             (states of self-stress needed for redistribution analysis).
%
% ALGORITHM — direct Lemma 1 / Lemma 2 enumeration (see metodika.md sec. 2):
%   1. SVD of A -> null space basis V (nel x gH).
%   2. Zero rows of V (Lemma 1) -> necessary bars -> cut-sets of size 1.
%   3. Remove those rows -> V' (b' x gH). For k = 2, 3, ..., gH+1: test every
%      k-subset of the b' remaining rows for rank(V_r) < k (eq. 22 — a
%      dependent set). No k-subset can be dependent for k > gH+1 (any
%      gH+1 vectors in a gH-dim space are automatically dependent, so
%      gH+1 is the maximum possible cut-set size).
%   4. Minimality (eq. 33): a dependent k-subset is a MINIMAL cut-set iff
%      every (k-1)-subset of it has full rank k-1. Skip any k-subset that
%      properly contains an already-found smaller cut-set (equivalent to,
%      but cheaper than, re-testing every (k-1)-subset from scratch once
%      k>=3, since minimality is monotonic: if a (k-1)-subset were
%      dependent it would already have been recorded at the previous k).
%   5. Deduplicate cut-sets (as sets) — not required by construction here
%      (each subset is tested exactly once) but kept for robustness.
%
% IMPLEMENTATION NOTE — WHY NOT THE "ROW-ECHELON STEPS" HEURISTIC: an
% earlier version of this file attempted to reproduce Wei & Deng's stated
% chapter-4 procedure literally (row-echelon reduction of V'^T with column
% swaps into gH "steps", then testing gamma_p = (V_b^T)^-1 * v_p for a
% SINGLE outside column p per candidate basis). That construction only
% ever adds ONE element outside a chosen gH-basis, so it can only ever
% find cut-sets of size <= gH+1 that decompose as "1 new element + a
% subset of ONE particular basis". It was verified against the 15-bar
% reference truss (metodika.md sec. 2, Wei & Deng kap. 6.1) and:
%   - correctly reproduces the paper's 2 necessary bars ({6},{13}),
%   - correctly reproduces all 20 reported size-2 cut-sets,
%   - correctly reproduces all 10 reported size-3 cut-sets,
%   - but ALSO finds 25 additional size-4 cut-sets, e.g. [1,3,8,10], that
%     do NOT appear in the paper's reported list of 32.
% These 25 extra sets were cross-checked THREE independent ways: (a) via
% this function's subset-rank search on V, (b) by directly computing
% rank(A_with_columns_removed) on the FULL equilibrium matrix (confirms
% removing e.g. members {1,3,8,10} really does drop the structure's rank
% below N, i.e. a genuine mechanism), and (c) by perturbing the geometry
% slightly (breaking exact symmetry) to rule out a knife-edge numerical
% coincidence — the extra cut-sets persist. Exhaustive brute force over
% ALL C(13,4)=715 four-element subsets of the reduced 15-bar truss found
% EXACTLY 25 such sets (all of the form {8,10} + one of {1,2,5,11,12} +
% one of {3,4,7,14,15} — 5x5=25 exactly), so this is a real, reproducible,
% non-numerical-noise structural property of the reconstructed geometry,
% not a bug in the rank/tolerance logic.
%
% Given this, the function below implements the mathematically exhaustive,
% directly-verifiable Lemma 1 + Lemma 2 subset search rather than trying to
% further reverse-engineer the paper's exact "steps" heuristic (which this
% investigation could not make match 32 without either missing genuine
% cut-sets or silently suppressing correct ones — see example_15bar_truss.m
% for the full discrepancy report). Small trusses (gH <= ~7, as expected
% per metodika.md) keep C(b', k) combinatorially tractable for k <= gH+1.
%
% NUMERICAL TOLERANCES:
%   rank/rowTol: consistent with MATLAB's own rank() convention, scaled by
%   problem size, so gH and all subset-rank tests use the same yardstick.
%
% COST: worst case ~sum_k C(b', k) * C(k, k-1) rank() calls for
% k=2..gH+1 — for gH<=7 and b'~15-20 (per metodika.md's stated scope,
% e.g. the 2024-paper's 16-element/78-cut-set structure) this is at most
% a few hundred thousand small-matrix rank() calls, seconds not minutes.
% Not optimized further per metodika.md's own MVP note (brute force over
% Pi b_i is explicitly called out as acceptable there for small gH).
%
% See also: equilibriumMatrixFn
%
% (c) S. Glanc, 2026

[~, nel] = size(A);   % A is N x nel (free DOFs x members) — nel = member count

%--------------------------------------------------------------------------
% STEP 1 — null space via SVD. Tolerance follows MATLAB's own rank()
% convention (max(size)*eps*largest singular value) since gH is obtained
% as a rank deficiency and must be consistent with any later rank() calls.
%--------------------------------------------------------------------------
[~, S, Vfull] = svd(A);
s = diag(S);
if isempty(s), s = 0; end
tol = max(size(A)) * eps(max(s));
r  = sum(s > tol);
gH = nel - r;

V = Vfull(:, r+1:end);   % (nel x gH) null space basis, AV = 0

cutSets = {};

if gH == 0
    return;   % statically determinate (or unstable with no self-stress) — no redundancy to speak of
end

%--------------------------------------------------------------------------
% STEP 2 — Lemma 1: zero rows of V => necessary bars => cut-sets {i}.
% Row-norm tolerance scaled to the magnitude of V (V has orthonormal
% columns so entries are O(1); a relative tolerance guards against
% accumulated SVD round-off for larger nel).
%--------------------------------------------------------------------------
rowTol = nel * eps(1) * 10;
rowNorms = sqrt(sum(V.^2, 2));
isNecessary = rowNorms <= rowTol;

necessaryIdx = find(isNecessary);
for i = 1:numel(necessaryIdx)
    cutSets{end+1} = necessaryIdx(i); %#ok<AGROW>
end

%--------------------------------------------------------------------------
% STEP 3 — remove necessary-bar rows, keep index map back to original
% member numbers (origIdx(j) = original member number of reduced row j).
%--------------------------------------------------------------------------
origIdx = find(~isNecessary);
Vp = V(origIdx, :);          % (b' x gH)
bPrime = numel(origIdx);

if bPrime == 0 || gH == 0
    cutSets = dedupeCutSets(cutSets);
    return;
end

%--------------------------------------------------------------------------
% colTol: entries of Vp are combinations of null-space components (O(1)
% scale like V); use a relative tolerance against the matrix's own norm
% so it self-scales with problem size / conditioning. Used as the rank()
% tolerance for every subset-rank test below.
%--------------------------------------------------------------------------
colTol = max(size(Vp)) * eps(norm(Vp, 'fro') + eps);

%--------------------------------------------------------------------------
% STEP 4-5 (Lemma 2) — for increasing subset size k=2..gH+1, find every
% dependent k-subset (rank(V_r) < k) that is MINIMAL (every (k-1)-subset
% has full rank k-1). Larger k cannot occur: any gH+1 rows of a rank-gH
% matrix are automatically dependent, so k=gH+1 is the hard upper bound.
% "Minimal" is checked by re-testing all direct (k-1)-subsets (eq. 33,
% metodika.md) rather than only against previously-found smaller cut-sets,
% since a (k-1)-subset could be dependent without itself being a MINIMAL
% cut-set only if some (k-2)-subset of IT is also dependent — but that
% would already make it fail full-rank-(k-1), so re-testing full rank
% directly is both correct and simplest.
%--------------------------------------------------------------------------
for k = 2:(gH + 1)
    if k > bPrime, break; end
    combos = nchoosek(1:bPrime, k);
    for ci = 1:size(combos, 1)
        idxSet = combos(ci, :);
        if rank(Vp(idxSet, :), colTol) < k
            minimal = true;
            subsetsKm1 = nchoosek(idxSet, k - 1);
            for si = 1:size(subsetsKm1, 1)
                if rank(Vp(subsetsKm1(si, :), :), colTol) < (k - 1)
                    minimal = false;
                    break;
                end
            end
            if minimal
                cutSets{end+1} = sort(origIdx(idxSet)); %#ok<AGROW>
            end
        end
    end
end

cutSets = dedupeCutSets(cutSets);

end

%--------------------------------------------------------------------------
function out = dedupeCutSets(cutSets)
% Dedupe cut-sets as SETS (order irrelevant) via sorted-vector equality.
out = {};
seen = {};
for i = 1:numel(cutSets)
    v = sort(cutSets{i}(:)');
    key = mat2str(v);
    if ~any(strcmp(key, seen))
        seen{end+1} = key; %#ok<AGROW>
        out{end+1} = v; %#ok<AGROW>
    end
end
end
