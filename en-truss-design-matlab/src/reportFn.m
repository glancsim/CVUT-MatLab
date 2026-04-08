function reportFn(params, nodes, members, sections, kinematic, loadParams, results, filename)
% reportFn  Generate a self-contained HTML engineering calculation report.
%
% Produces a professional HTML file documenting the EN 1993-1-1 design check
% of a steel truss girder.  The file can be opened in any browser and
% printed / exported to PDF (Ctrl+P in Chrome/Firefox → Save as PDF).
%
% Report sections:
%   1. Záhlaví (header)
%   2. Geometrie vazníku
%   3. Průřezy
%   4. Zatížení — char. hodnoty, výpočet sněhu a větru, 5 KZS + schémata
%   5. Vzpěrné délky (Tab. 1.29)
%   6. Metodika posudku (EN 1993-1-1 formule s citacemi)
%   7. Ukázka výpočtu — step-by-step pro kritický prut
%   8. Výsledky — tabulka prutů (barevně kódovaná)
%   9. Souhrn (OK / FAIL)
%
% INPUTS:
%   params     - struct from trussHallInputFn (span, slope, f_y, loads, …)
%   nodes      - struct with .x, .z
%   members    - struct with .nodesHead, .nodesEnd, .sections
%   sections   - struct with .A, .E, .I, .i_radius, .curve, .D, .t
%   kinematic  - struct with .x.nodes, .z.nodes (supports)
%   loadParams - struct from trussHallInputFn (g_total, g_min, …)
%   results    - struct from designCheckFn
%   filename   - output HTML file path (default: 'vaznik_posudek.html')
%
% (c) S. Glanc, 2026

if nargin < 8 || isempty(filename)
    filename = 'vaznik_posudek.html';
end

fid = fopen(filename, 'w', 'n', 'UTF-8');
if fid < 0
    error('reportFn: Cannot open ''%s'' for writing.', filename);
end
c = onCleanup(@() fclose(fid));

%% ── Precompute scalars ────────────────────────────────────────────────
L        = params.span;
fy_MPa   = params.f_y / 1e6;
E_GPa    = params.E   / 1e9;
nmembers = numel(members.nodesHead);
epsilon  = sqrt(235 / fy_MPa);
lambda_1 = pi * sqrt(params.E / params.f_y);
mu1      = 0.8;
s_d      = mu1 * loadParams.s_k;       % snow design value [kN/m²]

% Self-weight (Jandera formula)
g_d     = params.g_roof + params.s_k;
g_self  = L / 76 * sqrt(g_d * params.truss_spacing);
g_total = params.g_roof + g_self;
g_min   = params.g_roof + 0.5 * g_self;

% Topology / shape labels
if isfield(loadParams, 'topology'),  topo_key  = loadParams.topology;
elseif isfield(params, 'topology'),  topo_key  = params.topology;
else;                                topo_key  = 'pratt';
end
if isfield(loadParams, 'shape'),     shape_key = loadParams.shape;
elseif isfield(params, 'shape'),     shape_key = params.shape;
else;                                shape_key = 'saddle';
end

% Critical member
[~, p_crit] = max(results.util_max);
ic_crit     = results.governing_combo(p_crit);
chk_crit    = results.checks{ic_crit}(p_crit);
si_crit     = members.sections(p_crit);
alpha_crit  = curveAlpha(sections.curve{si_crit});
lb_crit     = chk_crit.lambda_bar;
Phi_crit    = 0.5 * (1 + alpha_crit*(lb_crit - 0.2) + lb_crit^2);
N_Ed_crit   = results.N_Ed(p_crit, ic_crit);   % [kN]
Lcr_in_crit  = results.Lcr.in_plane(p_crit);
Lcr_out_crit = results.Lcr.out_of_plane(p_crit);
Lcr_gov_crit = results.Lcr.governing(p_crit);

% Overall status colours
if strcmp(results.status, 'OK')
    sc = '#155724'; sbg = '#d4edda'; sb = '#c3e6cb';
else
    sc = '#721c24'; sbg = '#f8d7da'; sb = '#f5c6cb';
end

%% ── HEAD ─────────────────────────────────────────────────────────────
w(fid, '<!DOCTYPE html>');
w(fid, '<html lang="cs">');
w(fid, '<head>');
w(fid, '<meta charset="UTF-8">');
w(fid, '<meta name="viewport" content="width=device-width,initial-scale=1">');
w(fid, '<title>Posudek vazn&iacute;ku &mdash; EN 1993-1-1</title>');
w(fid, '<script>MathJax={tex:{inlineMath:[["$","$"]],displayMath:[["$$","$$"]]}};</script>');
w(fid, '<script async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js"></script>');

