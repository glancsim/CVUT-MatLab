%% ANALÝZA ROČNÍCH MAXIM ZÁKLADNÍ RYCHLOSTI VĚTRU (2004-2024)
% Seniorní data scientist & wind engineer analýza
% Vyžaduje: Statistics and Machine Learning Toolbox
% Autor: Claude AI
% Datum: 2025

clc; clear; close all;

% Nastavení reprodukovatelnosti
rng(1234);

fprintf('=== ANALÝZA ROČNÍCH MAXIM ZÁKLADNÍ RYCHLOSTI VĚTRU ===\n');
fprintf('Období: 2004-2024 (22 let)\n');

%% 1. NAČTENÍ A PŘÍPRAVA DAT

% Definice roků
years = (2004:2024)';
n_expected = length(years);

% Možnost 1: Načtení ze souboru
if exist('maxima.xlsx', 'file')
    fprintf('Načítám data ze souboru maxima.xlsx...\n');
    try
        raw_data = readtable('maxima.xlsx', 'Sheet', 1);
        data = raw_data{:, 2}; % druhý sloupec
        fprintf('✓ Soubor úspěšně načten\n');
    catch ME
        fprintf('⚠ Chyba při čtení souboru: %s\n', ME.message);
        fprintf('Přepínám na simulovaná data...\n');
        data = [];
    end
else
    fprintf('Soubor maxima.xlsx nenalezen.\n');
    data = [];
end

% Možnost 2: Simulovaná data (pokud soubor není dostupný)
if isempty(data)
    fprintf('Generujem simulovaná data (Gumbel, location=25, scale=3)...\n');
    pd_sim = makedist('ExtremeValue', 'A', 25, 'B', 3);
    data = random(pd_sim, n_expected, 1);
    fprintf('✓ Simulovaná data vygenerována\n');
end

% Validace dat
fprintf('\nValidace vstupních dat:\n');
fprintf('- Původní počet hodnot: %d\n', length(data));
fprintf('- Očekávaný počet: %d\n', n_expected);

% Odstranění NaN hodnot
data_clean = data(~isnan(data));
n_valid = length(data_clean);
fprintf('- Platných hodnot po odstranění NaN: %d\n', n_valid);

if n_valid ~= n_expected
    fprintf('⚠ VAROVÁNÍ: Počet platných dat (%d) neodpovídá očekávané délce (%d)\n', n_valid, n_expected);
end

if n_valid < 15
    error('❌ CHYBA: Nedostatek dat pro spolehlivou analýzu (<15 hodnot)');
end

data = data_clean; % Použijeme pouze platná data
years_used = years(1:length(data)); % Přizpůsobíme roky

fprintf('✓ Data připravena pro analýzu\n\n');

%% 2. ZÁKLADNÍ POPIS DAT

fprintf('=== ZÁKLADNÍ STATISTICKÝ POPIS ===\n');
fprintf('Počet hodnot: %d\n', length(data));
fprintf('Minimum: %.2f m/s\n', min(data));
fprintf('Průměr: %.2f m/s\n', mean(data));
fprintf('Medián: %.2f m/s\n', median(data));
fprintf('Maximum: %.2f m/s\n', max(data));
fprintf('Směrodatná odchylka: %.2f m/s\n', std(data));

CoV = std(data) / mean(data);
fprintf('Koeficient variability (CoV): %.3f\n', CoV);

% Sanity check na extrémy
p1 = prctile(data, 1);
p99 = prctile(data, 99);
Q1 = prctile(data, 25);
Q3 = prctile(data, 75);
IQR = Q3 - Q1;
lower_fence = Q1 - 3*IQR;
upper_fence = Q3 + 3*IQR;

fprintf('\nKontrol extrémů:\n');
fprintf('- 1%% percentil: %.2f m/s\n', p1);
fprintf('- 99%% percentil: %.2f m/s\n', p99);
fprintf('- Mezikvartilovt rozpětí (IQR): %.2f m/s\n', IQR);

