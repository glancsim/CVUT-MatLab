%% run_all_linear_fem_tests.m
% ==========================================================================
% LINEAR FEM TESTS - POROVNÁNÍ MATLAB vs OOFEM (lineární analýza)
% ==========================================================================
% Spustí lineární FEM analýzu pro všechny stability testy (Test 1 až Test 9)
% a porovná výchylky s referenčním řešením z OOFEM.
%
% Cíl: Ověřit, že MATLAB implementace lineárního MKP (sestavení K, řešení K\f,
%       transformace souřadnic) dává stejné výsledky jako OOFEM Beam3d prvek.
%
% Výstupy:
%   - results/linear_errors_summary.txt  - Textový report
%   - results/linear_results.mat         - MATLAB data
%   - results/linear_errors_bar.png      - Sloupcový graf průměrných chyb
%
% Použití:
%   Spusť z hlavní složky stability-tests/
% ==========================================================================

clear; close all; clc;

%% KONFIGURACE
scriptsDir = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptsDir, '..', 'Resources'));
baseDir = scriptsDir;

numTests = 9;

fprintf('\n');
fprintf('==============================================================================\n');
fprintf('  LINEAR FEM TESTS - MATLAB vs OOFEM\n');
fprintf('==============================================================================\n');
fprintf('  Počet testů: %d\n', numTests);
fprintf('==============================================================================\n\n');

%% INICIALIZACE
testNames      = cell(numTests, 1);
testStatus     = cell(numTests, 1);
meanRelErrors  = NaN(numTests, 1);
maxRelErrors   = NaN(numTests, 1);
minRelErrors   = NaN(numTests, 1);
meanAbsErrors  = NaN(numTests, 1);
maxAbsErrors   = NaN(numTests, 1);
minAbsErrors   = NaN(numTests, 1);
executionTimes = zeros(numTests, 1);
allErrors      = cell(numTests, 1);  % variable-length per test
allIsRelative  = cell(numTests, 1);  % logical mask (true=relative, false=absolute)