%% ── CSS ──────────────────────────────────────────────────────────────
w(fid, '<style>');
w(fid, ':root{--navy:#1a3a5c;--blue:#2b5f9e;--gray:#6c757d;}');
w(fid, 'body{font-family:"Segoe UI",Arial,sans-serif;font-size:10.5pt;color:#212529;max-width:1050px;margin:0 auto;padding:20px 28px;}');
w(fid, 'h1{color:var(--navy);border-bottom:3px solid var(--navy);padding-bottom:5px;font-size:15pt;margin-bottom:4px;}');
w(fid, 'h2{color:var(--navy);font-size:12pt;margin-top:26px;border-left:4px solid var(--blue);padding-left:8px;}');
w(fid, 'table{border-collapse:collapse;width:100%;margin-bottom:12px;font-size:9.5pt;}');
w(fid, 'th{background:var(--navy);color:#fff;padding:5px 9px;text-align:center;border:1px solid #0d2740;}');
w(fid, 'td{padding:4px 9px;border:1px solid #dee2e6;}');
w(fid, 'tr:nth-child(even) td{background:#f8f9fa;}');
w(fid, 'tr.warn td{background:#fff3cd !important;}');
w(fid, 'tr.fail td{background:#f8d7da !important;color:#721c24;font-weight:bold;}');
w(fid, '.ref{color:var(--gray);font-style:italic;font-size:8.5pt;}');
w(fid, '.fbox{background:#f8f9fa;border:1px solid #dee2e6;border-radius:4px;padding:9px 16px;margin:6px 0;font-size:10pt;line-height:1.9;}');
w(fid, '.wbox{background:#e8f4f8;border:1px solid #b8daff;border-radius:4px;padding:9px 16px;margin:6px 0;font-size:10pt;line-height:1.9;}');
w(fid, '.sbox{padding:14px 20px;border-radius:6px;font-size:12.5pt;font-weight:bold;text-align:center;margin-top:20px;}');
w(fid, '.meta{color:var(--gray);font-size:9.5pt;margin-bottom:20px;}');
w(fid, '.step{margin-left:20px;line-height:2.1;}');
w(fid, '@media print{');
w(fid, ' body{max-width:100%;padding:8mm 10mm;}');
w(fid, ' h2{page-break-after:avoid;}');
w(fid, ' .no-print{display:none;}');
w(fid, ' #s8{page-break-before:always;}');
w(fid, ' th{-webkit-print-color-adjust:exact;print-color-adjust:exact;}');
w(fid, ' tr.warn td,tr.fail td{-webkit-print-color-adjust:exact;print-color-adjust:exact;}');
w(fid, '}');
w(fid, '</style>');
w(fid, '</head><body>');

%% ── SECTION 1: Záhlaví ───────────────────────────────────────────────
w(fid, '<h1>Posudek p&#345;&#237;hradov&#233;ho vazn&#237;ku &mdash; EN&nbsp;1993-1-1</h1>');
wf(fid, '<div class="meta"><strong>Rozp&#283;t&#237;:</strong> L = %.0f m &nbsp;|&nbsp; <strong>V&yacute;&scaron;ka v ulo&#382;en&#237;:</strong> h = %.2f m &nbsp;|&nbsp; <strong>Datum:</strong> %s</div>', ...
    L, params.h_support, datestr(now, 'dd.mm.yyyy'));

%% ── SECTION 2: Geometrie ─────────────────────────────────────────────
w(fid, '<h2>1. Geometrie vazn&#237;ku</h2>');
w(fid, '<table><tr><th>Veli&#269;ina</th><th>Symbol</th><th>Hodnota</th><th>Jednotka</th></tr>');

switch lower(shape_key)
    case 'flat'
        h_max_str   = sprintf('%.2f', params.h_support);
        h_max_label = 'V&yacute;&scaron;ka (konstantn&#237;)';
    case 'mono'
        h_max_str   = sprintf('%.2f', params.h_support + params.slope * L);
        h_max_label = 'Max. v&yacute;&scaron;ka (napravo)';
    otherwise
        h_max_str   = sprintf('%.2f', params.h_support + params.slope * L/2);
        h_max_label = 'Max. v&yacute;&scaron;ka (uprost&#345;ed)';
end

geom = {
    'Rozp&#283;t&#237;',                  'L',  sprintf('%.0f',  L),                     'm';
    'Sklon st&#345;echy',                 '&alpha;', sprintf('%.0f %%', params.slope*100), '&mdash;';
    'V&yacute;&scaron;ka v ulo&#382;en&#237;', 'h<sub>s</sub>', sprintf('%.2f', params.h_support), 'm';
    h_max_label,  'h<sub>max</sub>', h_max_str, 'm';
    'Rozp&#283;t&#237; vaznic',           'a',  sprintf('%.1f',  params.purlin_spacing),  'm';
    'Vzd&#225;lenost vazn&#237;k&#367;',  'd',  sprintf('%.1f',  params.truss_spacing),   'm';
    'Po&#269;et pol&#237;',               'n',  sprintf('%d',    loadParams.n_panels),     '&mdash;';
    'Topologie',  '&mdash;', translateTopology(topo_key),  '&mdash;';
    'Tvar',       '&mdash;', translateShape(shape_key),    '&mdash;';
};
for k = 1:size(geom,1)
    wf(fid, '<tr><td>%s</td><td style="text-align:center">%s</td><td style="text-align:right"><strong>%s</strong></td><td>%s</td></tr>', geom{k,:});
end
w(fid, '</table>');

%% ── SECTION 3: Průřezy ───────────────────────────────────────────────
w(fid, '<h2>2. Pr&#367;&#345;ezy</h2>');
wf(fid, '<p>Ocel S355, $f_y = %.0f$ MPa, $E = %.0f$ GPa. CHS horn&#283; v&#225;lco van&#233; &rarr; vzp&#283;rn&#225; k&#345;ivka <strong>a</strong> ($\\alpha = 0{,}21$).</p>', fy_MPa, E_GPa);
w(fid, ['<table><tr><th>Skupina</th><th>Ozna&#269;en&#237;</th>'...
         '<th>D [mm]</th><th>t [mm]</th><th>A [cm&sup2;]</th>'...
         '<th>I [cm<sup>4</sup>]</th><th>i [mm]</th><th>D/t</th>'...
         '<th>T&#345;&#237;da&sup1;</th><th>K&#345;ivka vzp.</th></tr>']);
