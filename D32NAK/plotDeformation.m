function plotDeformation(nodes, elements, constraints, loads, displacements, scale_factor, load_case_index)
    % Funkce pro vykreslení deformované konstrukce
    % Vstup:
    %   nodes: [node_id, x, y] - Souřadnice uzlů
    %   elements: [elem_id, node1, node2, E, A, I] - Vlastnosti prvků
    %   constraints: [node_id, ux, uy, theta] - Okrajové podmínky
    %   loads: [node_id, Fx, Fy, M] - Aplikovaná zatížení
    %   displacements: [node_id, ux, uy, theta] - Vypočtené posunutí
    %               Může být buď matice pro jeden zatěžovací stav, nebo cell array pro více zatěžovacích stavů
    %   scale_factor: Zvětšení deformace pro lepší viditelnost
    %   load_case_index: Index zatěžovacího stavu (pokud je displacements cell array)
    
    % Zkontrolujeme, zda displacements je cell array a vybereme správný zatěžovací stav
    if iscell(displacements)
        if nargin < 7
            % Pokud není specifikován index zatěžovacího stavu, použijeme první
            load_case_index = 1;
        end
        disp_data = displacements{load_case_index};
    else
        disp_data = displacements;
    end
    
    % Zkontrolujeme, zda loads je cell array a vybereme správný zatěžovací stav
    if iscell(loads)
        if nargin < 7
            % Pokud není specifikován index zatěžovacího stavu, použijeme první
            load_case_index = 1;
        end
        load_data = loads{load_case_index};
    else
        load_data = loads;
    end
    
    if nargin < 6 || isempty(scale_factor)
        % Automatické určení měřítka deformace
        max_disp = max(max(abs(disp_data(:, 1:2))));
        if max_disp == 0
            max_disp = 1;
        end
        
        % Najít rozměry konstrukce
        x_vals = nodes(:, 2);
        y_vals = nodes(:, 3);
        struct_size = max(max(x_vals) - min(x_vals), max(y_vals) - min(y_vals));
        
        % Měřítko deformace - zpravidla 5-10% rozměru konstrukce
        scale_factor = 0.1 * struct_size / max_disp;
    end
    
    % Použijeme aktuální osu místo vytváření nového grafu
    hold on;
    grid on;
    axis equal;
    
    % Vykreslení původní konstrukce šedě
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        x1 = nodes(n1, 2); y1 = nodes(n1, 3);
        x2 = nodes(n2, 2); y2 = nodes(n2, 3);
        
        % Vykreslení prvků šedou barvou
        plot([x1, x2], [y1, y2], '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    end
    
    % Vykreslení deformované konstrukce
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        x1 = nodes(n1, 2); y1 = nodes(n1, 3);
        x2 = nodes(n2, 2); y2 = nodes(n2, 3);
        
        % Přidání deformace
        dx1 = disp_data(n1, 1) * scale_factor;
        dy1 = disp_data(n1, 2) * scale_factor;
        dx2 = disp_data(n2, 1) * scale_factor;
        dy2 = disp_data(n2, 2) * scale_factor;
        
        % Vykreslení deformovaných prvků červenou barvou
        plot([x1 + dx1, x2 + dx2], [y1 + dy1, y2 + dy2], 'r-', 'LineWidth', 2);
    end
    
    % Vykreslení uzlů deformované konstrukce
    for i = 1:size(nodes, 1)
        x = nodes(i, 2);
        y = nodes(i, 3);
        node_id = nodes(i, 1);
        
        % Přidání deformace
        dx = disp_data(i, 1) * scale_factor;
        dy = disp_data(i, 2) * scale_factor;
        
        % Vykreslení uzlů jako červených kroužků
        plot(x + dx, y + dy, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
        
        % Popisky uzlů
        text(x + dx + 0.1, y + dy + 0.1, num2str(node_id), 'FontSize', 10, 'Color', 'r');
    end
    
    % Vykreslení podpor
    for i = 1:size(constraints, 1)
        node = constraints(i, 1);
        x = nodes(node, 2);
        y = nodes(node, 3);
        
        % Podpory zůstanou na původních místech (bez deformace)
        if constraints(i, 2) == 1 && constraints(i, 3) == 1 && constraints(i, 4) == 1
            % Vykreslení kostičky pro znázornění vetknutí
            rectangle('Position', [x-0.3, y-0.3, 0.6, 0.3], 'FaceColor', [0.7 0.7 0.7]);
        elseif constraints(i, 2) == 1 && constraints(i, 3) == 1 && constraints(i, 4) == 0
            % Vykreslení trojúhelníku pro kloubovou podporu
            triangle_x = [x-0.3, x+0.3, x, x-0.3];
            triangle_y = [y-0.3, y-0.3, y, y-0.3];
            fill(triangle_x, triangle_y, [0.7 0.7 0.7], 'EdgeColor', 'k');
        end
    end
    
    % Vykreslení zatížení
    for i = 1:size(load_data, 1)
        node = load_data(i, 1);
        x = nodes(node, 2);
        y = nodes(node, 3);
        Fx = load_data(i, 2);
        Fy = load_data(i, 3);
        M = load_data(i, 4);
        
        % Přidání deformace k pozici šipky zatížení
        dx = disp_data(node, 1) * scale_factor;
        dy = disp_data(node, 2) * scale_factor;
        
        % Vykreslení zatížení na deformované konstrukci
        quiver_scale = 0.3;
        
        % Horizontální síla
        if Fx ~= 0
            quiver(x + dx, y + dy, sign(Fx) * quiver_scale, 0, 'r-', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
        end
        
        % Vertikální síla
        if Fy ~= 0
            quiver(x + dx, y + dy, 0, sign(Fy) * quiver_scale, 'r-', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
        end
    end
    
    % Přidání informací o měřítku deformace
    text(min(nodes(:, 2)), min(nodes(:, 3)) - 0.5, ...
        sprintf('Deformace zvětšena %.0f×', scale_factor), ...
        'FontSize', 10, 'Color', 'r');
    
    % Nastavení grafu
    xlabel('x [m]');
    ylabel('y [m]');
    
    % Legenda
    h_original = plot(NaN, NaN, '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    h_deformed = plot(NaN, NaN, 'r-', 'LineWidth', 2);
    h_nodes = plot(NaN, NaN, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
    
    legend([h_original, h_deformed, h_nodes], {'Původní konstrukce', 'Deformovaná konstrukce', 'Deformované uzly'});
    % hold off;
end