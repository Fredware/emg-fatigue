function finalPlot(data,control,tdata,tcontrol)
% this function plots both the data and the control values for each input.
% This allows users to see how they both look after recording them. 
%  = imresize(control,[1 length(data)]);
figure()
subplot(211)
plot(tdata,data(~isnan(data)))
ylabel('V')
xlabel('Time (s)')
ylim([-3.0, 3.0]);
yticks(-2.5:0.5:2.5)

grid on

subplot(212)
plot(tcontrol,control(~isnan(control)))
ylabel('C')
xlabel('Time (s)')
end