% Build section names dynamically
nSec = numel(sections.A);
sec_names = cell(nSec, 1);
sec_names{1} = 'Horn&#237; p&#225;s';
sec_names{2} = 'Doln&#237; p&#225;s';
if isfield(loadParams, 'sectionGroups')
    sgrp = loadParams.sectionGroups;
    for k = 1:sgrp.nDiag
        sec_names{sgrp.diagIdx(k)} = sprintf('Diagon&#225;la %d', k);
    end
    for k = 1:sgrp.nVert
        sec_names{sgrp.vertIdx(k)} = sprintf('Svislice %d', k);
    end
else
    % Fallback for legacy 3-group input
    for sg = 3:nSec
        sec_names{sg} = sprintf('V&yacute;pl&#328; %d', sg - 2);
    end
end

% Print only unique profiles (merge rows with identical D, t)
D_all = sections.D * 1e3;   % [mm]
t_all = sections.t * 1e3;
profile_key = round(D_all * 100 + t_all, 2);  % unique key per D/t combo
[uniq_keys, ~, key_idx] = unique(profile_key);

for uk = 1:numel(uniq_keys)
    grp = find(key_idx == uk);
    sg  = grp(1);  % representative section
    D_mm  = D_all(sg);
    t_mm  = t_all(sg);
    A_cm2 = sections.A(sg)*1e4;
    I_cm4 = sections.I(sg)*1e8;
    i_mm  = sections.i_radius(sg)*1e3;
    dt    = D_mm/t_mm;
    % Section class from any member using this group
    cls_str = '&mdash;';
    for gi = 1:numel(grp)
        p1 = find(members.sections == grp(gi), 1);
        if ~isempty(p1)
            sc_val  = results.checks{results.governing_combo(p1)}(p1).section_class;
            cls_str = num2strOrDash(sc_val);
            break;
        end
    end
    % Name: list all group names
    names = sec_names(grp);
    name_str = strjoin(names, ', ');
    wf(fid, ['<tr><td>%s</td>'...
             '<td style="text-align:center">TR&nbsp;%.0f&times;%.1f</td>'...
             '<td style="text-align:right">%.0f</td>'...
             '<td style="text-align:right">%.1f</td>'...
             '<td style="text-align:right">%.2f</td>'...
             '<td style="text-align:right">%.1f</td>'...
             '<td style="text-align:right">%.1f</td>'...
             '<td style="text-align:right">%.1f</td>'...
             '<td style="text-align:center"><strong>%s</strong></td>'...
             '<td style="text-align:center">%s</td></tr>'], ...
        name_str, D_mm, t_mm, D_mm, t_mm, A_cm2, I_cm4, i_mm, dt, cls_str, sections.curve{sg});
end
w(fid, '</table>');
wf(fid, '<p class="ref">&sup1; T&#345;&#237;da CHS dle EN 1993-1-1, Tab. 5.2: T&#345;. 1 &rarr; $D/t \\leq 50\\varepsilon^2 = %.1f$, T&#345;. 2 &rarr; $D/t \\leq 70\\varepsilon^2 = %.1f$ &nbsp; ($\\varepsilon = \\sqrt{235/f_y} = %.3f$)</p>', ...
    50*epsilon^2, 70*epsilon^2, epsilon);

%% ── SECTION 4: Zatížení ──────────────────────────────────────────────
w(fid, '<h2>3. Zat&#237;&#382;en&#237;</h2>');

% Characteristic values table
w(fid, '<table><tr><th>Zat&#237;&#382;en&#237;</th><th>Symbol</th><th>Charakt. hodnota [kN/m&sup2;]</th></tr>');
wf(fid, '<tr><td>St&#345;e&scaron;n&#237; pl&#225;&scaron;&#357; (st&#225;l&#233;)</td><td>g<sub>k</sub></td><td style="text-align:right">%.2f</td></tr>', params.g_roof);
wf(fid, '<tr><td>Sn&#237;h (charakt.)</td><td>s<sub>k</sub></td><td style="text-align:right">%.2f</td></tr>', params.s_k);
if isfield(loadParams, 'q_Wt')
    wf(fid, '<tr><td>V&#237;tr — p&#345;&#237;&#269;n&#253; (s&#225;n&#237;, nahoru)</td><td>q<sub>Wt</sub></td><td style="text-align:right">%.3f</td></tr>', loadParams.q_Wt);
    wf(fid, '<tr><td>V&#237;tr — pod&#233;ln&#253; (s&#225;n&#237;, nahoru)</td><td>q<sub>Wl</sub></td><td style="text-align:right">%.3f</td></tr>', loadParams.q_Wl);
else
    wf(fid, '<tr><td>S&#225;n&#237; v&#283;tru (nahoru)</td><td>w<sub>k</sub></td><td style="text-align:right">%.2f</td></tr>', params.w_suction);
end
w(fid, '</table>');

