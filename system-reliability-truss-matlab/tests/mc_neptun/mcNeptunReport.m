function txt = mcNeptunReport(out, outDir)
% mcNeptunReport  Formats the seven items requested in MC_NEPTUN_BRIEF.md
% section 7 and writes them to stdout plus a raw text file.
%
%   out    - struct returned by runMcNeptun / poolMcChunks
%   outDir - (optional) directory for the text file; '' = stdout only
%
% (c) S. Glanc, 2026

if nargin < 2, outDir = ''; end

PF_MIN = 4.62660874e-05;    % weakest member (11) in isolation -- analytic
PF_SYS = 1.11915173e-04;    % 91 cut-sets -> PNET, rho0 = 0.7
REF_CUTSETS = {'[11 14]', '[1 2 8]', '[5 12]'};   % analytical top 3

L = {};

add('===============================================================');
add('MC cross-check of beta_sys -- Warren X-brace truss');
add('===============================================================');
add('');

%% (1) headline
add('--- 1. Result --------------------------------------------------');
add('nFail        = %d', out.nFail);
add('nTotal       = %d', out.nTotal);
add('Pf_MC        = %.8e', out.Pf_MC);
add('95%% CI       = [%.8e , %.8e]  (+/- %.3e)', ...
    out.Pf_MC - out.ciHalfWidth, out.Pf_MC + out.ciHalfWidth, out.ciHalfWidth);
add('beta_MC      = %.6f', out.beta_MC);
if out.nFail > 0
    add('CoV(Pf_MC)   = %.2f %%', 100/sqrt(out.nFail));
end
add('');

%% (2) ratio + verdict
add('--- 2. Comparison ----------------------------------------------');
add('Pf_min  (component, member 11) = %.8e', PF_MIN);
add('Pf_sys  (PNET, rho0=0.7)       = %.8e', PF_SYS);
add('Pf_MC / Pf_min                 = %.4f   (PNET claims 2.4189)', out.Pf_MC / PF_MIN);
add('Pf_MC / Pf_sys                 = %.4f', out.Pf_MC / PF_SYS);
add('');

lo = out.Pf_MC - out.ciHalfWidth;
hi = out.Pf_MC + out.ciHalfWidth;
if hi < PF_MIN
    add('** VERDICT: Pf_MC lies BELOW Pf_min and the 95%% CI excludes it. **');
    add('** Brief section 1 says report this immediately.');
    add('** Note on section 6(b): the union-of-cut-sets lower bound is not');
    add('** strictly binding on THIS oracle, which is path-dependent -- it');
    add('** removes only the single min-g member per step, and with gH=3 the');
    add('** truss can shed up to 3 members and remain stable. So a shortfall');
    add('** is not automatically a setup error, and mcNeptunSetup''s asserts');
    add('** already rule a setup mismatch out.');
elseif lo <= PF_SYS && PF_SYS <= hi
    add('VERDICT: Pf_sys lies INSIDE the 95%% CI -- PNET at rho0=0.7 is well');
    add('         calibrated; the reported 2.42x effect stands.');
elseif hi < PF_SYS
    add('VERDICT: Pf_MC is significantly BELOW Pf_sys but above Pf_min -- the');
    add('         effect is real but smaller than reported. Recalibrate rho0');
    add('         against Pf_MC (target beta_sys = %.6f).', out.beta_MC);
else
    add('VERDICT: Pf_MC is significantly ABOVE Pf_sys -- PNET is');
    add('         under-estimating the union here, the opposite of the');
    add('         expected direction. Worth a closer look.');
end
add('');

%% (3) per-chunk homogeneity
add('--- 3. Per-chunk nFail -----------------------------------------');
nw = numel(out.nFail_all);
add('%6s %12s %14s %10s', 'chunk', 'seed', 'nSamples', 'nFail');
for w = 1:nw
    add('%6d %12d %14d %10d', w, out.seeds(w), out.nSamp_all(w), out.nFail_all(w));
