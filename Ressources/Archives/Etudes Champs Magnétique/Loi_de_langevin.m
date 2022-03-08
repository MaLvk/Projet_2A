close all
clear all

phi = 7.3/100;
dp = 10*10^(-9);
T=293.15;
M0=4.5*10^5;
kb = 1.380649*10^-23;

H=0:0.01:3;
alpha = ((pi()*M0*power(dp,3)*H)./(6*kb*T));
M=phi*M0*(coth(alpha)-1./alpha);
figure();
p=plot(H,M,'r');
p(1).Marker='.';
xlabel('μ_0 H');
ylabel('M');
title('Loi de langevin');