% Dead load (Jandera formula)
w(fid, '<div class="fbox">');
w(fid, '<strong>Vlastn&#237; t&#237;ha vazn&#237;ku</strong> &nbsp;<span class="ref">(Jandera &mdash; OK&nbsp;01, kap.&nbsp;1.4.4)</span>');
wf(fid, '<div class="step">$g_{self} = \\dfrac{L}{76} \\cdot \\sqrt{(g_k + s_k) \\cdot d} = \\dfrac{%.0f}{76} \\cdot \\sqrt{%.2f \\cdot %.1f} = \\mathbf{%.3f}$ kN/m&sup2;</div>', ...
    L, g_d, params.truss_spacing, g_self);
wf(fid, '<div class="step">$g_{total} = g_k + g_{self} = %.2f + %.3f = \\mathbf{%.3f}$ kN/m&sup2; &nbsp;&nbsp; (horn&#237; mez &mdash; pro KZS 1&ndash;3)</div>', ...
    params.g_roof, g_self, g_total);
wf(fid, '<div class="step">$g_{min} = g_k + 0{,}5 \\cdot g_{self} = %.2f + 0{,}5 \\cdot %.3f = \\mathbf{%.3f}$ kN/m&sup2; &nbsp;&nbsp; (doln&#237; mez &mdash; pro KZS 4&ndash;5)</div>', ...
    params.g_roof, g_self, g_min);
w(fid, '</div>');

% Snow (EN 1991-1-3)
w(fid, '<div class="fbox">');
w(fid, '<strong>Sn&#237;h</strong> &nbsp;<span class="ref">(EN 1991-1-3, Cl. 5.3.3)</span>');
wf(fid, '<div class="step">$s = \\mu_1 \\cdot C_e \\cdot C_t \\cdot s_k = %.1f \\cdot 1{,}0 \\cdot 1{,}0 \\cdot %.2f = \\mathbf{%.3f}$ kN/m&sup2;</div>', ...
    mu1, loadParams.s_k, s_d);
wf(fid, '<div class="step">$\\mu_1 = %.1f$ &mdash; tvarov&#253; sou&#269;initel pro sedlovou st&#345;echu, $\\alpha \\leq 30^\\circ$ &nbsp;<span class="ref">[Tab. 5.2]</span></div>', mu1);
w(fid, '</div>');

% Wind (EN 1991-1-4) — only if computed
if isfield(loadParams, 'q_p')
    w(fid, '<div class="wbox">');
    w(fid, '<strong>V&#237;tr</strong> &nbsp;<span class="ref">(EN 1991-1-4)</span>');
    wf(fid, '<div class="step">$q_b = \\frac{1}{2} \\rho v_b^2 = \\frac{1}{2} \\cdot 1{,}25 \\cdot %.1f^2 = \\mathbf{%.3f}$ kN/m&sup2; &nbsp;&nbsp;($v_b = %.1f$ m/s, ter&#233;n %s)</div>', ...
        loadParams.v_b, loadParams.q_b, loadParams.v_b, loadParams.terrain_cat);
    wf(fid, '<div class="step">$c_e(h) = %.2f$ &nbsp;&rarr;&nbsp; $q_p = c_e \\cdot q_b = %.2f \\cdot %.3f = \\mathbf{%.3f}$ kN/m&sup2; &nbsp;&nbsp;($h_{heben} = %.1f$ m)</div>', ...
        loadParams.c_e, loadParams.c_e, loadParams.q_b, loadParams.q_p, loadParams.h_ridge);
    alpha_deg = atan(params.slope)*180/pi;
    wf(fid, '<div class="step">P&#345;&#237;&#269;n&#253; v&#237;tr &mdash; z&#243;na H, $\\alpha = %.1f^\\circ$: $c_{pe} = %.2f$ &nbsp;&rarr;&nbsp; $q_{Wt} = |c_{pe}| \\cdot q_p = \\mathbf{%.3f}$ kN/m&sup2;</div>', ...
        alpha_deg, loadParams.c_pe_Wt, loadParams.q_Wt);
    wf(fid, '<div class="step">Pod&#233;ln&#253; v&#237;tr &mdash; z&#243;na H, $\\theta = 90^\\circ$: $c_{pe} = %.2f$ &nbsp;&rarr;&nbsp; $q_{Wl} = \\mathbf{%.3f}$ kN/m&sup2;</div>', ...
        loadParams.c_pe_Wl, loadParams.q_Wl);
    w(fid, '</div>');
end

% KZS combinations table
ncombos = numel(results.combos);
w(fid, '<p><strong>Kombinace zat&#237;&#382;en&#237; (MSÚ) &mdash; EN 1990, Eq. 6.10</strong></p>');
w(fid, ['<table><tr>'...
         '<th>KZS</th><th>Popis</th>'...
         '<th>&gamma;<sub>G</sub></th>'...
         '<th>q<sub>G</sub> [kN/m&sup2;]</th>'...
         '<th>q<sub>S</sub> [kN/m&sup2;]</th>'...
         '<th>q<sub>W</sub> [kN/m&sup2;]</th>'...
         '<th>q<sub>net</sub> [kN/m&sup2;]</th>'...
         '</tr>']);
for ic = 1:ncombos
    cc = results.combos{ic};
    % Colour negative q_net (uplift) differently
    if cc.q_net < 0
        row_style = ' style="color:#721c24"';
    else
        row_style = '';
    end
    wf(fid, ['<tr%s>'...
             '<td style="text-align:center"><strong>%d</strong></td>'...
             '<td>%s</td>'...
             '<td style="text-align:center">%.2f</td>'...
             '<td style="text-align:right">%.3f</td>'...
             '<td style="text-align:right">%.3f</td>'...
             '<td style="text-align:right">%.3f</td>'...
             '<td style="text-align:right"><strong>%.3f</strong></td>'...
             '</tr>'], ...
        row_style, ic, cc.description, cc.gamma_G, cc.q_G, cc.q_S, cc.q_W, cc.q_net);
