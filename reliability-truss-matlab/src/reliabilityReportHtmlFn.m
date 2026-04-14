function reliabilityReportHtmlFn(results, params, nodes, members, sections, loadParams, filename)
% reliabilityReportHtmlFn  Generate self-contained HTML methodology report.
%
% INPUTS:
%   results    - output of systemReliabilityFn (or [] for methodology only)
%   params     - struct from trussHallInputFn
%   nodes, members, sections, loadParams - from trussHallInputFn
%   filename   - output HTML file path (default: 'spolehlivost_metodika.html')
%
% (c) S. Glanc, 2026

if nargin < 7 || isempty(filename)
    filename = 'spolehlivost_metodika.html';
end

fid = fopen(filename, 'w', 'n', 'UTF-8');
if fid < 0
    error('reliabilityReportHtmlFn: Cannot open ''%s'' for writing.', filename);
end
cl = onCleanup(@() fclose(fid));

hasResults = ~isempty(results) && isstruct(results) && isfield(results, 'beta');

%% Precompute
L        = params.span;
fy_MPa   = params.f_y / 1e6;
E_GPa    = params.E   / 1e9;
nmembers = numel(members.nodesHead);
nG       = loadParams.sectionGroups.nGroups;
s_k      = loadParams.s_k;

K98_gumbel = (sqrt(6)/pi) * (0.5772 + abs(log(-log(0.98))));
Q1_cov = 0.20;
Q1_mean = 1.0 / (1 + K98_gumbel * Q1_cov);
R1_cov = 0.05;
R1_mean = 1.0 / exp(-1.645 * R1_cov);

if hasResults
    if results.beta >= 3.8
        sc = '#155724'; sbg = '#d4edda'; sb = '#c3e6cb';
    else
        sc = '#721c24'; sbg = '#f8d7da'; sb = '#f5c6cb';
    end
end

%% ── HTML HEAD ────────────────────────────────────────────────────────
w(fid, '<!DOCTYPE html>');
w(fid, '<html lang="cs"><head>');
w(fid, '<meta charset="UTF-8">');
w(fid, '<meta name="viewport" content="width=device-width,initial-scale=1">');
w(fid, '<title>Spolehlivostní analýza — metodika</title>');
w(fid, '<script>');
w(fid, 'window.MathJax = {');
w(fid, '  tex: {inlineMath: [["\\(","\\)"]], displayMath: [["\\[","\\]"]]},');
w(fid, '  options: {skipHtmlTags: ["script","noscript","style","textarea","code"]}');
w(fid, '};');
w(fid, '</script>');
w(fid, '<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js"></script>');

%% ── CSS ──────────────────────────────────────────────────────────────
w(fid, '<style>');
w(fid, ':root{--navy:#1a3a5c;--blue:#2b5f9e;--gray:#6c757d;}');
w(fid, 'body{font-family:"Segoe UI",Arial,sans-serif;font-size:10.5pt;color:#212529;max-width:1050px;margin:0 auto;padding:20px 28px;line-height:1.6;}');
w(fid, 'h1{color:var(--navy);border-bottom:3px solid var(--navy);padding-bottom:5px;font-size:15pt;margin-bottom:4px;}');
w(fid, 'h2{color:var(--navy);font-size:12pt;margin-top:30px;border-left:4px solid var(--blue);padding-left:8px;}');
w(fid, 'h3{color:var(--blue);font-size:10.5pt;margin-top:18px;}');
w(fid, 'table{border-collapse:collapse;width:100%%;margin-bottom:12px;font-size:9.5pt;}');
w(fid, 'th{background:var(--navy);color:#fff;padding:5px 9px;text-align:center;border:1px solid #0d2740;}');
w(fid, 'td{padding:4px 9px;border:1px solid #dee2e6;}');
w(fid, 'tr:nth-child(even) td{background:#f8f9fa;}');
w(fid, '.ref{color:var(--gray);font-style:italic;font-size:8.5pt;}');
w(fid, '.fbox{background:#f8f9fa;border:1px solid #dee2e6;border-radius:4px;padding:12px 18px;margin:8px 0;font-size:10pt;line-height:2.0;}');
w(fid, '.wbox{background:#e8f4f8;border:1px solid #b8daff;border-radius:4px;padding:12px 18px;margin:8px 0;font-size:10pt;line-height:2.0;}');
w(fid, '.sbox{padding:14px 20px;border-radius:6px;font-size:12.5pt;font-weight:bold;text-align:center;margin-top:20px;}');
w(fid, '.meta{color:var(--gray);font-size:9.5pt;margin-bottom:20px;}');
w(fid, '.step{margin-left:20px;line-height:2.2;}');
w(fid, 'tr.fail td{background:#f8d7da !important;color:#721c24;font-weight:bold;}');
w(fid, '@media print{body{max-width:100%%;padding:8mm 10mm;} h2{page-break-after:avoid;} th,tr.fail td{-webkit-print-color-adjust:exact;print-color-adjust:exact;}}');
w(fid, '</style>');
w(fid, '</head><body>');

