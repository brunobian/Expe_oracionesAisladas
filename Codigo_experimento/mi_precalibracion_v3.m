function filename=mi_precalibracion_v3()
fprintf('JK (08/11/2012): En esta version cambie el orden en que envia los mensajes al ET y al EEG, porque con DiegoSh hubo un problema en la sincronia. \n')
fprintf('JK (11/06/2015): Paso a _v3')
fprintf('JK (11/06/2015): Voy a probar el EEG-EYE toolbox (http://www2.hu-berlin.de/eyetracking-eeg)')
fprintf('JK (11/06/2015): Siguiendo recomendaciones de EEG-EYE (http://www2.hu-berlin.de/eyetracking-eeg/tutorial.html#tutorial1) voy a usar siempre la misma marca para el onset y el offset del trial.')
fprintf('BB (08/03/2018): Actualizo funciones de DAQ para win7. Actualizo Marcas. Saco investos de JK')

addpath('C:\EXPE\eyetracker_Funciones\funciones_eyetracker')  %adaptarlo al directorio que usemoes en la UNS
addpath('C:\Users\LNI\Documents\Bbianchi\puerto paralelo')

respuesta= inputdlg({'Nombre (no más de 8 caracteres)' 'Numero' '¿Usamos Eyelink?(S/N)' '¿Usamos EEG?(S/N)'},...
                     'Ingrese su Nombre',1,{'tst' '1' 'S' 'S'});

init.etConectado  = strcmp(upper(respuesta{3}),'S');  
init.eegConectado = strcmp(upper(respuesta{4}),'S');
    % Inicializo cosas de EEG y ET (para co-registro)
    init.eegConect =strcmp(upper(respuesta{4}),'S');
    init.portDir   = 'C100'; % Direccion del puerto
    init.lptport   = hex2dec(init.portDir);
    init.baseCode  = 0; % Código base. Del que parte y al que vuelve dsp de cada marca
try
% Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebuglevel', 3);% para que no aparezca la pantalla de presentacion
Screen('Preference', 'Verbosity', 1);% para que no muestre los warnings
% warning('off', 'daq:<objecttype>:adaptorobsolete'); 

%% Algunos parametros
KbName('UnifyKeyNames');
kEsc    = KbName('Escape');
kNumber = KbName('Space'); %32; % Space

% Abre y genera archivos/carpetas
expName     = 'pre';
filename    = [respuesta{1} '_' expName respuesta{2}];
params.filename = filename;

% Carga y ordena los estimulos a presentar  
params.backcol      = [180 180 180];
params.cruzcol      = [0 0 0];
params.circcol      = [255 255 255];
params.cruzsiz      = 15;
params.circsiz      = 15;
params.saccircsiz   = 10;
params.cruzpen      = 3;
params.circpen      = 10;
params.saccircpen   = 7;

params.t.stimdur    = 0.3;
params.t.isi        = 1;

% 1: Blinks (solo cruz)
% 2: Vertical corto (solo 2 circulos verticales, ang = ???)
% 3: Vertical largo (solo 2 circulos verticales, ang = ???)
% 4: Horizontal corto (solo 2 circulos horizontales, ang = ???)
% 5: Horizontal largo (solo 2 circulos horizontales, ang = ???)
params.conds      = [1 2 4 1 3 5 1 2 4 1 3 5];
params.Ntrials    = length(params.conds);  

%% Empieza

if init.etConectado
    ePARAMS.calBACKGROUND = params.backcol;
    ePARAMS.calFOREGROUND = [0 0 0];
    eyelink_ini_custom(filename,ePARAMS)
    sca
end

% SEÑAL DE SINCRONIZACION (EEG-EYE sugiere que sea siempre la misma)    
% Envio comienzo de expe
eegMsg = 254;
etMsg = ['keyword ' num2str(eegMsg)];
sendTriggers(init, eegMsg, etMsg)
    
[w,Rect]    = Screen('OpenWindow',0,params.backcol,[]);
% [w,Rect]    = Screen('OpenWindow',0,params.backcol,[0 0 1024 768]);
% [w,Rect]    = Screen('OpenWindow',0,params.backcol,[0 0 500 500]);
cxsiz        = Rect(3)/2;
cysiz        = Rect(4)/2;

params.vertPosLong   = floor(0.75*cysiz); % mas o menos 75% de la pantalla 
params.vertPosShort  = floor(0.5 *cysiz); % mas o menos 50% de la pantalla 
params.horizPosLong  = floor(0.75*cysiz); % la misma distancia que vert
params.horizPosShort = floor(0.5 *cysiz); % la misma distancia que vert

% inicio experimento
HideCursor;
Screen('FillRect', w, params.backcol)
text = 'Presiona la barra espaciadora para comenzar';
widtha  = RectWidth(Screen('TextBounds',w,text));
texto(w, text, 20, [0 0 0], Rect(3)/2-widtha/2, Rect(4)/3); % Presenta un texto.
Screen('Flip',w);

[kDown,secs,kCode] = KbCheck;

while ~kCode(kNumber); [kDown,secs,kCode] = KbCheck; if kCode(kEsc); break; end; end
    