end
mu = mean(out.nFail_all);
add('');
add('mean nFail/chunk = %.2f, std = %.2f, Poisson sqrt(mean) = %.2f', ...
    mu, std(out.nFail_all), sqrt(mu));
if mu > 0
    chi2 = sum((out.nFail_all - mu).^2) / mu;    % dispersion, ~chi2(nw-1)
    add('dispersion chi2 = %.2f on %d dof (expect ~%d if chunks homogeneous)', ...
        chi2, nw-1, nw-1);
end
if any(out.nSamp_all == 0)
    add('*** WARNING: chunk(s) %s returned ZERO samples -- worker died. ***', ...
        mat2str(find(out.nSamp_all == 0)'));
end
add('');

%% (4) timing
add('--- 4. Timing ---------------------------------------------------');
add('wall time            = %.1f s  (%.2f h)', out.wallTime, out.wallTime/3600);
add('samples per second   = %.0f  (aggregate)', out.nTotal / out.wallTime);
if isfield(out, 'time_all') && ~isempty(out.time_all) && all(out.time_all > 0)
    add('per-chunk time       = %.1f .. %.1f s (mean %.1f)', ...
        min(out.time_all), max(out.time_all), mean(out.time_all));
    add('per-core throughput  = %.0f samples/s', mean(out.nSamp_all ./ out.time_all));
end
add('');

%% (5) dominant failure sequences / cut-sets
add('--- 5. Dominant failure modes (pooled) --------------------------');
seqs = out.failSequences;
if isempty(seqs)
    add('no failed samples -- nothing to rank');
else
    add('(a) top 10 ORDERED removal sequences');
    rankAndPrint(@(s) mat2str(s(:)'), seqs, 10);
    add('');
    add('(b) top 10 UNORDERED cut-sets  [analytical top 3: %s, %s, %s]', REF_CUTSETS{:});
    keys = rankAndPrint(@(s) mat2str(sort(s(:))'), seqs, 10);
    add('');
    for r = 1:numel(REF_CUTSETS)
        pos = find(strcmp(keys, REF_CUTSETS{r}), 1);
        if isempty(pos)
            add('    analytical #%d %-10s : NOT observed in MC', r, REF_CUTSETS{r});
        else
            add('    analytical #%d %-10s : MC rank %d', r, REF_CUTSETS{r}, pos);
        end
    end
end
add('');

%% (6) provenance
add('--- 6. Provenance -----------------------------------------------');
add('MATLAB               = %s', out.matlabVersion);
add('seeds                = %d .. %d (chunk w -> baseSeed + w)', out.seeds(1), out.seeds(end));
add('sub-batch size       = %g (seed set once per chunk, stream continues)', out.subBatch);
add('oracle               = tests/progressiveCollapseMCFn.m (serial, brittle eta=0)');
add('===============================================================');

txt = strjoin(L, newline);
fprintf('%s\n', txt);

if ~isempty(outDir)
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    f = fullfile(outDir, sprintf('mc_neptun_report_%s.txt', stamp));
    fid = fopen(f, 'w');
    if fid > 0
        fprintf(fid, '%s\n', txt);
        fclose(fid);
        fprintf('\nraw report written to: %s\n', f);
    else
        warning('mcNeptunReport:noFile', 'could not write report to %s', f);
    end
end

% ---------------------------------------------------------------------
    function add(varargin)
        L{end+1} = sprintf(varargin{:});
    end

    function keys = rankAndPrint(keyFn, s, topN)
        k = cellfun(keyFn, s, 'UniformOutput', false);
        [u, ~, ic] = unique(k);
        cnt = accumarray(ic(:), 1);
        [cnt, ord] = sort(cnt, 'descend');
        u = u(ord);
        n = min(topN, numel(u));
        add('%6s  %-28s %10s %10s', 'rank', 'members', 'count', 'share');
        for i = 1:n
            add('%6d  %-28s %10d %9.2f %%', i, u{i}, cnt(i), 100*cnt(i)/numel(s));
        end
        keys = u;
    end
end