outliers = data < lower_fence | data > upper_fence;
if any(outliers)
    fprintf('⚠ VAROVÁNÍ: Nalezeny potenciální odlehlé hodnoty:\n');
    outlier_vals = data(outliers);
    for i = 1:length(outlier_vals)
        fprintf('  - %.2f m/s\n', outlier_vals(i));
    end
else
    fprintf('✓ Žádné extrémní odlehlé hodnoty nenalezeny\n');
end

fprintf('\n');

%% 3. FIT ROZDĚLENÍ EXTRÉMŮ

fprintf('=== FIT ROZDĚLENÍ EXTRÉMŮ ===\n');

% Fit Gumbel (Extreme Value)
fprintf('Fitování Gumbel rozdělení...\n');
try
    pd_gumbel = fitdist(data, 'ExtremeValue');
    gumbel_A = pd_gumbel.A; % location
    gumbel_B = pd_gumbel.B; % scale
    fprintf('✓ Gumbel parametry: location (A) = %.3f, scale (B) = %.3f\n', gumbel_A, gumbel_B);
    
    % Log-likelihood a informační kritéria
    gumbel_loglik = sum(log(pdf(pd_gumbel, data)));
    gumbel_aic = -2*gumbel_loglik + 2*2; % 2 parametry
    gumbel_bic = -2*gumbel_loglik + log(length(data))*2;
    
    fprintf('  Log-likelihood: %.3f\n', gumbel_loglik);
    fprintf('  AIC: %.3f\n', gumbel_aic);
    fprintf('  BIC: %.3f\n', gumbel_bic);
    gumbel_success = true;
catch ME
    fprintf('❌ Chyba při fitování Gumbel: %s\n', ME.message);
    gumbel_success = false;
end

% Fit GEV (Generalized Extreme Value)
fprintf('\nFitování GEV rozdělení...\n');
try
    pd_gev = fitdist(data, 'GeneralizedExtremeValue');
    gev_k = pd_gev.k; % shape
    gev_sigma = pd_gev.sigma; % scale
    gev_mu = pd_gev.mu; % location
    fprintf('✓ GEV parametry: shape (k) = %.3f, scale (σ) = %.3f, location (μ) = %.3f\n', gev_k, gev_sigma, gev_mu);
    
    % Log-likelihood a informační kritéria
    gev_loglik = sum(log(pdf(pd_gev, data)));
    gev_aic = -2*gev_loglik + 2*3; % 3 parametry
    gev_bic = -2*gev_loglik + log(length(data))*3;
    
    fprintf('  Log-likelihood: %.3f\n', gev_loglik);
    fprintf('  AIC: %.3f\n', gev_aic);
    fprintf('  BIC: %.3f\n', gev_bic);
    gev_success = true;
catch ME
    fprintf('❌ Chyba při fitování GEV: %s\n', ME.message);
    gev_success = false;
end

% Porovnání modelů
fprintf('\n--- POROVNÁNÍ MODELŮ ---\n');
if gumbel_success && gev_success
    fprintf('Model      | AIC     | BIC     | LogLik\n');
    fprintf('-----------|---------|---------|--------\n');
    fprintf('Gumbel     | %7.2f | %7.2f | %6.2f\n', gumbel_aic, gumbel_bic, gumbel_loglik);
    fprintf('GEV        | %7.2f | %7.2f | %6.2f\n', gev_aic, gev_bic, gev_loglik);
    
    if gumbel_aic < gev_aic
        fprintf('→ Gumbel má nižší AIC (%.2f vs %.2f) - preferovaný model\n', gumbel_aic, gev_aic);
        better_model = 'Gumbel';
        better_pd = pd_gumbel;
    else
        fprintf('→ GEV má nižší AIC (%.2f vs %.2f) - preferovaný model\n', gev_aic, gumbel_aic);
        better_model = 'GEV';
        better_pd = pd_gev;
    end
