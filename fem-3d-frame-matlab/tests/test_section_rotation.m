%% test_section_rotation.m
% ==========================================================================
%  TEST — Rotace průřezu (beams.angles) + Torri benchmarks
% ==========================================================================
%
% ČÁST 1: Rotace průřezu
%   Konzola podél osy X, obdélníkový průřez (b × h, Iy ≠ Iz).
%   Síla F v globálním −Z na volném konci.
%   Reference: analytické Euler-Bernoulliho řešení  δ = F·L³ / (3·E·I)
%
%   beams.angles rotuje průřez kolem lokální osy X (osy prutu).
%
%   angle=0°   → δ_z = F·L³/(3·E·Iy),  δ_y = 0
%   angle=90°  → δ_z = F·L³/(3·E·Iz),  δ_y = 0
%   angle=45°  → δ_y ≠ 0  (síla se rozkládá do obou lokálních os)
%
% ČÁST 2: Torri benchmarks (literatura)
%   Ex1 — prostorový rám, trubkové průřezy, OOFEM verifikace
%   Ex2 — totéž s různými průřezy (bez tenkých prutů)
%
% Tolerance: 0.1 % (Torri) / 0.01 % (analytické)
% ==========================================================================

clear; clc;
srcDir = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
addpath(srcDir);

passed = 0;
failed = 0;

fprintf('\n');
fprintf('==========================================================================\n');
fprintf('  TEST — Rotace průřezu + Torri benchmarks\n');
fprintf('==========================================================================\n\n');

%% =========================================================================
%  ČÁST 1: ROTACE PRŮŘEZU
%% =========================================================================
tol_analytic = 0.01;   % [%]

b = 0.04; h = 0.10; L = 2.0; F = -1000; E = 210e9;

sections_r.A  = b * h;
sections_r.Iy = b * h^3 / 12;
sections_r.Iz = h * b^3 / 12;
sections_r.Ix = sections_r.Iy + sections_r.Iz;
sections_r.E  = E;
sections_r.v  = 0.3;

nodes_r.x = [0; L]; nodes_r.y = [0; 0]; nodes_r.z = [0; 0];
kinematic_r.x.nodes=[1]; kinematic_r.y.nodes=[1]; kinematic_r.z.nodes=[1];
kinematic_r.rx.nodes=[1]; kinematic_r.ry.nodes=[1]; kinematic_r.rz.nodes=[1];
loads_r.x.nodes=[]; loads_r.x.value=[]; loads_r.y.nodes=[]; loads_r.y.value=[];
loads_r.z.nodes=[2]; loads_r.z.value=[F];
loads_r.rx.nodes=[]; loads_r.rx.value=[]; loads_r.ry.nodes=[]; loads_r.ry.value=[];
loads_r.rz.nodes=[]; loads_r.rz.value=[];

delta_z_0  = F * L^3 / (3 * E * sections_r.Iy);
delta_z_90 = F * L^3 / (3 * E * sections_r.Iz);
delta_y_45_exact = F * L^3 / (6 * E) * (1/sections_r.Iz - 1/sections_r.Iy);

fprintf('--- Část 1: Rotace průřezu (b=%d mm, h=%d mm, L=%.1f m) ---\n\n', ...
    b*1e3, h*1e3, L);

% --- Test 1a: angle=0°, δ_z ---
beams_r.nodesHead=[1]; beams_r.nodesEnd=[2]; beams_r.sections=[1]; beams_r.angles=[0];
[d0,~] = linearSolverFn(sections_r, nodes_r, 10, kinematic_r, beams_r, loads_r);
d0 = full(d0.global);
[passed, failed] = check(d0(3), delta_z_0, tol_analytic, 'angle=0° δ_z vs. FL³/3EIy', passed, failed);

% --- Test 1b: angle=0°, δ_y = 0 ---
[passed, failed] = check(d0(2), 0, abs(delta_z_0)*tol_analytic/100, 'angle=0° δ_y = 0', passed, failed, true);

% --- Test 2a: angle=90°, δ_z ---
beams_r.angles = [90];
[d90,~] = linearSolverFn(sections_r, nodes_r, 10, kinematic_r, beams_r, loads_r);
d90 = full(d90.global);
[passed, failed] = check(d90(3), delta_z_90, tol_analytic, 'angle=90° δ_z vs. FL³/3EIz', passed, failed);

% --- Test 2b: angle=90°, δ_y = 0 ---
[passed, failed] = check(d90(2), 0, abs(delta_z_90)*tol_analytic/100, 'angle=90° δ_y = 0', passed, failed, true);

% --- Test 3: poměr δ_z(90°)/δ_z(0°) = Iy/Iz ---
ratio_fem   = d90(3) / d0(3);
ratio_exact = sections_r.Iy / sections_r.Iz;
[passed, failed] = check(ratio_fem, ratio_exact, tol_analytic, ...
    sprintf('poměr δ_z(90°)/δ_z(0°) = Iy/Iz = %.2f', ratio_exact), passed, failed);

% --- Test 4: angle=45°, δ_y analyticky ---
beams_r.angles = [45];
[d45,~] = linearSolverFn(sections_r, nodes_r, 10, kinematic_r, beams_r, loads_r);
d45 = full(d45.global);
[passed, failed] = check(d45(2), delta_y_45_exact, tol_analytic, ...
    'angle=45° δ_y analyticky', passed, failed);

%% =========================================================================
%  ČÁST 2: TORRI BENCHMARKS
%% =========================================================================
tol_torri = 0.1;   % [%]  —  tolerance pro benchmark z literatury

fprintf('\n--- Část 2: Torri benchmark Ex1 ---\n\n');

