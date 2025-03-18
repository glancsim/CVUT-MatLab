clear 'x' 'y'
[iter,~] = size(results) ; 
y(:,1) = 1:iter;
x(:,1) = results(:,4) ;

cond = (x~= 0);

% Y7 = y(cond);
% X7 = x(cond);


data = {X1, Y1; X2, Y2; X3, Y3; X4, Y4; X5, Y5; X6, Y6; X7, Y7};

% Vykreslení křivek s vyhlazením
figure;
hold on;

for i = 1:size(data, 1)
    smoothedY = smoothdata(data{i, 1}, 'rloess'); % Vyhlazení pomocí metody 'rloess'
    smoothedX = smoothdata(data{i, 2}, 'rloess'); % Vyhlazení pomocí metody 'rloess'
    plot(smoothedX, smoothedY, 'LineWidth', 2);
end

hold off;

% Přidání popisků os a titulku
xlabel('X-osa');
ylabel('Vyhlazená Y-osa');
title('Vyhlazené grafy 7 křivek s různým počtem prvků');
legend('Křivka 1', 'Křivka 2', 'Křivka 3', 'Křivka 4', 'Křivka 5', 'Křivka 6', 'Křivka 7');
grid on;