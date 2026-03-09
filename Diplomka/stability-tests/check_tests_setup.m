%% check_tests_setup.m
% ==========================================================================
% KONTROLA NASTAVENÍ STABILITY TESTŮ
% ==========================================================================
% Tento skript zkontroluje že všechny testy jsou správně nastavené
% a připravené ke spuštění.
%
% Autor: glancsim
% Datum: 2026-01-13
%
% Spusť tento skript PŘED run_all_stability_tests.m pro kontrolu!
%
% ==========================================================================

clear; clc;

fprintf('\n');
fprintf('==============================================================================\n');
fprintf('  KONTROLA NASTAVENÍ STABILITY TESTŮ\n');
fprintf('==============================================================================\n\n');

%% 1. KONTROLA CEST
% --------------------------------------------------------------------------

fprintf('► Kontrola cest...\n');

% Cesta k Resources
resourcesPath = 'C:\GitHub\MatLab\Diplomka\Resources';
if exist(resourcesPath, 'dir')
    fprintf('  ✓ Resources složka nalezena: %s\n', resourcesPath);
else
    fprintf('  ✗ Resources složka NENALEZENA: %s\n', resourcesPath);
    fprintf('    → Uprav cestu v run_all_stability_tests.m\n');
end

% Aktuální složka
currentDir = pwd;
fprintf('  ℹ Aktuální složka: %s\n', currentDir);

%% 2. KONTROLA TESTOVÝCH SLOŽEK
% --------------------------------------------------------------------------

fprintf('\n► Kontrola testových složek...\n');

numTests = 9;
allTestsOK = true;

for i = 1:numTests
    testName = sprintf('Test %d', i);
    testDir = fullfile(currentDir, testName);
    
    fprintf('  %s: ', testName);
    
    if ~exist(testDir, 'dir')
        fprintf('✗ NEEXISTUJE\n');
        allTestsOK = false;
        continue;
    end
    
    % Kontrola test.mlx
    testFile = fullfile(testDir, 'test.mlx');
    if ~exist(testFile, 'file')
        fprintf('✗ Chybí test.mlx\n');
        allTestsOK = false;
        continue;
    end
    
    % Kontrola oofem
    oofemFile1 = fullfile(testDir, 'oofem');
    oofemFile2 = fullfile(testDir, 'oofem.cmd');
    if ~exist(oofemFile1, 'file') && ~exist(oofemFile2, 'file')
        fprintf('⚠ Chybí oofem/oofem.cmd (může se vygenerovat při běhu)\n');
    else
        fprintf('✓ OK\n');
    end
end

if allTestsOK
    fprintf('\n  ✓ Všechny testové složky jsou OK!\n');
else
    fprintf('\n  ✗ Některé testy mají problémy!\n');
end

%% 3. KONTROLA FUNKCÍ V RESOURCES
% --------------------------------------------------------------------------

fprintf('\n► Kontrola funkcí v Resources...\n');

requiredFunctions = {
    'stiffnessMatrixFn.m',
    'geometricMoofemFn.m',
    'oofemTestFn.m',
    'oofemInputFn.m',
    'transformationMatrixFn.m',
    'beamVertexFn.m',
    'codeNumbersFn.m',
    'XYtoRotBeamsFn.m',
    'discretizationBeamsFn.m',
    'XYtoElementFn.m',
    'sectionToElementFn.m',
    'EndForcesFn.m',
    'criticalLoadFn.m',
    'sortValuesVectorFn.m'
};

if exist(resourcesPath, 'dir')
    addpath(resourcesPath);
    
    missingFunctions = {};
    for i = 1:length(requiredFunctions)
        funcName = requiredFunctions{i};
        if exist(funcName, 'file')
            fprintf('  ✓ %s\n', funcName);
        else
            fprintf('  ✗ %s - CHYBÍ\n', funcName);
            missingFunctions{end+1} = funcName;
        end
    end
    
    if isempty(missingFunctions)
        fprintf('\n  ✓ Všechny požadované funkce jsou dostupné!\n');
    else
        fprintf('\n  ✗ Chybí %d funkcí!\n', length(missingFunctions));
    end
else
    fprintf('  ⚠ Nelze zkontrolovat - Resources složka nenalezena\n');
end

%% 4. KONTROLA OOFEM
% --------------------------------------------------------------------------

fprintf('\n► Kontrola OOFEM...\n');

[status, result] = system('oofem --version');
if status == 0
    fprintf('  ✓ OOFEM je dostupný v PATH\n');
    fprintf('    %s\n', strtrim(result));
else
    fprintf('  ✗ OOFEM NENÍ dostupný v PATH\n');
    fprintf('    → Přidej OOFEM do systémového PATH\n');
    fprintf('    → Nebo zkontroluj že oofem.cmd existuje v každé testové složce\n');
end

%% 5. TEST SPUŠTĚNÍ (volitelné)
% --------------------------------------------------------------------------

fprintf('\n► Chceš otestovat spuštění Test 1? (y/n): ');
response = input('', 's');

if strcmpi(response, 'y')
    fprintf('\n  Zkouším spustit Test 1...\n');
    
    testDir = fullfile(currentDir, 'Test 1');
    if exist(testDir, 'dir')
        originalDir = cd(testDir);
        
        try
            fprintf('  ► Spouštím test.mlx...\n');
            tic;
            run('test.mlx');
            elapsed = toc;
            
            if exist('errors', 'var')
                fprintf('  ✓ Test 1 úspěšně dokončen! (%.1fs)\n', elapsed);
                fprintf('    Průměrná chyba: %.2f%%\n', mean(errors));
                fprintf('    Počet vlastních čísel: %d\n', length(errors));
            else
                fprintf('  ✗ Test dokončen, ale proměnná "errors" nebyla vytvořena\n');
            end
            
        catch ME
            fprintf('  ✗ Chyba při spuštění: %s\n', ME.message);
        end
        
        cd(originalDir);
    else
        fprintf('  ✗ Složka Test 1 neexistuje\n');
    end
end

%% ZÁVĚR
% --------------------------------------------------------------------------

fprintf('\n');
fprintf('==============================================================================\n');
fprintf('  KONTROLA DOKONČENA\n');
fprintf('==============================================================================\n');
fprintf('\n');
fprintf('  Pokud jsou všechny kontroly ✓ OK, můžeš spustit:\n');
fprintf('    >> run_all_stability_tests\n');
fprintf('\n');
fprintf('  Pokud jsou některé kontroly ✗ CHYBA:\n');
fprintf('    1. Zkontroluj cesty v run_all_stability_tests.m\n');
fprintf('    2. Ověř že všechny funkce jsou v Resources/\n');
fprintf('    3. Zkontroluj že OOFEM je dostupný\n');
fprintf('\n');
fprintf('==============================================================================\n\n');
