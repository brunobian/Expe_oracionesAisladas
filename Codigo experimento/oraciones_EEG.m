function oraciones()

%      EVENTO                      | marca ET      | marca eeg
% Base                             |               | 0
% inicio expe                      | keyword 244   | 244
% inicio bloque                    | keyword 254   | 254
% cruz de fijacion                 | keyword i     | i (i: orac ID)
% aparece punto rojo               | keyword 220   | 220
% aparece text, start lectura Prov | keyword 230   | 230
% aparece text, start lectura Cont | keyword 231   | 231
% aparece text, start lectura Train| keyword 233   | 233
% desaparece texto, fin lectura	   | keyword 221   | 221
% aparece pregunta                 | keyword 222   | 222
% responde, desparece pregunta	   | keyword 223   | 223
% fin trial	                       | keyword 224   | 224
% Final bloque                     | keyword 254   | 255
% Final expe                       | keyword 245   | 245


try 
   
addpath('C:\EXPE\eyetracker_Funciones\funciones_eyetracker')  %adaptarlo al directorio que usemoes en la UNS
addpath('C:\Users\LNI\Documents\Bbianchi\puerto paralelo')

    pathname='C:\Users\LNI\Documents\Bbianchi';   
    filename='oracionesFINAL';    
    load(fullfile(pathname, filename))
    disp(['Archivo de oraciones ' filename ' cargado.'])    
    DATA=Shuffle(DATA);%#ok<NODEF> % revuelve las oraciones.
    DATA=agrega_preguntasino(DATA,.3);
    
    % cargo las oraciones de practica
    disp('Archivo de práctica "oracionesPRACTICA" cargado.')
    DATAPRACT=load('oracionesPRACTICA');DATAPRACT=DATAPRACT.DATA;
    DATAPRACT=agrega_preguntasino(DATAPRACT,.5);
%     
%  preguntas iniciales
    respuesta= inputdlg({'Nombre (no más de 8 caracteres)' ...
                         'Edad' ...
                         '¿Usamos Eyelink?(S/N)' ...
                         '¿Usamos EEG?(S/N)' ...
                         'Inicio'},...
                         'Ingrese su Nombre',1,{'test' '24' 'S' 'S' '1'});
                     
    if isempty(respuesta)
        return
    end
    filename=respuesta{1};
    init.etConectado=strcmp(upper(respuesta{3}),'S');  
    if init.etConectado 
        disp('Eyetracker en uso.')
    else
        disp('Modo prueba, sin conexión con el Eyetracker.')        
    end
    
%  inicializa video y eyelink
    ListenChar(2)%hace que los keypresses no se vean en matlab editor (ojo hay que habilitarlo al final del programa!)
    if init.etConectado        
        PARAMS.calBACKGROUND = 255;
        PARAMS.calFOREGROUND = 0;       
        
        [temp el]=eyelink_ini_custom(filename,PARAMS); %inicializa eyetracker

        init.eyelink_conf=el;
%         Eyelink('command','heuristic_filter=1 1'); %setea filtro STD para ver microsacadas
        sca%si no lo cierro, despues no puedo recalibrar, pues pierdo el handle, si lo inicializo de nuevo
    end    
    if init.etConectado       
        %transfiero la imagen a la compu de host
        finfo = imfinfo('imagen.bmp');
        finfo.Filename 
        Eyelink('StopRecording');
        transferStatus = Eyelink('ImageTransfer', finfo.Filename ,0,0,0,0,round(init.width/2 - finfo.Width/2) ,round(init.height/2 - finfo.Height/2),4);
        if transferStatus ~= 0
            fprintf('Image to host transfer failed\n');
        end
        WaitSecs(0.1);
        Eyelink('StartRecording');    
    end    
    disp(' ')    
    [w init]=inicializa_video(init); %#ok<NODEF> %inicializa video y variables
    init.eyelink_conf.window=w;% le dice al eyetracker que use la misma window que acabo de inicializar    
    disp(' ')
    
    % Inicializo cosas de EEG y ET (para co-registro)
    init.eegConect =strcmp(upper(respuesta{4}),'S');
    init.portDir   = 'C100'; % Direccion del puerto
    init.lptport   = hex2dec(init.portDir);
    init.baseCode  = 0; % Código base. Del que parte y al que vuelve dsp de cada marca
    
    % Arranco el EEG y el ET con una marca
    %%%% VIEJOOOO %%%%
    % init.dio= digitalio('parallel','LPT1');
    % out_lines=addline(init.dio,0:7,0,'out'); 
    % % primero es el objeto creado para mandar info, 
    % % 0:7 las lineas del objeto a usar, 
    % % 0 la linea del digital port creado, 
    % % 'out' si es entrada o salida (en este caso salida)
    % putvalue(init.dio.line(1:8),dec2binvec(0,8));

    %%%% NUEVOOO %%%%
    % Envio comienzo de experimento
    eegMsg = 244;
    etMsg = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)
    
    % Envio comienzo de bloque
    eegMsg = 254;
    etMsg = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)
    
    % pseud-calibracion
    if init.etConectado    
        pseudo_calibracion(w,init);
    end
    
