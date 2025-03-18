function plotStructure(nodes, elements, constraints, loads)
    % Funkce pro vykreslení konstrukce, zatížení a podpor
    % Vstup:
    %   nodes: [node_id, x, y] - Souřadnice uzlů
    %   elements: [elem_id, node1, node2, E, A, I] - Vlastnosti prvků
    %   constraints: [node_id, ux, uy, theta] - Okrajové podmínky
    %   loads: [node_id, Fx, Fy, M] - Aplikovaná zatížení
    
    % Použijeme aktuální osu místo vytváření nového grafu
    hold on;
    grid on;
    axis equal;
    
    % Vykreslení prvků (nosníků a sloupů)
    for i = 1:size(elements,1)
        n1 = elements(i,2);
        n2 = elements(i,3);
        x1 = nodes(n1,2); y1 = nodes(n1,3);
        x2 = nodes(n2,2); y2 = nodes(n2,3);
        
        % Vykreslení prvků modrou barvou s větší tloušťkou
        plot([x1, x2], [y1, y2], 'b-', 'LineWidth', 2);
    end
    
    % Vykreslení uzlů
    for i = 1:size(nodes,1)
        x = nodes(i,2);
        y = nodes(i,3);
        node_id = nodes(i,1);
        
        % Vykreslení uzlů jako černých kroužků
        plot(x, y, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6);
        
        % Popisky uzlů
        text(x+0.1, y+0.1, num2str(node_id), 'FontSize', 10);
    end
    
    % Vykreslení podpor
    for i = 1:size(constraints,1)
        node = constraints(i,1);
        x = nodes(node,2);
        y = nodes(node,3);
        
        % Pevná podpora (vetknutí) - KOSTIČKA
        if constraints(i,2) == 1 && constraints(i,3) == 1 && constraints(i,4) == 1
            % Vykreslení kostičky pro znázornění vetknutí
            rectangle('Position', [x-0.3, y-0.3, 0.6, 0.3], 'FaceColor', [0.7 0.7 0.7]);
        
        % Kloubová podpora - TROJÚHELNÍK
        elseif constraints(i,2) == 1 && constraints(i,3) == 1 && constraints(i,4) == 0
            % Vykreslení trojúhelníku
            triangle_x = [x-0.3, x+0.3, x, x-0.3];
            triangle_y = [y-0.3, y-0.3, y, y-0.3];
            fill(triangle_x, triangle_y, [0.7 0.7 0.7], 'EdgeColor', 'k');
        
        % Posuvná podpora - TROJÚHELNÍK S ČÁRKOU
        elseif constraints(i,2) == 0 && constraints(i,3) == 1 && constraints(i,4) == 0
            % Vykreslení trojúhelníku
            triangle_x = [x-0.3, x+0.3, x, x-0.3];
            triangle_y = [y-0.3, y-0.3, y, y-0.3];
            fill(triangle_x, triangle_y, [0.7 0.7 0.7], 'EdgeColor', 'k');
            
            % Přidání čárky pod trojúhelníkem
            line([x-0.4, x+0.4], [y-0.4, y-0.4], 'Color', 'k', 'LineWidth', 1.5);
            
            % Přidání malých koleček pro znázornění možnosti pohybu
            plot([x-0.2, x, x+0.2], [y-0.4, y-0.4, y-0.4], 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 3);
        
        % Podpora ve směru X (valivá ve směru Y)
        elseif constraints(i,2) == 1 && constraints(i,3) == 0 && constraints(i,4) == 0
            % Toto je rotovaná verze posuvné podpory
            % Vykreslení trojúhelníku (rotovaného)
            triangle_x = [x-0.3, x-0.3, x, x-0.3];
            triangle_y = [y-0.3, y+0.3, y, y-0.3];
            fill(triangle_x, triangle_y, [0.7 0.7 0.7], 'EdgeColor', 'k');
            
            % Přidání čárky vedle trojúhelníku
            line([x-0.4, x-0.4], [y-0.4, y+0.4], 'Color', 'k', 'LineWidth', 1.5);
            
            % Přidání malých koleček pro znázornění možnosti pohybu
            plot([x-0.4, x-0.4, x-0.4], [y-0.2, y, y+0.2], 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 3);
        end
    end
    
    % Vykreslení zatížení
    scale_factor = 0.5;  % Měřítko pro šipky zatížení
    max_load = max(max(abs([loads(:,2), loads(:,3)])));
    if max_load == 0
        max_load = 1;
    end
    
    for i = 1:size(loads,1)
        node = loads(i,1);
        x = nodes(node,2);
        y = nodes(node,3);
        Fx = loads(i,2);
        Fy = loads(i,3);
        M = loads(i,4);
        
        % Vykreslení silových zatížení - horizontální síla
        if Fx ~= 0
            Fx_scaled = scale_factor * Fx / max_load * 2;
            quiver(x, y, Fx_scaled, 0, 'r-', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
            text(x + Fx_scaled/2, y + 0.2, sprintf('%.1f N', Fx), 'Color', 'r');
        end
        
        % Vykreslení silových zatížení - vertikální síla
        if Fy ~= 0
            Fy_scaled = scale_factor * Fy / max_load * 2;
            quiver(x, y, 0, Fy_scaled, 'r-', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
            text(x + 0.2, y + Fy_scaled/2, sprintf('%.1f N', Fy), 'Color', 'r');
        end
        
        % Vykreslení momentového zatížení - VYLEPŠENÁ VERZE
        if M ~= 0
            radius = 0.3;
            % Určení směru momentu (kladný ve směru hodinových ručiček)
            if M > 0
                % Oblouk pro kladný moment (po směru hodinových ručiček)
                theta = linspace(-pi/2, pi, 30);
                arrow_end = pi;
            else
                % Oblouk pro záporný moment (proti směru hodinových ručiček)
                theta = linspace(0, 3*pi/2, 30);
                arrow_end = 3*pi/2;
            end
            
            % Vykreslení oblouku
            arc_x = x + radius * cos(theta);
            arc_y = y + radius * sin(theta);
            plot(arc_x, arc_y, 'r-', 'LineWidth', 1.5);
            
            % Přidání šipky na konec oblouku
            arrow_x = x + radius * cos(arrow_end);
            arrow_y = y + radius * sin(arrow_end);
            
            % Vytvoření šipky v závislosti na směru momentu
            if M > 0
                arrow_dx1 = -0.1;
                arrow_dy1 = -0.1;
                arrow_dx2 = 0.1;
                arrow_dy2 = -0.1;
            else
                arrow_dx1 = -0.1;
                arrow_dy1 = 0.1;
                arrow_dx2 = -0.1;
                arrow_dy2 = -0.1;
            end
            
            % Vykreslení šipky
            plot([arrow_x, arrow_x + arrow_dx1], [arrow_y, arrow_y + arrow_dy1], 'r-', 'LineWidth', 1.5);
            plot([arrow_x, arrow_x + arrow_dx2], [arrow_y, arrow_y + arrow_dy2], 'r-', 'LineWidth', 1.5);
            
            % Popisek momentu
            text(x, y + radius + 0.2, sprintf('%.1f Nm', M), 'Color', 'r');
        end
    end
    
    % Nastavení grafu
    xlabel('x [m]');
    ylabel('y [m]');
    
    % Vylepšení legendy
    h_elements = plot(NaN, NaN, 'b-', 'LineWidth', 2);
    h_nodes = plot(NaN, NaN, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6);
    h_forces = plot(NaN, NaN, 'r-', 'LineWidth', 1.5);
    
    legend([h_elements, h_nodes, h_forces], {'Prvky', 'Uzly', 'Zatížení'});
    % hold off;
end