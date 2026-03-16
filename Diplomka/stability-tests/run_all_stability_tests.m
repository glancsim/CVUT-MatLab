%% run_all_stability_tests.m
% ==========================================================================
% STABILITY TESTS - AUTOMATICKÉ SPUŠTĚNÍ VŠECH TESTŮ
% ==========================================================================
% Tento skript spustí všechny stability testy (Test 1 až Test 12)
% a vygeneruje souhrnný report s porovnáním oproti OOFEM.
%
% Autor: glancsim
% Datum: 2026-01-13
% Projekt: CVUT-MatLab / Diplomka / stability-tests
%
% Výstupy:
%   - results/errors_table.xlsx       - Excel tabulka s chybami
%   - results/all_tests_results.mat   - MATLAB data
%   - results/errors_summary.txt      - Textový report
%   - results/all_errors_heatmap.png  - Vizualizace
%
% Použití:
%   1. Spusť tento skript z hlavní složky stability-tests/
%   2. Skript automaticky projde všechny testy
%   3. Výsledky najdeš ve složce results/
%
% ==========================================================================

clear; close all; clc;

%% KONFIGURACE
% --------------------------------------------------------------------------

% Cesty - UPRAVIT PODLE TVÉHO SYSTÉMU
% Cesta k Resources - automaticky relativní k tomuto souboru (worktree kompatibilní)
scriptsDir = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptsDir, '..', 'Resources'));
addpath(scriptsDir);  % pro testFn, run_single_test_wrapper
baseDir = pwd; % Aktuální složka (stability-tests/)

% Nastavení testů
numTests = 12;               % Počet testů (Test 1 až Test 12)
numEigenvalues = 10;        % Počet vlastních čísel (předpoklad)

% Možnosti
saveGraphs = false;          % true = ukládat grafy z každého testu
closeGraphs = true;          % true = zavírat grafy po testu

%% INICIALIZACE
% --------------------------------------------------------------------------

% Příprava výsledkové struktury
resultsTable = NaN(numTests, numEigenvalues); % NaN pro případné chyby
testNames = cell(numTests, 1);
testStatus = cell(numTests, 1);
executionTimes = zeros(numTests, 1);

% Progress bar
fprintf('\n');
fprintf('==============================================================================\n');
fprintf('  STABILITY TESTS - AUTOMATICKÉ SPUŠTĚNÍ\n');
fprintf('==============================================================================\n');
fprintf('  Počet testů: %d\n', numTests);
fprintf('  Složka: %s\n', baseDir);
fprintf('==============================================================================\n\n');

%% HLAVNÍ SMYČKA - SPUŠTĚNÍ VŠECH TESTŮ
% --------------------------------------------------------------------------