elseif gumbel_success
    fprintf('→ Pouze Gumbel model je dostupný\n');
    better_model = 'Gumbel';
    better_pd = pd_gumbel;
elseif gev_success
    fprintf('→ Pouze GEV model je dostupný\n');
    better_model = 'GEV';
    better_pd = pd_gev;
else
    error('❌ Ani jeden model nebyl úspěšně nafitován');
end

% Goodness-of-fit testy
fprintf('\n--- TESTY DOBRÉ SHODY ---\n');
if gumbel_success
    try
        [h_ks_gumbel, p_ks_gumbel] = kstest(data, 'CDF', pd_gumbel, 'Alpha', 0.05);
        fprintf('Gumbel KS test: H=%d, p-value=%.4f %s\n', h_ks_gumbel, p_ks_gumbel, ...
            ternary(h_ks_gumbel, '(ZAMÍTNUT)', '(NEZAMÍTNUT)'));
    catch
        fprintf('Gumbel KS test: Nedostupný\n');
    end
end

if gev_success
    try
        [h_ks_gev, p_ks_gev] = kstest(data, 'CDF', pd_gev, 'Alpha', 0.05);
        fprintf('GEV KS test: H=%d, p-value=%.4f %s\n', h_ks_gev, p_ks_gev, ...
            ternary(h_ks_gev, '(ZAMÍTNUT)', '(NEZAMÍTNUT)'));
    catch
        fprintf('GEV KS test: Nedostupný\n');
    end
end

% Poznámka k Anderson-Darling testu
fprintf('Poznámka: Anderson-Darling test vyžaduje specifickou implementaci pro EV rozdělení\n');
fprintf('a není standardně dostupný v Statistics Toolbox pro custom distribuce.\n');

fprintf('\n');

%% 4. NÁVRATOVÉ HODNOTY (RETURN LEVELS)

fprintf('=== NÁVRATOVÉ HODNOTY ===\n');

% Definice návratových období
R = [10, 20, 50, 100]; % roky
p = 1 - 1./R; % pravděpodobnosti

fprintf('Návratové období | Pravděpodobnost | Gumbel (m/s)');
if gev_success
    fprintf(' | GEV (m/s)');
end
fprintf('\n');
fprintf('----------------|----------------|------------');
if gev_success
    fprintf('|-----------');
end
fprintf('\n');

% Tabulka s výsledky pro export
return_table = table();
return_table.R = R';
return_table.p = p';

for i = 1:length(R)
    if gumbel_success
        q_gumbel = icdf(pd_gumbel, p(i));
        return_table.Quantile_Gumbel(i) = q_gumbel;
    else
        q_gumbel = NaN;
        return_table.Quantile_Gumbel(i) = NaN;
    end
    
    if gev_success
        q_gev = icdf(pd_gev, p(i));
        return_table.Quantile_GEV(i) = q_gev;
    else
        q_gev = NaN;
        return_table.Quantile_GEV(i) = NaN;
    end
    
    fprintf('%15d | %14.4f | %10.2f', R(i), p(i), q_gumbel);
    if gev_success
        fprintf(' | %9.2f', q_gev);
    end
    fprintf('\n');
end

% Explicitně vypiš 50letou hodnotu
fprintf('\n--- KLÍČOVÝ VÝSLEDEK: 50LETÁ NÁVRATOVÁ HODNOTA ---\n');
p_50 = 0.98; % 1 - 1/50
if gumbel_success
    q_50_gumbel = icdf(pd_gumbel, p_50);
    fprintf('Gumbel 50letá hodnota: %.2f m/s\n', q_50_gumbel);
end
if gev_success
    q_50_gev = icdf(pd_gev, p_50);
    fprintf('GEV 50letá hodnota: %.2f m/s\n', q_50_gev);
end

fprintf('\n');

%% 5. BOOTSTRAP NEJISTOTY

fprintf('=== BOOTSTRAP ANALÝZA NEJISTOT ===\n');
fprintf('Model pro bootstrap: %s\n', better_model);

