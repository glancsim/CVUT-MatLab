function results = designCheckFn(nodes, members, sections, kinematic, loadParams)
% designCheckFn  EN 1993-1-1 design check orchestrator for a 2D truss.
%
% Pipeline:
%   1. Classify members (chord / diagonal / vertical)
%   2. Compute buckling lengths L_cr per Tab. 1.29
%   3. Generate load combinations (EN 1990)
%   4. For each combination: solve FEM → extract N_Ed → run section check
%   5. Compute utilization envelope across all combinations
%   6. Print result table
%
% INPUTS:
%   nodes     - struct: .x, .z  (from trussHallInputFn)
%   members   - struct: .nodesHead, .nodesEnd, .sections
%   sections  - struct: .A, .E, .I, .i_radius, .curve  (per section group)
%   kinematic - struct: .x.nodes, .z.nodes
%   loadParams - struct from trussHallInputFn
%
% OUTPUTS:
%   results - struct with fields:
%     .classification   output of memberClassificationFn
%     .Lcr              output of bucklingLengthsFn
%     .N_Ed             [kN] (nmembers × ncombos)  axial forces
%     .util             (nmembers × ncombos)        utilization per combo
%     .util_max         (nmembers × 1)              envelope utilization
%     .governing_combo  (nmembers × 1)              combo index governing
%     .checks           cell (ncombos × 1) of struct arrays (per member)
%     .status           'OK' or 'FAIL' (overall)
%
% (c) S. Glanc, 2026

%% --- Add path to FEM solver -------------------------------------------
femSrc = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
                  '..', 'fem-2d-truss-matlab', 'src');
addpath(femSrc);

nmembers = numel(members.nodesHead);

%% 1. Classify members ----------------------------------------------------
classification = memberClassificationFn(members, nodes);

%% 2. Buckling lengths ----------------------------------------------------
Lcr = bucklingLengthsFn(members, nodes, classification, loadParams);

%% 3. Load combinations ---------------------------------------------------
combos   = loadCombinationsFn(loadParams);
ncombos  = numel(combos);

%% 4. FEM analysis + section checks per combination -----------------------
N_Ed_all = zeros(nmembers, ncombos);   % [kN]
util_all  = zeros(nmembers, ncombos);
checks_all = cell(ncombos, 1);

for ic = 1:ncombos
    [~, endForces] = linearSolverFn(sections, nodes, kinematic, members, ...
                                     combos{ic}.loads);
    N_Ed = endForces.local(1, :)' / 1e3;   % [N] → [kN]
    N_Ed_all(:, ic) = N_Ed;

    chk = struct('N_pl_Rd', cell(nmembers,1), 'N_b_Rd', cell(nmembers,1), ...
                 'chi', cell(nmembers,1), 'lambda_bar', cell(nmembers,1), ...
                 'section_class', cell(nmembers,1), ...
                 'util_max', cell(nmembers,1), 'status', cell(nmembers,1));

    for p = 1:nmembers
        si   = members.sections(p);
        A    = sections.A(si);
        i_r  = sections.i_radius(si);
        f_y  = loadParams.f_y;
        L_cr = Lcr.governing(p);
        crv  = sections.curve{si};

        % Pass D, t for cross-section class check (optional fields)
        D_sec = []; t_sec = [];
        if isfield(sections, 'D') && isfield(sections, 't')
            D_sec = sections.D(si);
            t_sec = sections.t(si);
        end

        r = sectionCheckFn(N_Ed(p) * 1e3, A, i_r, f_y, L_cr, crv, D_sec, t_sec);

        chk(p).N_pl_Rd      = r.N_pl_Rd;
        chk(p).N_b_Rd       = r.N_b_Rd;
        chk(p).chi          = r.chi;
        chk(p).lambda_bar   = r.lambda_bar;
        chk(p).section_class = r.section_class;
        chk(p).util_max     = r.util_max;
        chk(p).status       = r.status;

        util_all(p, ic) = r.util_max;
    end

    checks_all{ic} = chk;
end

%% 5. Utilization envelope ------------------------------------------------
[util_max, gov_combo] = max(util_all, [], 2);

% Max tension and max compression per member (across all combos)
[N_max_tension, ic_tension]     = max(N_Ed_all, [], 2);   % max positive = tension
[N_max_compress, ic_compress]   = min(N_Ed_all, [], 2);   % min negative = compression

%% 6. Print result table --------------------------------------------------
fprintf('\n');
fprintf('╔══════════════════════════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║  EN 1993-1-1  —  Posudek příhradového vazníku                                                  ║\n');
fprintf('╠══════╦══════════════╦═══════════════╦═══════════════╦══════════╦═══════╦════════╦═══════╦═══════╣\n');
fprintf('║  č.  ║  Typ prutu   ║  N_Ed,tah     ║  N_Ed,tlak    ║  N_b_Rd  ║   λ̄   ║   χ    ║ Util. ║ Stat. ║\n');
fprintf('║      ║              ║  [kN]  (KZS)  ║  [kN]  (KZS)  ║  [kN]    ║       ║        ║       ║       ║\n');
fprintf('╠══════╬══════════════╬═══════════════╬═══════════════╬══════════╬═══════╬════════╬═══════╬═══════╣\n');

for p = 1:nmembers
    ic  = gov_combo(p);
    chk = checks_all{ic}(p);
    type_str = pad(char(classification.type(p)), 12);
    stat = chk.status;
    if strcmp(stat, 'FAIL')
        stat_str = ' FAIL ';
    else
        stat_str = '  OK  ';
    end
    % Format tension: show value (KZS) or dash if no tension
    if N_max_tension(p) > 0
        tah_str = sprintf('%7.1f (%d)', N_max_tension(p), ic_tension(p));
    else
        tah_str = '      —      ';
    end
    % Format compression
    if N_max_compress(p) < 0
        tlak_str = sprintf('%7.1f (%d)', N_max_compress(p), ic_compress(p));
    else
        tlak_str = '      —      ';
    end
    fprintf('║ %4d ║ %s ║ %13s ║ %13s ║ %8.1f ║ %5.2f ║ %6.3f ║ %5.3f ║ %s ║\n', ...
        p, type_str, tah_str, tlak_str, chk.N_b_Rd, chk.lambda_bar, chk.chi, chk.util_max, stat_str);
end

fprintf('╚══════╩══════════════╩═══════════════╩═══════════════╩══════════╩═══════╩════════╩═══════╩═══════╝\n');

n_fail = sum(util_max > 1.0);
fprintf('\nCelkový výsledek: %d/%d prutů NEVYHOVUJE\n', n_fail, nmembers);
fprintf('Max. využití: %.3f (prut %d, %s, kombo %d — %s)\n', ...
    max(util_max), find(util_max == max(util_max), 1), ...
    classification.type(find(util_max == max(util_max), 1)), ...
    gov_combo(find(util_max == max(util_max), 1)), ...
    combos{gov_combo(find(util_max == max(util_max), 1))}.description);

%% 7. Assemble output -----------------------------------------------------
results.classification  = classification;
results.Lcr             = Lcr;
results.N_Ed            = N_Ed_all;
results.N_max_tension   = N_max_tension;
results.ic_tension      = ic_tension;
results.N_max_compress  = N_max_compress;
results.ic_compress     = ic_compress;
results.util            = util_all;
results.util_max        = util_max;
results.governing_combo = gov_combo;
results.checks          = checks_all;
results.combos          = combos;
results.status         = 'OK';
if any(util_max > 1.0)
    results.status = 'FAIL';
end

end