for tr=1:params.Ntrials

    disp(tr)
    Screen('FillRect', w, params.backcol)
    if (params.conds(tr)==1);     text = 'Mira la cruz.';
    elseif (params.conds(tr)>1);  text = 'Mira los dos puntos alternadamente, sin apurarte.';
    end

    % Presenta un texto.
    widtha  = RectWidth(Screen('TextBounds',w,text));
    texto(w, text, 20, [0 0 0], Rect(3)/2-widtha/2, Rect(4)/3); 
    Screen('flip',w);
    [kDown,secs,kCode] = KbCheck;
    while ~kCode(kNumber); [kDown,secs,kCode] = KbCheck; if kCode(kEsc); break; end; end
    if kCode(kEsc); break; end

    
    % SEÑAL DE SINCRONIZACION (EEG-EYE sugiere que sea siempre la misma)    
    % Envio comienzo de bloque
    eegMsg = 100;
    etMsg = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)

    % SEÑAL PARA IDENTIFICAR LOS TRIALS
    % Envio comienzo de bloque
    eegMsg = params.conds(tr)*10 + tr;
    etMsg = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)
    Tiempo = 30;

    if (params.conds(tr)==1);
        % Fijacion
        Screen('FillRect', w, params.backcol)
        Screen('DrawLine', w, params.cruzcol, ...
            cxsiz-params.cruzsiz, cysiz,...
            cxsiz+params.cruzsiz, cysiz, params.cruzpen);
        Screen('DrawLine', w, params.cruzcol, ...
            cxsiz, cysiz-params.cruzsiz,...
            cxsiz, cysiz+params.cruzsiz, params.cruzpen);
        Screen('flip', w);
        WaitSecs(Tiempo)

    elseif (params.conds(tr)==2);
        % Vertical Corto
        Screen('FillRect', w, params.backcol)
        Screen('FrameOval',w, params.cruzcol, ...
            [cxsiz cysiz cxsiz cysiz]+...
            params.vertPosShort*[0 -1 0 -1]+...
            params.saccircsiz*[-1 -1 1 1], params.saccircpen);
        Screen('FrameOval',w, params.cruzcol, ...
            [cxsiz cysiz cxsiz cysiz]+...
            params.vertPosShort*[0 1 0 1]+...
            params.saccircsiz*[-1 -1 1 1], params.saccircpen);
        Screen('flip', w);
        WaitSecs(Tiempo)
    elseif (params.conds(tr)==3);
        % Vertical Long
        Screen('FillRect', w, params.backcol)
        Screen('FrameOval',w, params.cruzcol, ...
            [cxsiz cysiz cxsiz cysiz]+...
            params.vertPosLong*[0 -1 0 -1]+...
            params.saccircsiz*[-1 -1 1 1], params.saccircpen);
        Screen('FrameOval',w, params.cruzcol, ...
            [cxsiz cysiz cxsiz cysiz]+...
            params.vertPosLong*[0 1 0 1]+...
            params.saccircsiz*[-1 -1 1 1], params.saccircpen);
        Screen('flip', w);
        WaitSecs(Tiempo)
    elseif (params.conds(tr)==4);
        % Horizontal Short
        Screen('FillRect', w, params.backcol)
        Screen('FrameOval',w, params.cruzcol, ...
            [cxsiz cysiz cxsiz cysiz]+...
            params.horizPosShort*[-1 0 -1 0]+...
            params.saccircsiz*[-1 -1 1 1], params.saccircpen);
        Screen('FrameOval',w, params.cruzcol, ...
            [cxsiz cysiz cxsiz cysiz]+...
            params.horizPosShort*[1 0 1 0]+...
            params.saccircsiz*[-1 -1 1 1], params.saccircpen);
        Screen('flip', w);
        WaitSecs(Tiempo)
    elseif (params.conds(tr)==5);
        % Horizontal Short
        Screen('FillRect', w, params.backcol)
        Screen('FrameOval',w, params.cruzcol, ...
            [cxsiz cysiz cxsiz cysiz]+...
            params.horizPosLong*[-1 0 -1 0]+...
            params.saccircsiz*[-1 -1 1 1], params.saccircpen);
        Screen('FrameOval',w, params.cruzcol, ...
            [cxsiz cysiz cxsiz cysiz]+...
            params.horizPosLong*[1 0 1 0]+...
            params.saccircsiz*[-1 -1 1 1], params.saccircpen);
        Screen('flip', w);
        WaitSecs(Tiempo)

    end

    % SEÑAL DE SINCRONIZACION (EEG-EYE sugiere que sea siempre la misma)    
    % Envio fin de bloque
    eegMsg = 101;
    etMsg = ['keyword ' num2str(eegMsg)];
    sendTriggers(init, eegMsg, etMsg)
end

% Envio fin de expe
eegMsg = 255;
etMsg = ['keyword ' num2str(eegMsg)];
sendTriggers(init, eegMsg, etMsg)

disp('guarde')
save(filename, 'params');
Screen('CloseAll');
ShowCursor
    

catch ME
    Screen('CloseAll');
    ShowCursor

    keyboard
end
end

function texto(w,text,size,color,xx,yy)
    Screen('TextFont',  w, 'Courier New');
    Screen('TextSize',  w, size);
    Screen('DrawText',  w, text,xx,yy, color);
end
        
function sendTriggers(init, message, etMsg)
        
    % Si hay ET, mando al ET
    if init.etConectado
        Eyelink('Message', etMsg);
    end
    
    if init.eegConectado
        lptwrite(init.lptport, message+init.baseCode);
        pause(0.05)
        lptwrite(init.lptport, init.baseCode);
    end
end