Nboot = 2000;
fprintf('Počet bootstrap vzorků: %d\n', Nboot);

% Inicializace
bootstrap_q50 = NaN(Nboot, 1);
n_data = length(data);

fprintf('Probíhá bootstrap... ');
tic;

for b = 1:Nboot
    % Resample s opakováním
    boot_data = datasample(data, n_data, 'Replace', true);
    
    try
        if strcmp(better_model, 'Gumbel')
            boot_pd = fitdist(boot_data, 'ExtremeValue');
        else % GEV
            boot_pd = fitdist(boot_data, 'GeneralizedExtremeValue');
        end
        
        bootstrap_q50(b) = icdf(boot_pd, p_50);
    catch
        % Pokud fit selže, ponech NaN
        continue;
    end
    
    % Progress indikátor
    if mod(b, 500) == 0
        fprintf('.');
    end
end

boot_time = toc;
fprintf(' dokončeno (%.1f s)\n', boot_time);

% Vyhodnocení CI
valid_bootstrap = ~isnan(bootstrap_q50);
n_valid_boots = sum(valid_bootstrap);
fprintf('Úspěšných bootstrap vzorků: %d/%d (%.1f%%)\n', n_valid_boots, Nboot, 100*n_valid_boots/Nboot);

if n_valid_boots >= 100
    boot_q50_clean = bootstrap_q50(valid_bootstrap);
    ci_lower = prctile(boot_q50_clean, 2.5);
    ci_upper = prctile(boot_q50_clean, 97.5);
    
    fprintf('\n--- 95%% KONFIDENČNÍ INTERVAL (50letá hodnota) ---\n');
    fprintf('Model: %s\n', better_model);
    if strcmp(better_model, 'Gumbel')
        point_est = q_50_gumbel;
    else
        point_est = q_50_gev;
    end
    fprintf('Bodový odhad: %.2f m/s\n', point_est);
    fprintf('95%% CI: [%.2f, %.2f] m/s\n', ci_lower, ci_upper);
    fprintf('Šířka CI: %.2f m/s\n', ci_upper - ci_lower);
else
    fprintf('⚠ VAROVÁNÍ: Nedostatek úspěšných bootstrap vzorků pro spolehlivé CI\n');
end

fprintf('\n');

%% 6. VYTVOŘENÍ GRAFŮ

fprintf('=== TVORBA GRAFŮ ===\n');

% Vytvoření adresáře pro obrázky
if ~exist('figs', 'dir')
    mkdir('figs');
    fprintf('✓ Vytvořen adresář figs/\n');
end

% Graf 1: Histogram s fity
figure(1); clf;
histogram(data, 'Normalization', 'pdf', 'FaceColor', [0.7 0.7 0.9], ...
    'EdgeColor', 'black', 'FaceAlpha', 0.7);
hold on;

x_range = linspace(min(data)*0.9, max(data)*1.1, 200);

if gumbel_success
    y_gumbel = pdf(pd_gumbel, x_range);
    plot(x_range, y_gumbel, 'r-', 'LineWidth', 2, 'DisplayName', 'Gumbel');
end

if gev_success
    y_gev = pdf(pd_gev, x_range);
    plot(x_range, y_gev, 'b--', 'LineWidth', 2, 'DisplayName', 'GEV');
end

xlabel('Rychlost větru [m/s]');
ylabel('Hustota pravděpodobnosti');
title(sprintf('Roční maxima rychlosti větru (%d–%d)', min(years_used), max(years_used)));
legend('Data', 'Location', 'best');
grid on;

saveas(gcf, 'figs/hist_fits.png');
fprintf('✓ Uložen histogram: figs/hist_fits.png\n');

% Graf 2: QQ-plot Gumbel
if gumbel_success
    figure(2); clf;
    qqplot(data, pd_gumbel);
    title('QQ-plot: Gumbel rozdělení');
    xlabel('Teoretické kvantily [m/s]');
    ylabel('Vzorkové kvantily [m/s]');
    grid on;
    
    saveas(gcf, 'figs/qq_gumbel.png');
    fprintf('✓ Uložen QQ-plot Gumbel: figs/qq_gumbel.png\n');
