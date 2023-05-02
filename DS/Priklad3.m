clc
clear
addpath('BNB')
% Definice omezení
lb = [0, 0];  % dolní hranice
ub = [10, 10]; % horní hranice

% Počáteční stav
x0 = [0, 0];

% Spuštění B&B algoritmu
options = optimoptions('intlinprog','Display','off');
[x,fval,exitflag,output] = BNB20(@F,x0,lb,ub,options);
