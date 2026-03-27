%% example_section_rotation.m
% ==========================================================================
%  EXAMPLE — Ověření rotace průřezu (beams.angles)
% ==========================================================================
%
% Konzola podél osy X, obdélníkový průřez (b × h, b ≠ h).
% Síla F v globálním -Z směru na volném konci.
%
%   beams.angles rotuje průřez kolem lokální osy X (osy prutu).
%
%   angle = 0°:
%     lokální y = globální Y,  lokální z = globální Z
%     → síla F_global_z = síla v lokálním z směru
%     → ohyb okolo lokální osy y → využívá Iy
%     → δ_z = F·L³ / (3·E·Iy)
%
%   angle = 90°:
%     lokální y = globální Z,  lokální z = globální −Y
%     → síla F_global_z = síla v lokálním y směru
%     → ohyb okolo lokální osy z → využívá Iz
%     → δ_z = F·L³ / (3·E·Iz)
%
%   angle = 45°:
%     síla se rozkládá do obou lokálních směrů → průhyb v globálním Y i Z
%
%          F (−Z)
%          ↓
%   [===]========================[ ]
%   uzel 1                       uzel 2
%   <----------  L = 2 m  ------->
%
% ==========================================================================

clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% PRŮŘEZ — obdélník b × h
% --------------------------------------------------------------------------
b = 0.04;   % [m]  šířka (rozměr v rovině lokálního y pro angle=0)
h = 0.10;   % [m]  výška (rozměr v rovině lokálního z pro angle=0)

sections.A  = b * h;
sections.Iy = b * h^3 / 12;   % silná osa (pro angle=0: odolává ohybu v glob. Z)
sections.Iz = h * b^3 / 12;   % slabá osa (pro angle=0: odolává ohybu v glob. Y)
sections.Ix = sections.Iy + sections.Iz;  % St. Venant (obdélník: přibližně)
sections.E  = 210e9;
sections.v  = 0.3;

fprintf('Průřez: b = %.0f mm,  h = %.0f mm\n', b*1e3, h*1e3);
fprintf('  Iy = %.4e m^4  (silná osa)\n', sections.Iy);
fprintf('  Iz = %.4e m^4  (slabá osa)\n', sections.Iz);
fprintf('  Poměr Iy/Iz = %.2f\n\n', sections.Iy / sections.Iz);

%% GEOMETRIE — konzola podél osy X
% --------------------------------------------------------------------------
L = 2.0;   % [m]

nodes.x = [0; L];
nodes.y = [0; 0];
nodes.z = [0; 0];

%% OKRAJOVÉ PODMÍNKY — vetknutí v uzlu 1
% --------------------------------------------------------------------------
kinematic.x.nodes  = [1];
kinematic.y.nodes  = [1];
kinematic.z.nodes  = [1];
kinematic.rx.nodes = [1];
kinematic.ry.nodes = [1];
kinematic.rz.nodes = [1];

%% ZATÍŽENÍ — síla F v globálním −Z na volném konci (uzel 2)
% --------------------------------------------------------------------------
F = -1000;   % [N]  záporné = −Z směr

loads.x.nodes  = [];   loads.x.value  = [];
loads.y.nodes  = [];   loads.y.value  = [];
loads.z.nodes  = [2];  loads.z.value  = [F];
loads.rx.nodes = [];   loads.rx.value = [];
loads.ry.nodes = [];   loads.ry.value = [];
loads.rz.nodes = [];   loads.rz.value = [];

ndisc = 10;

%% ANALYTICKÉ REFERENCE
% --------------------------------------------------------------------------
%   angle = 0°:  δ_z = F·L³ / (3·E·Iy),  δ_y = 0
%   angle = 90°: δ_z = F·L³ / (3·E·Iz),  δ_y = 0
% --------------------------------------------------------------------------
delta_exact_0  = F * L^3 / (3 * sections.E * sections.Iy);
delta_exact_90 = F * L^3 / (3 * sections.E * sections.Iz);

%% FEM — tři úhly natočení průřezu
% --------------------------------------------------------------------------
angles_deg = [0, 45, 90];
results = struct();

