% seradi vlastni cisla a vektory podle absolutni hodnoty
%
function [e,v] = sorteigval (e,v)

%sort eigenvalues
[e,i]=sort(e);
n=size(e);

%sort eigenvectors (stored in columns)
for c=1:n
	vs(:,c)=v(:,i(c));
end;

v=vs;
end