% Geometrie — sdílená pro oba příklady
nodes_t.x=[0;2;0;2;4]*2; nodes_t.y=[0;0;0;0;0]*2; nodes_t.z=[0;0;2;2;0]*2;
kinematic_t.x.nodes=[1;3]; kinematic_t.y.nodes=[1;3]; kinematic_t.z.nodes=[1;3];
kinematic_t.rx.nodes=[]; kinematic_t.ry.nodes=[]; kinematic_t.rz.nodes=[1;3];
loads_t.x.nodes=[]; loads_t.x.value=[]; loads_t.y.nodes=[]; loads_t.y.value=[];
loads_t.rx.nodes=[]; loads_t.rx.value=[]; loads_t.ry.nodes=[]; loads_t.ry.value=[];
loads_t.rz.nodes=[]; loads_t.rz.value=[];

% --- Ex1: trubkový průřez, všechny pruty stejné ---
r_o1 = 0.04; r_i1 = 0.035;
sec1.A  = pi*(r_o1^2-r_i1^2); sec1.Iy = pi/4*(r_o1^4-r_i1^4);
sec1.Iz = sec1.Iy; sec1.Ix = 2*sec1.Iy; sec1.E = 210e9; sec1.v = 0.3;

nodes_t1 = nodes_t;
nodes_t1.x = [0;2;0;2;4]; nodes_t1.y = [0;0;0;0;0]; nodes_t1.z = [0;0;2;2;2];
loads_t1 = loads_t; loads_t1.z.nodes=[5]; loads_t1.z.value=[-1000];

beams_t1.nodesHead=[1;3;4;3;2;2]; beams_t1.nodesEnd=[2;4;5;2;5;4];
beams_t1.sections=[1;1;1;1;1;1];  beams_t1.angles=[0;0;0;0;0;0];

R1 = stabilitySolverFn(sec1, nodes_t1, 16, kinematic_t, beams_t1, loads_t1, 'oofem');
posV1 = R1.values(R1.values > 0);

% Reference z Torri (verifikováno OOFEM, ndisc=16)
lambda1_ex1_ref = 83.2118;
lambda2_ex1_ref = 288.9075;

[passed, failed] = check(posV1(1), lambda1_ex1_ref, tol_torri, 'Ex1 λ1 = 83.21', passed, failed);
[passed, failed] = check(posV1(2), lambda2_ex1_ref, tol_torri, 'Ex1 λ2 = 288.91', passed, failed);

fprintf('\n--- Část 2: Torri benchmark Ex2 (bez tenkých prutů) ---\n\n');

% --- Ex2: různé průřezy, bez prutů 3 a 5 (tenké) ---
r_o2 = [5.6793;5.0566;4.8887;6.0175;4.1126]*1e-2;   % bez indexů 3,5
r_i2 = r_o2 * 0.9;
sec2.A  = pi.*(r_o2.^2-r_i2.^2); sec2.Iy = pi/4*(r_o2.^4-r_i2.^4);
sec2.Iz = sec2.Iy; sec2.Ix = 2*sec2.Iy;
sec2.E  = ones(5,1)*210e9; sec2.v = ones(5,1)*0.3;

loads_t2 = loads_t; loads_t2.z.nodes=[5]; loads_t2.z.value=[-150e3];

beams_t2.nodesHead=[1;1;3;2;4];   % pruty 3,5 odstraněny
beams_t2.nodesEnd =[2;4;4;5;5];
beams_t2.sections =[1;2;3;4;5];
beams_t2.angles   =[0;0;0;0;0];

R2 = stabilitySolverFn(sec2, nodes_t, 8, kinematic_t, beams_t2, loads_t2, 'oofem');
posV2 = R2.values(R2.values > 0);

% Reference verifikováno ndisc=8 (oofem solver)
lambda1_ex2_ref = 0.8667;
lambda2_ex2_ref = 0.9308;

[passed, failed] = check(posV2(1), lambda1_ex2_ref, tol_torri, 'Ex2 λ1 = 0.8667', passed, failed);
[passed, failed] = check(posV2(2), lambda2_ex2_ref, tol_torri, 'Ex2 λ2 = 0.9308', passed, failed);

%% =========================================================================
%  SOUHRN
%% =========================================================================
total = passed + failed;
fprintf('\n==========================================================================\n');
if failed == 0
    fprintf('  PASSED  %d / %d\n', passed, total);
else
    fprintf('  FAILED  %d / %d  —  viz výše\n', failed, total);
end
fprintf('==========================================================================\n\n');

if failed > 0
    error('test_section_rotation: %d / %d subtestů selhalo.', failed, total);
end

%% =========================================================================
%  POMOCNÉ FUNKCE
%% =========================================================================
function [p, f] = check(val, ref, tol, name, p, f, absolute)
    if nargin < 7, absolute = false; end
    if absolute
        err  = abs(val - ref);
        ok   = err < tol;
        fprintf('  %-45s  val=%+.3e  ref=%+.3e  err=%.2e  [%s]\n', ...
            name, val, ref, err, pass_str(ok));
    else
        if ref == 0
            err = abs(val);
            ok  = err < tol;
        else
            err = abs(val - ref) / abs(ref) * 100;
            ok  = err < tol;
        end
        fprintf('  %-45s  val=%+.6f  ref=%+.6f  err=%.4f %%  [%s]\n', ...
            name, val, ref, err, pass_str(ok));
    end
    if ok; p = p + 1; else; f = f + 1; end
end

function s = pass_str(ok)
    if ok; s = 'PASS'; else; s = 'FAIL'; end
end