end
w(fid, '</table>');
w(fid, '<p class="ref">q<sub>S</sub>, q<sub>W</sub> jsou v&#253;po&#269;tov&#233; hodnoty v&#269;etn&#283; &gamma; a &psi;. q<sub>W</sub> > 0 = sn&#237;&#382;en&#237; v&yacute;sledn&#233;ho zat&#237;&#382;en&#237; (v&#237;tr zvedá st&#345;echu).</p>');

% --- Obrázky zatěžovacích stavů (KZS) ------------------------------------
w(fid, '<p><strong>Sch&#233;mata zat&#283;&#382;ovac&#237;ch stav&#367;</strong></p>');
prevVisible = get(0, 'DefaultFigureVisible');
set(0, 'DefaultFigureVisible', 'off');
for ic = 1:ncombos
    hfig = plotTrussFn(nodes, members, results.combos{ic}.loads, kinematic);
    title(hfig.CurrentAxes, sprintf('KZS %d: %s', ic, ...
        strrep(strrep(regexprep(results.combos{ic}.description, '<[^>]+>', ''), ...
        '&middot;', char(183)), '&nbsp;', ' ')));
    tmpPng = [tempname '.png'];
    print(hfig, tmpPng, '-dpng', '-r150');
    close(hfig);
    imgBytes = fileread_binary(tmpPng);
    b64 = base64encode(imgBytes);
    delete(tmpPng);
    wf(fid, '<div style="text-align:center;margin:8px 0"><img src="data:image/png;base64,%s" style="max-width:100%%;border:1px solid #dee2e6;border-radius:4px;" alt="KZS %d"></div>', ...
        b64, ic);
end
set(0, 'DefaultFigureVisible', prevVisible);

%% ── SECTION 5: Vzpěrné délky ─────────────────────────────────────────
w(fid, '<h2>4. Vzp&#283;rn&#233; d&#233;lky</h2>');
wf(fid, '<p class="ref">Pravidla dle Tab.&nbsp;1.29 (Jandera &mdash; OK&nbsp;01). Trubkov&yacute; vazn&#237;k. Vzp&#283;rn&#225; d&#233;lka doln&#237;ho p&#225;su z roviny = vzd&#225;lenost svislych zt&#250;&#382;idel = <strong>%.1f m</strong>.</p>', ...
    loadParams.bracing_spacing);

w(fid, ['<table><tr>'...
         '<th>Typ prutu</th>'...
         '<th>L<sub>cr,v&nbsp;rovine</sub></th>'...
         '<th>L<sub>cr,z&nbsp;roviny</sub></th>'...
         '</tr>']);
rules_all = {
    "top_chord",    'Horn&#237; p&#225;s',  'L<sub>sys</sub>',                   '0,9 &middot; a';
    "bottom_chord", 'Doln&#237; p&#225;s',  'L<sub>sys</sub>',                   'vzd. zt&#250;&#382;idel';
    "diagonal",     'Diagon&#225;la',       '0,9 &middot; L<sub>sys</sub>',      '0,75 &middot; L<sub>sys</sub>';
    "vertical",     'Svislice',             '0,9 &middot; L<sub>sys</sub>',      '0,75 &middot; L<sub>sys</sub>';
};
for k = 1:size(rules_all, 1)
    if ~any(results.classification.type == rules_all{k,1}); continue; end
    wf(fid, '<tr><td>%s</td><td>%s</td><td>%s</td></tr>', rules_all{k,2}, rules_all{k,3}, rules_all{k,4});
end
w(fid, '</table>');

type_keys = ["top_chord","bottom_chord","diagonal","vertical"];
type_disp = {'Horn&#237; p&#225;s','Doln&#237; p&#225;s','Diagon&#225;la','Svislice'};
w(fid, ['<table><tr>'...
         '<th>Typ prutu</th>'...
         '<th>L<sub>cr,in</sub> min [m]</th><th>L<sub>cr,in</sub> max [m]</th>'...
         '<th>L<sub>cr,out</sub> min [m]</th><th>L<sub>cr,out</sub> max [m]</th>'...
         '<th>L<sub>cr,gov</sub> max [m]</th>'...
         '</tr>']);
for k = 1:4
    mask = results.classification.type == type_keys(k);
    if ~any(mask); continue; end
    lin  = results.Lcr.in_plane(mask);
    lout = results.Lcr.out_of_plane(mask);
    lgov = results.Lcr.governing(mask);
    wf(fid, '<tr><td>%s</td><td>%.2f</td><td>%.2f</td><td>%.2f</td><td>%.2f</td><td><strong>%.2f</strong></td></tr>', ...
        type_disp{k}, min(lin), max(lin), min(lout), max(lout), max(lgov));
end
w(fid, '</table>');

%% ── SECTION 6: Metodika posudku ──────────────────────────────────────
w(fid, '<h2>5. Metodika posudku</h2>');

% Material
w(fid, '<div class="fbox">');
w(fid, '<strong>Materi&#225;l</strong> &nbsp;<span class="ref">[EN 1993-1-1, §3.2]</span><br>');
wf(fid, '&nbsp;&nbsp; $f_y = %.0f$ MPa, &nbsp; $E = %.0f$ GPa, &nbsp; $\\gamma_{M0} = 1{,}0$, &nbsp; $\\gamma_{M1} = 1{,}0$ &nbsp;<span class="ref">(&#268;SN EN 1993-1-1/NA)</span>', ...
    fy_MPa, E_GPa);