for k = 1:3
    alpha = angles_deg(k);

    beams.nodesHead = [1];
    beams.nodesEnd  = [2];
    beams.sections  = [1];
    beams.angles    = [alpha];

    [disp, ~] = linearSolverFn(sections, nodes, ndisc, kinematic, beams, loads);

    % Uzel 1: všechny DOFy vetknuty (0 volných DOFů)
    % Uzel 2: 6 volných DOFů → [ux, uy, uz, rx, ry, rz] = kódová čísla 1–6
    d = full(disp.global);
    results(k).angle = alpha;
    results(k).uy    = d(2);   % průhyb v globálním Y
    results(k).uz    = d(3);   % průhyb v globálním Z
end

%% VÝSTUP
% --------------------------------------------------------------------------
fprintf('=== Ověření rotace průřezu — konzola, F = %.0f N v −Z ===\n\n', abs(F));
fprintf('  %-10s  %-14s  %-14s  %-14s  %-10s\n', ...
    'Úhel [°]', 'δ_z FEM [mm]', 'δ_z exact [mm]', 'δ_y FEM [mm]', 'Chyba δ_z [%]');
fprintf('  %s\n', repmat('-', 1, 70));

for k = 1:3
    r = results(k);

    if r.angle == 0
        ref = delta_exact_0;
        err = abs(r.uz - ref) / abs(ref) * 100;
        fprintf('  %-10d  %-14.4f  %-14.4f  %-14.4f  %-10.4f\n', ...
            r.angle, r.uz*1e3, ref*1e3, r.uy*1e3, err);

    elseif r.angle == 90
        ref = delta_exact_90;
        err = abs(r.uz - ref) / abs(ref) * 100;
        fprintf('  %-10d  %-14.4f  %-14.4f  %-14.4f  %-10.4f\n', ...
            r.angle, r.uz*1e3, ref*1e3, r.uy*1e3, err);

    else
        fprintf('  %-10d  %-14.4f  %-14s  %-14.4f  %-10s\n', ...
            r.angle, r.uz*1e3, '(viz níže)', r.uy*1e3, '—');
    end
end

fprintf('\n');
fprintf('  angle=0°:  δ_z silná osa → δ = F·L³/(3·E·Iy) = %.4f mm\n', delta_exact_0*1e3);
fprintf('  angle=90°: δ_z slabá osa → δ = F·L³/(3·E·Iz) = %.4f mm\n', delta_exact_90*1e3);
fprintf('  Poměr průhybů (90°/0°) = Iy/Iz = %.2f\n', delta_exact_90/delta_exact_0);
fprintf('\n');
fprintf('  angle=45°: síla se rozkládá do obou lokálních os\n');
fprintf('    δ_y = %.4f mm (≠ 0 → průhyb v obou rovinách)\n', results(2).uy*1e3);
fprintf('    δ_z = %.4f mm\n', results(2).uz*1e3);

%% VIZUALIZACE
% --------------------------------------------------------------------------
figure('Name', 'Rotace průřezu — průhyb v závislosti na úhlu', ...
    'Position', [100 100 700 420]);

alpha_sweep = 0:5:90;
uz_sweep = zeros(size(alpha_sweep));
uy_sweep = zeros(size(alpha_sweep));

for k = 1:numel(alpha_sweep)
    beams.nodesHead = [1];
    beams.nodesEnd  = [2];
    beams.sections  = [1];
    beams.angles    = [alpha_sweep(k)];
    [disp_k, ~] = linearSolverFn(sections, nodes, ndisc, kinematic, beams, loads);
    d = full(disp_k.global);
    uz_sweep(k) = d(3);
    uy_sweep(k) = d(2);
end

plot(alpha_sweep, abs(uz_sweep)*1e3, 'b-o', 'LineWidth', 2, 'MarkerSize', 5); hold on;
plot(alpha_sweep, abs(uy_sweep)*1e3, 'r-s', 'LineWidth', 2, 'MarkerSize', 5);
yline(abs(delta_exact_0)*1e3,  'b--', 'F·L³/(3EIy)', 'LabelVerticalAlignment', 'bottom');
yline(abs(delta_exact_90)*1e3, 'r--', 'F·L³/(3EIz)', 'LabelVerticalAlignment', 'bottom');

xlabel('beams.angles  [°]');
ylabel('|průhyb|  [mm]');
title('Konzola — průhyb na volném konci vs. úhel natočení průřezu');
legend('|δ_z|', '|δ_y|', 'Location', 'northwest');
grid on;
xticks(0:15:90);