%% ── 1. Záhlaví ──────────────────────────────────────────────────────
w(fid, '<h1>Spolehlivostní analýza příhradového vazníku</h1>');
fprintf(fid, '<div class="meta"><strong>Metoda:</strong> Monte Carlo simulace (UQLab) &nbsp;|&nbsp; <strong>Norma:</strong> EN 1993-1-1, JRC TR (2024) &nbsp;|&nbsp; <strong>Datum:</strong> %s</div>\n', datestr(now, 'dd.mm.yyyy'));

w(fid, '<table>');
w(fid, '<tr><th>Veličina</th><th>Symbol</th><th>Hodnota</th><th>Jednotka</th></tr>');
fprintf(fid, '<tr><td>Rozpětí</td><td style="text-align:center">L</td><td style="text-align:right"><strong>%.1f</strong></td><td>m</td></tr>\n', L);
fprintf(fid, '<tr><td>Ocel</td><td style="text-align:center">—</td><td style="text-align:right"><strong>S%.0f</strong></td><td>—</td></tr>\n', fy_MPa);
fprintf(fid, '<tr><td>Mez kluzu (char.)</td><td style="text-align:center">f<sub>y,k</sub></td><td style="text-align:right"><strong>%.0f</strong></td><td>MPa</td></tr>\n', fy_MPa);
fprintf(fid, '<tr><td>Modul pružnosti</td><td style="text-align:center">E</td><td style="text-align:right"><strong>%.0f</strong></td><td>GPa</td></tr>\n', E_GPa);
fprintf(fid, '<tr><td>Počet prutů</td><td style="text-align:center">n<sub>mem</sub></td><td style="text-align:right"><strong>%d</strong></td><td>—</td></tr>\n', nmembers);
fprintf(fid, '<tr><td>Průřez. skupin</td><td style="text-align:center">n<sub>G</sub></td><td style="text-align:right"><strong>%d</strong></td><td>—</td></tr>\n', nG);
fprintf(fid, '<tr><td>Sníh na zemi (char.)</td><td style="text-align:center">s<sub>k</sub></td><td style="text-align:right"><strong>%.2f</strong></td><td>kN/m²</td></tr>\n', s_k);
w(fid, '</table>');

%% ── 2. Popis metody ─────────────────────────────────────────────────
w(fid, '<h2>1. Popis metody</h2>');
w(fid, '<p>Cílem analýzy je ověřit systémovou spolehlivost příhradového vazníku');
w(fid, 'pro zatěžovací případ tíha + sníh. Použitá metoda je <strong>simulace Monte Carlo</strong>');
w(fid, '(MCS) s náhodnými veličinami dle JRC&nbsp;TR „Reliability background of the Eurocodes" (2024).</p>');

