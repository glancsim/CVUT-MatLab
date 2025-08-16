function plot_deformed_shape(nodes, elements, displacements, loadcase_index, scale_factor)
    % Funkce pro vykreslení deformovaného tvaru konstrukce
    % Vstup:
    %   nodes - matice uzlů [node_id, x, y]
    %   elements - matice prvků [elem_id, node1, node2, E, A, I]
    %   displacements - buňkové pole posunů z frame2D_FEM
    %   loadcase_index - index zatěžovacího stavu
    %   scale_factor - faktor zvětšení deformací (default: automaticky)
    
    % Získání posunů pro daný zatěžovací stav
    U = displacements{loadcase_index};
    
    % Pokud není zadán scale_factor, automaticky jej vypočítáme
    if nargin < 5 || isempty(scale_factor)
        % Najdeme maximální posunutí
        max_disp = max(max(abs(U(:, 1:2))));
        % Najdeme maximální rozměr konstrukce
        max_dim = max([max(nodes(:, 2)) - min(nodes(:, 2)), max(nodes(:, 3)) - min(nodes(:, 3))]);
        % Nastavíme scale_factor tak, aby maximální posunutí bylo 20% maximálního rozměru
        if max_disp > 0
            scale_factor = 0.2 * max_dim / max_disp;
        else
            scale_factor = 1;
        end
    end
    
    % Vytvoření figure
    figure('Name', sprintf('Deformovaný tvar - Zatěžovací stav %d', loadcase_index));
    hold on;
    
    % Vykreslení nedeformované konstrukce
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        x1 = nodes(n1, 2); y1 = nodes(n1, 3);
        x2 = nodes(n2, 2); y2 = nodes(n2, 3);
        
        plot([x1, x2], [y1, y2], 'k--', 'LineWidth', 1);
    end
    
    % Vykreslení deformované konstrukce pomocí segmentů pro hladší křivky
    num_segments = 10;  % Počet segmentů na prvek
    
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        E = elements(i, 4);
        A = elements(i, 5);
        I = elements(i, 6);
        
        % Souřadnice uzlů prvku
        x1 = nodes(n1, 2); y1 = nodes(n1, 3);
        x2 = nodes(n2, 2); y2 = nodes(n2, 3);
        
        % Výpočet délky a orientace prvku
        L = sqrt((x2-x1)^2 + (y2-y1)^2);
        c = (x2-x1)/L;  % cos(theta)
        s = (y2-y1)/L;  % sin(theta)
        
        % Vytvoření transformační matice
        T = [
            c  s  0  0  0  0;
           -s  c  0  0  0  0;
            0  0  1  0  0  0;
            0  0  0  c  s  0;
            0  0  0 -s  c  0;
            0  0  0  0  0  1
        ];
        
        % Získání posunů koncových uzlů v globálních souřadnicích
        u_global = [U(n1, 1); U(n1, 2); U(n1, 3); U(n2, 1); U(n2, 2); U(n2, 3)];
        
        % Transformace posunů do lokálních souřadnic
        u_local = T * u_global;
        
        % Inicializace polí pro deformované souřadnice
        x_deformed = zeros(num_segments + 1, 1);
        y_deformed = zeros(num_segments + 1, 1);
        
        % Pro každý segment vypočítáme pozici na deformovaném prvku
        for j = 0:num_segments
            % Pozice v lokálních souřadnicích (xi jde od 0 do L)
            xi = j * L / num_segments;
            
            % Tvarové funkce pro osové deformace
            N1_axial = 1 - xi/L;
            N2_axial = xi/L;
            
            % Tvarové funkce pro průhyb nosníku
            N1 = 1 - 3*(xi/L)^2 + 2*(xi/L)^3;
            N2 = xi*(1 - xi/L)^2;
            N3 = 3*(xi/L)^2 - 2*(xi/L)^3;
            N4 = (xi^2/L)*(xi/L - 1);
            
            % Výpočet deformací v lokálních souřadnicích
            u_x = N1_axial * u_local(1) + N2_axial * u_local(4);
            u_y = N1 * u_local(2) + N2 * u_local(3) + N3 * u_local(5) + N4 * u_local(6);
            
            % Transformace zpět do globálních souřadnic
            u_global_x = c * u_x - s * u_y;
            u_global_y = s * u_x + c * u_y;
            
            % Výpočet pozice na deformovaném prvku
            x_undeformed = x1 + xi * c;
            y_undeformed = y1 + xi * s;
            
            x_deformed(j+1) = x_undeformed + scale_factor * u_global_x;
            y_deformed(j+1) = y_undeformed + scale_factor * u_global_y;
        end
        
        % Vykreslení deformovaného prvku
        plot(x_deformed, y_deformed, 'r-', 'LineWidth', 2);
    end
    
    % Vykreslení uzlů v deformované poloze
    for i = 1:size(nodes, 1)
        x = nodes(i, 2) + scale_factor * U(i, 1);
        y = nodes(i, 3) + scale_factor * U(i, 2);
        plot(x, y, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
    end
    
    % Přidání popisků a legendy
    title(sprintf('Deformovaný tvar konstrukce (měřítko deformací: %.1fx)', scale_factor));
    xlabel('x [m]');
    ylabel('y [m]');
    legend('Nedeformovaný tvar', 'Deformovaný tvar', 'Uzly', 'Location', 'best');
    axis equal;
    grid on;
end