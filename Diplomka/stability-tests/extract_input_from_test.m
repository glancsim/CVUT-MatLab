%% extract_input_from_test.m
% ==========================================================================
% EXTRAKCE VSTUPNÍCH DAT Z test.mlx
% ==========================================================================
% Tento skript vytvoří test_input.m ze stávajícího test.mlx
%
% POSTUP:
%   1. cd do složky s testem (např. Test 1/)
%   2. Spusť tento skript
%   3. Vygeneruje test_input.m
%
% ==========================================================================

clear; clc;

fprintf('\n');
fprintf('=========================================================================\n');
fprintf('  EXTRAKCE VSTUPNÍCH DAT Z test.mlx\n');
fprintf('==================================================================\n\n');

% Kontrola existence test.mlx
if ~exist('test.mlx', 'file')
    error('test.mlx nenalezen v aktuální složce');
end

fprintf('► Spouštím test.mlx...\n');

% Spuštění test.mlx
run('test.mlx');

fprintf('✓ Test dokončen\n\n');

%% KONTROLA PROMĚNNÝCH
% --------------------------------------------------------------------------

fprintf('► Kontroluji proměnné...\n');

requiredVars = {'sections', 'nodes', 'ndisc', 'kinematic', 'beams', 'loads'};
missing = {};

for i = 1:length(requiredVars)
    if ~exist(requiredVars{i}, 'var')
        missing{end+1} = requiredVars{i};
    end
end

if ~isempty(missing)
    error('Chybí proměnné: %s', strjoin(missing, ', '));
end

fprintf('✓ Všechny proměnné nalezeny\n\n');

%% VYTVOŘENÍ test_input.m
% --------------------------------------------------------------------------

fprintf('► Vytvářím test_input.m...\n');

fid = fopen('test_input.m', 'w');

fprintf(fid, '%% test_input.m - Vstupní data pro stability test\n');
fprintf(fid, '%%\n');
fprintf(fid, '%% Automaticky vygenerováno pomocí extract_input_from_test.m\n');
fprintf(fid, '%% Datum: %s\n\n', datestr(now));

% PRŮŘEZY
fprintf(fid, '%%%% PRŮŘEZY\n');
fprintf(fid, 'sections.id = [');
fprintf(fid, '%d', sections.id(1));
for i = 2:length(sections.id)
    fprintf(fid, '; %d', sections.id(i));
end
fprintf(fid, '];  %% section id in sectionsSet.mat\n\n');

% UZLY
fprintf(fid, '%%%% UZLY\n');
fprintf(fid, 'nodes.x = [');
fprintf(fid, '%.4f', nodes.x(1));
for i = 2:length(nodes.x)
    fprintf(fid, '; %.4f', nodes.x(i));
end
fprintf(fid, '];  %% x coordinates of nodes\n');

fprintf(fid, 'nodes.y = [');
fprintf(fid, '%.4f', nodes.y(1));
for i = 2:length(nodes.y)
    fprintf(fid, '; %.4f', nodes.y(i));
end
fprintf(fid, '];  %% y coordinates of nodes\n');

fprintf(fid, 'nodes.z = [');
fprintf(fid, '%.4f', nodes.z(1));
for i = 2:length(nodes.z)
    fprintf(fid, '; %.4f', nodes.z(i));
end
fprintf(fid, '];  %% z coordinates of nodes\n\n');

% DISKRETIZACE
fprintf(fid, '%%%% DISKRETIZACE\n');
fprintf(fid, 'ndisc = %d;  %% discretization of beams\n\n', ndisc);

% PODPORY
fprintf(fid, '%%%% PODPORY\n');
writeField(fid, 'kinematic', 'x', kinematic.x.nodes, 'node indices with restricted x-direction displacements');
writeField(fid, 'kinematic', 'y', kinematic.y.nodes, 'node indices with restricted y-direction displacements');
writeField(fid, 'kinematic', 'z', kinematic.z.nodes, 'node indices with restricted z-direction displacements');
writeField(fid, 'kinematic', 'rx', kinematic.rx.nodes, 'node indices with restricted x-direction rotations');
writeField(fid, 'kinematic', 'ry', kinematic.ry.nodes, 'node indices with restricted y-direction rotations');
writeField(fid, 'kinematic', 'rz', kinematic.rz.nodes, 'node indices with restricted z-direction rotations');
fprintf(fid, '\n');