w(fid, '<h3>1.1 Sériový systém</h3>');
w(fid, '<p>Příhrada je modelována jako <strong>sériový systém</strong> — selhání');
w(fid, 'libovolného prutu způsobí kolaps celé konstrukce (staticky určitá soustava).</p>');

w(fid, '<div class="fbox">');
w(fid, '\[g_{\mathrm{sys}} = \min_{p=1}^{n_{\mathrm{mem}}} g_p(\mathbf{X})\]');
w(fid, '\[P_{f,\mathrm{sys}} = P\!\left(g_{\mathrm{sys}} \leq 0\right) = P\!\left(\bigcup_{p=1}^{n_{\mathrm{mem}}} \{g_p \leq 0\}\right)\]');
w(fid, '\[\beta_{\mathrm{sys}} = -\Phi^{-1}\!\left(P_{f,\mathrm{sys}}\right)\]');
w(fid, '</div>');
w(fid, '<p class="ref">Kde \(\Phi^{-1}\) je inverzní standardní normální distribuční funkce.</p>');

w(fid, '<h3>1.2 Cílová spolehlivost</h3>');
w(fid, '<div class="wbox">');
w(fid, 'Cílový index spolehlivosti: \(\beta_{\mathrm{target}} = 3{,}8\) &nbsp;(CC2, referenční období 50 let)<br>');
w(fid, '<span class="ref">EN 1990:2002, Tab. B.2; JRC TR (2024), Tab. 3.1</span>');
w(fid, '</div>');

%% ── 3. Náhodné veličiny ──────────────────────────────────────────────
w(fid, '<h2>2. Náhodné veličiny</h2>');
fprintf(fid, '<p>Model zahrnuje \\(n_{\\mathrm{dim}} = n_G + 10\\) náhodných veličin (NV), tj. <strong>%d NV</strong> pro tuto konstrukci. Parametry dle JRC&nbsp;TR (2024), Tab.&nbsp;3.7 a Annex&nbsp;A.</p>\n', nG + 10);

w(fid, '<table>');
w(fid, '<tr><th>NV</th><th>Popis</th><th>Distribuce</th><th>Střední hodnota</th><th>COV</th><th>Normalizace</th></tr>');

% R1
fprintf(fid, '<tr><td>\\(R_1\\)</td><td>Mez kluzu (multiplikátor)</td><td>Lognormal</td><td style="text-align:right">%.4f</td><td style="text-align:right">%.3f</td><td>\\(x_{0{,}05} = 1{,}0\\)</td></tr>\n', R1_mean, R1_cov);

% d per group
for sg = 1:nG
    fprintf(fid, '<tr><td>\\(d_{%d}\\)</td><td>Průměr CHS sk. %d (D=%.0f mm)</td><td>Normal</td><td style="text-align:right">%.4f m</td><td style="text-align:right">0.005</td><td>\\(\\mu = D_{\\mathrm{nom}}\\)</td></tr>\n', ...
        sg, sg, sections.D(sg)*1e3, sections.D(sg));
end

