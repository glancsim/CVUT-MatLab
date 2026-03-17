function plotStructureFn(nodes, beams, loads, kinematic)
% PLOTSTRUCTUREFN  3D vizualizace konstrukce, podpor a zatížení.
%
%   plotStructureFn(nodes, beams, loads)
%   plotStructureFn(nodes, beams, loads, kinematic)
%
%   Vstupy:
%     nodes     - struktura: x, y, z (souřadnice uzlů, [n×1])
%     beams     - struktura: nodesHead, nodesEnd ([nbeams×1] indexy uzlů)
%     loads     - struktura: x/y/z.nodes, x/y/z.value (síly [N])
%                            rx/ry/rz.nodes, rx/ry/rz.value (momenty [N·m])
%     kinematic - (volitelné) struktura: x/y/z/rx/ry/rz.nodes (podpory)
%
%   Barevný kód:
%     Černá           — pruty a uzly
%     Modrá  šipka    — podpora (omezený posun), šipka míří K uzlu
%     Zelená šipka    — podpora (omezené pootočení), šipka míří K uzlu
%     Červená šipka   — silové zatížení, šipka vychází Z uzlu + popisek [N]
%     Fialová 2× šipka— momentové zatížení (dvě paralelní) + popisek [N·m]

figure; hold on;

% --- Charakteristický rozměr ---
L_char    = max([range(nodes.x); range(nodes.y); range(nodes.z); 1]);
arrow_len = 0.15 * L_char;
eps_off   = 0.02 * L_char;
margin    = 0.15 * L_char;

uvecs = {[1 0 0], [0 1 0], [0 0 1]};

% =========================================================
%  PRUTY A UZLY
% =========================================================
h_beams = plot3([nodes.x(beams.nodesHead) nodes.x(beams.nodesEnd)]', ...
                [nodes.y(beams.nodesHead) nodes.y(beams.nodesEnd)]', ...
                [nodes.z(beams.nodesHead) nodes.z(beams.nodesEnd)]', ...
                'k', 'LineWidth', 1.5);

h_nodes = scatter3(nodes.x, nodes.y, nodes.z, 40, 'k', 'filled');

% =========================================================
%  PODPORY (kinematic)
% =========================================================
h_sup_t = []; h_sup_r = [];

