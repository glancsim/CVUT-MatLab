function tx = mat2tex(x,f)
%
% MAT2TEX  LaTeX code for a matrix.
%
%  MAT2TEX(X) returns latex code for NUM2STR(X).
%
%  MAT2TEX(X,FORMAT) returns latex code for NUM2STR(X,FORMAT).
%
%  See also num2str.
%  
% Example: 
%
% mat2tex(rand(6,4)*9999) =
%
% $\left[ \begin{array}{cccc}                              
% 9500.3427  &   4564.2202  &   9217.2079  &   4102.2918 \\
%  2311.154  &   185.01793  &   7381.3343  &   8935.6017 \\
%  6067.819  &   8213.2502  &   1762.4852  &   578.85516 \\
% 4859.3387  &   4446.5889  &   4056.6564  &   3528.3285 \\
% 8912.0984  &    6153.708  &   9353.7615  &   8130.8518 \\
% 7620.2062  &   7918.5784  &   9168.1275  &   98.603145   
% \end{array} \right]$  

% Mukhtar Ullah
% mukhtar.ullah@informatik.uni-rostock.de
% August 26, 2005

[m,n] = size(x);
b(1:m,:) = ' ';

if nargin<2
    s = [num2str(x) b];
else
    s = [num2str(x,f) b];
end

if n>1
    ib = find(ismember(s',b','rows'));             % blank columns
    k = find(diff(ib)>1);                          % blank to non-blank transitions
    i = fix(mean([ib([1;k(1:end-1)+1]) ib(k)],2)); % middle of blank areas
    s(:,i) = '&';
end

s(1:m-1,end+(1:2)) = '\';
c(1:n) = 'c';

tx = char({['$\left[ \begin{array}{',c,'}'], s, '\end{array} \right]$'});