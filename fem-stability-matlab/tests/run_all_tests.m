%% run_all_tests.m
% ==========================================================================
%  STABILITY TESTS — Run all 9 validation tests (no OOFEM required)
% ==========================================================================
%
% Runs stabilitySolverFn on each of the 9 test cases and compares the
% computed critical-load multipliers against pre-computed reference
% eigenvalues stored in  tests/Test N/reference_eigenvalues.mat.
%
% No external software (OOFEM, Python) is needed.
%
% USAGE:
%   1. Open MATLAB and change the working directory to  tests/
%   2. Run this script:  run_all_tests
%   3. Results are printed to the Command Window and saved to  results/
%
% OUTPUT FILES (written to tests/results/):
%   errors_summary.txt   — text report with per-mode errors for all tests
%   errors_table.xlsx    — Excel table (requires MATLAB Spreadsheet toolbox)
%   all_tests_results.mat — MATLAB workspace with all numeric results
%   errors_overview.png  — heatmap + boxplot overview figure
%
% See also: run_single_test, stabilitySolverFn, linearSolverFn
% ==========================================================================

clear; close all; clc;

%% PATHS
% --------------------------------------------------------------------------
scriptsDir = fileparts(mfilename('fullpath'));   % .../tests/
srcDir     = fullfile(scriptsDir, '..', 'src');
addpath(srcDir);
addpath(scriptsDir);                             % for run_single_test

baseDir   = scriptsDir;
numTests  = 9;
numModes  = 10;   % number of eigenvalues per test

%% INITIALISE
% --------------------------------------------------------------------------
resultsTable   = NaN(numTests, numModes);
testNames      = cell(numTests, 1);
testStatus     = cell(numTests, 1);
executionTimes = zeros(numTests, 1);

fprintf('\n');
fprintf('==========================================================================\n');
fprintf('  3D BEAM FEM — STABILITY VALIDATION TESTS\n');
fprintf('==========================================================================\n');
fprintf('  Tests : %d\n', numTests);
fprintf('  Source: %s\n', baseDir);
fprintf('==========================================================================\n\n');

%% MAIN LOOP
% --------------------------------------------------------------------------
for testNum = 1:numTests

    testName        = sprintf('Test %d', testNum);
    testNames{testNum} = testName;
    fprintf('  [%d/%d] %-8s  ', testNum, numTests, testName);

    testDir = fullfile(baseDir, testName);

    if ~exist(testDir, 'dir')
        fprintf('SKIP — directory not found\n');
        testStatus{testNum} = 'MISSING';
        continue;
    end

    tStart = tic;

    try
        [errors, sortedValues] = run_single_test(testDir);

        elapsedTime = toc(tStart);
        executionTimes(testNum) = elapsedTime;

        n = min(length(errors), numModes);
        resultsTable(testNum, 1:n) = errors(1:n)';

        testStatus{testNum} = 'OK';
        fprintf('OK   %.1fs  |  mean error: %5.3f %%  |  max: %5.3f %%\n', ...
                elapsedTime, mean(errors), max(errors));

    catch ME
        elapsedTime = toc(tStart);
        executionTimes(testNum) = elapsedTime;
        testStatus{testNum}     = 'ERROR';
        fprintf('FAIL %.1fs  |  %s\n', elapsedTime, ME.message);
    end

end

%% RESULTS FOLDER
% --------------------------------------------------------------------------
cd(baseDir);
if ~exist('results', 'dir');  mkdir('results');  end

%% TEXT REPORT
% --------------------------------------------------------------------------
fid = fopen('results/errors_summary.txt', 'w');
fprintf(fid, '==========================================================================\n');
fprintf(fid, '  3D BEAM FEM — STABILITY VALIDATION RESULTS\n');
fprintf(fid, '==========================================================================\n');
fprintf(fid, '  Date    : %s\n', datestr(now));
fprintf(fid, '  Tests   : %d\n', numTests);
fprintf(fid, '==========================================================================\n\n');
fprintf(fid, '  Errors are given as:  |lambda_MATLAB - lambda_ref| / lambda_ref * 100 %%\n');
fprintf(fid, '  Reference values come from pre-computed OOFEM results.\n\n');