% PRÁCTICA!!!!!!
% PRÁCTICA!!!!!!    
% PRÁCTICA!!!!!!
    Screen('fillrect',w,init.colback)% aparece una pantalla para empezar la practica
    Screen('TextSize', w, 20);%ver tamaño    
    Screen('DrawText', w, 'Pulse una tecla para comenzar práctica',init.CX-300,init.CY-100,0);
    t=GetSecs;Screen('Flip', w,t+init.ifi);
    while ~KbCheck;end %espero a que toque una tecla
    Screen('FillRect', w, init.colback);
    t=GetSecs;Screen('Flip', w,t+init.ifi); 
    while KbCheck;end  %espero a que la suelte!!!
    
    start = str2num(respuesta{5});
    for trial=1:length(DATAPRACT)
        if start  == 1 % Si estamos corriendolo por primera vez
            [DATAPRACT init cond_salida_pract]=runtrial(DATAPRACT,w,init,trial);%un trial
            if cond_salida_pract==1
                disp(['Práctica interrumpida en el trial ' num2str(trial) '.'])            
                break
            end
            save('porsi','DATA','init','DATAPRACT');
        else
            cond_salida_pract=0 ;
        end
    end
    
    % Envio marca final de bloque
    eegMsg = 255;
    etMsg = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)
    
% EXPERIMENTO!!!!!!
% EXPERIMENTO!!!!!!    
% EXPERIMENTO!!!!!!
    if cond_salida_pract==0 %solo hago el experimento si no abortaron la practica
        if  start > 1 % Si estamos corriendolo por segunda vez
            load(filename)
            DATA(1)
        end
        
        Screen('fillrect',w,init.colback)
        Screen('TextSize', w, 20);%ver tamaño    
        Screen('DrawText', w, 'Fin de la práctica',init.CX-200,init.CY-100,0);
        Screen('DrawText', w, 'Pulse una tecla para comenzar el experimento',init.CX-300,init.CY,0);
        t=GetSecs;Screen('Flip', w,t+init.ifi);        
        while ~KbCheck;end %espero a que toque una tecla
        Screen('FillRect', w, init.colback);
        t=GetSecs;Screen('Flip', w,t+init.ifi); 
        while KbCheck;end  %espero a que la suelte!!!        
        WaitSecs(1);
        
        % Envio marca inicio de bloque
        eegMsg = 254;
        etMsg = ['keyword ' num2str(eegMsg)];
        sendTriggers(init, eegMsg, etMsg)

        for trial=start:length(DATA) %corre los trials desde el idicado en el prompt
            [DATA init cond_salida]=runtrial(DATA,w,init,trial);%un trial
            if cond_salida==1
                disp(['Experimento interrumpido en el trial ' num2str(trial) '.'])
                
                % Envio marca final de bloque
                eegMsg = 255;
                etMsg = ['keyword ' num2str(eegMsg)];
                sendTriggers(init, eegMsg, etMsg)
                break
            end
            
            if mod(trial,42)==0
                % Envio marca final de bloque
                eegMsg = 255;
                etMsg = ['keyword ' num2str(eegMsg)];
                sendTriggers(init, eegMsg, etMsg)
                
                instrucciones={'Vamos a hacer una pausa para descansar.' '' 'Pulse una tecla cuando esté listo para seguir.'};
                muestra_instrucciones(w,init,instrucciones);

                recalibracion(init.eyelink_conf)                                              
                
                pseudo_calibracion(w,init);            
                
                % Envio marca inicio de bloque
                eegMsg = 254;
                etMsg = ['keyword ' num2str(eegMsg)];
                sendTriggers(init, eegMsg, etMsg)
            end                  
            
            save('porsi','DATA','init','DATAPRACT');
        end
          
        
        % pseud-calibracion
        if init.etConectado    
            pseudo_calibracion(w,init);
        end
    end
    
    % Envío marcas del Final del Experimento
    eegMsg = 255;
    etMsg  = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)
    
    % Envio fin de experimento
    eegMsg = 245;
    etMsg = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)  
    
    % FIN EXPERIMENTO!!!!!!    
    ListenChar(0)%vuelve a la normalidad. si no pude ejecutarlo, ctrl+c hace lo mismo    
    sca   
    if init.etConectado
        eyelink_end
    end
    save(filename,'DATA','init','DATAPRACT')
  
    %%cierra todo y se va
    Screen('CloseAll');
    sca
    if init.etConectado
            fprintf('comentado  eyelink_receive_file(filename)\n')
    end
    disp('Fin!!')

   
    
    