for testNum = 1:numTests
    
    % Název testu
    testName = sprintf('Test %d', testNum);
    testNames{testNum} = testName;
    
    % Progress indikátor
    fprintf('► %s (%d/%d): ', testName, testNum, numTests);
    
    % Cesta k testu
    testDir = fullfile(baseDir, testName);
    
    % Kontrola existence složky
    if ~exist(testDir, 'dir')
        fprintf('✗ CHYBA - Složka neexistuje!\n');
        testStatus{testNum} = 'MISSING';
        continue;
    end
    
    % Měření času
    startTime = tic;
    
    try
        % Spuštění test.mlx přes wrapper funkci (izolovaný workspace!)
        [errors, h] = run_single_test_wrapper(testDir);
        
        % NYNÍ jsme zpět v run_all_stability_tests workspace
        % testNum stále existuje!
        
        % Kontrola velikosti errors
        currentNumEigen = length(errors);
        if currentNumEigen ~= numEigenvalues
            warning('Test %d má %d vlastních čísel (očekáváno %d)', ...
                    testNum, currentNumEigen, numEigenvalues);
            % Upravíme velikost resultsTable dynamicky
            if currentNumEigen > size(resultsTable, 2)
                resultsTable = [resultsTable, NaN(numTests, currentNumEigen - size(resultsTable, 2))];
            end
        end
        
        % Uložení výsledků
        resultsTable(testNum, 1:length(errors)) = errors';
        
        % Čas běhu
        elapsedTime = toc(startTime);
        executionTimes(testNum) = elapsedTime;
        
        % Status
        testStatus{testNum} = 'OK';
        
        % Výpis výsledků
        avgError = mean(errors);
        maxError = max(errors);
        fprintf('✓ HOTOVO (%.1fs) | Průměr: %.2f%% | Max: %.2f%%\n', ...
                elapsedTime, avgError, maxError);
        
        % Uložení grafu (volitelné)
        if saveGraphs && ~isempty(h)
            saveas(h, fullfile(testDir, sprintf('error_plot_test_%d.png', testNum)));
        end
        
        % Zavření grafu (volitelné)
        if closeGraphs && ~isempty(h)
            close(h);
        end
        
    catch ME
        % Chyba při běhu testu
        elapsedTime = toc(startTime);
        executionTimes(testNum) = elapsedTime;
        testStatus{testNum} = 'ERROR';
        fprintf('✗ CHYBA (%.1fs): %s\n', elapsedTime, ME.message);
        
        % Uložení detailů chyby
        logFile = fullfile(testDir, 'error_log.txt');
        fid = fopen(logFile, 'w');
        fprintf(fid, 'Chyba při spuštění testu:\n');
        fprintf(fid, '%s\n\n', ME.message);
        fprintf(fid, 'Stack trace:\n');
        for k = 1:length(ME.stack)
            fprintf(fid, '  %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
        end
        fclose(fid);
    end
    
end

%% VYTVOŘENÍ VÝSLEDKOVÉ SLOŽKY
% --------------------------------------------------------------------------

cd(baseDir);

if ~exist('results', 'dir')
    mkdir('results');
end

fprintf('\n');
fprintf('==============================================================================\n');
fprintf('  GENEROVÁNÍ REPORTŮ\n');
fprintf('==============================================================================\n\n');

%% EXPORT VÝSLEDKŮ
% --------------------------------------------------------------------------

% Dynamická aktualizace počtu vlastních čísel (pokud se lišily)
numEigenvalues = size(resultsTable, 2);

% 1. MATLAB TABLE
columnNames = arrayfun(@(x) sprintf('Error_%d', x), 1:numEigenvalues, ...
                       'UniformOutput', false);
T = array2table(resultsTable, 'RowNames', testNames, ...
                'VariableNames', columnNames);

% Přidání statistik
T.Mean = mean(resultsTable, 2, 'omitnan');
T.Max = max(resultsTable, [], 2, 'omitnan');
T.Min = min(resultsTable, [], 2, 'omitnan');
T.Status = testStatus;

% 2. EXCEL EXPORT
try
    writetable(T, 'results/errors_table.xlsx', 'WriteRowNames', true);
    fprintf('✓ Excel tabulka: results/errors_table.xlsx\n');
catch
    warning('Excel export selhal - možná nemáš nainstalovaný Excel');
end

% 3. MAT FILE
save('results/all_tests_results.mat', 'resultsTable', 'testNames', ...
     'testStatus', 'executionTimes', 'T');
fprintf('✓ MAT soubor: results/all_tests_results.mat\n');

% 4. TEXTOVÝ REPORT
fid = fopen('results/errors_summary.txt', 'w');
fprintf(fid, '==============================================================================\n');
fprintf(fid, '  STABILITY TESTS - SOUHRN VÝSLEDKŮ\n');
fprintf(fid, '==============================================================================\n');
fprintf(fid, 'Datum: %s\n', datestr(now));
fprintf(fid, 'Počet testů: %d\n', numTests);
fprintf(fid, '==============================================================================\n\n');

for i = 1:numTests
    fprintf(fid, '%s:\n', testNames{i});
    fprintf(fid, '  Status:         %s\n', testStatus{i});
    fprintf(fid, '  Čas běhu:       %.2f s\n', executionTimes(i));
    if strcmp(testStatus{i}, 'OK')
        fprintf(fid, '  Průměrná chyba: %.3f %%\n', mean(resultsTable(i,:), 'omitnan'));
        fprintf(fid, '  Max chyba:      %.3f %%\n', max(resultsTable(i,:), [], 'omitnan'));
        fprintf(fid, '  Min chyba:      %.3f %%\n', min(resultsTable(i,:), [], 'omitnan'));
    end
    fprintf(fid, '\n');
end

% Celkové statistiky
successTests = sum(strcmp(testStatus, 'OK'));
fprintf(fid, '==============================================================================\n');
fprintf(fid, 'CELKOVÉ STATISTIKY:\n');
fprintf(fid, '  Úspěšné testy:  %d / %d\n', successTests, numTests);
fprintf(fid, '  Celkový čas:    %.2f s\n', sum(executionTimes));
if successTests > 0
    fprintf(fid, '  Průměrná chyba: %.3f %%\n', mean(resultsTable(:), 'omitnan'));
    fprintf(fid, '  Max chyba:      %.3f %%\n', max(resultsTable(:), [], 'omitnan'));
end
fprintf(fid, '==============================================================================\n');
fclose(fid);

fprintf('✓ Textový report: results/errors_summary.txt\n');

%% VIZUALIZACE
% --------------------------------------------------------------------------

% 1. Heatmapa všech chyb
figure('Position', [100, 100, 1400, 700], 'Name', 'Stability Tests - Errors Overview');

subplot(2,1,1);
imagesc(resultsTable);
colorbar;
colormap(jet);
xlabel('Vlastní číslo', 'FontSize', 12);
ylabel('Test', 'FontSize', 12);
title('Procentuální chyby všech testů (heatmapa)', 'FontSize', 14, 'FontWeight', 'bold');
yticks(1:numTests);
yticklabels(testNames);
xticks(1:numEigenvalues);
grid on;

% 2. Box plot pro každý test
subplot(2,1,2);
boxplot(resultsTable', 'Labels', testNames);
ylabel('Chyba (%)', 'FontSize', 12);
xlabel('Test', 'FontSize', 12);
title('Distribuce chyb pro jednotlivé testy', 'FontSize', 14, 'FontWeight', 'bold');
grid on;

saveas(gcf, 'results/all_errors_overview.png');
fprintf('✓ Vizualizace: results/all_errors_overview.png\n');

% 3. Sloupcový graf průměrných chyb
figure('Position', [150, 150, 1000, 500], 'Name', 'Average Errors');
avgErrors = mean(resultsTable, 2, 'omitnan');
bar(1:numTests, avgErrors);
xlabel('Test', 'FontSize', 12);
ylabel('Průměrná chyba (%)', 'FontSize', 12);
title('Průměrná chyba jednotlivých testů', 'FontSize', 14, 'FontWeight', 'bold');
xticks(1:numTests);
xticklabels(testNames);
grid on;
saveas(gcf, 'results/average_errors_bar.png');
fprintf('✓ Sloupcový graf: results/average_errors_bar.png\n');

%% ZÁVĚREČNÝ VÝPIS
% --------------------------------------------------------------------------

fprintf('\n');
fprintf('==============================================================================\n');
fprintf('  HOTOVO!\n');
fprintf('==============================================================================\n');
fprintf('  Úspěšné testy:  %d / %d\n', successTests, numTests);
fprintf('  Celkový čas:    %.2f s\n', sum(executionTimes));
fprintf('  Výsledky:       %s/results/\n', baseDir);
fprintf('==============================================================================\n\n');

% Zobrazení tabulky v konzoli
fprintf('TABULKA VÝSLEDKŮ:\n\n');
disp(T);

fprintf('\n✓ Pro detailní výsledky otevři: results/errors_table.xlsx\n');
fprintf('✓ Pro textový report otevři: results/errors_summary.txt\n\n');
