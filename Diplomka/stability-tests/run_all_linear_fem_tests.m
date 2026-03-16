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
allAbsErrors   = cell(numTests, 1);  % absolute errors [m or rad], all DOFs
allRelErrors   = cell(numTests, 1);  % relative errors [%], NaN for near-zero-ref DOFs

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
        [absErrors, relErrors, matlabDispl, oofemDispl] = linearFemTestFn( ...
            sections, nodes, ndisc, kinematic, beams, loads);

        cd(oldDir);
        elapsedTime = toc(startTime);
        executionTimes(testNum) = elapsedTime;

        allAbsErrors{testNum}  = absErrors;
        allRelErrors{testNum}  = relErrors;
        meanAbsErrors(testNum) = mean(absErrors, 'omitnan');
        maxAbsErrors(testNum)  = max(absErrors,  [], 'omitnan');
        minAbsErrors(testNum)  = min(absErrors,  [], 'omitnan');
        meanRelErrors(testNum) = mean(relErrors, 'omitnan');
        maxRelErrors(testNum)  = max(relErrors,  [], 'omitnan');
        minRelErrors(testNum)  = min(relErrors,  [], 'omitnan');
        testStatus{testNum} = 'OK';

        fprintf('✓ HOTOVO (%.1fs) | Abs průměr: %.4g m/rad | Rel průměr: %.4f%%\n', ...
            elapsedTime, meanAbsErrors(testNum), meanRelErrors(testNum));

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
fprintf('  %-10s  %-18s  %-18s  %-8s\n', ...
    'Test', 'Abs průměr [m/rad]', 'Rel průměr [%]', 'Status');
fprintf('  %s\n', repmat('-', 1, 64));
for i = 1:numTests
    if strcmp(testStatus{i}, 'OK')
        if isnan(meanRelErrors(i))
            relStr = 'N/A (ref≈0)';
        else
            relStr = sprintf('%.6g', meanRelErrors(i));
        end
        fprintf('  %-10s  %-18.6g  %-18s  %s\n', ...
            testNames{i}, meanAbsErrors(i), relStr, testStatus{i});
    else
        fprintf('  %-10s  %-18s  %-18s  %s\n', ...
            testNames{i}, '-', '-', testStatus{i});
    end
end

%% EXPORT
cd(baseDir);
if ~exist('results', 'dir'), mkdir('results'); end

% MAT file
save('results/linear_results.mat', 'testNames', 'testStatus', ...
    'meanAbsErrors', 'maxAbsErrors', 'minAbsErrors', ...
    'meanRelErrors', 'maxRelErrors', 'minRelErrors', ...
    'executionTimes', 'allAbsErrors', 'allRelErrors');
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
        fprintf(fid, '  absMean=%.4g m/rad  absMax=%.4g m/rad', ...
            meanAbsErrors(i), maxAbsErrors(i));
        if ~isnan(meanRelErrors(i))
            fprintf(fid, '  relMean=%.4g%%  relMax=%.4g%%  relMin=%.4g%%', ...
                meanRelErrors(i), maxRelErrors(i), minRelErrors(i));
        else
            fprintf(fid, '  rel=N/A (all ref near-zero)');
        end
    end
    fprintf(fid, '\n');
end
fprintf(fid, '==============================================================================\n');
fclose(fid);
fprintf('✓ Textový report: results/linear_errors_summary.txt\n');

% Bar chart (absolute errors)
okIdx = strcmp(testStatus, 'OK');
if any(okIdx)
    figure('Position', [100 100 900 500], 'Name', 'Linear FEM Errors');

    subplot(2,1,1);
    bar(find(okIdx), meanAbsErrors(okIdx));
    xlabel('Test', 'FontSize', 11);
    ylabel('Průměrná abs. chyba [m/rad]', 'FontSize', 11);
    title('Lineární FEM: Absolutní chyba MATLAB vs OOFEM', ...
        'FontSize', 12, 'FontWeight', 'bold');
    xticks(1:numTests);
    xticklabels(testNames);
    grid on;

    relOkIdx = okIdx & ~isnan(meanRelErrors);
    if any(relOkIdx)
        subplot(2,1,2);
        bar(find(relOkIdx), meanRelErrors(relOkIdx));
        hold on;
        errorbar(find(relOkIdx), meanRelErrors(relOkIdx), ...
            meanRelErrors(relOkIdx) - minRelErrors(relOkIdx), ...
            maxRelErrors(relOkIdx) - meanRelErrors(relOkIdx), 'k.', 'LineWidth', 1.2);
        xlabel('Test', 'FontSize', 11);
        ylabel('Průměrná rel. chyba [%]', 'FontSize', 11);
        title('Lineární FEM: Relativní chyba MATLAB vs OOFEM (jen nenulové ref)', ...
            'FontSize', 12, 'FontWeight', 'bold');
        xticks(1:numTests);
        xticklabels(testNames);
        grid on;
    end

    saveas(gcf, 'results/linear_errors_bar.png');
    fprintf('✓ Graf: results/linear_errors_bar.png\n');
end

fprintf('\n==============================================================================\n');
successCount = sum(strcmp(testStatus, 'OK'));
fprintf('  Úspěšné: %d / %d  |  Čas: %.1f s\n', successCount, numTests, sum(executionTimes));
fprintf('==============================================================================\n\n');