if nargin >= 4 && ~isempty(kinematic)

    % Omezené posuny — modrá, šipka od offsetu K uzlu
    dirs_t = {'x', 'y', 'z'};
    for d = 1:3
        nds = kinematic.(dirs_t{d}).nodes;
        if isempty(nds), continue; end
        u  = uvecs{d};
        xn = nodes.x(nds); yn = nodes.y(nds); zn = nodes.z(nds);
        hh = quiver3(xn - u(1)*arrow_len, yn - u(2)*arrow_len, zn - u(3)*arrow_len, ...
                     repmat(u(1)*arrow_len, size(nds)), ...
                     repmat(u(2)*arrow_len, size(nds)), ...
                     repmat(u(3)*arrow_len, size(nds)), ...
                     0, 'b', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
        if isempty(h_sup_t), h_sup_t = hh; end
    end

    % Omezená pootočení — zelená, šipka ve směru osy K uzlu
    dirs_r = {'rx', 'ry', 'rz'};
    for d = 1:3
        nds = kinematic.(dirs_r{d}).nodes;
        if isempty(nds), continue; end
        u  = uvecs{d};
        xn = nodes.x(nds); yn = nodes.y(nds); zn = nodes.z(nds);
        hh = quiver3(xn - u(1)*arrow_len, yn - u(2)*arrow_len, zn - u(3)*arrow_len, ...
                     repmat(u(1)*arrow_len, size(nds)), ...
                     repmat(u(2)*arrow_len, size(nds)), ...
                     repmat(u(3)*arrow_len, size(nds)), ...
                     0, 'g', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
        if isempty(h_sup_r), h_sup_r = hh; end
    end

end

% =========================================================
%  ZATÍŽENÍ — SÍLY (červená, jednoduchá šipka Z uzlu)
% =========================================================
allF = [loads.x.value; loads.y.value; loads.z.value];
h_forces = [];
if ~isempty(allF) && max(abs(allF)) > 0
    scale_f = arrow_len / max(abs(allF));
    dirs_f  = {'x', 'y', 'z'};
    for d = 1:3
        nds = loads.(dirs_f{d}).nodes;
        if isempty(nds), continue; end
        val = loads.(dirs_f{d}).value;
        u   = uvecs{d};
        xn  = nodes.x(nds); yn = nodes.y(nds); zn = nodes.z(nds);
        hh  = quiver3(xn, yn, zn, ...
                      val * scale_f * u(1), ...
                      val * scale_f * u(2), ...
                      val * scale_f * u(3), ...
                      0, 'r', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
        if isempty(h_forces), h_forces = hh; end
        for k = 1:numel(nds)
            text(xn(k) + val(k)*scale_f*u(1), ...
                 yn(k) + val(k)*scale_f*u(2), ...
                 zn(k) + val(k)*scale_f*u(3), ...
                 sprintf('%.4g N', val(k)), 'Color', 'r', 'FontSize', 8);
        end
    end
end

% =========================================================
%  ZATÍŽENÍ — MOMENTY (fialová, dvojitá šipka = dvě paralelní)
% =========================================================
allM = [loads.rx.value; loads.ry.value; loads.rz.value];
h_moments = [];
perp = {[0 1 0], [0 0 1], [1 0 0]};   % perpendikula pro příčný offset dvojité šipky
if ~isempty(allM) && max(abs(allM)) > 0
    scale_m = arrow_len / max(abs(allM));
    dirs_m  = {'rx', 'ry', 'rz'};
    for d = 1:3
        nds = loads.(dirs_m{d}).nodes;
        if isempty(nds), continue; end
        val = loads.(dirs_m{d}).value;
        u   = uvecs{d};
        p   = perp{d};
        xn  = nodes.x(nds); yn = nodes.y(nds); zn = nodes.z(nds);
        for sgn = [-1 1]
            hh = quiver3(xn + sgn*eps_off*p(1), yn + sgn*eps_off*p(2), zn + sgn*eps_off*p(3), ...
                         val * scale_m * u(1), ...
                         val * scale_m * u(2), ...
                         val * scale_m * u(3), ...
                         0, 'm', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
            if isempty(h_moments), h_moments = hh; end
        end
        for k = 1:numel(nds)
            text(xn(k) + val(k)*scale_m*u(1), ...
                 yn(k) + val(k)*scale_m*u(2), ...
                 zn(k) + val(k)*scale_m*u(3), ...
                 sprintf('%.4g N·m', val(k)), 'Color', 'm', 'FontSize', 8);
        end
    end
end

% =========================================================
%  FORMÁTOVÁNÍ
% =========================================================
axis equal; grid on; view(3);
xlim([min(nodes.x) - margin, max(nodes.x) + margin]);
ylim([min(nodes.y) - margin, max(nodes.y) + margin]);
zlim([min(nodes.z) - margin, max(nodes.z) + margin]);
xlabel('x [m]'); ylabel('y [m]'); zlabel('z [m]');

% Legenda — jen existující prvky
leg_h = [h_beams(1), h_nodes];
leg_l = {'Pruty', 'Uzly'};
if ~isempty(h_sup_t),   leg_h(end+1) = h_sup_t;   leg_l{end+1} = 'Podpora – posun';     end
if ~isempty(h_sup_r),   leg_h(end+1) = h_sup_r;   leg_l{end+1} = 'Podpora – pootočení'; end
if ~isempty(h_forces),  leg_h(end+1) = h_forces;  leg_l{end+1} = 'Síla';                end
if ~isempty(h_moments), leg_h(end+1) = h_moments; leg_l{end+1} = 'Moment';              end
legend(leg_h, leg_l, 'Location', 'best');

end