% FIN EXPERIMENTO!!!!!!    
% FIN EXPERIMENTO!!!!!!        
% Catch errores
catch ME
    disp(ME)
    ListenChar(0)%vuelve a la normalidad. si no pude ejecutarlo, ctrl+c hace lo mismo
    sca
    disp('Error!!')
    Screen('CloseAll');
    if init.etConectado
        eyelink_end
    end
    Priority(0);
    ShowCursor
    if init.etConectado
        fprintf('comentado  eyelink_receive_file(filename)\n')
    end
    save porsi DATA init DATAPRACT
    ListenChar(0)
    disp('Tipear dbcont (o F5) para salir, o mierror para ver el error' )
    keyboard
end
end


% %%%%%%% FUNCIONES
function sendTriggers(init, message, etMsg)
        
    % Si hay ET, mando al ET
    if init.etConectado
        Eyelink('Message', etMsg);
    end
    
    if init.eegConect
        lptwrite(init.lptport, message+init.baseCode);
        pause(0.05)
        lptwrite(init.lptport, init.baseCode);
    end
end

function recalibracion(el)
    disp('Launch calibration')
    
    Eyelink('StopRecording'); 
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);

    % do a final check of calibration using driftcorrection
    EyelinkDoDriftCorrection(el);

    % borra las teclas del buffer de teclado
    FlushEvents('keydown')

    Eyelink('StartRecording');  
end  

function DATA=agrega_preguntasino(DATA,proporcion)
    for i=1:length(DATA)  %%busco las oraciones que no tienen pregunta
        l(i)=length(DATA(i).pregunta);
    end
    ind=find(l>1); % las oraciones que tienen pregunta...
    ind=Shuffle(ind); % las revuelvo
    proporcion_oraciones_con_pregunta=proporcion;
    cuantas_preguntas=ceil(length(ind)*proporcion_oraciones_con_pregunta);
    ind=ind(1:cuantas_preguntas); %me quedo con las primeras (en el orden shuffleado)

    preguntasino=zeros(length(DATA),1);           
    preguntasino(ind)=1;

    for i=1:length(DATA)
        DATA(i).preguntasino=preguntasino(i);
    end
end

