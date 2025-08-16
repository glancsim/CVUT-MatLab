function UQVar = createSnowGumbelDistribution(s_gk, varName)
% createSnowGumbelDistribution - Vytvoří UQLab proměnnou s Gumbelovým
% rozdělením na základě historických dat maxim sněhu na zemi
%
% Syntax:
%   UQVar = createSnowGumbelDistribution(s_gk, varName)
%
% Inputs:
%   s_gk    - vektor obsahující maxima sněhu v jednotlivých letech [kN/m²]
%   varName - název proměnné (string)
%
% Output:
%   UQVar   - struktura proměnné pro UQLab s Gumbelovým rozdělením
%
% Popis:
%   Funkce zpracuje historická data maxim sněhu a vytvoří Gumbelovo rozdělení
%   pro použití v UQLabu. Gumbelovo rozdělení je vhodné pro modelování 
%   extrémních hodnot, jako jsou právě maxima sněhu.

% Kontrola vstupních dat
if isempty(s_gk)
    error('Vstupní data jsou prázdná.');
end

if ~isnumeric(s_gk) || ~isvector(s_gk)
    error('Vstupní data musí být numerický vektor.');
end

% Odstraníme NaN hodnoty a zkontrolujeme, zda máme dostatek dat
s_gk = s_gk(~isnan(s_gk));
if length(s_gk) < 5
    warning('Pro spolehlivý odhad Gumbelova rozdělení je doporučeno mít alespoň 10 let dat. Aktuální počet: %d', length(s_gk));
end

% Pomocí metody momentů odhadneme parametry Gumbelova rozdělení
mean_value = mean(s_gk);  % Průměr dat
std_dev = std(s_gk);      % Směrodatná odchylka dat

% Výpočet parametrů Gumbelova rozdělení
% Pro Gumbelovo rozdělení: 
% β (beta) = std_dev * sqrt(6) / pi      - scale parameter
% μ (mu) = mean_value - 0.5772 * beta    - location parameter
beta_gumbel = std_dev * sqrt(6) / pi;
mu_gumbel = mean_value - 0.5772 * beta_gumbel;

% Vytvoření struktury pro UQLab
UQVar = struct();
UQVar.Name = varName;
UQVar.Type = 'Gumbel';
UQVar.Parameters = [mu_gumbel, beta_gumbel];

% Volitelná vizualizace - porovnání histogramu dat a fitu
if nargout == 0 || (nargin > 2 && varargin{1})
    figure;
    
    % Histogram dat
    histogram(s_gk, 'Normalization', 'pdf');
    hold on;
    
    % Vygenerujeme křivku hustoty Gumbelova rozdělení
    x_range = linspace(min(s_gk) - std_dev, max(s_gk) + 2*std_dev, 1000);
    pdf_values = gumbel_pdf(x_range, mu_gumbel, beta_gumbel);
    
    % Vykreslíme distribuční funkci
    plot(x_range, pdf_values, 'r-', 'LineWidth', 2);
    
    % Popisky grafu
    title('Histogram dat a fit Gumbelova rozdělení');
    xlabel('Maxima sněhu [kN/m²]');
    ylabel('Hustota pravděpodobnosti');
    legend('Historická data', 'Gumbelovo rozdělení');
    grid on;
end

% Výpis informací o vytvořeném rozdělení
if nargout == 0
    fprintf('===== Vytvořeno Gumbelovo rozdělení pro sněhová maxima =====\n');
    fprintf('Název proměnné: %s\n', varName);
    fprintf('Počet použitých dat: %d\n', length(s_gk));
    fprintf('Průměrná hodnota dat: %.4f kN/m²\n', mean_value);
    fprintf('Směrodatná odchylka dat: %.4f kN/m²\n', std_dev);
    fprintf('Parametry Gumbelova rozdělení:\n');
    fprintf('- Location parameter (μ): %.4f\n', mu_gumbel);
    fprintf('- Scale parameter (β): %.4f\n', beta_gumbel);
    fprintf('============================================================\n');
end

end

% Pomocná funkce pro výpočet hustoty pravděpodobnosti Gumbelova rozdělení
function y = gumbel_pdf(x, mu, beta)
    z = (x - mu) / beta;
    y = (1/beta) * exp(-(z + exp(-z)));
end