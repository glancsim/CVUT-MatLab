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
loads = {   loadcase1, ...
            % loadcase2, ...
            % loadcase3...
        };

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
end

% Vykreslení deformovaného tvaru pro každý zatěžovací stav
for i = 1:length(loads)
    plot_deformed_shape(nodes, elements, displacements, i);
end

% Vykreslení průběhů vnitřních sil pro každý zatěžovací stav
% s rozdělením každého prvku na 20 segmentů pro hladší průběhy
for i = 1:length(loads)
    plot_internal_forces(nodes, elements, displacements, i, 20);
end

% Vykreslení grafů průběhů vnitřních sil podél prvků
figure('Name', 'Průběhy vnitřních sil podél prvků');

for elem_id = 1:size(elements, 1)
    % Získání vlastností prvku
    n1 = elements(elem_id, 2);
    n2 = elements(elem_id, 3);
    L = sqrt((nodes(n2,2) - nodes(n1,2))^2 + (nodes(n2,3) - nodes(n1,3))^2);
    
    % Pro každý zatěžovací stav
    for lc = 1:length(loads)
        % Vytvoření x souřadnic podél prvku (20 bodů)
        num_points = 20;
        x_local = linspace(0, L, num_points);
        
        % Inicializace polí pro vnitřní síly
        N = zeros(num_points, 1);
        V = zeros(num_points, 1);
        M = zeros(num_points, 1);
        
        % Výpočet vnitřních sil v každém bodě
        for i = 1:num_points
            % Zde byste vypočítali vnitřní síly podobně jako ve funkci plot_internal_forces
            % Pro zjednodušení zde využijeme jen krajní hodnoty z element_forces
            xi = x_local(i);
            N1 = element_forces{lc}(elem_id, 1);
            V1 = element_forces{lc}(elem_id, 2);
            M1 = element_forces{lc}(elem_id, 3);
            N2 = element_forces{lc}(elem_id, 4);
            V2 = element_forces{lc}(elem_id, 5);
            M2 = element_forces{lc}(elem_id, 6);
            
            % Lineární interpolace pro N a V
            N(i) = N1 * (1 - xi/L) + N2 * (xi/L);
            V(i) = V1 * (1 - xi/L) + V2 * (xi/L);
            
            % Pro M použijeme kvadratickou interpolaci (M = M1 + V1*x - q*x^2/2)
            % Předpokládáme, že q je konstantní po délce prvku
            q = (V2 - V1) / L;  % Změna posouvající síly / délka
            M(i) = M1 + V1 * xi - q * xi^2 / 2;
        end
        
        % Vykreslení grafů
        subplot(3, length(loads), lc);
        plot(x_local, N, 'LineWidth', 2);
        title(sprintf('N - Prvek %d - ZS %d', elem_id, lc));
        xlabel('Pozice na prvku [m]');
        ylabel('N [N]');
        grid on;
        
        subplot(3, length(loads), length(loads) + lc);
        plot(x_local, V, 'LineWidth', 2);
        title(sprintf('V - Prvek %d - ZS %d', elem_id, lc));
        xlabel('Pozice na prvku [m]');
        ylabel('V [N]');
        grid on;
        
        subplot(3, length(loads), 2*length(loads) + lc);
        plot(x_local, M, 'LineWidth', 2);
        title(sprintf('M - Prvek %d - ZS %d', elem_id, lc));
        xlabel('Pozice na prvku [m]');
        ylabel('M [Nm]');
        grid on;
    end
end