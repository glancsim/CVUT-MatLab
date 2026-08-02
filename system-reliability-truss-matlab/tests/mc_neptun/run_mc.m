% run_mc.m
% Neptun01 launcher for the MC cross-check of beta_sys (MC_NEPTUN_BRIEF.md).
% Same conventions as StableTrussOpt-MATLAB/*/run_bb.m: cd to script dir,
% diary logging, 28 workers on the shared 32-core machine, ntfy notification
% on both success and failure.
%
% Launch with nohup so it survives closing PuTTY:
%   nohup /home/tyburec/MATLAB/R2023a/bin/matlab -batch \
%     "run('/home/sglanc/MatLab/system-reliability-truss-matlab/tests/mc_neptun/run_mc.m')" \
%     > /tmp/mc_out.log 2>&1 &
%   echo "PID: $!"
%
% Monitor:
%   tail -f /home/sglanc/MatLab/system-reliability-truss-matlab/tests/mc_neptun/mc_neptun.log
%
% (c) S. Glanc, 2026

script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = pwd; end
cd(script_dir);
addpath(script_dir);

diary(fullfile(script_dir, 'mc_neptun.log'));
diary on;

NTFY = 'https://ntfy.sh/hexic-notifications-matlab';

t0 = posixtime(datetime('now'));
fprintf('=== run_mc START  %s ===\n', char(datetime('now')));

try
    % 28 workers: neptun01 has 32 cores and is shared -- leave 4 free.
    o = struct();
    o.nTargetTotal = 1e8;
    o.nWorkers     = 28;
    o.poolSize     = 28;
    o.baseSeed     = 1000;
    o.subBatch     = 5e5;

    out = runMcNeptun(o);

    elapsed = (posixtime(datetime('now')) - t0) / 60;
    fprintf('=== run_mc DONE in %.1f min ===\n', elapsed);

    msg = sprintf(['MC beta_sys DONE (%.1f min)\n' ...
                   'Pf_MC   = %.4e +/- %.2e\n' ...
                   'beta_MC = %.4f\n' ...
                   'nFail   = %d / %d\n' ...
                   'Pf_MC/Pf_min = %.3f (PNET claims 2.419)'], ...
                  elapsed, out.Pf_MC, out.ciHalfWidth, out.beta_MC, ...
                  out.nFail, out.nTotal, out.Pf_MC / 4.62660874e-05);
    try, webwrite(NTFY, msg); catch, end

catch ME
    elapsed = (posixtime(datetime('now')) - t0) / 60;
    fprintf('=== run_mc FAILED after %.1f min ===\n', elapsed);
    fprintf('%s\n', getReport(ME, 'extended'));
    try
        webwrite(NTFY, sprintf('MC beta_sys FAILED after %.1f min: %s', ...
                               elapsed, ME.message));
    catch
    end
end

diary off;
