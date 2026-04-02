function reportFn(params, nodes, members, sections, loadParams, results, filename)
% reportFn  Generate a self-contained HTML engineering calculation report.
%
% Produces a professional HTML file documenting the EN 1993-1-1 design check
% of a steel Pratt truss girder.  The file can be opened in any browser and
% printed / exported to PDF (Ctrl+P in Chrome/Firefox → Save as PDF).
%
% Report sections:
%   1. Záhlaví (header)
%   2. Geometrie vazníku
%   3. Průřezy
%   4. Zatížení (char. hodnoty + vlastní tíha + kombinace)
%   5. Vzpěrné délky (Tab. 1.29)
%   6. Metodika posudku (EN 1993-1-1 formule s citacemi)
%   7. Výsledky — tabulka prutů (barevně kódovaná)
%   8. Souhrn (OK / FAIL)
%
% INPUTS:
%   params     - struct from trussHallInputFn (span, slope, f_y, loads, …)
%   nodes      - struct with .x, .z
%   members    - struct with .nodesHead, .nodesEnd, .sections
%   sections   - struct with .A, .E, .I, .i_radius, .curve, .D, .t
%   loadParams - struct from trussHallInputFn (g_total, g_min, …)
%   results    - struct from designCheckFn
%   filename   - output HTML file path (default: 'vaznik_posudek.html')
%
% EXAMPLE:
%   reportFn(params, nodes, members, sections, loadParams, results, ...
%            'posudek_vaznik_30m.html');
%
% (c) S. Glanc, 2026

if nargin < 7 || isempty(filename)
    filename = 'vaznik_posudek.html';
end

fid = fopen(filename, 'w', 'n', 'UTF-8');
if fid < 0
    error('reportFn: Cannot open ''%s'' for writing.', filename);
end
c = onCleanup(@() fclose(fid));   % ensure file is closed even on error

%% ── Precompute scalars ────────────────────────────────────────────────
L        = params.span;
fy_MPa   = params.f_y / 1e6;
E_GPa    = params.E   / 1e9;
nmembers = numel(members.nodesHead);
epsilon  = sqrt(235 / fy_MPa);

% Replicate self-weight formula (Jandera OK-01, kap. 1.4.4)
g_d      = params.g_roof + params.s_k;
g_self   = L / 76 * sqrt(g_d * params.truss_spacing);
g_total  = params.g_roof + g_self;
g_min    = params.g_roof + 0.5 * g_self;

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
% MathJax for inline TeX (optional, loads from CDN)
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
w(fid, '.sbox{padding:14px 20px;border-radius:6px;font-size:12.5pt;font-weight:bold;text-align:center;margin-top:20px;}');
w(fid, '.meta{color:var(--gray);font-size:9.5pt;margin-bottom:20px;}');
w(fid, '@media print{');
w(fid, ' body{max-width:100%;padding:8mm 10mm;}');
w(fid, ' h2{page-break-after:avoid;}');
w(fid, ' .no-print{display:none;}');
w(fid, ' #s7{page-break-before:always;}');
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

% Topology and shape (read from loadParams if available, else params, else defaults)
if isfield(loadParams, 'topology'),  topo_key  = loadParams.topology;
elseif isfield(params, 'topology'),  topo_key  = params.topology;
else;                                topo_key  = 'pratt';
end
if isfield(loadParams, 'shape'),     shape_key = loadParams.shape;
elseif isfield(params, 'shape'),     shape_key = params.shape;
else;                                shape_key = 'saddle';
end

% Max height label and value depend on chord shape
switch lower(shape_key)
    case 'flat'
        h_max_str   = sprintf('%.2f', params.h_support);
        h_max_label = 'V&yacute;&scaron;ka (konstantn&#237;)';
    case 'mono'
        h_max_str   = sprintf('%.2f', params.h_support + params.slope * L);
        h_max_label = 'Max. v&yacute;&scaron;ka (napravo)';
    otherwise  % saddle
        h_max_str   = sprintf('%.2f', params.h_support + params.slope * L/2);
        h_max_label = 'Max. v&yacute;&scaron;ka (uprost&#345;ed)';
end

