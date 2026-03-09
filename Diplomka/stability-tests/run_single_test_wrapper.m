function [errors, h] = run_single_test_wrapper(testDir)
% run_single_test_wrapper - Spustí test pomocí testFn a test_input
%
% Vstupy:
%   testDir - Cesta ke složce s testem
%
% Výstupy:
%   errors - Vektor procentuálních chyb (10x1)
%   h      - Handle grafu (pokud existuje)
%
% Použití:
%   [errors, h] = run_single_test_wrapper('C:\...\Test 1');

    % Změna do složky testu
    oldDir = cd(testDir);
    
    try
        % Načtení vstupních dat testu
        if exist('test_input.m', 'file')
            % Nová metoda - použití test_input.m
            test_input;  % Načte proměnné: sections, nodes, ndisc, kinematic, beams, loads
            [errors, h, ~] = testFn(sections, nodes, ndisc, kinematic, beams, loads);
            
        elseif exist('test.mlx', 'file')
            % Stará metoda - spuštění test.mlx (fallback)
            run('test.mlx');
            
            % Kontrola existence proměnné 'errors'
            if ~exist('errors', 'var')
                error('Proměnná "errors" nebyla vytvořena testem!');
            end
            
            % Handle grafu (pokud existuje)
            if ~exist('h', 'var')
                h = [];
            end
        else
            error('Nenalezen ani test_input.m ani test.mlx');
        end
        
    catch ME
        % Návrat do původní složky
        cd(oldDir);
        % Předání chyby dál
        rethrow(ME);
    end
    
    % Návrat do původní složky
    cd(oldDir);
    
end