% PRVKY
fprintf(fid, '%%%% PRVKY\n');
writeBeamField(fid, 'nodesHead', beams.nodesHead, 'elements starting nodes');
writeBeamField(fid, 'nodesEnd', beams.nodesEnd, 'elements ending nodes');
writeBeamField(fid, 'sections', beams.sections, 'section to beams');
writeBeamField(fid, 'angles', beams.angles, 'angle of section');
fprintf(fid, '\n');

% ZATÍŽENÍ
fprintf(fid, '%%%% ZATÍŽENÍ\n');
writeLoadField(fid, 'x', loads.x.nodes, loads.x.value);
fprintf(fid, '\n');
writeLoadField(fid, 'y', loads.y.nodes, loads.y.value);
fprintf(fid, '\n');
writeLoadField(fid, 'z', loads.z.nodes, loads.z.value);
fprintf(fid, '\n');
writeLoadField(fid, 'rx', loads.rx.nodes, loads.rx.value);
fprintf(fid, '\n');
writeLoadField(fid, 'ry', loads.ry.nodes, loads.ry.value);
fprintf(fid, '\n');
writeLoadField(fid, 'rz', loads.rz.nodes, loads.rz.value);

fclose(fid);

fprintf('✓ test_input.m vytvořen\n\n');

fprintf('==================================================================\n');
fprintf('  HOTOVO!\n');
fprintf('==================================================================\n\n');
fprintf('test_input.m byl vytvořen v aktuální složce.\n');
fprintf('Nyní můžeš otestovat:\n\n');
fprintf('  test_input;\n');
fprintf('  [errors, h] = testFn(sections, nodes, ndisc, kinematic, beams, loads);\n\n');

%% POMOCNÉ FUNKCE
% --------------------------------------------------------------------------

function writeField(fid, structName, field, data, comment)
    if isempty(data)
        fprintf(fid, '%s.%s.nodes = [];', structName, field);
    else
        fprintf(fid, '%s.%s.nodes = [', structName, field);
        if isinteger(data(1)) || floor(data(1)) == data(1)
            fprintf(fid, '%d', data(1));
            for i = 2:length(data)
                fprintf(fid, '; %d', data(i));
            end
        else
            fprintf(fid, '%.4f', data(1));
            for i = 2:length(data)
                fprintf(fid, '; %.4f', data(i));
            end
        end
        fprintf(fid, ']');
    end
    fprintf(fid, ';  %% %s\n', comment);
end

function writeBeamField(fid, field, data, comment)
    % Pro beams - bez .nodes suffix
    if isempty(data)
        fprintf(fid, 'beams.%s = [];', field);
    else
        fprintf(fid, 'beams.%s = [', field);
        if isinteger(data(1)) || floor(data(1)) == data(1)
            fprintf(fid, '%d', data(1));
            for i = 2:length(data)
                fprintf(fid, '; %d', data(i));
            end
        else
            fprintf(fid, '%.4f', data(1));
            for i = 2:length(data)
                fprintf(fid, '; %.4f', data(i));
            end
        end
        fprintf(fid, ']');
    end
    fprintf(fid, ';  %% %s\n', comment);
end

function writeLoadField(fid, field, nodes, values)
    % Nodes
    if isempty(nodes)
        fprintf(fid, 'loads.%s.nodes = [];', field);
    else
        fprintf(fid, 'loads.%s.nodes = [', field);
        fprintf(fid, '%d', nodes(1));
        for i = 2:length(nodes)
            fprintf(fid, '; %d', nodes(i));
        end
        fprintf(fid, ']');
    end
    fprintf(fid, ';  %% node indices with %s-direction forces\n', field);
    
    % Values
    if isempty(values)
        fprintf(fid, 'loads.%s.value = [];', field);
    else
        fprintf(fid, 'loads.%s.value = [', field);
        fprintf(fid, '%.4f', values(1));
        for i = 2:length(values)
            fprintf(fid, '; %.4f', values(i));
        end
        fprintf(fid, ']');
    end
    fprintf(fid, ';  %% magnitude of the %s-direction forces\n', field);
end