%% HLAVNÍ SMYČKA
for testNum = 1:numTests

    testName = sprintf('Test %d', testNum);
    testNames{testNum} = testName;

    fprintf('► %s (%d/%d): ', testName, testNum, numTests);

    testDir = fullfile(baseDir, testName);

    if ~exist(testDir, 'dir')
        fprintf('✗ CHYBA - Složka neexistuje!\n');
        testStatus{testNum} = 'MISSING';
        continue;
    end

    startTime = tic;
    oldDir = cd(testDir);

    try
        % Load test input
        test_input;  % loads: sections, nodes, ndisc, kinematic, beams, loads

        % Run linear FEM comparison
        [errors, matlabDispl, oofemDispl, isRelative] = linearFemTestFn( ...
            sections, nodes, ndisc, kinematic, beams, loads);

        cd(oldDir);
        elapsedTime = toc(startTime);
        executionTimes(testNum) = elapsedTime;

        allErrors{testNum}     = errors;
        allIsRelative{testNum} = isRelative;

        % Relative errors [%] — DOFs with non-zero OOFEM reference
        relE = errors(isRelative);
        if ~isempty(relE)
            meanRelErrors(testNum) = mean(relE, 'omitnan');
            maxRelErrors(testNum)  = max(relE,  [], 'omitnan');
            minRelErrors(testNum)  = min(relE,  [], 'omitnan');
        end

        % Absolute errors [m or rad] — DOFs where OOFEM reference ≈ 0
        absE = errors(~isRelative);
        if ~isempty(absE)
            meanAbsErrors(testNum) = mean(absE, 'omitnan');
            maxAbsErrors(testNum)  = max(absE,  [], 'omitnan');
            minAbsErrors(testNum)  = min(absE,  [], 'omitnan');
        end

        testStatus{testNum} = 'OK';

        % Progress line with correct units
        if ~isempty(relE) && ~isempty(absE)
            fprintf('✓ HOTOVO (%.1fs) | Rel. průměr: %.4f%% | Abs. průměr: %.4e m/rad\n', ...
                elapsedTime, meanRelErrors(testNum), meanAbsErrors(testNum));
        elseif ~isempty(relE)
            fprintf('✓ HOTOVO (%.1fs) | Rel. průměr: %.4f%% | Max: %.4f%%\n', ...
                elapsedTime, meanRelErrors(testNum), maxRelErrors(testNum));
        else
            fprintf('✓ HOTOVO (%.1fs) | Abs. průměr: %.4e m/rad | Max: %.4e m/rad\n', ...
                elapsedTime, meanAbsErrors(testNum), maxAbsErrors(testNum));
        end

    catch ME
        cd(oldDir);
        elapsedTime = toc(startTime);
        executionTimes(testNum) = elapsedTime;
        testStatus{testNum} = 'ERROR';
        fprintf('✗ CHYBA (%.1fs): %s\n', elapsedTime, ME.message);

        logFile = fullfile(testDir, 'linear_error_log.txt');
        fid = fopen(logFile, 'w');
        fprintf(fid, 'Chyba lineárního FEM testu:\n%s\n\nStack:\n', ME.message);
        for k = 1:length(ME.stack)
            fprintf(fid, '  %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
        end
        fclose(fid);
    end

end

%% VÝSLEDKY
fprintf('\n');
fprintf('==============================================================================\n');
fprintf('  VÝSLEDKY\n');
fprintf('==============================================================================\n');
fprintf('  %-10s  %-14s  %-14s  %-14s  %-8s\n', ...
    'Test', 'Rel.průměr [%]', 'Rel.max [%]', 'Abs.průměr [m]', 'Status');
fprintf('  %s\n', repmat('-', 1, 68));
for i = 1:numTests
    if strcmp(testStatus{i}, 'OK')
        relStr = '-';
        relMaxStr = '-';
        absStr = '-';
        if ~isnan(meanRelErrors(i))
            relStr    = sprintf('%.6g', meanRelErrors(i));
            relMaxStr = sprintf('%.6g', maxRelErrors(i));
        end
        if ~isnan(meanAbsErrors(i))
            absStr = sprintf('%.4e', meanAbsErrors(i));
        end
        fprintf('  %-10s  %-14s  %-14s  %-14s  %s\n', ...
            testNames{i}, relStr, relMaxStr, absStr, testStatus{i});
    else
        fprintf('  %-10s  %-14s  %-14s  %-14s  %s\n', ...
            testNames{i}, '-', '-', '-', testStatus{i});
    end
end

%% EXPORT
cd(baseDir);
if ~exist('results', 'dir'), mkdir('results'); end

% MAT file
save('results/linear_results.mat', 'testNames', 'testStatus', ...
    'meanRelErrors', 'maxRelErrors', 'minRelErrors', ...
    'meanAbsErrors', 'maxAbsErrors', 'minAbsErrors', ...
    'executionTimes', 'allErrors', 'allIsRelative');
fprintf('\n✓ MAT soubor: results/linear_results.mat\n');

% Text report
fid = fopen('results/linear_errors_summary.txt', 'w');
fprintf(fid, '==============================================================================\n');
fprintf(fid, '  LINEAR FEM TESTS - SOUHRN (MATLAB vs OOFEM)\n');
fprintf(fid, '==============================================================================\n');
fprintf(fid, 'Datum: %s\n\n', datestr(now));
for i = 1:numTests
    fprintf(fid, '%s:  status=%s', testNames{i}, testStatus{i});
    if strcmp(testStatus{i}, 'OK')
        if ~isnan(meanRelErrors(i))
            fprintf(fid, '  rel_mean=%.4g%%  rel_max=%.4g%%  rel_min=%.4g%%', ...
                meanRelErrors(i), maxRelErrors(i), minRelErrors(i));
        end
        if ~isnan(meanAbsErrors(i))
            fprintf(fid, '  abs_mean=%.4e m/rad  abs_max=%.4e m/rad', ...
                meanAbsErrors(i), maxAbsErrors(i));
        end
    end
    fprintf(fid, '\n');
end
fprintf(fid, '==============================================================================\n');
fclose(fid);
fprintf('✓ Textový report: results/linear_errors_summary.txt\n');

% Bar charts — relative and absolute errors shown in separate subplots
okIdx = strcmp(testStatus, 'OK');
hasRel = okIdx & ~isnan(meanRelErrors);
hasAbs = okIdx & ~isnan(meanAbsErrors);
if any(hasRel) || any(hasAbs)
    nSubplots = double(any(hasRel)) + double(any(hasAbs));
    figure('Position', [100 100 900 450 * nSubplots], 'Name', 'Linear FEM Errors');
    spIdx = 0;

    if any(hasRel)
        spIdx = spIdx + 1;
        subplot(nSubplots, 1, spIdx);
        bar(find(hasRel), meanRelErrors(hasRel));
        hold on;
        errorbar(find(hasRel), meanRelErrors(hasRel), ...
            meanRelErrors(hasRel) - minRelErrors(hasRel), ...
            maxRelErrors(hasRel) - meanRelErrors(hasRel), 'k.', 'LineWidth', 1.2);
        xlabel('Test', 'FontSize', 12);
        ylabel('Relativní chyba výchylky [%]', 'FontSize', 12);
        title('Lineární FEM: Relativní chyby MATLAB vs OOFEM (nenulové ref. DOF)', ...
            'FontSize', 12, 'FontWeight', 'bold');
        xticks(1:numTests); xticklabels(testNames); grid on;
    end

    if any(hasAbs)
        spIdx = spIdx + 1;
        subplot(nSubplots, 1, spIdx);
        bar(find(hasAbs), meanAbsErrors(hasAbs));
        hold on;
        errorbar(find(hasAbs), meanAbsErrors(hasAbs), ...
            meanAbsErrors(hasAbs) - minAbsErrors(hasAbs), ...
            maxAbsErrors(hasAbs) - meanAbsErrors(hasAbs), 'k.', 'LineWidth', 1.2);
        xlabel('Test', 'FontSize', 12);
        ylabel('Absolutní chyba výchylky [m nebo rad]', 'FontSize', 12);
        title('Lineární FEM: Absolutní chyby MATLAB vs OOFEM (ref. DOF ≈ 0)', ...
            'FontSize', 12, 'FontWeight', 'bold');
        xticks(1:numTests); xticklabels(testNames); grid on;
    end

    saveas(gcf, 'results/linear_errors_bar.png');
    fprintf('✓ Graf: results/linear_errors_bar.png\n');
end

fprintf('\n==============================================================================\n');
successCount = sum(strcmp(testStatus, 'OK'));
fprintf('  Úspěšné: %d / %d  |  Čas: %.1f s\n', successCount, numTests, sum(executionTimes));
fprintf('==============================================================================\n\n');
