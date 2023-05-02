clc
clear
S = [1:10; 1:10];

% Inicializace prohledávání
x_best = S(:,10); % nejlepší kombinace proměnných
f_best = F(x_best); % hodnota F pro nejlepší kombinaci proměnných
subspaces = {S}; % fronta podprostorů prohledávání

% Hlavní cyklus B&B algoritmu
while ~isempty(subspaces)
    % Výběr podprostoru prohledávání a jeho odstranění z fronty
    S = subspaces{1};
    subspaces = subspaces(2:end);
    
    % Určení dolních a horních mezí pro proměnné v S
    lb = min(S,[],2);
    ub = max(S,[],2);
    
    % Spočítání hodnot F pro každou kombinaci proměnných v S
    F_vals = zeros(size(S,2),1);
    for i = 1:size(S,2)
        F_vals(i) = F(S(:,i));
    end
    
    % Určení nejlepší kombinace proměnných a její hodnoty F v S
    [f_min, idx] = min(F_vals);
    x_min = S(:,idx);
    
    % Pokud je aktuální řešení lepší než nejlepší dosud nalezené, uložit jej jako nové nejlepší řešení
    if f_min < f_best
        f_best = f_min;
        x_best = x_min;
    end
    
    % Ořezávající strategie: Pokud je hodnota F pro nejlepší kombinaci proměnných v S vyšší než aktuální nejlepší hodnota F, není nutné prohledávat další podprostory
    if f_min >= f_best
        continue;
    end
    
    % Rozdělení podprostoru S a vložení nových podprostorů do fronty prohledávání
    for i = 1:size(S,1)
        for j = lb(i):ub(i)
            idx = find(S(i,:) == j);
            if isempty(idx)
                continue;
            end
            S_new = S;
            S_new(i,idx) = [];
            subspaces{end+1} = S_new;
        end
    end
end

% Výsledky
disp(['Nejlepší kombinace proměnných: x1 = ' num2str(x_best(1)) ', x2 = ' num2str(x_best(2))]);
disp(['Hodnota F pro nejlepší kombinaci proměnných: ' num2str(f_best)]);
