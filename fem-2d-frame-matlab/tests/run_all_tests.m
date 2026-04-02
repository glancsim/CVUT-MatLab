% run_all_tests.m  Run all fem-2d-frame-matlab tests and report results.
%
% Tests:
%   Test 1 — Cantilever beam, tip vertical load         (analytical reference)
%   Test 2 — Fixed-fixed beam, midspan load              (analytical reference)
%   Test 3 — Portal frame with hinge, vertical load      (FEM reference)
%
% Reference files are generated automatically if missing.
%
% (c) S. Glanc, 2026

numTests = 3;

% Auto-generate references if any are missing
testsDir = fileparts(mfilename('fullpath'));
needsGen = false;
for t = 1:numTests
    if ~isfile(fullfile(testsDir, sprintf('Test %d', t), 'reference.mat'))
        needsGen = true;
        break;
    end
end
if needsGen
    fprintf('Generating references...\n');
    generate_references;
    fprintf('\n');
end

results  = false(1, numTests);

fprintf('=== fem-2d-frame-matlab: running %d tests ===\n\n', numTests);

for t = 1:numTests
    try
        results(t) = run_single_test(t);
    catch ME
        fprintf('Test %d: ERROR — %s\n', t, ME.message);
        results(t) = false;
    end
end

fprintf('\n--- Summary ---\n');
nPass = sum(results);
nFail = numTests - nPass;
fprintf('Passed: %d / %d\n', nPass, numTests);
if nFail > 0
    fprintf('FAILED tests: ');
    fprintf('%d ', find(~results));
    fprintf('\n');
else
    fprintf('All tests PASSED.\n');
end
