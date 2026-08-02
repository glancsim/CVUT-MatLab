function preemption_check(nChunks)
% preemption_check  Is the per-group "overcount" of MC_NEPTUN_FINDINGS.md
% section 2 a real error of the probability model, or the gap between two
% different definitions?
%
% The finding puts, side by side, the analytical Pf of a PNET group (the
% probability that the representative cut-set's failure SEQUENCE is
% violated -- an event that OVERLAPS other cut-sets' events) and the MC
% count for that group (the number of samples whose realised mechanism was
% that group's -- a DISJOINT partition). A cut-set can be satisfied often
% and still almost never be the mechanism that completes, because another
% mechanism completes first. Call that PRE-EMPTION.
%
% This script measures, for the four leading PNET groups:
%
%   (a1) P(representative ORDERING's sequence limit state violated)
%        -- exactly the event whose probability the analysis reports, so
%        this is a direct MC validation of the analytical Pf_p.
%   (a2) P(the cut-set is satisfied in ANY order) -- the brief's
%        "regardless of order" reading; the union over all k! orderings.
%        The analysis reports only the single most probable ordering
%        (mostProbableSequenceFn takes min beta_p over perms), so a2 >= a1.
%   (a3) P(the oracle actually removed every member of the cut-set),
%        over ALL 1e8 samples, mechanism or not -- damaged survivors
%        included.
%   (b)  P(the realised mechanism was exactly that cut-set) and the group
%        total -- the number already reported, recomputed identically.
%
% and then attributes: among the samples of (a2), what did the oracle
% actually end up with?
%
% ------------------------------------------------------------------------
% HOW (a1)-(a3) CAN BE MEASURED WITHOUT A NEW MONTE CARLO RUN
%
% mc_neptun_result.mat stores the removal sequence of FAILED samples only,
% and each sequence stops at the first mechanism, so it cannot answer (a1)
% or (a3) -- see PART A, which reports the restricted version honestly and
% shows why it is degenerate.
%
% Instead this script REPLAYS the stored run. The replay is not a new
% simulation: it regenerates the identical random stream from the stored
% seeds and re-derives every sample's outcome in closed form. It is exact
% because, for a given set of surviving members, the axial forces are
% LINEAR in the two load multipliers, so one pair of unit-load FEM solves
% per structural state (memoised, a few dozen in total) replaces the
% 1e8 per-sample solves of the original run. 28 s instead of 2 h.
%
% The replay is verified against the stored output before anything is
% derived from it: all 28 per-chunk failure counts and all 12 observed
% mechanism counts must reproduce exactly, and the script errors out if
% they do not.
%
% RNG NOTE (found while building this): the run is reproducible only under
% the THREEFRY generator. runMcNeptun seeds each chunk with rng(1000+w),
% which sets the seed but keeps the current generator type -- and a parpool
% worker's default generator is Threefry, not the client's Mersenne
% Twister. Replaying with 'twister' gives per-chunk counts off by up to 80
% and a total of 18 799 instead of 18 820 (a statistically consistent but
% different run). See the assertion below.
% ------------------------------------------------------------------------
%
%   nChunks - (optional, default 28) replay only the first nChunks chunks.
%             Use a small value for a smoke test; the reproduction
%             assertions are then checked on that prefix only.
%
% (c) S. Glanc, 2026

if nargin < 1 || isempty(nChunks), nChunks = 28; end

here = fileparts(mfilename('fullpath'));
addpath(here); addpath(fullfile(here, '..'));

matFile = fullfile(here, '..', 'mc_neptun_result.mat');
if ~isfile(matFile)
    error('preemption_check:noResult', ...
        ['%s not found -- run runMcNeptun first (the .mat is git-ignored, ' ...
         'see ../README.md).'], matFile);
end
S = load(matFile); o = S.out;

fprintf('MC of record: nFail = %d / %d, Pf_MC = %.8e\n', o.nFail, o.nTotal, o.Pf_MC);

[nodes, members, kinematic, sections, rvSpec] = mcNeptunSetup();

%% ===================== analytical side (rng 42, twister) ================
% Must run BEFORE the replay switches the global generator to Threefry.
rng(42);
R = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, ...
                        struct('eta', 0, 'rho0', 0.7, 'verbose', false));
fprintf('Pf_sys (rng 42) = %.8e\n\n', R.Pf_sys);

[~, po]  = sort([R.pnetGroups.beta], 'ascend');
nGrpShow = 4;

grpOf = zeros(numel(R.cutSets), 1);
for r = 1:numel(po)
    grpOf(R.pnetGroups(po(r)).members) = r;
end
allKey = cellfun(@(v) mat2str(sort(v(:))'), R.cutSets, 'UniformOutput', false);

% --- the cut-sets to track ----------------------------------------------
% the four leading group representatives, plus the two tied siblings the MC
% actually observes inside groups 2 and 3 (same beta_p as their group's
% representative, so the analysis cannot tell them apart)
track = struct('label', {}, 'cutSet', {}, 'grp', {}, 'PfAnalytical', {}, 'isRep', {});
for r = 1:nGrpShow
    rep = R.pnetGroups(po(r)).repIdx;
    track(end+1) = struct('label', sprintf('grp %d rep', r), ...
        'cutSet', sort(R.cutSets{rep}(:))', 'grp', r, ...
        'PfAnalytical', normcdf(-R.pnetGroups(po(r)).beta), 'isRep', true); %#ok<AGROW>
end
for cs = {[2 5], [5 15]}
    j = find(strcmp(allKey, mat2str(cs{1})), 1);
    track(end+1) = struct('label', sprintf('grp %d sibling', grpOf(j)), ...
        'cutSet', cs{1}, 'grp', grpOf(j), ...
        'PfAnalytical', normcdf(-R.betaPerCutSet(j)), 'isRep', false); %#ok<AGROW>
end
nTrack = numel(track);

% --- limit-state coefficients for EVERY ordering of every tracked cut-set
% g_k = meanG_k + coeffU_k * U,  U = [U_R(1:4) U_P(1:2)];  failure: g_k <= 0
fprintf('building sequence limit states ...\n');
for t = 1:nTrack
    pmt = perms(track(t).cutSet);
    track(t).ord = cell(size(pmt,1), 1);
    for q = 1:size(pmt, 1)
        sq = sequenceLimitStateFn(nodes, members, kinematic, sections, ...
                                  pmt(q,:), rvSpec, 0);
        track(t).ord{q} = struct('seq', pmt(q,:), ...
            'A', vertcat(sq.coeffU), 'b', vertcat(sq.meanG));
    end
    % the representative ordering the analysis actually used
    repSeqIdx = find(strcmp(allKey, mat2str(track(t).cutSet)), 1);
    track(t).repSeq = R.repSequence{repSeqIdx};
    track(t).repOrd = find(arrayfun(@(q) isequal(pmt(q,:), track(t).repSeq), ...
                                    1:size(pmt,1)), 1);
end

%% ========================= PART A -- stored data only ===================
fprintf('\n');
fprintf('=========================================================================\n');
fprintf('PART A -- what the stored failSequences alone can say\n');
fprintf('=========================================================================\n');
fprintf(['failSequences holds the removal order of FAILED samples only, and\n' ...
         'each stops at the first mechanism. So "the cut-set was satisfied"\n' ...
         'can only be read as "all its members appear in a failed sample''s\n' ...
         'sequence" -- which for a 2-member cut-set is the same thing as being\n' ...
         'the mechanism, up to the 0.46%% of samples with a 3-member sequence.\n' ...
         'This is reported for completeness; PART B is the answer.\n\n']);

kStored = cellfun(@(s) mat2str(sort(s(:))'), o.failSequences, 'UniformOutput', false);
setStored = cellfun(@(s) sort(s(:))', o.failSequences, 'UniformOutput', false);

fprintf('%-16s %12s %12s %12s\n', 'representative', 'contained', 'was mech', 'ratio');
for t = 1:nTrack
    C = track(t).cutSet;
    nContained = sum(cellfun(@(v) all(ismember(C, v)), setStored));
    nMech      = sum(strcmp(kStored, mat2str(C)));
    fprintf('%-16s %12d %12d %12s\n', mat2str(C), nContained, nMech, ...
            ratioStr(nContained, nMech));
end
fprintf('\n(over the %d failed samples only -- 0 of the %d surviving samples\n', ...
        o.nFail, o.nTotal - o.nFail);
fprintf(' contribute, because their sequences were never recorded.)\n');

%% ========================= PART B -- exact replay =======================
fprintf('\n');
fprintf('=========================================================================\n');
fprintf('PART B -- exact replay of the same 1e8 samples\n');
fprintf('=========================================================================\n');

nm       = members.nmembers;
role     = rvSpec.resGroup(:);
resMean  = rvSpec.resMean(:)';   resStd  = rvSpec.resStd(:)';
loadMean = rvSpec.loadMean(:)';  loadStd = rvSpec.loadStd(:)';

subBatch   = o.subBatch;
nPerWorker = o.nSamp_all(1);

% event columns: 2 per tracked cut-set (representative ordering, any ordering)
nEv        = 2 * nTrack;
evTotal    = zeros(1, nEv);
evCo       = zeros(nTrack);   % co-occurrence of the "any ordering" events

stateMap   = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
termMask   = uint32([]);      % terminal states, in discovery order
termIsMech = false(0, 1);
termCnt    = zeros(0, 1);
termEv     = zeros(0, nEv);   % per terminal state, count of samples per event

nFailChunk = zeros(nChunks, 1);
nTot       = 0;

tic
for w = 1:nChunks
    remaining = nPerWorker; first = true; nfw = 0;
    while remaining > 0
        n = min(subBatch, remaining);
        if first
            rng(1000 + w, 'threefry');   % parpool worker default -- see header
            first = false;
        end
        U_R = randn(n, 4); U_P = randn(n, 2);

        Rmat = resMean  + U_R .* resStd;      % n x 4  member resistances by group
        P    = loadMean + U_P .* loadStd;     % n x 2  load multipliers
        U    = [U_R, U_P];                    % n x 6  the shared standard normals

        % --- sequence limit states, evaluated on every sample -----------
        EV = false(n, nEv);
        for t = 1:nTrack
            anyOrd = false(n, 1);
            for q = 1:numel(track(t).ord)
                od = track(t).ord{q};
                hit = all(U * od.A' + od.b' <= 0, 2);
                if q == track(t).repOrd, EV(:, 2*t-1) = hit; end
                anyOrd = anyOrd | hit;
            end
            EV(:, 2*t) = anyOrd;
        end
        evTotal = evTotal + sum(EV, 1);
        A2      = double(EV(:, 2:2:end));
        evCo    = evCo + A2' * A2;

        nfw = nfw + processBatch(uint32(0), (1:n)');
        nTot = nTot + n;
        remaining = remaining - n;
    end
    nFailChunk(w) = nfw;
end
fprintf('replayed %d chunks / %d samples in %.0f s\n', nChunks, nTot, toc);

%% --- reproduction gates -------------------------------------------------
mismatch = find(nFailChunk(:) ~= o.nFail_all(1:nChunks));
if ~isempty(mismatch)
    error('preemption_check:chunkMismatch', ...
        ['replay does not reproduce the stored run: chunk(s) %s differ ' ...
         '(replay %s vs stored %s). Nothing below is trustworthy.'], ...
        mat2str(mismatch'), mat2str(nFailChunk(mismatch)'), ...
        mat2str(o.nFail_all(mismatch)'));
end

mechKey = cell(0,1); mechCnt = [];
for e = 1:numel(termMask)
    if ~termIsMech(e), continue; end
    key = mat2str(find(bitget(termMask(e), 1:nm)));
    j = find(strcmp(mechKey, key), 1);
    if isempty(j), mechKey{end+1,1} = key; mechCnt(end+1,1) = termCnt(e); %#ok<AGROW>
    else,          mechCnt(j) = mechCnt(j) + termCnt(e); end
end
if nChunks == numel(o.nFail_all)
    [uS, ~, icS] = unique(kStored); cS = accumarray(icS(:), 1);
    for i = 1:numel(uS)
        j = find(strcmp(mechKey, uS{i}), 1);
        got = 0; if ~isempty(j), got = mechCnt(j); end
        if got ~= cS(i)
            error('preemption_check:mechMismatch', ...
                'mechanism %s: replay %d vs stored %d.', uS{i}, got, cS(i));
        end
    end
    if numel(mechKey) ~= numel(uS)
        error('preemption_check:mechExtra', ...
            'replay produced %d distinct mechanisms, stored has %d.', ...
            numel(mechKey), numel(uS));
    end
end
fprintf(['GATE PASSED: all %d per-chunk failure counts and all %d mechanism\n' ...
         '             counts reproduce the stored run exactly.\n'], ...
        nChunks, numel(mechKey));

%% --- terminal-state census ---------------------------------------------
% Answers the brief's first caveat: can a sample shed members and stop
% without forming a mechanism? It can -- the oracle removes one member and
% re-solves -- so those samples must be counted towards "the cut-set was
% satisfied". Here is how many there are.
fprintf('\n--- terminal-state census over all %d samples ---\n\n', nTot);
[~, ordC] = sort(termCnt, 'descend');
nDamagedSurv = 0;
for e = ordC'
    lbl = mat2str(find(bitget(termMask(e), 1:nm)));
    if strcmp(lbl, 'zeros(1,0)')
        lbl = '(intact -- nothing removed)';
    elseif ~termIsMech(e)
        nDamagedSurv = nDamagedSurv + termCnt(e);
    end
    fprintf('  %-28s %-6s %12d\n', lbl, ...
            string(termIsMech(e)), termCnt(e));
end
fprintf('\n  survivors that lost at least one member: %d (%.2e)\n', ...
        nDamagedSurv, nDamagedSurv / nTot);

%% --- the table ----------------------------------------------------------
fprintf('\n');
fprintf('--- probabilities, all over the same %d samples ---\n\n', nTot);
fprintf('%-16s %-11s %11s %11s %11s %11s %11s\n', ...
        'representative', 'group', 'analytic', '(a1) rep', '(a2) any', ...
        '(a3) both', '(b) mech');
fprintf('%-16s %-11s %11s %11s %11s %11s %11s\n', ...
        '', '', 'Pf_p', 'ordering', 'ordering', 'removed', 'formed');
for t = 1:nTrack
    C  = track(t).cutSet;
    a1 = evTotal(2*t-1) / nTot;
    a2 = evTotal(2*t)   / nTot;
    a3 = sum(termCnt(bitand(termMask(:), maskOf(C)) == maskOf(C))) / nTot;
    bb = mechCountOf(C) / nTot;
    fprintf('%-16s %-11s %11.4e %11.4e %11.4e %11.4e %11.4e\n', ...
            mat2str(C), track(t).label, track(t).PfAnalytical, a1, a2, a3, bb);
end

fprintf('\n%-16s %-11s %14s %14s %14s\n', 'representative', 'group', ...
        'a1/analytic', 'pre-empt a2/b', 'pre-empt a3/b');
for t = 1:nTrack
    C  = track(t).cutSet;
    a1 = evTotal(2*t-1); a2 = evTotal(2*t);
    a3 = sum(termCnt(bitand(termMask(:), maskOf(C)) == maskOf(C)));
    bb = mechCountOf(C);
    fprintf('%-16s %-11s %14s %14s %14s\n', mat2str(C), track(t).label, ...
            ratioStr(a1, nTot * track(t).PfAnalytical), ...
            ratioStr(a2, bb), ratioStr(a3, bb));
end

%% --- group totals (the quantity the paper's figure plots) ---------------
fprintf('\n--- PNET group totals, as in MC_NEPTUN_FINDINGS.md section 2 ---\n\n');
fprintf('%6s %-16s %13s %13s %10s\n', 'grp', 'representative', 'PNET Pf', 'MC Pf', 'ratio');
for r = 1:nGrpShow
    rep  = R.pnetGroups(po(r)).repIdx;
    PfP  = normcdf(-R.pnetGroups(po(r)).beta);
    mcSum = 0;
    for i = 1:numel(mechKey)
        j = find(strcmp(allKey, mechKey{i}), 1);
        if ~isempty(j) && grpOf(j) == r, mcSum = mcSum + mechCnt(i); end
    end
    fprintf('%6d %-16s %13.4e %13.4e %10s\n', r, allKey{rep}, PfP, ...
            mcSum / nTot, ratioStr(mcSum / nTot, PfP));
end

%% --- do the tracked cut-sets describe the SAME samples? -----------------
% If group 3's probability mass is literally the same samples as part of
% group 2's, then the "overcount" and the "undercount" are one displacement,
% not two independent errors. Off-diagonal = |A and B|; the diagonal is |A|.
fprintf('\n--- overlap of the "satisfied in any order" events (sample counts) ---\n\n');
fprintf('%-14s', '');
for t = 1:nTrack, fprintf('%12s', mat2str(track(t).cutSet)); end
fprintf('\n');
for t = 1:nTrack
    fprintf('%-14s', mat2str(track(t).cutSet));
    for s = 1:nTrack, fprintf('%12d', evCo(t, s)); end
    fprintf('\n');
end

%% --- re-attribution: pair each over-counted group with the group whose
%% --- mechanism actually absorbed it (read off PART C below)
grpPf = zeros(nGrpShow, 1); grpMC = zeros(nGrpShow, 1);
for r = 1:nGrpShow
    grpPf(r) = normcdf(-R.pnetGroups(po(r)).beta);
    for i = 1:numel(mechKey)
        j = find(strcmp(allKey, mechKey{i}), 1);
        if ~isempty(j) && grpOf(j) == r, grpMC(r) = grpMC(r) + mechCnt(i) / nTot; end
    end
end
pairs = {[1 4], [2 3]};
fprintf('\n--- groups re-paired with the group that absorbed their samples ---\n\n');
fprintf('%-14s %13s %13s %10s\n', 'groups', 'PNET Pf', 'MC Pf', 'ratio');
for k = 1:numel(pairs)
    p = pairs{k};
    fprintf('%-14s %13.4e %13.4e %10s\n', ...
            sprintf('%d + %d', p(1), p(2)), sum(grpPf(p)), sum(grpMC(p)), ...
            ratioStr(sum(grpMC(p)), sum(grpPf(p))));
end
fprintf('%-14s %13.4e %13.4e %10s\n', 'all 1-4', sum(grpPf), sum(grpMC), ...
        ratioStr(sum(grpMC), sum(grpPf)));

%% ================= PART C -- which mechanism pre-empts which ============
fprintf('\n');
fprintf('=========================================================================\n');
fprintf('PART C -- what the oracle did instead\n');
fprintf('=========================================================================\n');
for t = 1:nTrack
    C = track(t).cutSet;
    col = 2*t;                                  % "satisfied in any order"
    tot = evTotal(col);
    if tot == 0, continue; end
    [~, ordIdx] = sort(termEv(:, col), 'descend');
    fprintf('\n%s satisfied (any order) in %d of %d samples. Oracle outcome:\n', ...
            mat2str(C), tot, nTot);
    fprintf('  %-24s %-8s %10s %8s\n', 'terminal removed set', 'mech', 'count', 'share');
    shown = 0;
    for e = ordIdx'
        if termEv(e, col) == 0 || shown >= 5, break; end
        lbl = mat2str(find(bitget(termMask(e), 1:nm)));
        if strcmp(lbl, 'zeros(1,0)'), lbl = '(nothing removed)'; end
        fprintf('  %-24s %-8d %10d %7.1f %%\n', lbl, termIsMech(e), ...
                termEv(e, col), 100 * termEv(e, col) / tot);
        shown = shown + 1;
    end
end

fprintf('\ndone.\n');

%% ======================= nested helpers =================================
    function nf = processBatch(mask, idx)
        nf = 0;
        if isempty(idx), return; end
        st = getState(mask);
        if st.isMech
            addTerm(mask, true, idx); nf = numel(idx); return;
        end
        gmin = inf(numel(idx), 1); imin = zeros(numel(idx), 1, 'uint8');
        P1 = P(idx, 1); P2 = P(idx, 2);
        for tt = 1:numel(st.keepIdx)
            i  = st.keepIdx(tt);
            gi = Rmat(idx, role(i)) - abs(st.B(i,1) * P1 + st.B(i,2) * P2);
            upd = gi < gmin;                    % strict: same tie-break as min()
            gmin(upd) = gi(upd); imin(upd) = i;
        end
        alive = gmin > 0;
        if any(alive), addTerm(mask, false, idx(alive)); end
        rest = find(~alive);
        if isempty(rest), return; end
        for i = unique(imin(rest))'
            sel = rest(imin(rest) == i);
            nf  = nf + processBatch(bitset(mask, double(i)), idx(sel));
        end
    end

    function addTerm(mask, isMech, idx)
        e = find(termMask == mask, 1);
        if isempty(e)
            termMask(end+1, 1)  = mask;
            termIsMech(end+1,1) = isMech;
            termCnt(end+1, 1)   = 0;
            termEv(end+1, :)    = 0;
            e = numel(termMask);
        end
        termCnt(e)   = termCnt(e) + numel(idx);
        termEv(e, :) = termEv(e, :) + sum(EV(idx, :), 1);
    end

    function st = getState(mask)
        if isKey(stateMap, mask), st = stateMap(mask); return; end
        keepIdx = find(~bitget(mask, 1:nm))';
        st.keepIdx = keepIdx; st.B = nan(nm, 2); st.isMech = false;
        if isempty(keepIdx)
            st.isMech = true;
        else
            if numel(keepIdx) < nm
                mr.nodesHead = members.nodesHead(keepIdx);
                mr.nodesEnd  = members.nodesEnd(keepIdx);
                mr.nmembers  = numel(keepIdx);
                Ared = equilibriumMatrixFn(nodes, mr, kinematic);
                st.isMech = rank(Ared) < size(Ared, 1);
            end
            if ~st.isMech
                mr.nodesHead = members.nodesHead(keepIdx);
                mr.nodesEnd  = members.nodesEnd(keepIdx);
                mr.sections  = members.sections(keepIdx);
                mr.nmembers  = numel(keepIdx);
                for j = 1:2
                    [~, ef] = linearSolverFn(sections, nodes, kinematic, mr, ...
                                             rvSpec.loadCases{j});
                    st.B(keepIdx, j) = ef.local(1, :)';
                end
            end
        end
        stateMap(mask) = st;
    end

    function m = maskOf(C)
        m = uint32(0);
        for i = C(:)', m = bitset(m, double(i)); end
    end

    function c = mechCountOf(C)
        j = find(strcmp(mechKey, mat2str(sort(C(:))')), 1);
        if isempty(j), c = 0; else, c = mechCnt(j); end
    end
end

%% ------------------------------------------------------------------------
function s = ratioStr(num, den)
if den == 0
    if num == 0, s = '-'; else, s = 'inf'; end
else
    s = sprintf('%.2f', num / den);
end
end
