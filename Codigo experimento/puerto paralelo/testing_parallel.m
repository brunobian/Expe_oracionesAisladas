%http://www.alivelearn.net/?p=691

portDir = 'C100';
lptport = hex2dec(portDir);


dir = hex2dec('0'); % Código base. Del que parte y al que vuelve dsp de cada marca
for ii=0:255
    data = hex2dec(num2str(ii));    %esto es la data..
%     data = hex2dec('255');    
    lptwrite(lptport, data+dir);
%     lptwrite(lptport, data);

%     a=lptread(lptport); %por si quiero leer
    pause(0.1)
    lptwrite(lptport, dir)
    
    ii
end
