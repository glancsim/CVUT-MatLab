clc
clear
iter=0;
ro(1)=50;
ro(2)=50;
ro(3)=50;
ro(4)=50;
ro(5)=50;
ro(6)=50;
ro(7)=50;
P=ro;
for i = 1:1000
    N = P+randn(1,7);
    new = globalStabTorri(N);
    newEig(i) = min(new( new>=0 )); 
    N=P;
end