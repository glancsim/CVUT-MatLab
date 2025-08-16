function plot_internal_forces(nodes, elements, displacements, loadcase_index, num_segments)
    % Funkce pro vykreslení průběhů vnitřních sil po délce prvků
    % Vstup:
    %   nodes - matice uzlů [node_id, x, y]
    %   elements - matice prvků [elem_id, node1, node2, E, A, I]
    %   displacements - buňkové pole posunů z frame2D_FEM
    %   loadcase_index - index zatěžovacího stavu
    %   num_segments - počet segmentů na každém prvku pro vykreslení (default 10)
    
    if nargin < 5
        num_segments = 10;
    end
    
    % Vytvoření figure se třemi subploty
    figure('Name', sprintf('Průběhy vnitřních sil - Zatěžovací stav %d', loadcase_index), 'Position', [100, 100, 900, 600]);
    
    % Získání posunů pro daný zatěžovací stav
    U = displacements{loadcase_index};
    
    % Inicializace matic pro uložení výsledků
    all_x_coords = cell(size(elements, 1), 1);
    all_y_coords = cell(size(elements, 1), 1);
    all_normal_forces = cell(size(elements, 1), 1);
    all_shear_forces = cell(size(elements, 1), 1);
    all_moments = cell(size(elements, 1), 1);
    
    % Výpočet vnitřních sil pro každý prvek
    for i = 1:size(elements, 1)
        % Extrakce vlastností prvku
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
        
        % Inicializace polí pro souřadnice a vnitřní síly
        x_coords = zeros(num_segments + 1, 1);
        y_coords = zeros(num_segments + 1, 1);
        normal_forces = zeros(num_segments + 1, 1);
        shear_forces = zeros(num_segments + 1, 1);
        moments = zeros(num_segments + 1, 1);
        
        % Pro každý segment vypočítáme vnitřní síly
        for j = 0:num_segments
            % Pozice v lokálních souřadnicích (xi jde od 0 do L)
            xi = j * L / num_segments;
            
            % Hodnota normálové síly v daném místě (konstantní po délce prvku)
            % N(x) = E*A*du/dx
            axial_strain = (u_local(4) - u_local(1)) / L;
            N = E * A * axial_strain;
            
            % Tvarové funkce pro průhyb nosníku
            N1 = 1 - 3*(xi/L)^2 + 2*(xi/L)^3;
            N2 = xi*(1 - xi/L)^2;
            N3 = 3*(xi/L)^2 - 2*(xi/L)^3;
            N4 = (xi^2/L)*(xi/L - 1);
            
            % Derivace tvarových funkcí
            dN1_dx = (-6/L^2)*(xi/L) + (6/L^3)*xi^2;
            dN2_dx = (1/L)*((1 - xi/L)^2) + (xi/L)*(-2/L)*(1 - xi/L);
            dN3_dx = (6/L^2)*(xi/L) - (6/L^3)*xi^2;
            dN4_dx = (1/L^2)*(2*xi - 3*xi^2/L);
            
            % Druhé derivace tvarových funkcí
            d2N1_dx2 = (-6/L^3) + (12/L^4)*xi;
            d2N2_dx2 = (-4/L^2) + (6/L^3)*xi;
            d2N3_dx2 = (6/L^3) - (12/L^4)*xi;
            d2N4_dx2 = (2/L^3) - (6/L^4)*xi;
            
            % Posouvající síla V(x) = -E*I*d³w/dx³
            % Pro nosník s kubickou interpolací je druhá derivace lineární
            % a třetí derivace konstantní mezi uzly
            V = -E * I * (d2N1_dx2 * u_local(2) + d2N2_dx2 * u_local(3) +... 
                          d2N3_dx2 * u_local(5) + d2N4_dx2 * u_local(6));
            
            % Ohybový moment M(x) = E*I*d²w/dx²
            M = E * I * (d2N1_dx2 * u_local(2) + d2N2_dx2 * u_local(3) +... 
                         d2N3_dx2 * u_local(5) + d2N4_dx2 * u_local(6));
            
            % Výpočet souřadnic v globálním systému
            x_coords(j+1) = x1 + xi * c;
            y_coords(j+1) = y1 + xi * s;
            
            % Uložení vnitřních sil
            normal_forces(j+1) = N;
            shear_forces(j+1) = V;
            moments(j+1) = M;
        end
        
        % Uložení výsledků pro daný prvek
        all_x_coords{i} = x_coords;
        all_y_coords{i} = y_coords;
        all_normal_forces{i} = normal_forces;
        all_shear_forces{i} = shear_forces;
        all_moments{i} = moments;
    end
    
    % Vykreslení nedeformované konstrukce pro referenci
    subplot(3, 1, 1);
    hold on;
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        plot([nodes(n1, 2), nodes(n2, 2)], [nodes(n1, 3), nodes(n2, 3)], 'k--', 'LineWidth', 1);
    end
    
    % Vykreslení průběhu normálových sil
    colors = lines(size(elements, 1));
    max_N = max(cellfun(@(x) max(abs(x)), all_normal_forces));
    scale_N = 0.2 * max(max(nodes(:,2)), max(nodes(:,3))) / max_N;
    
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        x1 = nodes(n1, 2); y1 = nodes(n1, 3);
        x2 = nodes(n2, 2); y2 = nodes(n2, 3);
        
        % Výpočet normály k prvku
        dx = x2 - x1;
        dy = y2 - y1;
        L = sqrt(dx^2 + dy^2);
        nx = -dy / L;
        ny = dx / L;
        
        % Vykreslení průběhu normálové síly
        x_plot = all_x_coords{i} + nx * all_normal_forces{i} * scale_N;
        y_plot = all_y_coords{i} + ny * all_normal_forces{i} * scale_N;
        
        plot(x_plot, y_plot, 'Color', colors(i,:), 'LineWidth', 2);
        
        % Vyplnění oblasti mezi průběhem a osou prvku
        x_fill = [all_x_coords{i}; flipud(x_plot)];
        y_fill = [all_y_coords{i}; flipud(y_plot)];
        fill(x_fill, y_fill, colors(i,:), 'FaceAlpha', 0.3);
    end
    
    title('Průběh normálových sil N [N]');
    xlabel('x [m]');
    ylabel('y [m]');
    axis equal;
    grid on;
    
    % Vykreslení průběhu posouvajících sil
    subplot(3, 1, 2);
    hold on;
    
    % Opět nedeformovaná konstrukce pro referenci
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        plot([nodes(n1, 2), nodes(n2, 2)], [nodes(n1, 3), nodes(n2, 3)], 'k--', 'LineWidth', 1);
    end
    
    max_V = max(cellfun(@(x) max(abs(x)), all_shear_forces));
    scale_V = 0.2 * max(max(nodes(:,2)), max(nodes(:,3))) / max_V;
    
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        x1 = nodes(n1, 2); y1 = nodes(n1, 3);
        x2 = nodes(n2, 2); y2 = nodes(n2, 3);
        
        % Výpočet normály k prvku
        dx = x2 - x1;
        dy = y2 - y1;
        L = sqrt(dx^2 + dy^2);
        nx = -dy / L;
        ny = dx / L;
        
        % Vykreslení průběhu posouvající síly
        x_plot = all_x_coords{i} + nx * all_shear_forces{i} * scale_V;
        y_plot = all_y_coords{i} + ny * all_shear_forces{i} * scale_V;
        
        plot(x_plot, y_plot, 'Color', colors(i,:), 'LineWidth', 2);
        
        % Vyplnění oblasti mezi průběhem a osou prvku
        x_fill = [all_x_coords{i}; flipud(x_plot)];
        y_fill = [all_y_coords{i}; flipud(y_plot)];
        fill(x_fill, y_fill, colors(i,:), 'FaceAlpha', 0.3);
    end
    
    title('Průběh posouvajících sil V [N]');
    xlabel('x [m]');
    ylabel('y [m]');
    axis equal;
    grid on;
    
    % Vykreslení průběhu ohybových momentů
    subplot(3, 1, 3);
    hold on;
    
    % Opět nedeformovaná konstrukce pro referenci
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        plot([nodes(n1, 2), nodes(n2, 2)], [nodes(n1, 3), nodes(n2, 3)], 'k--', 'LineWidth', 1);
    end
    
    max_M = max(cellfun(@(x) max(abs(x)), all_moments));
    scale_M = 0.2 * max(max(nodes(:,2)), max(nodes(:,3))) / max_M;
    
    for i = 1:size(elements, 1)
        n1 = elements(i, 2);
        n2 = elements(i, 3);
        x1 = nodes(n1, 2); y1 = nodes(n1, 3);
        x2 = nodes(n2, 2); y2 = nodes(n2, 3);
        
        % Výpočet normály k prvku
        dx = x2 - x1;
        dy = y2 - y1;
        L = sqrt(dx^2 + dy^2);
        nx = -dy / L;
        ny = dx / L;
        
        % Vykreslení průběhu ohybového momentu
        x_plot = all_x_coords{i} + nx * all_moments{i} * scale_M;
        y_plot = all_y_coords{i} + ny * all_moments{i} * scale_M;
        
        plot(x_plot, y_plot, 'Color', colors(i,:), 'LineWidth', 2);
        
        % Vyplnění oblasti mezi průběhem a osou prvku
        x_fill = [all_x_coords{i}; flipud(x_plot)];
        y_fill = [all_y_coords{i}; flipud(y_plot)];
        fill(x_fill, y_fill, colors(i,:), 'FaceAlpha', 0.3);
    end
    
    title('Průběh ohybových momentů M [Nm]');
    xlabel('x [m]');
    ylabel('y [m]');
    axis equal;
    grid on;
    
    % Přidání legendy
    legend_entries = cell(size(elements, 1), 1);
    for i = 1:size(elements, 1)
        legend_entries{i} = sprintf('Prvek %d', elements(i, 1));
    end
    legend(legend_entries, 'Location', 'best');
end