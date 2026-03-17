%% diag_test9_h2.m — Debug Test 9: axis-aligned geometrie + jediný diag. prut
%
% Cíl: Otestovat, zda chyba zmizí při:
%   (a) 4 svislé sloupky (osy Z) — zarovnané s osami souřadnic
%   (b) jediný diagonální prut (2,2,5) — minimální případ
%   (c) jediný svislý prut (0,0,5) — referenční případ
%
% Předpoklad: run AFTER diag_test9_h1 — pokud A (trubka, angle=0) stále
% vykazuje chybu, problém je v geometrii (diagonální prvky), ne v průřezu.
%
% Spuštění: z adresáře stability-tests/Test 9/

clear; close all;

%% Přidat cesty
thisDir  = fileparts(mfilename('fullpath'));
testsDir = fileparts(thisDir);
addpath(testsDir);
addpath(fullfile(testsDir, '..', 'Resources'));
cd(thisDir);

fprintf('=============================================================\n');
fprintf('  Debug Test 9 — Hypotéza H2: geometrie diag. prut vs. svislý\n');
fprintf('=============================================================\n\n');

% Trubkový průřez (Iy=Iz, angle-independent) — izoluje vliv geometrie
A_tube  = 1.4923e-3;
I_tube  = 1.6894e-6;
Ix_tube = 2 * I_tube;
E_val   = 210e9;
v_val   = 0.3;

sections1.id = [1];
sections1.A  = [A_tube];
sections1.Iy = [I_tube];
sections1.Iz = [I_tube];
sections1.Ix = [Ix_tube];
sections1.E  = [E_val];
sections1.v  = [v_val];

loads_std.x.nodes  = []; loads_std.x.value  = [];
loads_std.y.nodes  = []; loads_std.y.value  = [];
loads_std.rx.nodes = []; loads_std.rx.value = [];
loads_std.ry.nodes = []; loads_std.ry.value = [];
loads_std.rz.nodes = []; loads_std.rz.value = [];

% ─────────────────────────────────────────────────────────────────────────
%% SCÉNÁŘ E: 4 svislé sloupky (osy Z, fixace dole, Fz nahoře)
% ─────────────────────────────────────────────────────────────────────────
fprintf('── Scénář E: 4 svislé sloupky (axis-aligned, trubka) ──\n');
nodes_e.x = [0; 4; 4; 0; 0; 4; 4; 0];
nodes_e.y = [0; 0; 4; 4; 0; 0; 4; 4];
nodes_e.z = [0; 0; 0; 0; 5; 5; 5; 5];

ndisc_e = 10;

kin_e.x.nodes  = [1;2;3;4];
kin_e.y.nodes  = [1;2;3;4];
kin_e.z.nodes  = [1;2;3;4];
kin_e.rx.nodes = [1;2;3;4];
kin_e.ry.nodes = [1;2;3;4];
kin_e.rz.nodes = [1;2;3;4];

beams_e.nodesHead = [1;2;3;4];
beams_e.nodesEnd  = [5;6;7;8];
beams_e.sections  = [1;1;1;1];
beams_e.angles    = [0;0;0;0];

loads_e = loads_std;
loads_e.z.nodes = [5;6;7;8];
loads_e.z.value = [-6.25;-6.25;-6.25;-6.25];  % celkem -25 jako pyramida

try
    [errE, ~, valE] = testFn(sections1, nodes_e, ndisc_e, kin_e, beams_e, loads_e);
    n5 = min(5, length(errE));
    fprintf('  Průměrná chyba (prvních %d módů): %.2f %%\n', n5, mean(errE(1:n5)));
    fprintf('  Chyby: '); fprintf('%.1f%% ', errE(1:n5)); fprintf('\n\n');
catch ME
    fprintf('  CHYBA: %s\n\n', ME.message);
    errE = [];
end