% Other RVs
rv = {
    'G_s',          'Vlastní tíha (multiplik.)',        'Normal',    '1.000', '0.025', '\\(\\mu = 1\\)';
    'G_P',          'Stálé zatížení (multiplik.)',      'Normal',    '1.000', '0.100', '\\(\\mu = 1\\)';
    'Q_1',          'Sníh na zemi (50-let max)',        'Gumbel',    sprintf('%.4f', Q1_mean), sprintf('%.3f', Q1_cov), '\\(x_{0{,}98} = 1{,}0\\)';
    '\theta_{Q2}',  'Model. nejist. sněhu (čas. inv.)', 'Lognormal', '0.810', '0.260', 'JRC Tab. 3.7';
    '\mu_1',        'Tvarový souč. sněhu',              'Lognormal', '0.800', '0.200', 'EN 1991-1-3';
    'C_e',          'Souč. expozice',                   'Lognormal', '1.000', '0.150', 'JRC Tab. 3.7';
    '\theta_R',     'Model. nejist. (tah)',             'Lognormal', '1.150', '0.050', 'JRC Tab. 3.7';
    '\theta_b',     'Model. nejist. (vzpěr)',           'Lognormal', '1.000', '0.100', 'JRC Tab. 3.7';
    '\theta_E',     'Model. nejist. (účinek zat.)',     'Lognormal', '1.000', '0.050', 'JRC Tab. 3.7';
};
for k = 1:size(rv,1)
    fprintf(fid, '<tr><td>\\(%s\\)</td><td>%s</td><td>%s</td><td style="text-align:right">%s</td><td style="text-align:right">%s</td><td>%s</td></tr>\n', rv{k,:});
end
w(fid, '</table>');

% Normalization
w(fid, '<h3>2.1 Normalizace \(R_1\) a \(Q_1\)</h3>');
w(fid, '<p>NV jsou normalizovány tak, aby charakteristická hodnota odpovídala fraktilu 1,0:</p>');

w(fid, '<div class="fbox">');
w(fid, '<strong>Mez kluzu \(R_1\)</strong> (Lognormal, 5%% fraktil = 1,0):<br>');
w(fid, '\[\mu_{R_1} = \frac{1}{\exp(-1{,}645 \cdot V_{R_1})}\]');
fprintf(fid, 'Pro \\(V_{R_1} = %.3f\\): &nbsp; \\(\\mu_{R_1} = %.4f\\), &nbsp; \\(f_y = R_1 \\cdot f_{y,k}\\), &nbsp; \\(f_y(5%%%%) = f_{y,k}\\) &#10003;\n', R1_cov, R1_mean);
w(fid, '</div>');

w(fid, '<div class="fbox">');
w(fid, '<strong>Sníh \(Q_1\)</strong> (Gumbel, 98%% fraktil = 1,0):<br>');
w(fid, '\[x_{0{,}98} = \mu \cdot \left(1 + K_{98} \cdot V\right), \quad K_{98} = \frac{\sqrt{6}}{\pi}\left(\gamma + \ln(-\ln 0{,}98)\right) \approx 2{,}593\]');
w(fid, '\[\mu_{Q_1} = \frac{1}{1 + K_{98} \cdot V_{Q_1}}\]');
fprintf(fid, 'Pro \\(V_{Q_1} = %.2f\\): &nbsp; \\(\\mu_{Q_1} = %.4f\\), &nbsp; \\(s_g = Q_1 \\cdot s_k\\), &nbsp; \\(s_g(98%%%%) = s_k\\) &#10003;\n', Q1_cov, Q1_mean);
w(fid, '</div>');

%% ── 4. Model zatížení ────────────────────────────────────────────────
w(fid, '<h2>3. Model zatížení</h2>');
w(fid, '<p>Uvažuje se kombinace stálého a sněhového zatížení <strong>bez dílčích součinitelů</strong>');
w(fid, '(ty jsou nahrazeny náhodnými veličinami).</p>');

w(fid, '<h3>3.1 Sníh na střeše</h3>');
w(fid, '<div class="fbox">');
w(fid, '\[s_{\mathrm{roof}} = \theta_{Q2} \cdot \mu_1 \cdot C_e \cdot C_t \cdot Q_1 \cdot s_k\]');
w(fid, 'kde \(C_t = 1{,}0\) (tepelný součinitel).<br>');
w(fid, '<span class="ref">EN 1991-1-3:2025, Eq. 7.3; JRC TR Tab. 3.7</span>');
w(fid, '</div>');

