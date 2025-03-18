function plotInternalForces(nodes, elements, element_forces, force_type, load_case_index)
    % Funkce pro vykreslení vnitřních sil v konstrukci
    % Využívá diskretizaci prvků pro přesnější zobrazení průběhu vnitřních sil
    % Vstup:
    %   nodes: [node_id, x, y] - Souřadnice uzlů
    %   elements: [elem_id, node1, node2, E, A, I] - Vlastnosti prvků
    %   element_forces: {load_case1, load_case2, ...} - Buňkové pole vnitřních sil
    %                   Každý záznam je matice [N1 V1 M1 N2 V2 M2] pro každý prvek
    %   force_type: Typ vnitřní síly k vykreslení ('N', 'V', 'M')
    %   load_case_index: Index zatěžovacího stavu
    
    hold on;
    grid on;
    axis equal;
    
    % Zvolíme, které indexy se mají použít podle typu síly
    switch upper(force_type)
        case 'N'  % Normálová síla
            indices = [1, 4];  % N1, N2
            title_text = 'Normálové síly N [N]';
            color = 'b';  % Modrá pro normálové síly
        case 'V'  % Posouvající síla
            indices = [2, 5];  % V1, V2
            title_text = 'Posouvající síly V [N]';
            color = 'g';  % Zelená pro posouvající síly
        case 'M'  % Ohybový moment
            indices = [3, 6];  % M1, M2
            title_text = 'Ohybové momenty M [Nm]';
            color = 'm';  % Purpurová pro momenty
        otherwise
            error('Neplatný typ vnitřní síly. Použijte ''N'', ''V'' nebo ''M''.');
    end
    
    % Získání vnitřních sil pro konkrétní zatěžovací stav
    if iscell(element_forces)
        forces = element_forces{load_case_index};
    else
        forces = element_forces;
    end
    
    % Nejprve vykreslíme konstrukci slabě
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        x1 = nodes(n1, 2); y1 = nodes(n1, 3);
        x2 = nodes(n2, 2); y2 = nodes(n2, 3);
        
        % Vykreslení prvků šedou čárkovanou čarou
        plot([x1, x2], [y1, y2], '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    end
    
    % Najít maximální absolutní hodnotu pro normalizaci
    max_value = 0;
    for i = 1:size(elements, 1)
        force_start = forces(i, indices(1));
        force_end = forces(i, indices(2));
        max_value = max([max_value, abs(force_start), abs(force_end)]);
    end
    
    % Nastavíme měřítko (pro lepší viditelnost)
    scale = 0.2;
    if max_value ~= 0
        scale = scale * max(max(abs(nodes(:, 2:3)))) / max_value;
    end
    
    % Počet segmentů pro každý prvek (diskretizace)
    num_segments = 20;  % Můžete zvýšit pro jemnější diskretizaci
    
    % Vykreslíme vnitřní síly pro každý prvek
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        x1 = nodes(n1, 2); y1 = nodes(n1, 3);
        x2 = nodes(n2, 2); y2 = nodes(n2, 3);
        
        % Získání hodnot vnitřních sil na koncích prvku
        force_start = forces(i, indices(1));
        force_end = forces(i, indices(2));
        
        % Směrový vektor prvku
        dx = x2 - x1;
        dy = y2 - y1;
        L = sqrt(dx^2 + dy^2);
        
        % Normálový vektor (kolmý na prvek)
        nx = -dy / L;
        ny = dx / L;
        
        % Vytvoříme body pro diskretizovaný prvek
        t = linspace(0, 1, num_segments + 1);
        x_points = x1 + t * dx;
        y_points = y1 + t * dy;
        
        % Lineární interpolace vnitřních sil v každém bodě diskretizace
        force_values = force_start + t * (force_end - force_start);
        
        % Vytvoříme offsetové body pro vykreslení
        x_offset = x_points + nx * force_values * scale;
        y_offset = y_points + ny * force_values * scale;
        
        % Vykreslíme polygon pro znázornění vnitřní síly
        % Spojíme body podél prvku s offsetovými body v opačném pořadí
        fill([x_points, fliplr(x_offset)], [y_points, fliplr(y_offset)], color, 'FaceAlpha', 0.5);
        
        % Vykreslíme čáru znázorňující průběh vnitřní síly
        plot(x_offset, y_offset, color, 'LineWidth', 1.5);
        
        % Přidáme hodnoty na koncích
        text(x_offset(1) + 0.1, y_offset(1) + 0.1, sprintf('%.1f', force_values(1)), 'Color', color);
        text(x_offset(end) + 0.1, y_offset(end) + 0.1, sprintf('%.1f', force_values(end)), 'Color', color);
        
        % Pro ohybový moment přidáme hodnotu ve středu, pokud se liší od koncových hodnot
        if upper(force_type) == 'M'
            mid_idx = ceil((num_segments + 1) / 2);
            mid_value = force_values(mid_idx);
            % Pokud se střední hodnota výrazně liší od koncových
            if abs(mid_value - force_values(1)) > 0.1*abs(max(force_values)) && ...
               abs(mid_value - force_values(end)) > 0.1*abs(max(force_values))
                text(x_offset(mid_idx) + 0.1, y_offset(mid_idx) + 0.1, sprintf('%.1f', mid_value), 'Color', color);
            end
        end
        
        % Přidáme šipky pro znázornění směru vnitřní síly
        if upper(force_type) ~= 'M'
            % Vykreslíme šipky ve středu prvku
            xmid = (x1 + x2) / 2;
            ymid = (y1 + y2) / 2;
            
            % Směr šipky závisí na znaménku střední hodnoty síly
            mid_value = force_values(ceil((num_segments + 1) / 2));
            if abs(mid_value) > 1e-6  % Pokud není síla téměř nulová
                arrow_scale = 0.1;
                if upper(force_type) == 'N'
                    % Pro normálovou sílu ve směru prvku
                    quiver(xmid, ymid, sign(mid_value) * dx/L * arrow_scale, sign(mid_value) * dy/L * arrow_scale, 'Color', color, 'LineWidth', 1.5, 'MaxHeadSize', 1);
                else  % 'V'
                    % Pro posouvající sílu kolmo na prvek
                    quiver(xmid, ymid, sign(mid_value) * nx * arrow_scale, sign(mid_value) * ny * arrow_scale, 'Color', color, 'LineWidth', 1.5, 'MaxHeadSize', 1);
                end
            end
        end
    end
    
    % Nastavení grafu
    xlabel('x [m]');
    ylabel('y [m]');
    title(title_text);
    
    % Přidání legendy
    h_structure = plot(NaN, NaN, '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    h_force = fill([NaN, NaN, NaN, NaN], [NaN, NaN, NaN, NaN], color, 'FaceAlpha', 0.5);
    
    legend([h_structure, h_force], {'Konstrukce', title_text});
end