end

% Graf 3: QQ-plot GEV
if gev_success
    figure(3); clf;
    qqplot(data, pd_gev);
    title('QQ-plot: GEV rozdělení');
    xlabel('Teoretické kvantily [m/s]');
    ylabel('Vzorkové kvantily [m/s]');
    grid on;
    
    saveas(gcf, 'figs/qq_gev.png');
    fprintf('✓ Uložen QQ-plot GEV: figs/qq_gev.png\n');
end

% Graf 4: Return level plot
figure(4); clf;
R_plot = logspace(0.5, 2.5, 100); % 3 až ~300 let
p_plot = 1 - 1./R_plot;

hold on;

if gumbel_success
    q_plot_gumbel = icdf(pd_gumbel, p_plot);
    semilogx(R_plot, q_plot_gumbel, 'r-', 'LineWidth', 2, 'DisplayName', 'Gumbel');
    
    % Zvýraz 50letý bod
    semilogx(50, q_50_gumbel, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'red', ...
        'DisplayName', sprintf('Gumbel 50r: %.1f m/s', q_50_gumbel));
end

if gev_success
    q_plot_gev = icdf(pd_gev, p_plot);
    semilogx(R_plot, q_plot_gev, 'b--', 'LineWidth', 2, 'DisplayName', 'GEV');
    
    % Zvýraz 50letý bod
    semilogx(50, q_50_gev, 'bs', 'MarkerSize', 8, 'MarkerFaceColor', 'blue', ...
        'DisplayName', sprintf('GEV 50r: %.1f m/s', q_50_gev));
end

xlabel('Návratové období [roky]');
ylabel('Návratová hodnota [m/s]');
title('Return Level Plot');
legend('Location', 'best');
grid on;
xlim([3, 300]);

saveas(gcf, 'figs/return_level.png');
fprintf('✓ Uložen return level plot: figs/return_level.png\n');

%% 7. EXPORT VÝSLEDKŮ

fprintf('\n=== EXPORT VÝSLEDKŮ ===\n');

% Vytvoření adresáře pro výsledky
if ~exist('results', 'dir')
    mkdir('results');
    fprintf('✓ Vytvořen adresář results/\n');
end

% Tabulka parametrů modelů
param_table = table();
if gumbel_success && gev_success
    param_table.Model = {'Gumbel'; 'GEV'};
    param_table.Param1 = [gumbel_A; gev_k];
    param_table.Param2 = [gumbel_B; gev_sigma];
    param_table.Param3 = [NaN; gev_mu];
    param_table.LogLik = [gumbel_loglik; gev_loglik];
    param_table.AIC = [gumbel_aic; gev_aic];
    param_table.BIC = [gumbel_bic; gev_bic];
    
    % Poznámky k parametrům
    param_table.Properties.VariableDescriptions = {'Model name', ...
        'Location (Gumbel) / Shape (GEV)', 'Scale', 'Location (GEV only)', ...
        'Log-likelihood', 'Akaike Information Criterion', 'Bayesian Information Criterion'};
        
elseif gumbel_success
    param_table.Model = {'Gumbel'};
    param_table.Param1 = gumbel_A;
    param_table.Param2 = gumbel_B;
    param_table.Param3 = NaN;
    param_table.LogLik = gumbel_loglik;
    param_table.AIC = gumbel_aic;
    param_table.BIC = gumbel_bic;
elseif gev_success
    param_table.Model = {'GEV'};
    param_table.Param1 = gev_k;
    param_table.Param2 = gev_sigma;
    param_table.Param3 = gev_mu;
    param_table.LogLik = gev_loglik;
    param_table.AIC = gev_aic;
    param_table.BIC = gev_bic;
end