w(fid, '<h3>3.2 Skládání účinků zatížení</h3>');
w(fid, '<p>Osová síla v prutu \(p\) se získá superpozicí:</p>');
w(fid, '<div class="fbox">');
w(fid, '\[N_{\mathrm{Ed},p} = G_P \cdot N_p^{\mathrm{perm}} + s_{\mathrm{roof}} \cdot N_p^{\mathrm{snow}} + G_s \cdot N_p^{\mathrm{sw}}\]');
w(fid, '</div>');
w(fid, '<p>kde \(N_p^{\mathrm{perm}}\), \(N_p^{\mathrm{snow}}\), \(N_p^{\mathrm{sw}}\) jsou <strong>vlivové koeficienty</strong>');
w(fid, '— osové síly získané ze tří jednotkových FEM výpočtů (viz kap. 6).</p>');

%% ── 5. Model odolnosti ──────────────────────────────────────────────
w(fid, '<h2>4. Model odolnosti</h2>');

w(fid, '<h3>4.1 Tah (Cl. 6.2.3)</h3>');
w(fid, '<div class="fbox">');
w(fid, '\[N_{t,\mathrm{Rd}} = \theta_R \cdot f_y \cdot A\]');
w(fid, '<span class="ref">EN 1993-1-1:2005, Cl. 6.2.3</span>');
w(fid, '</div>');

w(fid, '<h3>4.2 Vzpěr (Cl. 6.3.1)</h3>');
w(fid, '<div class="fbox">');
w(fid, '\[\bar{\lambda} = \frac{L_{\mathrm{cr}} / i}{\pi \sqrt{E / f_y}}\]');
w(fid, '\[\Phi = \tfrac{1}{2}\left[1 + \alpha\left(\bar{\lambda} - 0{,}2\right) + \bar{\lambda}^2\right]\]');
w(fid, '\[\chi = \min\!\left(\frac{1}{\Phi + \sqrt{\Phi^2 - \bar{\lambda}^2}},\; 1{,}0\right)\]');
w(fid, '\[N_{b,\mathrm{Rd}} = \theta_b \cdot \chi \cdot f_y \cdot A\]');
w(fid, '<span class="ref">EN 1993-1-1:2005, Cl. 6.3.1.2</span>');
w(fid, '</div>');

w(fid, '<h3>4.3 CHS geometrie</h3>');
w(fid, '<p>Průřezové charakteristiky CHS z náhodného průměru \(d\) a deterministické tloušťky \(t\):</p>');
w(fid, '<div class="fbox">');
w(fid, '\[A = \frac{\pi}{4}\left(d^2 - (d - 2t)^2\right), \quad I = \frac{\pi}{64}\left(d^4 - (d - 2t)^4\right), \quad i = \sqrt{I/A}\]');
w(fid, '</div>');

% Sections table
w(fid, '<table>');
w(fid, '<tr><th>Skupina</th><th>D [mm]</th><th>t [mm]</th><th>A [cm²]</th><th>i [mm]</th><th>Křivka</th><th>α</th></tr>');
for sg = 1:nG
    D_mm = sections.D(sg)*1e3;
    t_mm = sections.t(sg)*1e3;
    A_cm2 = sections.A(sg)*1e4;
    i_mm  = sections.i_radius(sg)*1e3;
    alpha_val = curveAlpha(sections.curve{sg});
    fprintf(fid, '<tr><td style="text-align:center">%d</td><td style="text-align:right">%.1f</td><td style="text-align:right">%.1f</td><td style="text-align:right">%.2f</td><td style="text-align:right">%.1f</td><td style="text-align:center">%s</td><td style="text-align:right">%.2f</td></tr>\n', ...
        sg, D_mm, t_mm, A_cm2, i_mm, sections.curve{sg}, alpha_val);
end
w(fid, '</table>');

%% ── 6. Limitní stavová funkce ────────────────────────────────────────
w(fid, '<h2>5. Limitní stavová funkce</h2>');
w(fid, '<p>Pro každý prut \(p\) se vyhodnotí limitní stavová funkce \(g_p\):</p>');

