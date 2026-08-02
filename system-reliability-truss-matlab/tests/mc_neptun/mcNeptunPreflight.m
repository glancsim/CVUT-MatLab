function ok = mcNeptunPreflight(probeSamples)
% mcNeptunPreflight  Run this FIRST on neptun01. Takes ~1 minute and tells
% you whether the 1e8-sample job will survive the night.
%
%   matlab -batch "run('~/MatLab/system-reliability-truss-matlab/tests/mc_neptun/mcNeptunPreflight.m')"
%
% Checks, in order:
%   1. MATLAB release and required toolbox licences
%      (Statistics & ML -- normcdf/norminv; Parallel Computing -- parpool)
%   2. Every function the MC path calls is actually on the path
%   3. mcNeptunSetup's deterministic asserts (FSD areas, beta_min)
%   4. A short serial timing probe -> extrapolated wall time for 1e7/1e8
%
% Returns true only if all checks pass.
%
% (c) S. Glanc, 2026

if nargin < 1 || isempty(probeSamples), probeSamples = 2000; end

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

ok = true;
fprintf('=== mcNeptun PREFLIGHT ===\n\n');

%% 1. release + licences
fprintf('MATLAB    : %s\n', version);
fprintf('hostname  : %s\n', getHostname());
fprintf('numcores  : %d\n', feature('numcores'));
fprintf('\n');

lics = { 'Statistics_Toolbox',      'Statistics and Machine Learning (normcdf/norminv)'
         'Distrib_Computing_Toolbox','Parallel Computing (parpool/parfor)' };
for k = 1:size(lics,1)
    got = license('test', lics{k,1});
    fprintf('licence %-28s : %s\n', lics{k,1}, tf(got));
    if ~got
        ok = false;
        fprintf('   ^^ MISSING -- %s\n', lics{k,2});
        if strcmp(lics{k,1}, 'Statistics_Toolbox')
            fprintf('      Without it progressiveCollapseMCFn and componentReliabilityFn\n');
            fprintf('      both fail. Workaround: normcdf(-b) == 0.5*erfc(b/sqrt(2)) and\n');
            fprintf('      norminv(p) == -sqrt(2)*erfcinv(2*p), both core MATLAB -- but that\n');
            fprintf('      means patching repo code, so report back before doing it.\n');
        end
    end
end
fprintf('\n');

%% 2. required functions on path
need = { 'progressiveCollapseMCFn', 'equilibriumMatrixFn', 'linearSolverFn', ...
         'componentReliabilityFn',  'fullyStressedDesignFn', ...
         'sequenceLimitStateFn',    'mcRunChunk', 'mcNeptunReport' };
% mcNeptunSetup does the addpath work, so resolve it first
addpath(fullfile(thisDir, '..', '..', 'src'));
addpath(fullfile(thisDir, '..'));
addpath(fullfile(thisDir, '..', '..', '..', 'fem-2d-truss-matlab', 'src'));
for k = 1:numel(need)
    w = which(need{k});
    got = ~isempty(w);
    fprintf('function %-24s : %s  %s\n', need{k}, tf(got), w);
    if ~got, ok = false; end
end
fprintf('\n');

if ~ok
    fprintf('*** PREFLIGHT FAILED at the environment stage -- fix the above first. ***\n');
    return;
end

%% 3. deterministic setup asserts
fprintf('--- setup asserts ---\n');
try
    [nodes, members, kinematic, sections, rvSpec] = mcNeptunSetup();
catch ME
    fprintf('*** PREFLIGHT FAILED: %s\n', ME.message);
    ok = false;
    return;
end
fprintf('\n');

%% 4. timing probe
fprintf('--- timing probe (%d samples, serial) ---\n', probeSamples);
o = struct('verbose', false, 'seed', 999);
t = tic;
progressiveCollapseMCFn(nodes, members, kinematic, sections, rvSpec, probeSamples, o);
el = toc(t);
rate = probeSamples / el;
fprintf('serial throughput : %.0f samples/s\n', rate);

for nTot = [1e7 1e8]
    for nw = [28 1]
        secs = nTot / (rate * nw);
        if nw == 28
            fprintf('est. wall time %.0e samples on %2d workers : %6.0f s = %5.2f h\n', ...
                    nTot, nw, secs, secs/3600);
        end
    end
end
fprintf('(per-core rate under full load is typically 60-80 %% of the serial\n');
fprintf(' figure above, so treat these as optimistic lower bounds.)\n\n');

fprintf('*** PREFLIGHT PASSED -- safe to launch run_mc.m ***\n');
end

% -------------------------------------------------------------------------
function s = tf(b)
if b, s = 'OK    '; else, s = 'MISSING'; end
end

function h = getHostname()
try
    [st, r] = system('hostname');
    if st == 0, h = strtrim(r); else, h = '(unknown)'; end
catch
    h = '(unknown)';
end
end