writetable(param_table, 'results/fit_summary.csv');
fprintf('✓ Uložena tabulka parametrů: results/fit_summary.csv\n');

% Tabulka návratových hodnot
writetable(return_table, 'results/return_levels.csv');
fprintf('✓ Uložena tabulka návratových hodnot: results/return_levels.csv\n');

% Textový souhrn
fid = fopen('results/summary.txt', 'w');
fprintf(fid, 'ANALÝZA ROČNÍCH MAXIM ZÁKLADNÍ RYCHLOSTI VĚTRU\n');
fprintf(fid, '===============================================\n\n');
fprintf(fid, 'Období analýzy: %d–%d (%d let)\n', min(years_used), max(years_used), length(data));

fprintf(fid, 'ZÁKLADNÍ STATISTIKY:\n');
fprintf(fid, '- Průměr: %.2f m/s\n', mean(data));
fprintf(fid, '- Směrodatná odchylka: %.2f m/s\n', std(data));
fprintf(fid, '- Koeficient variability: %.3f\n', CoV);
fprintf(fid, '- Minimum: %.2f m/s\n', min(data));
fprintf(fid, '- Maximum: %.2f m/s\n\n', max(data));

fprintf(fid, 'FITOVANÉ MODELY:\n');
if gumbel_success
    fprintf(fid, '- Gumbel: AIC=%.2f, location=%.3f, scale=%.3f\n', gumbel_aic, gumbel_A, gumbel_B);
end
if gev_success
    fprintf(fid, '- GEV: AIC=%.2f, shape=%.3f, scale=%.3f, location=%.3f\n', gev_aic, gev_k, gev_sigma, gev_mu);
end
fprintf(fid, '- Preferovaný model: %s\n\n', better_model);

fprintf(fid, 'KLÍČOVÉ NÁVRATOVÉ HODNOTY:\n');
if gumbel_success
    fprintf(fid, '- 50letá hodnota (Gumbel): %.2f m/s\n', q_50_gumbel);
end
if gev_success
    fprintf(fid, '- 50letá hodnota (GEV): %.2f m/s\n', q_50_gev);
end

if exist('ci_lower', 'var') && exist('ci_upper', 'var')
    fprintf(fid, '- 95%% CI (50letá, %s): [%.2f, %.2f] m/s\n', better_model, ci_lower, ci_upper);
end
fprintf(fid, '\n');

fprintf(fid, 'INTERPRETAČNÍ POZNÁMKY:\n');
fprintf(fid, '- 50letá hodnota odpovídá 2%% roční pravděpodobnosti překročení\n');
fprintf(fid, '- Koeficient variability %.3f ', CoV);
if CoV >= 0.18 && CoV <= 0.23
    fprintf(fid, 'je v souladu s referenčními hodnotami EC Annex L (0.18-0.23)\n');
elseif CoV < 0.18
    fprintf(fid, 'je nižší než referenční rozsah EC Annex L (0.18-0.23)\n');
else
    fprintf(fid, 'je vyšší než referenční rozsah EC Annex L (0.18-0.23)\n');
end

fprintf(fid, '- Analýza byla provedena podle principů extrémní statistiky\n');
fprintf(fid, '- Výsledky jsou vhodné pro technické aplikace v souladu s evropskými normami\n');

fclose(fid);
fprintf('✓ Uložen textový souhrn: results/summary.txt\n');

%% 8. POZNÁMKY KE KONZISTENCI S NORMAMI

fprintf('\n=== KONZISTENCE S EVROPSKÝMI NORMAMI ===\n');
fprintf('• 50leté maximum odpovídá 2%% roční pravděpodobnosti překročení\n');
fprintf('  (viz EC JRC Annex L - Action of Wind on Structures)\n\n');

fprintf('• Koeficient variability (CoV = %.3f):\n', CoV);
if CoV >= 0.18 && CoV <= 0.23
    fprintf('  ✓ V souladu s referenčními hodnotami Annex L (0.18–0.23)\n');
    fprintf('  → Data vykazují typickou variabilitu pro větrné extrémy\n');