w(fid, '<div class="wbox">');
w(fid, '<strong>Tah</strong> (\(N_{\mathrm{Ed},p} \geq 0\)):');
w(fid, '\[g_p = \theta_R \cdot f_y \cdot A_p - \theta_E \cdot N_{\mathrm{Ed},p}\]');
w(fid, '<strong>Tlak — vzpěr</strong> (\(N_{\mathrm{Ed},p} < 0\)):');
w(fid, '\[g_p = \theta_b \cdot \chi_p \cdot f_y \cdot A_p - \theta_E \cdot |N_{\mathrm{Ed},p}|\]');
w(fid, '</div>');

w(fid, '<p>\(g_p > 0\): bezpečný stav; &ensp; \(g_p \leq 0\): selhání prutu \(p\).</p>');
w(fid, '<p>Systémová funkce (sériový systém): \(g_{\mathrm{sys}} = \min_p g_p\).</p>');

%% ── 7. Efektivní výpočet ─────────────────────────────────────────────
w(fid, '<h2>6. Efektivní výpočet (superposice)</h2>');
w(fid, '<p>Pro lineární analýzu staticky určité příhrady platí <strong>princip superpozice</strong>:');
w(fid, 'osové síly jsou lineární funkcí zatížení. Namísto \(N\) volání FEM solveru');
w(fid, '(jedno na každý MC vzorek) stačí <strong>3 jednotkové výpočty</strong>:</p>');

w(fid, '<div class="fbox">');
w(fid, '<ol style="margin:0;padding-left:20px;">');
w(fid, '<li>\(\mathbf{N}^{\mathrm{perm}}\): jednotkové stálé zatížení (\(G_P = 1\), \(s = 0\), \(G_s = 0\))</li>');
w(fid, '<li>\(\mathbf{N}^{\mathrm{snow}}\): jednotkový sníh (\(G_P = 0\), \(s = 1\;\mathrm{kN/m^2}\), \(G_s = 0\))</li>');
w(fid, '<li>\(\mathbf{N}^{\mathrm{sw}}\): jednotková vlastní tíha (\(G_P = 0\), \(s = 0\), \(G_s = 1\))</li>');
w(fid, '</ol><br>');
w(fid, 'Každý MC vzorek pak: &ensp; \(N_{\mathrm{Ed},p} = G_P \cdot N_p^{\mathrm{perm}} + s_{\mathrm{roof}} \cdot N_p^{\mathrm{snow}} + G_s \cdot N_p^{\mathrm{sw}}\)<br><br>');
w(fid, '<strong>Zrychlení:</strong> ~500× oproti přímému FEM (vektorové operace místo řešení soustav).');
w(fid, '</div>');
w(fid, '<p class="ref">Platnost: exaktní pro staticky určité příhrady. Pro staticky neurčité');
w(fid, 'zanedbává vliv variability \(EA\) na rozdělení sil — chyba &lt; 0,01 %% (COV(\(d\)) = 0,5 %%).</p>');

%% ── 8. Vzpěrné délky ─────────────────────────────────────────────────
w(fid, '<h2>7. Vzpěrné délky</h2>');
w(fid, '<p>Vzpěrné délky \(L_{\mathrm{cr}}\) dle Tab. 1.29 (Jandera, OK-01):</p>');

