%% diag_test9_h1.m — Debug Test 9: hypotéza H1
%
% Cíl: Otestovat, zda chyba 114 % zmizí při:
%   (a) trubkovém průřezu Iy = Iz (angle-independent K)  — H1a
%   (b) trubkovém průřezu + axis-aligned geometrie       — H1b
%   (c) původní sekce, ale angle = 0                     — H1c
%
% Spuštění: z adresáře stability-tests/Test 9/
%   diag_test9_h1
%
% Výstup: tabulka průměrných chyb pro každý scénář (prvních 5 módů)

clear; close all;

%% Přidat cesty
thisDir   = fileparts(mfilename('fullpath'));
testsDir  = fileparts(thisDir);
addpath(testsDir);
addpath(fullfile(testsDir, '..', 'Resources'));
cd(thisDir);

fprintf('=============================================================\n');
fprintf('  Debug Test 9 — Hypotéza H1: vliv průřezu a geometrie\n');
fprintf('=============================================================\n\n');

% ─────────────────────────────────────────────────────────────────────────
%% SPOLEČNÁ GEOMETRIE PYRAMIDY (všechny scénáře)
% ─────────────────────────────────────────────────────────────────────────
nodes.x = [0; 4; 4; 0; 2];
nodes.y = [0; 0; 4; 4; 2];
nodes.z = [0; 0; 0; 0; 5];

ndisc = 10;

kinematic.x.nodes  = [1;2;3;4];
kinematic.y.nodes  = [1;2;3;4];
kinematic.z.nodes  = [1;2;3;4];
kinematic.rx.nodes = [1;2;3;4];
kinematic.ry.nodes = [1;2;3;4];
kinematic.rz.nodes = [1;2;3;4];

beams.nodesHead = [1;2;3;4];
beams.nodesEnd  = [5;5;5;5];

loads.x.nodes  = [5]; loads.x.value  = [0];
loads.y.nodes  = [5]; loads.y.value  = [0];
loads.z.nodes  = [5]; loads.z.value  = [-25];
loads.rx.nodes = [5]; loads.rx.value = [0];
loads.ry.nodes = [5]; loads.ry.value = [0];
loads.rz.nodes = [5]; loads.rz.value = [0];

% Trubkový průřez CHS 100×5 mm — Iy = Iz (symetrický)
%   A  = π/4*(0.1² − 0.09²) = 1.4923e-3 m²
%   I  = π/64*(0.1⁴ − 0.09⁴) = 1.6894e-6 m⁴
%   Ix = 2*I (torzní = 2× ohybový pro plný kruh/trubka)
A_tube  = 1.4923e-3;
I_tube  = 1.6894e-6;
Ix_tube = 2 * I_tube;
E_val   = 210e9;
v_val   = 0.3;

% ─────────────────────────────────────────────────────────────────────────
%% SCÉNÁŘ A: Trubka Iy=Iz, angle = 0 (původní pyramida)
% ─────────────────────────────────────────────────────────────────────────
fprintf('── Scénář A: Trubka Iy=Iz, angle=0, pyramida ──\n');
beams.sections = [1;1;1;1];
beams.angles   = [0;0;0;0];
sections.id    = [1];
sections.A     = [A_tube];
sections.Iy    = [I_tube];
sections.Iz    = [I_tube];
sections.Ix    = [Ix_tube];
sections.E     = [E_val];
sections.v     = [v_val];

try
    [errA, ~, valA] = testFn(sections, nodes, ndisc, kinematic, beams, loads);
    posA = sort(valA(valA>0));
    n5 = min(5, length(posA));
    fprintf('  Průměrná chyba (prvních %d módů): %.2f %%\n', n5, mean(errA(1:n5)));
    fprintf('  Chyby: '); fprintf('%.1f%% ', errA(1:n5)); fprintf('\n\n');
catch ME
    fprintf('  CHYBA: %s\n\n', ME.message);
    errA = [];
end