function [DATA,init,cond_salida]=runtrial(DATA,w,init,trial)  
    cond_salida=0;
    
    %cruz de fijacion al principio
    Screen('FillRect', w, init.colback);
    drawfix(w,init);
    t=GetSecs;Screen('Flip', w,t+init.ifi);     

    % Envío marcas de la cruz
    etMsg = ['keyword ' num2str(trial)];
    sendTriggers(init, trial, etMsg)
    
    keyCode=espero_mouse_teclado(2);%espero a lo sumo un rato 
    %si aprieta esc, saldra
    %si aprieta C, recalibra    
        
    %pantalla en blanco al tocar una tecla
    Screen('FillRect', w, init.colback);
    t=GetSecs;Screen('Flip', w,t+init.ifi);             
    espero_suelte_mouse_teclado;
    if find(keyCode)==27 % si toca esc, termino
        cond_salida=1;
        return
    end    
    
    if find(keyCode)==67 % si toca C, hago una recalibracion
        if init.init.etConectado
            str='Recalibracion';
            if Eyelink('isconnected');Eyelink('Message', str);end  
            
            
            recalibracion(init.eyelink_conf);        
                    %cruz de fijacion al principio
            Screen('FillRect', w, init.colback);
            drawfix(w,init);
            t=GetSecs;Screen('Flip', w,t+init.ifi);     

            %espero a que toque un boton del mouse o teclado, y que lo suelte
            espero_mouse_teclado;
        end
    end    
    
    WaitSecs(.5);

    % PONGO puntito donde va la primera letra
    cx=DATA(trial).posoracion(1);
    cy=mean(DATA(trial).posoracion([3 4]));
    size=8;
    pos_1raletra=[cx-size cy-size cx+size cy+size];       
    Screen('FillRect', w,init.colback);
    Screen('FillOval', w,[255 0 0], pos_1raletra);
    t=GetSecs;Screen('Flip', w,t+init.ifi); 
    
    % Envío marcas del puntito (220)
    etMsg = ['keyword ' num2str(220) num2str(trial)];
    sendTriggers(init, 220, etMsg)
    
    %espero a que el ojo este en donde la primera letra
    [tresp condicion] = espera_posicion_ojo([cx cy],30,0);
    WaitSecs(0.2);
    DATA(trial).tresp_ojo1=tresp; %tiempo de respuesta del ojo a la primera letra
    DATA(trial).condicion1=condicion; % condicion de salida primera letra=[0=ojo 1=timeout 2=teclado 3=mousebutton]
  
    %escribe la oracion en la pantalla    
    Screen('fillrect',w,init.colback);
    temp=Screen('maketexture',w,DATA(trial).imagen);
    Screen('drawtexture',w,temp);
    cx=DATA(trial).posoracion(2);
    cy=mean(DATA(trial).posoracion([3 4]));
    anchoCaracter = 5*(DATA(trial).posoracion(2)-DATA(trial).posoracion(1))/length(DATA(trial).oracion);
    pos_punto=[cx+anchoCaracter-size cy-size cx+anchoCaracter+size cy+size];     
    Screen('FillOval', w,[255 0 0], pos_punto);   
    t=GetSecs;Screen('Flip', w,t+init.ifi); 
    Screen('close',temp);
    
    % Envío marcas del Comienzo de lectura
    eegMsg = 230+DATA(trial).tipo;
    etMsg  = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)
       
    % espera fin de la lectura
    [tresp condicion]=espera_posicion_ojo([cx cy],30,0);
    
    %desaparece la oracion, el puntito rojo queda por otros 300ms
    Screen('FillRect', w, init.colback);
    Screen('FillOval', w,[0 128 0], pos_punto);  %dibuja el puntito otro rato
    t=GetSecs;Screen('Flip', w,t+init.ifi);     
    DATA(trial).tresp_ojo2=tresp; %tiempo de respuesta del ojo al fin de la lectura
    DATA(trial).condicion2=condicion; % condicion de salida lectura=[0=ojo 1=timeout 2=teclado 3=mousebutton]

    % Envío marcas del Fin de lectura
    eegMsg = 221;
    etMsg  = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)

    % Espero 300ms y pongo pantalla en blanco.
    WaitSecs(0.3);
    Screen('FillRect', w, init.colback);
    t=GetSecs;Screen('Flip', w,t+init.ifi);     

    % Toma respuesta con 3 opciones
    if DATA(trial).preguntasino==1
        [DATA]=toma_respuesta_pregunta(w,init,DATA,trial); 
    end

    % Envío marcas de Fin trial
    eegMsg = 224;
    etMsg  = ['keyword  ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)

    a=imaqmem;DATA(trial).mem=a.AvailPhys;    
end

function drawfix(window,init)
%    [width, height]=Screen('WindowSize', window);
%    CX=width/2;CY=height/2;

    color=0; %negro
    width=3;
    radio=10;
    pointList=radio*[[1 -1 0 0];[0 0 1 -1]];
    Screen('DrawLines', window, pointList ,width,color,[init.CX,init.CY]);
end

function [DATA]=toma_respuesta_pregunta(w,init,DATA,trial) 
try
  
    %genera la pantalla con todo
    wresp=Screen(w,'OpenOffscreenWindow', init.colback);
    impregunta=Screen('maketexture',w,DATA(trial).impregunta);  
    Screen('drawtexture',wresp,impregunta);Screen('close',impregunta)    
    opciones(1).opcion=DATA(trial).target;
    opciones(2).opcion=DATA(trial).opcion1;
    opciones(3).opcion=DATA(trial).opcion2;    
    opciones(1).target=1;
    opciones(2).target=0;
    opciones(3).target=0;
    opciones(1).imagen=DATA(trial).imtarget;
    opciones(2).imagen=DATA(trial).imopcion1;
    opciones(3).imagen=DATA(trial).imopcion2;    
    opciones(1).posicion=DATA(trial).postarget([1 3 2 4]);
    opciones(2).posicion=DATA(trial).posopcion1([1 3 2 4]);
    opciones(3).posicion=DATA(trial).posopcion2([1 3 2 4]);
    opciones=Shuffle(opciones);
    opciones(1).posicion=opciones(1).posicion+[-200 100 -200 100];
    opciones(2).posicion=opciones(2).posicion+[ 0   100   0  100];
    opciones(3).posicion=opciones(3).posicion+[ 200 100  200 100];
    for i=1:3
        opciones(i).frame=opciones(i).posicion+[-10 -10 10 10];
    end
    for i=1:3    
        imtemp=Screen('maketexture',w,opciones(i).imagen);
        Screen('drawtexture',wresp,imtemp,[],opciones(i).posicion);
        Screen('close',imtemp)
    end
    
    % Envío marcas del Comienzo Pregunta
    eegMsg = 222;
    etMsg  = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)

    % loop mientras responde
    aux=0;
    while aux==0 %sale cuando se responde
        [x,y,buttons] = GetMouse;
        indopcion=1+floor(3*x/init.width);
        
        Screen('drawtexture',w,wresp);        
        Screen('framerect', w, [0 0 255],opciones(indopcion).frame,2);
        t=GetSecs;Screen('Flip', w,t+init.ifi);
        

        %buttons=1;disp('buttons=1 hace que no pare para la seguridad')
        if any(buttons) 
            aux=1;
            DATA(trial).opciones={opciones.opcion};
            DATA(trial).indopcion=indopcion;
            DATA(trial).opcion_elegida=opciones(indopcion).opcion;
            DATA(trial).correcta=opciones(indopcion).target;
        end
        [keyIsDown, seconds, keyCode] = KbCheck;   
        if (keyIsDown && keyCode(27)); %escape!!
            aux=1;
        end

    end
    Screen('close',wresp)
    
    %cruz de fijacion
    Screen('FillRect', w, init.colback);
    t=GetSecs;Screen('Flip', w,t+init.ifi); 

    % Envío marcas del Fin Pregunta
    eegMsg = 223;
    etMsg  = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)

    while any(buttons)% espera a que suelte el boton
        [x,y,buttons] = GetMouse;
    end