w(fid, '</div>');

% Cross-section class
w(fid, '<div class="fbox">');
w(fid, '<strong>T&#345;&#237;da pr&#367;&#345;ezu CHS</strong> &nbsp;<span class="ref">[EN 1993-1-1, Tab. 5.2]</span><br>');
wf(fid, '<div class="step">$\\varepsilon = \\sqrt{\\dfrac{235}{f_y}} = \\sqrt{\\dfrac{235}{%.0f}} = %.3f$</div>', fy_MPa, epsilon);
wf(fid, '<div class="step">T&#345;&#237;da 1: $D/t \\leq 50\\varepsilon^2 = %.1f$ &nbsp;|&nbsp; T&#345;&#237;da 2: $D/t \\leq 70\\varepsilon^2 = %.1f$ &nbsp;|&nbsp; T&#345;&#237;da 3: $D/t \\leq 90\\varepsilon^2 = %.1f$</div>', ...
    50*epsilon^2, 70*epsilon^2, 90*epsilon^2);
w(fid, '</div>');

% Tension / compression cross-section resistance
w(fid, '<div class="fbox">');
w(fid, '<strong>Odolnost pr&#367;&#345;ezu</strong> &nbsp;<span class="ref">[EN 1993-1-1, Cl. 6.2.3 / 6.2.4]</span><br>');
w(fid, '<div class="step">$N_{pl,Rd} = A \\cdot f_y \\;/\\; \\gamma_{M0}$</div>');
w(fid, '<div class="step">Tah: &nbsp;$N_{Ed} / N_{pl,Rd} \\leq 1{,}0$ &nbsp;&nbsp; Tlak: &nbsp;v&#382;dy rozhoduje vzp&#283;rn&#253; posudek ($\\chi \\leq 1$)</div>');
w(fid, '</div>');

% Buckling
w(fid, '<div class="fbox">');
w(fid, '<strong>Vzp&#283;rn&#225; odolnost &mdash; ohybov&yacute; vzp&#283;r</strong> &nbsp;<span class="ref">[EN 1993-1-1, Cl. 6.3.1]</span><br>');
wf(fid, '<div class="step">$\\lambda_1 = \\pi \\sqrt{E/f_y} = \\pi \\sqrt{%.0f/%.0f} = %.2f$</div>', E_GPa*1e9, params.f_y, lambda_1);
w(fid, '<div class="step">$\\bar{\\lambda} = \\dfrac{L_{cr}/i}{\\lambda_1}$ &nbsp;<span class="ref">[Eq. 6.50]</span></div>');
w(fid, '<div class="step">$\\Phi = 0{,}5 \\left[1 + \\alpha(\\bar{\\lambda}-0{,}2) + \\bar{\\lambda}^2\\right]$</div>');
w(fid, '<div class="step">$\\chi = \\dfrac{1}{\\Phi + \\sqrt{\\Phi^2 - \\bar{\\lambda}^2}} \\leq 1{,}0$ &nbsp;<span class="ref">[Eq. 6.49]</span></div>');
w(fid, '<div class="step">$N_{b,Rd} = \\chi \\cdot A \\cdot f_y \\;/\\; \\gamma_{M1}$ &nbsp;<span class="ref">[Eq. 6.47]</span></div>');
wf(fid, '<div class="step">CHS horn&#283; v&#225;lco van&#233; &rarr; <strong>k&#345;ivka a</strong>, $\\alpha = 0{,}21$ &nbsp;<span class="ref">[Tab. 6.2]</span></div>');
w(fid, '</div>');

%% ── SECTION 7: Ukázka výpočtu ────────────────────────────────────────
w(fid, '<h2>6. Uk&#225;zka v&yacute;po&#269;tu &mdash; kritick&#253; prut</h2>');

si_D  = sections.D(si_crit) * 1e3;
si_t  = sections.t(si_crit) * 1e3;
si_A  = sections.A(si_crit) * 1e4;
si_i  = sections.i_radius(si_crit) * 1e3;
si_fy = fy_MPa;

w(fid, '<div class="fbox">');
wf(fid, '<strong>Prut #%d &mdash; %s, KZS&nbsp;%d: %s</strong><br>', ...
    p_crit, translateType(results.classification.type(p_crit)), ...
    ic_crit, results.combos{ic_crit}.description);
wf(fid, '<div class="step">Pr&#367;&#345;ez: TR&nbsp;%.0f&times;%.1f, &nbsp; $A = %.2f$ cm&sup2;, &nbsp; $i = %.1f$ mm, &nbsp; k&#345;ivka&nbsp;<strong>%s</strong> ($\\alpha = %.2f$)</div>', ...
    si_D, si_t, si_A, si_i, sections.curve{si_crit}, alpha_crit);
w(fid, '<br>');

% Vzpěrná délka
w(fid, '<strong>1. Vzp&#283;rn&#225; d&#233;lka</strong>');
wf(fid, '<div class="step">$L_{cr,in} = %.2f$ m, &nbsp; $L_{cr,out} = %.2f$ m</div>', ...
    Lcr_in_crit, Lcr_out_crit);