for i = 1:numTests
    fprintf(fid, '%s  [%s]\n', testNames{i}, testStatus{i});
    if strcmp(testStatus{i}, 'OK')
        row = resultsTable(i, :);
        fprintf(fid, '  Mode errors (%%)   : ');
        fprintf(fid, '  %8.4f', row);
        fprintf(fid, '\n');
        fprintf(fid, '  Mean / Max / Min  :   %8.4f %%  /  %8.4f %%  /  %8.4f %%\n', ...
                mean(row,'omitnan'), max(row,[],'omitnan'), min(row,[],'omitnan'));
        fprintf(fid, '  Execution time    :   %.2f s\n', executionTimes(i));
    end
    fprintf(fid, '\n');
end

successCount = sum(strcmp(testStatus, 'OK'));
fprintf(fid, '==========================================================================\n');
fprintf(fid, '  SUMMARY\n');
fprintf(fid, '==========================================================================\n');
fprintf(fid, '  Passed : %d / %d\n', successCount, numTests);
fprintf(fid, '  Total time : %.2f s\n', sum(executionTimes));
if successCount > 0
    fprintf(fid, '  Overall mean error : %.4f %%\n', mean(resultsTable(:), 'omitnan'));
    fprintf(fid, '  Overall max  error : %.4f %%\n', max(resultsTable(:), [], 'omitnan'));
end
fprintf(fid, '==========================================================================\n');
fclose(fid);
fprintf('\n  Report : results/errors_summary.txt\n');

%% MATLAB DATA
% --------------------------------------------------------------------------
save('results/all_tests_results.mat', 'resultsTable', 'testNames', ...
     'testStatus', 'executionTimes');
fprintf('  Data   : results/all_tests_results.mat\n');

%% EXCEL TABLE (optional — requires Spreadsheet toolbox)
% --------------------------------------------------------------------------
try
    colNames = [arrayfun(@(x) sprintf('Mode_%d', x), 1:numModes, ...
                'UniformOutput', false), {'Mean', 'Max', 'Status'}];
    T = array2table([ resultsTable, ...
                      mean(resultsTable, 2, 'omitnan'), ...
                      max(resultsTable,  [], 2, 'omitnan') ], ...
                    'RowNames',      testNames, ...
                    'VariableNames', colNames(1:end-1));
    T.Status = testStatus;
    writetable(T, 'results/errors_table.xlsx', 'WriteRowNames', true);
    fprintf('  Excel  : results/errors_table.xlsx\n');
catch
    % silently skip if toolbox missing
end

%% FIGURES
% --------------------------------------------------------------------------
figure('Position', [100 100 1200 600], 'Name', 'Stability Tests — Error Overview');

subplot(2,1,1);
imagesc(resultsTable);  colorbar;  colormap(jet);
xlabel('Mode index');   ylabel('Test');
title('Per-mode relative errors [%]  (heatmap)');
yticks(1:numTests);  yticklabels(testNames);
xticks(1:numModes);

subplot(2,1,2);
avgE = mean(resultsTable, 2, 'omitnan');
bar(1:numTests, avgE);
xlabel('Test');   ylabel('Mean error [%]');
title('Mean error per test');
xticks(1:numTests);  xticklabels(testNames);
grid on;

saveas(gcf, 'results/errors_overview.png');
fprintf('  Figure : results/errors_overview.png\n');

%% FINAL SUMMARY
% --------------------------------------------------------------------------
fprintf('\n');
fprintf('==========================================================================\n');
fprintf('  DONE  —  %d / %d tests passed\n', successCount, numTests);
fprintf('  Total computation time: %.2f s\n', sum(executionTimes));
if successCount > 0
    fprintf('  Overall mean error: %.4f %%\n', mean(resultsTable(:), 'omitnan'));
end
fprintf('==========================================================================\n\n');
