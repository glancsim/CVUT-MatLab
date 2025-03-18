close all; clc; clear all;
% Define nodes [node_id, x, y]
nodes = [
    1, 0, 0;
    2, 0, 3;
    3, 4, 3
];

% Define elements [elem_id, node1, node2, E, A, I]
elements = [
    1, 1, 2, 200e9, 0.01, 8.33e-6;  % Column
    2, 2, 3, 200e9, 0.01, 8.33e-6   % Beam
];

% Define constraints [node_id, ux, uy, theta]
constraints = [
    1, 1, 1, 1  % Fixed support at base
];

% Define multiple load cases
% Zatěžovací stav 1: Vertikální síla na konci nosníku
loadcase1 = [
    3, 0, -10000, 0  % Vertical load at tip
];

% Zatěžovací stav 2: Horizontální síla na konci nosníku
loadcase2 = [
    3, 5000, 0, 0  % Horizontal load at tip
];

% Zatěžovací stav 3: Moment na konci nosníku
loadcase3 = [
    3, 0, 0, 15000  % Moment at tip
];

% Spojení zatěžovacích stavů do jedné buňkové matice
loads = {loadcase1, loadcase2, loadcase3};

% Názvy zatěžovacích stavů pro výpis
loadcase_names = {'Vertikální síla', 'Horizontální síla', 'Moment'};

% Volání funkce s ukládáním výsledků
[displacements, reactions, element_forces] = frame2D_FEM(nodes, elements, constraints, loads);

% Zobrazení výsledků pro každý zatěžovací stav
for i = 1:length(loads)
    fprintf('\n==== ZATĚŽOVACÍ STAV %d: %s ====\n', i, loadcase_names{i});
    
    fprintf('Posunutí uzlů [ux, uy, rotace]:\n');
    for j = 1:size(nodes, 1)
        fprintf('Uzel %d: %.6e, %.6e, %.6e\n', j, displacements{i}(j, 1), displacements{i}(j, 2), displacements{i}(j, 3));
    end
    
    fprintf('\nReakce v podporách:\n');
    for j = 1:size(constraints, 1)
        node = constraints(j, 1);
        fprintf('Uzel %d: Rx=%.2f N, Ry=%.2f N, M=%.2f Nm\n', node, reactions{i}(3*node-2), reactions{i}(3*node-1), reactions{i}(3*node));
    end
    
    fprintf('\nVnitřní síly v prvcích [N1 V1 M1 N2 V2 M2]:\n');
    for j = 1:size(elements, 1)
        fprintf('Prvek %d: %.2f N, %.2f N, %.2f Nm, %.2f N, %.2f N, %.2f Nm\n', j, ...
            element_forces{i}(j, 1), element_forces{i}(j, 2), element_forces{i}(j, 3), ...
            element_forces{i}(j, 4), element_forces{i}(j, 5), element_forces{i}(j, 6));
    end
    
    fprintf('\n');
    
    % Vykreslení konstrukce a deformace vedle sebe pro každý zatěžovací stav
    figure('Name', ['Zatěžovací stav ' num2str(i) ': ' loadcase_names{i} ' - Konstrukce a deformace'], 'Position', [100, 100, 1200, 500]);
    
    % Subplot pro původní konstrukci
    subplot(1, 2, 1);
    plotStructure(nodes, elements, constraints, loads{i});
    title(['Původní konstrukce - ' loadcase_names{i}]);
    
    % Subplot pro deformovanou konstrukci
    subplot(1, 2, 2);
    plotDeformation(nodes, elements, constraints, loads, displacements, 1, i);
    title(['Deformace - ' loadcase_names{i}]);
    
    % Vykreslení vnitřních sil N, V, M pro každý zatěžovací stav
    figure('Name', ['Zatěžovací stav ' num2str(i) ': ' loadcase_names{i} ' - Vnitřní síly'], 'Position', [100, 600, 1200, 400]);
    
    % Subplot pro normálové síly N
    subplot(1, 3, 1);
    plotInternalForces(nodes, elements, element_forces, 'N', i);
    
    % Subplot pro posouvající síly V
    subplot(1, 3, 2);
    plotInternalForces(nodes, elements, element_forces, 'V', i);
    
    % Subplot pro ohybové momenty M
    subplot(1, 3, 3);
    plotInternalForces(nodes, elements, element_forces, 'M', i);
end