geom = {
    'Rozp&#283;t&#237;',                  'L',  sprintf('%.0f',  L),                     'm';
    'Sklon st&#345;echy',                 '&mdash;', sprintf('%.0f %%', params.slope*100),'&mdash;';
    'V&yacute;&scaron;ka v ulo&#382;en&#237;', 'h',  sprintf('%.2f',  params.h_support),  'm';
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
w(fid, '<h2>2. Pr&#367;&#345;ezy (ocel S355, CHS horn&#283; v&#225;lco van&#233;)</h2>');
w(fid, ['<table><tr><th>Skupina</th><th>Ozna&#269;en&#237;</th>'...
         '<th>D [mm]</th><th>t [mm]</th><th>A [cm&sup2;]</th>'...
         '<th>I [cm<sup>4</sup>]</th><th>i [mm]</th><th>D/t</th>'...
         '<th>T&#345;&#237;da&sup1;</th><th>K&#345;ivka vzp.</th></tr>']);
sec_names = {'Horn&#237; p&#225;s', 'Doln&#237; p&#225;s', 'V&yacute;pl&#328;'};
for sg = 1:3
    D_mm  = sections.D(sg)*1e3;
    t_mm  = sections.t(sg)*1e3;
    A_cm2 = sections.A(sg)*1e4;
    I_cm4 = sections.I(sg)*1e8;
    i_mm  = sections.i_radius(sg)*1e3;
    dt    = D_mm/t_mm;
    % find section class from results
    p1 = find(members.sections == sg, 1);
    if ~isempty(p1)
        sc_val = results.checks{results.governing_combo(p1)}(p1).section_class;
        cls_str = num2strOrDash(sc_val);
    else; cls_str = '&mdash;'; end
    wf(fid, ['<tr><td>%s</td>'...
             '<td style="text-align:center">TR %.0f&times;%.1f</td>'...
             '<td style="text-align:right">%.0f</td>'...
             '<td style="text-align:right">%.1f</td>'...
             '<td style="text-align:right">%.2f</td>'...
             '<td style="text-align:right">%.1f</td>'...
             '<td style="text-align:right">%.1f</td>'...
             '<td style="text-align:right">%.1f</td>'...
             '<td style="text-align:center"><strong>%s</strong></td>'...
             '<td style="text-align:center">%s</td></tr>'], ...
        sec_names{sg}, D_mm, t_mm, D_mm, t_mm, A_cm2, I_cm4, i_mm, dt, cls_str, sections.curve{sg});
end
w(fid, '</table>');
wf(fid, '<p class="ref">&sup1; T&#345;&#237;da pr&#367;&#345;ezu CHS dle EN 1993-1-1, Tab. 5.2. L&#237;mit t&#345;&#237;dy 1: D/t &le; 50&varepsilon;&sup2; = %.1f &nbsp; (&varepsilon; = &radic;(235/f<sub>y</sub>) = %.3f pro S355)</p>', ...
    50*epsilon^2, epsilon);

%% ── SECTION 4: Zatížení ──────────────────────────────────────────────
w(fid, '<h2>3. Zat&#237;&#382;en&#237;</h2>');
w(fid, '<table><tr><th>Zat&#237;&#382;en&#237;</th><th>Symbol</th><th>Charakt. hodnota [kN/m&sup2;]</th></tr>');
wf(fid, '<tr><td>St&#345;e&scaron;n&#237; pl&#225;&scaron;&#357; (st&#225;l&#233;)</td><td>g<sub>k</sub></td><td style="text-align:right">%.2f</td></tr>', params.g_roof);
wf(fid, '<tr><td>Sn&#237;h</td><td>s<sub>k</sub></td><td style="text-align:right">%.2f</td></tr>', params.s_k);
wf(fid, '<tr><td>S&#225;n&#237; v&#283;tru (nahoru)</td><td>w<sub>k</sub></td><td style="text-align:right">%.2f</td></tr>', params.w_suction);
w(fid, '</table>');

w(fid, '<div class="fbox">');
w(fid, '<strong>Odhad vlastn&#237; t&#237;hy vazn&#237;ku</strong> (Jandera &mdash; OK&nbsp;01, kap.&nbsp;1.4.4):');
wf(fid, '<br>&nbsp;&nbsp;&nbsp;g<sub>self</sub> = L/76 &middot; &radic;(q<sub>d</sub>&middot;d) = %.0f/76 &middot; &radic;(%.2f&middot;%.1f) = <strong>%.3f kN/m&sup2;</strong>', ...
    L, g_d, params.truss_spacing, g_self);
wf(fid, '<br>&nbsp;&nbsp;&nbsp;g<sub>total</sub> = g<sub>k</sub> + g<sub>self</sub> = %.2f + %.3f = <strong>%.3f kN/m&sup2;</strong>', ...
    params.g_roof, g_self, g_total);
wf(fid, '<br>&nbsp;&nbsp;&nbsp;g<sub>min</sub> = g<sub>k</sub> + 0.5&middot;g<sub>self</sub> = %.2f + 0.5&middot;%.3f = <strong>%.3f kN/m&sup2;</strong>', ...
    params.g_roof, g_self, g_min);
w(fid, '</div>');

w(fid, '<table><tr><th>Kombina</th><th>Popis</th><th>&gamma;<sub>G</sub></th><th>&gamma;<sub>Q</sub></th><th>q<sub>net</sub> [kN/m&sup2;]</th></tr>');
for ic = 1:numel(results.combos)
    cc = results.combos{ic};
    wf(fid, '<tr><td style="text-align:center"><strong>%d</strong></td><td>%s</td><td style="text-align:center">%.2f</td><td style="text-align:center">%.2f</td><td style="text-align:right"><strong>%.3f</strong></td></tr>', ...
        ic, cc.description, cc.gamma_G, cc.gamma_Q, cc.q_net);
end
w(fid, '</table>');

%% ── SECTION 5: Vzpěrné délky ─────────────────────────────────────────
w(fid, '<h2>4. Vzp&#283;rn&#233; d&#233;lky</h2>');
wf(fid, '<p class="ref">Pravidla dle Tab.&nbsp;1.29 (Jandera &mdash; OK&nbsp;01). Trubkov&yacute; vazn&#237;k. Vzp&#283;rn&#225; d&#233;lka z roviny doln&#237;ho p&#225;su = vzd&#225;lenost svislych ztu&#382;idel = <strong>%.1f m</strong>.</p>', ...
    loadParams.bracing_spacing);

w(fid, ['<table><tr>'...
         '<th>Typ prutu</th>'...
         '<th>L<sub>cr,v rovine</sub></th>'...
         '<th>L<sub>cr,z roviny</sub></th>'...
         '</tr>']);
% Show only member types that are actually present in the model
rules_all = {
    "top_chord",    'Horn&#237; p&#225;s',  'L<sub>sys</sub> (vzd. uzl&#367;)',  '0.9 &middot; a (rozp. vaznic)';
    "bottom_chord", 'Doln&#237; p&#225;s',  'L<sub>sys</sub>',                   'vzd. zt&#250;&#382;idel';
    "diagonal",     'Diagon&#225;la',       '0.9 &middot; L<sub>sys</sub>',      '0.75 &middot; L<sub>sys</sub>';
    "vertical",     'Svislice',             '0.9 &middot; L<sub>sys</sub>',      '0.75 &middot; L<sub>sys</sub>';
};
for k = 1:size(rules_all, 1)
    if ~any(results.classification.type == rules_all{k,1}); continue; end
    wf(fid, '<tr><td>%s</td><td>%s</td><td>%s</td></tr>', rules_all{k,2}, rules_all{k,3}, rules_all{k,4});
end
w(fid, '</table>');

% Per-type actual values
type_keys = ["top_chord","bottom_chord","diagonal","vertical"];
type_disp = {'Horn&#237; p&#225;s','Doln&#237; p&#225;s','Diagon&#225;la','Svislice'};
w(fid, ['<table><tr>'...
         '<th>Typ prutu</th>'...
         '<th>L<sub>cr,in</sub> min [m]</th><th>L<sub>cr,in</sub> max [m]</th>'...
         '<th>L<sub>cr,out</sub> min [m]</th><th>L<sub>cr,out</sub> max [m]</th>'...
         '<th>L<sub>cr,gov</sub> max [m]</th>'...
         '</tr>']);
for k=1:4
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

w(fid, '<div class="fbox">');
w(fid, '<strong>T&#345;&#237;da pr&#367;&#345;ezu CHS</strong> &nbsp;<span class="ref">[EN 1993-1-1, Tab. 5.2]</span><br>');
wf(fid, '&nbsp;&nbsp;&nbsp;$\\varepsilon = \\sqrt{235/f_y} = \\sqrt{235/%.0f} = %.3f$<br>', fy_MPa, epsilon);
wf(fid, '&nbsp;&nbsp;&nbsp;T&#345;&#237;da 1: $D/t \\leq 50\\varepsilon^2 = %.1f$<br>', 50*epsilon^2);
wf(fid, '&nbsp;&nbsp;&nbsp;T&#345;&#237;da 2: $D/t \\leq 70\\varepsilon^2 = %.1f$', 70*epsilon^2);
w(fid, '</div>');

w(fid, '<div class="fbox">');
w(fid, '<strong>Odolnost pr&#367;&#345;ezu v tahu a tlaku</strong> &nbsp;<span class="ref">[EN 1993-1-1, Cl. 6.2.3 / 6.2.4]</span><br>');
w(fid, '&nbsp;&nbsp;&nbsp;$N_{pl,Rd} = A \cdot f_y / \gamma_{M0}$ &nbsp;&nbsp;&nbsp; ($\gamma_{M0} = 1{,}0$ dle &#268;SN EN 1993-1-1/NA)');
w(fid, '</div>');

lambda_1 = pi * sqrt(params.E / params.f_y);
w(fid, '<div class="fbox">');
w(fid, '<strong>Vzp&#283;rn&#225; odolnost &mdash; ohybov&yacute; vzp&#283;r</strong> &nbsp;<span class="ref">[EN 1993-1-1, Cl. 6.3.1]</span><br>');
wf(fid, '&nbsp;&nbsp;&nbsp;$\\lambda_1 = \\pi \\sqrt{E/f_y} = \\pi \\sqrt{%.0f/%.0f} = %.2f$<br>', E_GPa*1e9, params.f_y, lambda_1);
w(fid, '&nbsp;&nbsp;&nbsp;$\\bar{\\lambda} = \\dfrac{L_{cr}/i}{\\lambda_1}$ &nbsp;<span class="ref">[Eq. 6.50]</span><br>');
w(fid, '&nbsp;&nbsp;&nbsp;$\Phi = 0{,}5 \left[1 + \alpha(\bar{\lambda}-0{,}2) + \bar{\lambda}^2\right]$<br>');
w(fid, '&nbsp;&nbsp;&nbsp;$\chi = \dfrac{1}{\Phi + \sqrt{\Phi^2 - \bar{\lambda}^2}} \leq 1{,}0$ &nbsp;<span class="ref">[Eq. 6.49]</span><br>');
w(fid, '&nbsp;&nbsp;&nbsp;$N_{b,Rd} = \chi \cdot A \cdot f_y / \gamma_{M1}$ &nbsp;<span class="ref">[Eq. 6.47]</span>&nbsp;, &nbsp;$\gamma_{M1} = 1{,}0$<br>');
w(fid, '&nbsp;&nbsp;&nbsp;CHS horn&#283; v&#225;lco van&#233; &rarr; <strong>k&#345;ivka a</strong>, $\alpha = 0{,}21$ &nbsp;<span class="ref">[Tab. 6.2]</span>');
w(fid, '</div>');

w(fid, '<div class="fbox">');
w(fid, '<strong>Posouzeni:</strong><br>');
w(fid, '&nbsp;&nbsp;&nbsp;Tah:&nbsp;&nbsp; $N_{Ed} / N_{pl,Rd} \leq 1{,}0$<br>');
w(fid, '&nbsp;&nbsp;&nbsp;Tlak: $|N_{Ed}| / N_{b,Rd} \leq 1{,}0$ &nbsp;&nbsp; (vzp&#283;rn&yacute; posudek v&#382;dy rozhoduje, proto&#382;e $\chi \leq 1$)');
w(fid, '</div>');

%% ── SECTION 7: Tabulka prutů ─────────────────────────────────────────
w(fid, '<h2 id="s7">6. V&yacute;sledky &mdash; tabulka prut&#367;</h2>');
w(fid, ['<table>'...
         '<tr><th>#</th><th>Typ</th>'...
         '<th>N<sub>Ed</sub><br>[kN]</th>'...
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
    sup_str = sprintf('<sup>%d</sup>', ic);

    wf(fid, '<tr%s>', row_cls);
    wf(fid, '<td style="text-align:center">%d</td>', p);
    wf(fid, '<td>%s</td>', type_cs);
    wf(fid, '<td style="text-align:right">%.1f%s</td>', ned, sup_str);
    wf(fid, '<td style="text-align:right">%.2f</td>', results.Lcr.governing(p));
    wf(fid, '<td style="text-align:right">%.2f</td>', chk.lambda_bar);
    wf(fid, '<td style="text-align:right">%.3f</td>', chk.chi);
    wf(fid, '<td style="text-align:right">%.1f</td>', chk.N_b_Rd);
    wf(fid, '<td style="text-align:right"><strong>%.3f</strong></td>', u);
    wf(fid, '<td style="text-align:center">%s</td>', chk.status);
    w(fid,  '</tr>');
end
w(fid, '</table>');
wf(fid, ['<p class="ref">Barva: b&#237;l&#225; = OK, '...
         '&#382;lut&#225; = pozor (util &gt; 0.85), '...
         '&#269;erven&#225; = NEVYHOVUJE (util &gt; 1.0). '...
         'Hork&#233; &#269;&#237;slo: rozhoduj&#237;c&#237; kombinace '...
         '(&sup1; = %s, &sup2; = %s).</p>'], ...
    results.combos{1}.description, results.combos{2}.description);

%% ── SECTION 8: Souhrn ────────────────────────────────────────────────
w(fid, '<h2>7. Souhrn</h2>');
[u_max, p_max] = max(results.util_max);
ic_max = results.governing_combo(p_max);
n_fail = sum(results.util_max > 1.0);
n_warn = sum(results.util_max > 0.85 & results.util_max <= 1.0);

wf(fid, '<div class="sbox" style="background:%s;color:%s;border:2px solid %s;">', sbg, sc, sb);
wf(fid, 'Celkov&yacute; v&yacute;sledek: <span style="font-size:15pt">&nbsp; %s &nbsp;</span><br>', results.status);
wf(fid, '<span style="font-size:10pt;font-weight:normal">');
wf(fid, 'Max. vyu&#382;it&#237;: <strong>%.3f</strong> &nbsp;&mdash;&nbsp; prut %d (%s), kombina %d<br>', ...
    u_max, p_max, translateType(results.classification.type(p_max)), ic_max);
wf(fid, 'Prut&#367; NEVYHOVUJE: <strong>%d / %d</strong> &nbsp;|&nbsp; s upozorn&#283;n&#237;m (&gt;85&nbsp;%%): <strong>%d / %d</strong>', ...
    n_fail, nmembers, n_warn, nmembers);
w(fid, '</span></div>');

%% ── Footer ───────────────────────────────────────────────────────────
wf(fid, '<p class="ref" style="margin-top:40px;text-align:right;border-top:1px solid #dee2e6;padding-top:6px;">Generov&aacute;no: MATLAB <code>reportFn.m</code> &mdash; %s</p>', datestr(now));
w(fid, '</body></html>');

fprintf('Report ulo&#382;en: %s\n', filename);

end   % end reportFn

%% ── Local helpers ────────────────────────────────────────────────────
function w(fid, str)
    fprintf(fid, '%s\n', str);
end

function wf(fid, fmt, varargin)
    fprintf(fid, [fmt '\n'], varargin{:});
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
        case 'pratt',   s = 'Pratt';
        case 'howe',    s = 'Howe';
        case 'warren',  s = 'Warren';
        otherwise,      s = upper(char(t));
    end
end

function s = translateShape(t)
    switch lower(char(t))
        case 'saddle',  s = 'Sedlov&#253;';
        case 'flat',    s = 'Rovn&#253;';
        case 'mono',    s = 'Pultov&#253; &#353;ikm&#253;';
        otherwise,      s = char(t);
    end
end