catch
    ListenChar(0)
    sca
    keyboard
end
end

function pseudo_calibracion(window,init)   
    xx=[.2 .5 .8 .2 .5 .8 .2 .5 .8]*init.width;
    yy=[.2 .2 .2 .5 .5 .5 .8 .8 .8]*init.height;
    
    Screen('FillRect', window,init.colback);
    Screen('TextSize', window, 20);%ver tamaï¿½o    
    Screen('DrawText', window, 'Mire los puntitos que aparecen',init.CX-200,init.CY-100,init.coltext);
    Screen('DrawText', window, 'Pulse una tecla para comenzar ',init.CX-200,init.CY,init.coltext);
    t=GetSecs;Screen('Flip', window,t+init.ifi); 
  
    espero_mouse_teclado;
    espero_suelte_mouse_teclado;
    WaitSecs(.5);  
    
    for i=1:length(xx)             
        Screen('FillRect', window,init.colback);
        ssize=10;
        poscirculo=[xx(i)-ssize yy(i)-ssize xx(i)+ssize yy(i)+ssize];       
        Screen('FillOval', window,init.coltext, poscirculo);
        ssize=2;
        poscirculo=[xx(i)-ssize yy(i)-ssize xx(i)+ssize yy(i)+ssize];       
        Screen('FillOval', window,init.colback, poscirculo);
        t=GetSecs;Screen('Flip', window,t+init.ifi); 
        str=['pseudocalib ' num2str(xx(i)) ',' num2str(yy(i)) ];
        if init.etConectado
            if Eyelink('isconnected');Eyelink('Message', str);end          
            [tresp condicion]=espera_posicion_ojo([xx(i) yy(i)],30,0);%espero a que el ojo este en donde la primera letra
        else
            condicion=2;
        end
        Screen('FillRect', window,init.colback);
        ssize=10;
        poscirculo=[xx(i)-ssize yy(i)-ssize xx(i)+ssize yy(i)+ssize];       
        Screen('FillOval', window,init.coltext, poscirculo);        
        ssize=2;
        poscirculo=[xx(i)-ssize yy(i)-ssize xx(i)+ssize yy(i)+ssize];       
        Screen('FillOval', window,[255 0 0], poscirculo);
        
        t=GetSecs;Screen('Flip', window,t+init.ifi); 
        if condicion==2%si toca una tecla, salgo
            break
        end
        WaitSecs(.2);        
    end
    Screen('FillRect', window,init.colback);
    Screen('Flip', window); 
