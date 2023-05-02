clc
clear
load Volumes.mat
Volumes=Volumes+4;
f=figure
x = [200;600;1000;5000;10000;15000;20000;30000];
y = Volumes;
h = plot(x,y);
for i=1:50
    set(h(i),'Color',[125 125 125]/255);
end
set(h(1),'linewidth',1);
set(h(1),'color','blue');
set(h(1),'linestyle','--');
set(h(50),'linewidth',1);
set(h(50),'color','blue');
set(h(50),'linestyle','--');
set(h(51),'linewidth',3);
set(h(51),'color','red');
set(h(51),'linestyle','-.');

handlevec = [h(1) h(50) h(51)];
legend(handlevec, 'min', 'max', 'průměr') % pridani legendy ke grafu

xlabel('Maximální počet iterací při spuštění');
ylabel('Objem materiálu');

set(f, 'PaperUnits', 'centimeters');
set(f, 'PaperSize', [30 10]);