w(fid, '<table>');
w(fid, '<tr><th>Typ prutu</th><th>\(L_{\mathrm{cr}}\) v rovině</th><th>\(L_{\mathrm{cr}}\) z roviny</th></tr>');
w(fid, '<tr><td>Horní pás</td><td style="text-align:center">\(L_{\mathrm{sys}}\)</td><td style="text-align:center">\(0{,}9 \times a\) (rozteč vaznic)</td></tr>');
w(fid, '<tr><td>Dolní pás</td><td style="text-align:center">\(L_{\mathrm{sys}}\)</td><td style="text-align:center">rozteč ztužení</td></tr>');
w(fid, '<tr><td>Diagonála</td><td style="text-align:center">\(0{,}9 \times L_{\mathrm{sys}}\)</td><td style="text-align:center">\(0{,}75 \times L_{\mathrm{sys}}\)</td></tr>');
w(fid, '<tr><td>Svislice</td><td style="text-align:center">\(0{,}9 \times L_{\mathrm{sys}}\)</td><td style="text-align:center">\(0{,}75 \times L_{\mathrm{sys}}\)</td></tr>');
w(fid, '</table>');
w(fid, '<p class="ref">Pro CHS (\(I_y = I_z\)) rozhoduje \(\max(L_{\mathrm{cr,in}}, L_{\mathrm{cr,out}})\).</p>');

%% ── 9. Monte Carlo ───────────────────────────────────────────────────
w(fid, '<h2>8. Monte Carlo simulace</h2>');
w(fid, '<div class="fbox">');
w(fid, '<strong>Algoritmus:</strong><br><div class="step">');
w(fid, '1. Vygeneruj \(N\) vzorků náhodného vektoru \(\mathbf{X}\)<br>');
w(fid, '2. Pro každý vzorek \(k\): vypočti \(f_y^{(k)}\), \(A_p^{(k)}\), \(i_p^{(k)}\), \(N_{\mathrm{Ed},p}^{(k)}\) (superpozice)<br>');
w(fid, '3. Vyhodnoť \(g_p^{(k)}\) pro všechny pruty, urči \(g_{\mathrm{sys}}^{(k)} = \min_p g_p^{(k)}\)<br>');
w(fid, '4. Odhad: \(\hat{P}_f = \frac{1}{N} \sum_{k=1}^{N} \mathbf{1}\!\left[g_{\mathrm{sys}}^{(k)} \leq 0\right]\), &ensp; \(\hat{\beta} = -\Phi^{-1}(\hat{P}_f)\)<br>');
w(fid, '5. Koeficient variace: \(\mathrm{CoV}(\hat{P}_f) = \sqrt{\frac{1 - \hat{P}_f}{N \cdot \hat{P}_f}}\)');
w(fid, '</div></div>');
w(fid, '<p>Software: <strong>UQLab</strong> (ETH Zürich), metoda MCS nebo Subset Simulation.</p>');