wf(fid, '<div class="step">$L_{cr} = \\max(L_{cr,in},\\ L_{cr,out}) = \\max(%.2f,\\ %.2f) = \\mathbf{%.2f}$ m</div>', ...
    Lcr_in_crit, Lcr_out_crit, Lcr_gov_crit);

% Štíhlost
w(fid, '<br><strong>2. &#352;t&#237;hlost</strong>');
slenderness = Lcr_gov_crit / (sections.i_radius(si_crit));
wf(fid, '<div class="step">$L_{cr}/i = %.2f / %.4f = %.1f$</div>', ...
    Lcr_gov_crit, sections.i_radius(si_crit), slenderness);
wf(fid, '<div class="step">$\\bar{\\lambda} = \\dfrac{L_{cr}/i}{\\lambda_1} = \\dfrac{%.1f}{%.2f} = \\mathbf{%.3f}$</div>', ...
    slenderness, lambda_1, lb_crit);

% Vzpěrnostní součinitel
w(fid, '<br><strong>3. Vzp&#283;rnostn&#237; sou&#269;initel $\\chi$</strong>');
wf(fid, '<div class="step">$\\Phi = 0{,}5 \\left[1 + %.2f\\cdot(%.3f - 0{,}2) + %.3f^2\\right] = \\mathbf{%.4f}$</div>', ...
    alpha_crit, lb_crit, lb_crit, Phi_crit);
wf(fid, '<div class="step">$\\chi = \\dfrac{1}{%.4f + \\sqrt{%.4f^2 - %.3f^2}} = \\mathbf{%.4f}$</div>', ...
    Phi_crit, Phi_crit, lb_crit, chk_crit.chi);

% Únosnost a posouzení
if N_Ed_crit < 0
    % Compression — buckling
    w(fid, '<br><strong>4. &#218;nosnost ve vzp&#283;ru</strong>');
    wf(fid, '<div class="step">$N_{b,Rd} = \\chi \\cdot A \\cdot f_y / \\gamma_{M1} = %.4f \\cdot %.2f{\\cdot}10^{-4} \\cdot %.0f{\\cdot}10^6 / 1{,}0 = \\mathbf{%.1f}$ kN</div>', ...
        chk_crit.chi, sections.A(si_crit)*1e4, fy_MPa, chk_crit.N_b_Rd);
    w(fid, '<br><strong>5. Posouzen&#237;</strong>');
    util_val = chk_crit.util_max;
    check_sym = '\\leq 1{,}0';
    if util_val > 1.0; check_sym = '> 1{,}0'; end
    wf(fid, '<div class="step">$\\dfrac{|N_{Ed}|}{N_{b,Rd}} = \\dfrac{%.1f}{%.1f} = \\mathbf{%.3f}$ &nbsp; $%s$ &nbsp;&nbsp; &rarr; &nbsp; <strong>%s</strong></div>', ...
        abs(N_Ed_crit), chk_crit.N_b_Rd, util_val, check_sym, chk_crit.status);
else
    % Tension
    w(fid, '<br><strong>4. &#218;nosnost v tahu</strong>');
    wf(fid, '<div class="step">$N_{pl,Rd} = A \\cdot f_y / \\gamma_{M0} = %.2f{\\cdot}10^{-4} \\cdot %.0f{\\cdot}10^6 / 1{,}0 = \\mathbf{%.1f}$ kN</div>', ...
        sections.A(si_crit)*1e4, fy_MPa, chk_crit.N_pl_Rd);
    w(fid, '<br><strong>5. Posouzen&#237;</strong>');
    util_val = chk_crit.util_max;
    check_sym = '\\leq 1{,}0';
    if util_val > 1.0; check_sym = '> 1{,}0'; end
    wf(fid, '<div class="step">$\\dfrac{N_{Ed}}{N_{pl,Rd}} = \\dfrac{%.1f}{%.1f} = \\mathbf{%.3f}$ &nbsp; $%s$ &nbsp;&nbsp; &rarr; &nbsp; <strong>%s</strong></div>', ...
        N_Ed_crit, chk_crit.N_pl_Rd, util_val, check_sym, chk_crit.status);
end
w(fid, '</div>');

%% ── SECTION 8: Tabulka prutů ─────────────────────────────────────────
w(fid, '<h2 id="s8">7. V&yacute;sledky &mdash; tabulka prut&#367;</h2>');
w(fid, ['<table>'...
         '<tr><th>#</th><th>Typ</th>'...
         '<th>N<sub>Ed</sub><br>[kN]</th>'...
         '<th>KZS</th>'...
         '<th>L<sub>cr</sub><br>[m]</th>'...
         '<th>&lambda;&#773;</th>'...
         '<th>&chi;</th>'...
         '<th>N<sub>b,Rd</sub><br>[kN]</th>'...
         '<th>Vyu&#382;it&#237;<br>[&mdash;]</th>'...
         '<th>Status</th></tr>']);