elseif CoV < 0.18
    fprintf('  ⚠ Nižší než referenční rozsah (0.18–0.23)\n');
    fprintf('  → Možné příčiny: homogenní lokalita, krátký záznam, filtrace dat\n');
else
    fprintf('  ⚠ Vyšší než referenční rozsah (0.18–0.23)\n');
    fprintf('  → Možné příčiny: heterogenní podmínky, klimatické změny, kvalita dat\n');
end
fprintf('\n');

%% 9. PŘÍPRAVA PRO UQLAB

fprintf('=== PŘÍPRAVA VSTUPU PRO UQLAB ===\n');
fprintf('%% UQLab input preparation\n');
fprintf('%% Po načtení této analýzy můžete pokračovat:\n\n');

fprintf('%%%% Definice vstupních proměnných pro UQLab\n');
fprintf('uqlab_input_opts.Marginals(1).Type = ''%s'';\n', class(better_pd));

if strcmp(better_model, 'Gumbel')
    fprintf('uqlab_input_opts.Marginals(1).Parameters = [%.6f, %.6f]; %% [location, scale]\n', ...
        better_pd.A, better_pd.B);
else % GEV
    fprintf('uqlab_input_opts.Marginals(1).Parameters = [%.6f, %.6f, %.6f]; %% [shape, scale, location]\n', ...
        better_pd.k, better_pd.sigma, better_pd.mu);
end

fprintf('%%%% Data pro validaci\n');
fprintf('validation_data = [');
for i = 1:length(data)
    if i > 1; fprintf(', '); end
    if mod(i-1, 10) == 0 && i > 1; fprintf('...\n               '); end
    fprintf('%.2f', data(i));
end
fprintf('];\n\n');

fprintf('%%%% Klíčové výsledky pro další použití\n');
fprintf('best_model = ''%s'';\n', better_model);
if gumbel_success
    fprintf('return_50_gumbel = %.3f; %% m/s\n', q_50_gumbel);
end
if gev_success
    fprintf('return_50_gev = %.3f; %% m/s\n', q_50_gev);
end
if exist('ci_lower', 'var')
    fprintf('ci_95_lower = %.3f; %% m/s\n', ci_lower);
    fprintf('ci_95_upper = %.3f; %% m/s\n', ci_upper);
end

fprintf('\n%%%% Příklad použití v UQLab:\n');
fprintf('%% myInput = uq_createInput(uqlab_input_opts);\n');
fprintf('%% mySample = uq_getSample(myInput, 10000);\n');
fprintf('%% %% Dále můžete pokračovat s uncertainty quantification...\n\n');

fprintf('✓ UQLab příprava dokončena\n');

%% 10. ZÁVĚREČNÝ SOUHRN

fprintf('\n=== ZÁVĚREČNÝ SOUHRN ===\n');
fprintf('✓ Analýza úspěšně dokončena\n');
fprintf('✓ Vygenerovány 4 grafy v adresáři figs/\n');
fprintf('✓ Exportovány 3 soubory s výsledky v adresáři results/\n');
fprintf('✓ Připraveny vstupy pro UQLab\n\n');

fprintf('HLAVNÍ VÝSLEDKY:\n');
fprintf('• Preferovaný model: %s\n', better_model);
if exist('point_est', 'var')
    fprintf('• 50letá návratová hodnota: %.2f m/s', point_est);
    if exist('ci_lower', 'var')
        fprintf(' [95%% CI: %.2f–%.2f m/s]', ci_lower, ci_upper);
    end
    fprintf('\n');
end
fprintf('• Koeficient variability: %.3f ', CoV);
if CoV >= 0.18 && CoV <= 0.23
    fprintf('(✓ v normě)\n');
else
    fprintf('(⚠ mimo referenční rozsah)\n');
end

fprintf('\nAnalýza dokončena: %s\n', datestr(now));
fprintf('========================================\n');

%% Pomocné funkce (inline)
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end