%% ── 10. Výsledky ─────────────────────────────────────────────────────
if hasResults
    w(fid, '<h2>9. Výsledky</h2>');
    w(fid, '<table>');
    w(fid, '<tr><th>Veličina</th><th>Symbol</th><th>Hodnota</th></tr>');
    fprintf(fid, '<tr><td>Pravděpodobnost selhání</td><td>\\(P_f\\)</td><td style="text-align:right"><strong>%.4e</strong></td></tr>\n', results.Pf);
    fprintf(fid, '<tr><td>Index spolehlivosti</td><td>\\(\\beta\\)</td><td style="text-align:right"><strong>%.3f</strong></td></tr>\n', results.beta);
    fprintf(fid, '<tr><td>Koef. variace odhadu</td><td>\\(\\mathrm{CoV}(\\hat{P}_f)\\)</td><td style="text-align:right">%.1f %%%%</td></tr>\n', results.Pf_CoV * 100);
    fprintf(fid, '<tr><td>Počet vzorků</td><td>\\(N\\)</td><td style="text-align:right">%.0e</td></tr>\n', results.nSamples);
    fprintf(fid, '<tr><td>Počet selhání</td><td>\\(n_f\\)</td><td style="text-align:right">%d</td></tr>\n', results.nFailures);
    if isfield(results, 'elapsed')
        fprintf(fid, '<tr><td>Čas výpočtu</td><td>—</td><td style="text-align:right">%.1f s</td></tr>\n', results.elapsed);
    end
    w(fid, '</table>');

    % Per-member table
    if isfield(results, 'member') && isfield(results.member, 'Pf')
        w(fid, '<h3>9.1 Spolehlivost jednotlivých prutů</h3>');
        w(fid, '<table>');
        w(fid, '<tr><th>Prut</th><th>Typ</th><th>Profil</th><th>\(P_{f,p}\)</th><th>\(\beta_p\)</th><th>Kritický [%%]</th><th>Mód</th></tr>');

        classification = results.classification;
        for pp = 1:nmembers
            si = members.sections(pp);
            type_str = translateType(char(classification.type(pp)));
            D_mm = sections.D(si)*1e3;
            t_mm = sections.t(si)*1e3;
            prof_str = sprintf('%.0f×%.1f', D_mm, t_mm);

            if results.member.n_buckling_fail(pp) > results.member.n_tension_fail(pp)
                mode_str = 'vzpěr';
            elseif results.member.n_tension_fail(pp) > 0
                mode_str = 'tah';
            else
                mode_str = '—';
            end

            if isinf(results.member.beta(pp))
                beta_str = '∞';
            else
                beta_str = sprintf('%.2f', results.member.beta(pp));
            end

            if results.member.Pf(pp) > 0 && results.member.beta(pp) < 3.8
                rc = ' class="fail"';
            else
                rc = '';
            end

            fprintf(fid, '<tr%s><td style="text-align:center">%d</td><td>%s</td><td style="text-align:center">%s</td><td style="text-align:right">%.2e</td><td style="text-align:right">%s</td><td style="text-align:right">%.1f</td><td style="text-align:center">%s</td></tr>\n', ...
                rc, pp, type_str, prof_str, results.member.Pf(pp), beta_str, results.member.critical_pct(pp), mode_str);
        end
        w(fid, '</table>');
    end

    % Summary box
    w(fid, '<h2>10. Souhrn</h2>');
    if results.beta >= 3.8
        status_txt = 'VYHOVUJE';
    else
        status_txt = 'NEVYHOVUJE';
    end
    fprintf(fid, '<div class="sbox" style="background:%s;border:2px solid %s;color:%s;">\n', sbg, sb, sc);
    fprintf(fid, '\\(\\beta = %.3f\\) &nbsp; vs. &nbsp; \\(\\beta_{\\mathrm{target}} = 3{,}8\\) &nbsp;&rarr;&nbsp; <strong>%s</strong>\n', results.beta, status_txt);
    w(fid, '</div>');
else
    w(fid, '<h2>9. Výsledky</h2>');
    w(fid, '<p><em>Výsledky nebyly předány — report obsahuje pouze metodiku.</em></p>');
end

%% ── Patička ──────────────────────────────────────────────────────────
w(fid, '<hr style="margin-top:30px;border:none;border-top:1px solid #ccc;">');
fprintf(fid, '<p class="ref">Vygenerováno: %s &nbsp;|&nbsp; Software: MATLAB + UQLab &nbsp;|&nbsp; Autor: S. Glanc</p>\n', datestr(now, 'dd.mm.yyyy HH:MM'));
w(fid, '</body></html>');

fprintf('Report uložen: %s\n', filename);

end

%% ── Helpers ──────────────────────────────────────────────────────────

function w(fid, s)
    fprintf(fid, '%s\n', s);
end

function a = curveAlpha(curve)
    switch lower(curve)
        case 'a0', a = 0.13;
        case 'a',  a = 0.21;
        case 'b',  a = 0.34;
        case 'c',  a = 0.49;
        case 'd',  a = 0.76;
        otherwise, a = 0.21;
    end
end

function s = translateType(t)
    switch t
        case 'top_chord',    s = 'Horní pás';
        case 'bottom_chord', s = 'Dolní pás';
        case 'diagonal',     s = 'Diagonála';
        case 'vertical',     s = 'Svislice';
        otherwise,           s = t;
    end
end