for p = 1:nmembers
    ic  = results.governing_combo(p);
    chk = results.checks{ic}(p);
    ned = results.N_Ed(p, ic);
    u   = results.util_max(p);

    if strcmp(chk.status,'FAIL')
        row_cls = ' class="fail"';
    elseif u > 0.85
        row_cls = ' class="warn"';
    else
        row_cls = '';
    end

    type_cs = translateType(results.classification.type(p));

    wf(fid, '<tr%s>', row_cls);
    wf(fid, '<td style="text-align:center">%d</td>', p);
    wf(fid, '<td>%s</td>', type_cs);
    wf(fid, '<td style="text-align:right">%.1f</td>', ned);
    wf(fid, '<td style="text-align:center">%d</td>', ic);
    wf(fid, '<td style="text-align:right">%.2f</td>', results.Lcr.governing(p));
    wf(fid, '<td style="text-align:right">%.2f</td>', chk.lambda_bar);
    wf(fid, '<td style="text-align:right">%.3f</td>', chk.chi);
    wf(fid, '<td style="text-align:right">%.1f</td>', chk.N_b_Rd);
    wf(fid, '<td style="text-align:right"><strong>%.3f</strong></td>', u);
    wf(fid, '<td style="text-align:center">%s</td>', chk.status);
    w(fid,  '</tr>');
end
w(fid, '</table>');

% Dynamic footnotes for all combos
fn_parts = cell(1, ncombos);
for ic = 1:ncombos
    fn_parts{ic} = sprintf('&sup%s; = %s', ...
        footnoteNum(ic), results.combos{ic}.description);
end
wf(fid, '<p class="ref">Barva: b&#237;l&#225; = OK, &#382;lut&#225; = upozorn&#283;n&#237; (util &gt; 0,85), &#269;erven&#225; = NEVYHOVUJE (util &gt; 1,0). KZS = rozhoduj&#237;c&#237; kombinace: &nbsp; %s</p>', ...
    strjoin(fn_parts, ';&nbsp; '));

%% ── SECTION 9: Souhrn ────────────────────────────────────────────────
w(fid, '<h2>8. Souhrn</h2>');
[u_max, p_max] = max(results.util_max);
ic_max = results.governing_combo(p_max);
n_fail = sum(results.util_max > 1.0);
n_warn = sum(results.util_max > 0.85 & results.util_max <= 1.0);

wf(fid, '<div class="sbox" style="background:%s;color:%s;border:2px solid %s;">', sbg, sc, sb);
wf(fid, 'Celkov&yacute; v&yacute;sledek: <span style="font-size:15pt">&nbsp; %s &nbsp;</span><br>', results.status);
w(fid, '<span style="font-size:10pt;font-weight:normal">');
wf(fid, 'Max. vyu&#382;it&#237;: <strong>%.3f</strong> &nbsp;&mdash;&nbsp; prut %d (%s), KZS %d<br>', ...
    u_max, p_max, translateType(results.classification.type(p_max)), ic_max);
wf(fid, 'Prut&#367; NEVYHOVUJE: <strong>%d / %d</strong> &nbsp;|&nbsp; s upozorn&#283;n&#237;m (&gt;85&nbsp;%%): <strong>%d / %d</strong>', ...
    n_fail, nmembers, n_warn, nmembers);
w(fid, '</span></div>');

%% ── Footer ───────────────────────────────────────────────────────────
wf(fid, '<p class="ref" style="margin-top:40px;text-align:right;border-top:1px solid #dee2e6;padding-top:6px;">Generov&aacute;no: MATLAB <code>reportFn.m</code> &mdash; %s</p>', datestr(now));
w(fid, '</body></html>');

fprintf('Report ulozen: %s\n', filename);

end   % end reportFn

%% ── Local helpers ────────────────────────────────────────────────────
function w(fid, str)
    fprintf(fid, '%s\n', str);
end

function wf(fid, fmt, varargin)
    fprintf(fid, [fmt '\n'], varargin{:});
end

function alpha = curveAlpha(curve)
    switch lower(char(curve))
        case 'a0', alpha = 0.13;
        case 'a',  alpha = 0.21;
        case 'b',  alpha = 0.34;
        case 'c',  alpha = 0.49;
        case 'd',  alpha = 0.76;
        otherwise, alpha = 0.21;
    end
end

function s = footnoteNum(n)
    % Returns HTML superscript entity for n = 1..5
    entities = {'1','2','3','4','5','6','7','8','9'};
    if n <= numel(entities)
        s = entities{n};
    else
        s = num2str(n);
    end
end

function s = translateType(t)
    switch char(t)
        case 'top_chord',    s = 'Horn&#237; p&#225;s';
        case 'bottom_chord', s = 'Doln&#237; p&#225;s';
        case 'diagonal',     s = 'Diagon&#225;la';
        case 'vertical',     s = 'Svislice';
        otherwise,           s = char(t);
    end
end

function s = num2strOrDash(v)
    if isnan(v);  s = '&mdash;';
    else;         s = sprintf('%d', v);
    end
end

function s = translateTopology(t)
    switch lower(char(t))
        case 'pratt',            s = 'Pratt';
        case 'howe',             s = 'Howe';
        case 'warren',           s = 'Warren';
        case 'warren_inverted',  s = 'Warren&nbsp;(invertovan&yacute;)';
        otherwise,               s = upper(char(t));
    end
end

function s = translateShape(t)
    switch lower(char(t))
        case 'saddle',  s = 'Sedlov&#253;';
        case 'flat',    s = 'Rovn&#253;';
        case 'mono',    s = 'Pultov&#253;&nbsp;&#353;ikm&#253;';
        otherwise,      s = char(t);
    end
end

function bytes = fileread_binary(filepath)
    f = fopen(filepath, 'rb');
    bytes = fread(f, inf, 'uint8=>uint8')';
    fclose(f);
end

function s = base64encode(bytes)
    encoder = org.apache.commons.codec.binary.Base64;
    s = char(encoder.encodeBase64(bytes))';
    s = s(:)';   % ensure row vector
end