end

function [tresp condicion]=espera_posicion_ojo(posicion,tamanio,tiempomax)
%[tresp condicion]=espera_posicion_ojo([512 384],30,0);
%condicion: 0->ojo entro a la region 1->timeout 2->teclado 
    tstart=GetSecs;
    while 1
        [x,y,buttons] = GetMouse;
        if max(buttons)>0 % si toca boton mouse sale con condicion 3
            while any(buttons)
                [x,y,buttons] = GetMouse;
            end
            condicion=3;
            break             
        end
        if KbCheck %si toca una tecla salgo con condicion 2
            condicion=2;
            while KbCheck;end % espera a que sueltes el teclado
            break 
        end
        if tiempomax>0 && GetSecs-tstart<tiempomax    %si pasa el tiempomax  salgo con condicion 1
           condicion=1;
           break
        end
        if Eyelink('isconnected')
            if Eyelink( 'NewFloatSampleAvailable') > 0 %se fija si hay un nuevo dato
                evt = Eyelink( 'NewestFloatSample'); % pide el dato actual
                %evt.time es eltiempo
                %evt.gx es un vector con [posxleft posxright] 
                %evt.gy es un vector con [posyleft posyright] 
                %evt.pa es un vector con [tampupilaleft tampupilaright] 
                distleft =sqrt((evt.gx(1)-posicion(1))^2+(evt.gy(1)-posicion(2))^2);
                distright=sqrt((evt.gx(2)-posicion(1))^2+(evt.gy(2)-posicion(2))^2);            
                if distleft<tamanio || distright<tamanio %si ojo posicion salgo con condicion 0
                    condicion=0;
                    break
                end
            end
        end
    end
    tresp=GetSecs-tstart;    
end

function [w init]=inicializa_video(init)
    doublebuffer=1;
    screenNumber=max(Screen('Screens'));
    [w, rect] = Screen('OpenWindow', screenNumber, 0,[], 32, doublebuffer+1); %#ok<NASGU>
    [init.width, init.height]=Screen('WindowSize', w);
    init.CX=init.width/2;
    init.CY=init.height/2;
    init.ifi=Screen('GetFlipInterval', w);
    init.fps=Screen('FrameRate',w);      % frames per second
    init.colback=200 ;    

    
    Screen('FillRect', w, init.colback);  
    t=GetSecs;Screen('Flip', w,t+init.ifi);    
    HideCursor;

end

function muestra_instrucciones(w,init,instrucciones)
% muestra instrucciones en la pantalla   

    [width, height]=Screen('WindowSize', w);               
    Screen('TextSize', w, 18);%ver tamaño            
    Screen('FillRect', w, init.colback);    
    for i=1:length(instrucciones)
        Screen('DrawText', w,instrucciones{i} ,width*.1,height*.15+40*i, 0);    
    end
    Screen('Flip', w);  

    espero_mouse_teclado;
    Screen('FillRect', w, init.colback);    
    Screen('Flip', w);      

    espero_suelte_mouse_teclado;
    
end

function [keyCode,x,y,buttons]=espero_mouse_teclado(tiempomax)
    %espero a que toque un boton del mouse o teclado, y que lo suelte
    if nargin==0
        tiempomax=1e6;
    end
    
    tic;
    [x,y,buttons] = GetMouse;
    [ keyIsDown, seconds, keyCode ]=KbCheck;
    while max(buttons)==0 && ~keyIsDown && toc<tiempomax% mientras no toca teclado o mouse espero.
        [x,y,buttons] = GetMouse;            
        [ keyIsDown, seconds, keyCode ]=KbCheck;            
        WaitSecs(0.001);
    end
end

function espero_suelte_mouse_teclado
    [x,y,buttons] = GetMouse;
    [ keyIsDown, seconds, keyCode ]=KbCheck;
    while max(max(buttons),keyIsDown) % mientras este tocando teclado o mouse espero.        
        [x,y,buttons] = GetMouse;            
        [ keyIsDown, seconds, keyCode ]=KbCheck;            
        WaitSecs(0.001);
    end

end
