%% run_all_linear_fem_tests.m
% ==========================================================================
% LINEAR FEM TESTS - POROVNÁNÍ MATLAB vs OOFEM (lineární analýza)
% ==========================================================================
% Spustí lineární FEM analýzu pro všechny stability testy (Test 1 až Test 12)
% Testy 10–12: nové geometrie (portálový rám, konzola s pootočeným průřezem, L-rám)
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
addpath(scriptsDir);  % aby bylo linearFemTestFn viditelné po cd do testDir
baseDir = scriptsDir;

numTests = 12;

fprintf('\n');
fprintf('==============================================================================\n');
fprintf('  LINEAR FEM TESTS - MATLAB vs OOFEM\n');
fprintf('==============================================================================\n');
fprintf('  Počet testů: %d\n', numTests);
fprintf('==============================================================================\n\n');

%% INICIALIZACE
testNames      = cell(numTests, 1);
testStatus     = cell(numTests, 1);
meanErrors     = NaN(numTests, 1);
maxErrors      = NaN(numTests, 1);
minErrors      = NaN(numTests, 1);
meanForceErrors = NaN(numTests, 1);
maxForceErrors  = NaN(numTests, 1);
minForceErrors  = NaN(numTests, 1);
executionTimes = zeros(numTests, 1);
allErrors      = cell(numTests, 1);  % variable-length per test
allForceErrors = cell(numTests, 1);  % (12 x nelement) per test

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
        [errors, matlabDispl, oofemDispl, forceErrors] = linearFemTestFn( ...
            sections, nodes, ndisc, kinematic, beams, loads);

        cd(oldDir);
        elapsedTime = toc(startTime);
        executionTimes(testNum) = elapsedTime;

        allErrors{testNum}      = errors;
        meanErrors(testNum)     = mean(errors, 'omitnan');
        maxErrors(testNum)      = max(errors,  [], 'omitnan');
        minErrors(testNum)      = min(errors,  [], 'omitnan');
        allForceErrors{testNum} = forceErrors;
        meanForceErrors(testNum) = mean(forceErrors(:), 'omitnan');
        maxForceErrors(testNum)  = max(forceErrors(:),  [], 'omitnan');
        minForceErrors(testNum)  = min(forceErrors(:),  [], 'omitnan');
        testStatus{testNum} = 'OK';

        fprintf('✓ HOTOVO (%.1fs) | Posuny avg: %.4f%% max: %.4f%% | Síly avg: %.4f%% max: %.4f%%\n', ...
            elapsedTime, meanErrors(testNum), maxErrors(testNum), ...
            meanForceErrors(testNum), maxForceErrors(testNum));

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
fprintf('  %-10s  %-12s  %-12s  %-12s  %-12s  %-8s\n', ...
    'Test', 'Posuny avg', 'Posuny max', 'Síly avg', 'Síly max', 'Status');
fprintf('  %s\n', repmat('-', 1, 75));
for i = 1:numTests
    if strcmp(testStatus{i}, 'OK')
        fprintf('  %-10s  %-12.6g  %-12.6g  %-12.6g  %-12.6g  %s\n', ...
            testNames{i}, meanErrors(i), maxErrors(i), ...
            meanForceErrors(i), maxForceErrors(i), testStatus{i});
    else
        fprintf('  %-10s  %-12s  %-12s  %-12s  %-12s  %s\n', ...
            testNames{i}, '-', '-', '-', '-', testStatus{i});
    end
end

%% EXPORT
cd(baseDir);
if ~exist('results', 'dir'), mkdir('results'); end

% MAT file
save('results/linear_results.mat', 'testNames', 'testStatus', ...
    'meanErrors', 'maxErrors', 'minErrors', ...
    'meanForceErrors', 'maxForceErrors', 'minForceErrors', ...
    'executionTimes', 'allErrors', 'allForceErrors');
fprintf('\n✓ MAT soubor: results/linear_results.mat\n');

% Text report
fid = fopen('results/linear_errors_summary.txt', 'w');
fprintf(fid, '==============================================================================\n');
fprintf(fid, '  LINEAR FEM TESTS - SOUHRN (MATLAB vs OOFEM)\n');
fprintf(fid, '==============================================================================\n');
fprintf(fid, 'Datum: %s\n\n', datestr(now));
fprintf(fid, '  %-10s  %-12s  %-12s  %-12s  %-12s  %-8s\n', ...
    'Test', 'Posuny avg', 'Posuny max', 'Sily avg', 'Sily max', 'Status');
fprintf(fid, '  %s\n', repmat('-', 1, 75));
for i = 1:numTests
    if strcmp(testStatus{i}, 'OK')
        fprintf(fid, '  %-10s  %-12.4g  %-12.4g  %-12.4g  %-12.4g  %s\n', ...
            testNames{i}, meanErrors(i), maxErrors(i), ...
            meanForceErrors(i), maxForceErrors(i), testStatus{i});
    else
        fprintf(fid, '  %-10s  %-12s  %-12s  %-12s  %-12s  %s\n', ...
            testNames{i}, '-', '-', '-', '-', testStatus{i});
    end
end
fprintf(fid, '==============================================================================\n');
fclose(fid);
fprintf('✓ Textový report: results/linear_errors_summary.txt\n');

% Bar charts
okIdx = strcmp(testStatus, 'OK');
if any(okIdx)
    % Displacement errors
    figure('Position', [100 100 900 450], 'Name', 'Linear FEM Displacement Errors');
    bar(find(okIdx), meanErrors(okIdx));
    hold on;
    errorbar(find(okIdx), meanErrors(okIdx), ...
        meanErrors(okIdx) - minErrors(okIdx), ...
        maxErrors(okIdx) - meanErrors(okIdx), 'k.', 'LineWidth', 1.2);
    xlabel('Test', 'FontSize', 12);
    ylabel('Relativní chyba výchylky [%]', 'FontSize', 12);
    title('Lineární FEM: Relativní chyba posunů MATLAB vs OOFEM', ...
        'FontSize', 13, 'FontWeight', 'bold');
    xticks(1:numTests);
    xticklabels(testNames);
    grid on;
    saveas(gcf, 'results/linear_errors_bar.png');
    fprintf('✓ Graf posunů: results/linear_errors_bar.png\n');

    % Force errors
    figure('Position', [100 100 900 450], 'Name', 'Linear FEM Internal Force Errors');
    bar(find(okIdx), meanForceErrors(okIdx));
    hold on;
    errorbar(find(okIdx), meanForceErrors(okIdx), ...
        meanForceErrors(okIdx) - minForceErrors(okIdx), ...
        maxForceErrors(okIdx) - meanForceErrors(okIdx), 'k.', 'LineWidth', 1.2);
    xlabel('Test', 'FontSize', 12);
    ylabel('Relativní chyba vnitřních sil [%]', 'FontSize', 12);
    title('Lineární FEM: Relativní chyba vnitřních sil MATLAB vs OOFEM', ...
        'FontSize', 13, 'FontWeight', 'bold');
    xticks(1:numTests);
    xticklabels(testNames);
    grid on;
    saveas(gcf, 'results/linear_force_errors_bar.png');
    fprintf('✓ Graf sil: results/linear_force_errors_bar.png\n');
end

fprintf('\n==============================================================================\n');
successCount = sum(strcmp(testStatus, 'OK'));
fprintf('  Úspěšné: %d / %d  |  Čas: %.1f s\n', successCount, numTests, sum(executionTimes));
fprintf('==============================================================================\n\n');
