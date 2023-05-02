clc
clear
addpath('tests/Volume')
load V00200.mat
V00200=testV;
load V00600.mat
V00600=testV;
load V01000.mat
V01000=testV;
load V05000.mat
V05000=testV;
load V10000.mat
V10000=testV;
load V15000.mat
V15000=testV;
load V20000.mat
V20000=testV;
load V30000.mat
V30000=testV

clear vars testV

Volumes(1,:)=sort(V00200);
Volumes(2,:)=sort(V00600);
Volumes(3,:)=sort(V01000);
Volumes(4,:)=sort(V05000);
Volumes(5,:)=sort(V10000);
Volumes(6,:)=sort(V15000);
Volumes(7,:)=sort(V20000);
Volumes(8,:)=sort(V30000);

Volumes(1,51)=mean(V00200);
Volumes(2,51)=mean(V00600);
Volumes(3,51)=mean(V01000);
Volumes(4,51)=mean(V05000);
Volumes(5,51)=mean(V10000);
Volumes(6,51)=mean(V15000);
Volumes(7,51)=mean(V20000);
Volumes(8,51)=mean(V30000);

f=figure
x = [200;600;1000;5000;10000;15000;20000;30000];
y = Volumes;
h = plot(x,y);
hold on
for i=1:51
    set(h(i),'Color',[125 125 125]/255);
end
set(h(1),'linewidth',1);
set(h(1),'color','blue');
set(h(50),'linewidth',1);
set(h(50),'color','blue');
set(h(51),'linewidth',2);
set(h(51),'color','red');

xlabel('Počet iterací');
ylabel('Objem materiálu');

set(f, 'PaperUnits', 'centimeters');
set(f, 'PaperSize', [30 10]);