% ─────────────────────────────────────────────────────────────────────────
%% SCÉNÁŘ B: Trubka Iy=Iz, angle = 45 (původní pyramida)
% ─────────────────────────────────────────────────────────────────────────
fprintf('── Scénář B: Trubka Iy=Iz, angle=45, pyramida ──\n');
beams.angles   = [45;45;45;45];

try
    [errB, ~, valB] = testFn(sections, nodes, ndisc, kinematic, beams, loads);
    posB = sort(valB(valB>0));
    n5 = min(5, length(posB));
    fprintf('  Průměrná chyba (prvních %d módů): %.2f %%\n', n5, mean(errB(1:n5)));
    fprintf('  Chyby: '); fprintf('%.1f%% ', errB(1:n5)); fprintf('\n\n');
catch ME
    fprintf('  CHYBA: %s\n\n', ME.message);
    errB = [];
end

% ─────────────────────────────────────────────────────────────────────────
%% SCÉNÁŘ C: Původní sekce id=[15;25;10;12], angle=0
% ─────────────────────────────────────────────────────────────────────────
fprintf('── Scénář C: Původní sekce, angle=0 ──\n');
beams.sections    = [1;1;2;2];
beams.angles      = [0;0;0;0];
sections_orig.id  = [15;25;10;12];
% Bez pole A → testFn načte z sectionsSet.mat

try
    [errC, ~, valC] = testFn(sections_orig, nodes, ndisc, kinematic, beams, loads);
    posC = sort(valC(valC>0));
    n5 = min(5, length(posC));
    fprintf('  Průměrná chyba (prvních %d módů): %.2f %%\n', n5, mean(errC(1:n5)));
    fprintf('  Chyby: '); fprintf('%.1f%% ', errC(1:n5)); fprintf('\n\n');
catch ME
    fprintf('  CHYBA: %s\n\n', ME.message);
    errC = [];
end

% ─────────────────────────────────────────────────────────────────────────
%% SCÉNÁŘ D: Původní sekce id=[15;25;10;12], angle=45 (= referenční Test 9)
% ─────────────────────────────────────────────────────────────────────────
fprintf('── Scénář D: Původní sekce, angle=45 (referenční Test 9) ──\n');
beams.sections    = [1;1;2;2];
beams.angles      = [45;45;45;45];

try
    [errD, ~, valD] = testFn(sections_orig, nodes, ndisc, kinematic, beams, loads);
    posD = sort(valD(valD>0));
    n5 = min(5, length(posD));
    fprintf('  Průměrná chyba (prvních %d módů): %.2f %%\n', n5, mean(errD(1:n5)));
    fprintf('  Chyby: '); fprintf('%.1f%% ', errD(1:n5)); fprintf('\n\n');
catch ME
    fprintf('  CHYBA: %s\n\n', ME.message);
    errD = [];
end

% ─────────────────────────────────────────────────────────────────────────
%% SHRNUTÍ
% ─────────────────────────────────────────────────────────────────────────
fprintf('=============================================================\n');
fprintf('  SHRNUTÍ — průměrné chyby (prvních 5 módů)\n');
fprintf('=============================================================\n');
scenarios = {'A: Trubka, angle=0', 'B: Trubka, angle=45', ...
             'C: Orig. sekce, angle=0', 'D: Orig. sekce, angle=45 (ref)'};
allErr = {errA, errB, errC, errD};
for k = 1:4
    if ~isempty(allErr{k})
        n5 = min(5, length(allErr{k}));
        fprintf('  %s → avg=%.2f%%, max=%.2f%%\n', ...
            scenarios{k}, mean(allErr{k}(1:n5)), max(allErr{k}(1:n5)));
    else
        fprintf('  %s → CHYBA\n', scenarios{k});
    end
end
fprintf('\nInterpretace:\n');
fprintf('  A≈0%%    → H1 potvrzena (průřez nebo úhel způsobuje chybu)\n');
fprintf('  A≈114%% → problém nezávisí na průřezu → H2 (formulace Kg)\n');
fprintf('  A≈0, B≈114%% → vliv je angle=45, ne asymetrie průřezu\n');
fprintf('  C≈0, D≈114%% → vliv je angle=45 + nesym. průřez kombinace\n');