% ─────────────────────────────────────────────────────────────────────────
%% SCÉNÁŘ F: Jediný diagonální prut (0,0,0)→(2,2,5), trubka
% ─────────────────────────────────────────────────────────────────────────
fprintf('── Scénář F: Jediný diagonální prut (trubka, angle=0) ──\n');
nodes_f.x = [0; 2];
nodes_f.y = [0; 2];
nodes_f.z = [0; 5];

ndisc_f = 10;

kin_f.x.nodes  = [1];
kin_f.y.nodes  = [1];
kin_f.z.nodes  = [1];
kin_f.rx.nodes = [1];
kin_f.ry.nodes = [1];
kin_f.rz.nodes = [1];

beams_f.nodesHead = [1];
beams_f.nodesEnd  = [2];
beams_f.sections  = [1];
beams_f.angles    = [0];

loads_f = loads_std;
loads_f.z.nodes = [2]; loads_f.z.value = [-25];

try
    [errF, ~, valF] = testFn(sections1, nodes_f, ndisc_f, kin_f, beams_f, loads_f);
    n5 = min(5, length(errF));
    fprintf('  Průměrná chyba (prvních %d módů): %.2f %%\n', n5, mean(errF(1:n5)));
    fprintf('  Chyby: '); fprintf('%.1f%% ', errF(1:n5)); fprintf('\n\n');
catch ME
    fprintf('  CHYBA: %s\n\n', ME.message);
    errF = [];
end

% ─────────────────────────────────────────────────────────────────────────
%% SCÉNÁŘ G: Jediný svislý prut (0,0,0)→(0,0,5), trubka — referenční
% ─────────────────────────────────────────────────────────────────────────
fprintf('── Scénář G: Jediný svislý prut (axis-aligned, trubka) ──\n');
nodes_g.x = [0; 0];
nodes_g.y = [0; 0];
nodes_g.z = [0; 5];

ndisc_g = 10;

kin_g.x.nodes  = [1];
kin_g.y.nodes  = [1];
kin_g.z.nodes  = [1];
kin_g.rx.nodes = [1];
kin_g.ry.nodes = [1];
kin_g.rz.nodes = [1];

beams_g.nodesHead = [1];
beams_g.nodesEnd  = [2];
beams_g.sections  = [1];
beams_g.angles    = [0];

loads_g = loads_std;
loads_g.z.nodes = [2]; loads_g.z.value = [-25];

try
    [errG, ~, valG] = testFn(sections1, nodes_g, ndisc_g, kin_g, beams_g, loads_g);
    n5 = min(5, length(errG));
    fprintf('  Průměrná chyba (prvních %d módů): %.2f %%\n', n5, mean(errG(1:n5)));
    fprintf('  Chyby: '); fprintf('%.1f%% ', errG(1:n5)); fprintf('\n\n');
catch ME
    fprintf('  CHYBA: %s\n\n', ME.message);
    errG = [];
end

% ─────────────────────────────────────────────────────────────────────────
%% SHRNUTÍ
% ─────────────────────────────────────────────────────────────────────────
fprintf('=============================================================\n');
fprintf('  SHRNUTÍ — průměrné chyby (prvních 5 módů)\n');
fprintf('=============================================================\n');
scenarios = {'E: 4 sloupky axis-aligned', 'F: 1 diag. prut (2,2,5)', 'G: 1 svislý prut (0,0,5)'};
allErr = {errE, errF, errG};
for k = 1:3
    if ~isempty(allErr{k})
        n5 = min(5, length(allErr{k}));
        fprintf('  %s → avg=%.2f%%, max=%.2f%%\n', ...
            scenarios{k}, mean(allErr{k}(1:n5)), max(allErr{k}(1:n5)));
    else
        fprintf('  %s → CHYBA\n', scenarios{k});
    end
end
fprintf('\nInterpretace:\n');
fprintf('  E≈0%%, F≈0%%, G≈0%% → chyba závisela jen na průřezu (viz H1)\n');
fprintf('  E≈0%%, F>0%%        → problém specificky v diag. prutu\n');
fprintf('  G≈0%%, F>0%%        → problém v non-axis-aligned geometrii\n');
fprintf('  Všechny >0%%       → Kg formulace obecně špatná → H3\n');
