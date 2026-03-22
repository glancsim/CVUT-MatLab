% run_all_tests.m  Run all fem-truss-2d-matlab tests and report results.
%
% Tests:
%   Test 1 — Symmetric 3-member truss, vertical load        (analytical ref)
%   Test 2 — 4-panel Pratt truss, loads at interior nodes   (FEM ref)
%   Test 3 — Simple diagonal truss, horizontal load         (analytical ref)
%
% (c) S. Glanc, 2025

numTests = 3;
results  = false(1, numTests);

fprintf('=== fem-truss-2d-matlab: running %d tests ===\n\n', numTests);

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
