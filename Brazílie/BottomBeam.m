%% LLENTAB - Prefabricated steel hall

clc;clear all;clearvars;uqlab;close all
%% Vazník - Dolní pás
% Section properties

section.h_w =  119.0   * 10^-3; % m
section.b   =  110.0   * 10^-3; % m
section.c   =   42.0   * 10^-3; % m
section.e_1 =   55.8   * 10^-3; % m
section.A_g = 1615.93  * 10^-6; % m^2
section.t   =    4.0   * 10^-3; % m
% Material properties

section.f_u =   480.0  * 10^3 ; % kN/m
section.f_y =   420.0  * 10^3  ; % kN/m
% Profile capacity

section.N_cRk =  652.65     ; % kN
section.M_Rk  =   22.57     ; % kNm
% Internal forces - characteristic values
forces.G.N_k = 161.89 * 1.00; %kN
forces.Q.N_k = 140.47 * 1.00; %kN
%% Probabilistic reliability analysis

N = 1000000; % počet simulací
% Probablistic models of variables
% Yeild strength

model.f_y.V_x = 5 / 100; % percent
model.f_y.ratio = 1.09 ;
model.f_y.Dist = 'Lognormal';
model.f_y.nominal = section.f_y;
model.f_y.variable = createUQVariable(model.f_y, 'fy');
InputOpts.Marginals(1) = model.f_y.variable;
% Geometry

model.a.V_x = 3 / 100; % percent
model.a.ratio = 1.00 ;
model.a.Dist = 'Gaussian';
model.a.nominal = section.A_g;
model.a.variable = createUQVariable(model.a, 'A');
InputOpts.Marginals(2) = model.a.variable;
% Pernament load

model.G.V_x = 5 / 100 ;% percent
model.G.ratio = 1.00 ;
model.G.Dist = 'Gaussian';
model.G.nominal = forces.G.N_k;
model.G.variable = createUQVariable(model.G, 'G');
InputOpts.Marginals(3) = model.G.variable;
% Snow load

model.Q.V_x = 50 / 100 ;% percent
model.Q.ratio = 0.40 ;
model.Q.Dist = 'Gaussian';
model.Q.nominal = forces.Q.N_k;
model.Q.variable = createUQVariable(model.Q, 'Q');
InputOpts.Marginals(4) = model.Q.variable;
% Resistance model uncertainty

model.theta_R.V_x = 6 / 100; % percent
model.theta_R.ratio = 1.15 ;
model.theta_R.Dist = 'Lognormal';
model.theta_R.nominal = 1;
model.theta_R.variable = createUQVariable(model.theta_R, 'ThetaR');
InputOpts.Marginals(5) = model.theta_R.variable;
% Load effect model uncertainty

model.theta_E.V_x = 7.5 / 100 ;% percent
model.theta_E.ratio = 1.00 ;
model.theta_E.Dist = 'Lognormal';
model.theta_E.nominal = 1;
model.theta_E.variable = createUQVariable(model.theta_E, 'ThetaE');
InputOpts.Marginals(6) = model.theta_E.variable;
% UQLab variables

% Vytvoření vstupního objektu pro UQlab
inputOpts.Marginals = InputOpts.Marginals;  % Přiřazení všech marginalit
input = uq_createInput(inputOpts);  % Vytvoření vstupního objektu pro analýzu
%% Definice limitní funkce (Limit State Function - LSF)
% $$g(x) = \theta _R \cdot R - \theta _E \cdot (G + Q)$$

ModelOpts.mFile = 'limitStateFunction';
ModelOpts.isVectorized = true;

% Vytvoření modelu
myModel = uq_createModel(ModelOpts);

% Definice metody Monte Carlo pro výpočet pravděpodobnosti poruchy
SimOpts.Type = 'Reliability';
SimOpts.Method = 'MCS';
SimOpts.Simulation.MaxSampleSize = N;

% Vytvoření a spuštění analýzy
reliability = uq_createAnalysis(SimOpts);
results = reliability.Results;

% Výpočet beta indexu
% Oprava: použití správné funkce pro inverzní normální distribuční funkci
beta = -norminv(results.Pf);

% Výpis výsledků
fprintf('Pravděpodobnost poruchy: Pf = %e\n', results.Pf);
fprintf('Index spolehlivosti: β = %.4f\n', beta);

% % Vizualizace výsledků
% figure;
% uq_display(reliability);
% title('Analýza spolehlivosti - Dolní pás vazníku');
% 
% % Analýza citlivosti
% if isfield(results, 'Sensitivity')
%     figure;
%     bar(results.Sensitivity.Value);
%     set(gca, 'XTickLabel', {model.f_y.variable.Name, model.a.variable.Name, ...
%         model.G.variable.Name, model.Q.variable.Name, ...
%         model.theta_R.variable.Name, model.theta_E.variable.Name});
%     title('Analýza citlivosti');
%     ylabel('Citlivostní index');
%     grid on;
% end