function genera_estimulos
%  esto arma las imagenes de las oraciones.
try
    
    [filename, pathname] = uigetfile('*.xls', 'Elija el archivo de oraciones a procesar (*.xls)');
    if isequal(filename,0)
       disp('User selected Cancel')
       return
    else
       disp(['User selected ', fullfile(pathname, filename)])
    end

%   si ya existe, pregunto de abrirlo para seguir desde donde estaba
    matfilename= [filename(1:end-4) '.mat'];
    if exist(fullfile(pathname, matfilename),'file')
        respuesta= questdlg({'El archivo .mat ya existe.' '¿Desea sobreescribirlo o continuarlo?'},'Archivo ya existe','Sobreescribir','Continuar','Sobreescribir');
        if isempty(respuesta)
            disp('cancelado')
            return
        end
        if strcmp(respuesta,'Continuar')
            load(fullfile(pathname, matfilename))
        end
    end

    if ~exist('DATA','var')
       DATA=lee_archivo(fullfile(pathname, filename));
    end
    
    init.colback=200;    
    init.coltext=0;
    init.fontsize=22; 
    init.fontstyle=1;%0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend.
    [w init]=inicializa_video(init);

    tic

    if ~isfield(DATA,'posoracion')    
        DATA=genera_imagenes_oracion(w,DATA,init);
        save(fullfile(pathname, filename(1:end-4)),'DATA','init')
    end
    if ~isfield(DATA,'pospregunta')    
        DATA=genera_imagenes_pregunta(w,DATA,init);
        save(fullfile(pathname, filename(1:end-4)),'DATA','init')
    end
    if ~isfield(DATA,'postarget')
        DATA=genera_imagenes_target(w,DATA,init);
        save(fullfile(pathname, filename(1:end-4)),'DATA','init')
    end
    if ~isfield(DATA,'posopcion1')
        DATA=genera_imagenes_opciones(w,DATA,init);
        save(fullfile(pathname, filename(1:end-4)),'DATA','init')
    end
    
%    [init]=genera_pantalla_seguridad(w,init);    
%    [init]=genera_pantalla_sentido(w,init);
    save(fullfile(pathname, filename(1:end-4)),'DATA','init')
    toc
catch ME
    ME 
    sca
    keyboard
end
sca

end

function muestra_oracion_y_rectangulo(DATA,i)
    figure(1);
    clf
    imagesc(DATA(i).imagen)
    hold on
    pos=DATA(i).posoracion;
    line([pos(1) pos(1) pos(2) pos(2) pos(1)],[pos(3) pos(4) pos(4) pos(3) pos(3)])
end

function [w init]=inicializa_video(init)
    doublebuffer=1;
    screenNumber=max(Screen('Screens'));
    [w, rect] = Screen('OpenWindow', screenNumber, 0,[], 32, doublebuffer+1);
    [init.width, init.height]=Screen('WindowSize', w);
    init.CX=init.width/2;
    init.CY=init.height/2;
    init.ifi=Screen('GetFlipInterval', w);
    init.fps=Screen('FrameRate',w);      % frames per second
    init.colback=200 ;    

    
    Screen('FillRect', w, init.colback);  
    t=GetSecs;
    vbl=Screen('Flip', w,t+init.ifi);    
    HideCursor;

end

function [init]=genera_pantalla_seguridad(w,init)
%if ~isfield(init,'imagenrespsegu')
    CX=init.CX;CY=init.CY;
    width=init.width;height=init.height;
    myColors=192;
    lineWidthsMouse=5;

    anchoresp=2*round(width*.4); % ancho de la linea de respuesta
    posysegu=CY;%posicion vertical de la linea de seguridad
    % guardo wrespsegu en init, para no tener que generarla cada vez
    %con esto, lo genero una sola vez

    disp('genero la pantalla de seguridad')
    wrespsegu=Screen(w,'OpenOffscreenWindow');

    Screen('FillRect', wrespsegu, init.colback);  
    Screen('LineStipple',wrespsegu, 0); 
    texto_centrado(wrespsegu,'¿Cuán predecible le resultó',20,0,CX,posysegu-110);
    texto_centrado(wrespsegu,'la última palabra?',20,0,CX,posysegu-80);
    texto_centrado(wrespsegu,'Nada predecible',15,0,CX-anchoresp/2,posysegu-50);
    texto_centrado(wrespsegu,'Muy predecible',15,0,CX+anchoresp/2,posysegu-50)  ;  
    Screen('DrawLine', wrespsegu, myColors, CX, posysegu+10, CX, posysegu-10, lineWidthsMouse);
    Screen('DrawLine', wrespsegu, myColors, CX-anchoresp/2, posysegu, CX+anchoresp/2, posysegu, lineWidthsMouse);
    Screen('FillPoly', wrespsegu, myColors,[CX-anchoresp/2-30, posysegu; CX-anchoresp/2, posysegu+10; CX-anchoresp/2, posysegu-10]);
    Screen('FillPoly', wrespsegu, myColors,[CX+anchoresp/2+30, posysegu; CX+anchoresp/2, posysegu+10; CX+anchoresp/2, posysegu-10]);

    init.imagenrespsegu=Screen('getimage',wrespsegu);
%end
%screen('maketexture',wrespsegu,init.imagenrespsegu);

%wrespsegutemp=Screen(wrespsegu,'OpenOffscreenWindow');
%Screen('CopyWindow', wrespsegu, wrespsegutemp); 

    Screen('close',wrespsegu)
end

function [init]=genera_pantalla_sentido(w,init)
    CX=init.CX;CY=init.CY;
    disp('genero la pantalla de sentido')
    wrespsegu=Screen(w,'OpenOffscreenWindow');

    Screen('FillRect', wrespsegu, init.colback);  
    Screen('LineStipple',wrespsegu, 0); 
    texto_centrado(wrespsegu,'¿Qué tipo de oración era?',25,0,CX,CY-150);
    texto_centrado(wrespsegu,'   Refrán  / Refrán modificado / No-Refrán ',20,0,CX,CY-110);    
    texto_centrado(wrespsegu,' Izquierda /      Abajo        /  Derecha ',20,0,CX,CY-60);    
    init.imagenrespsentido=Screen('getimage',wrespsegu);
    Screen('close',wrespsegu)
end

function DATA=genera_imagenes_oracion(window,DATA,init)
try
    Screen('fillrect',window,init.colback)    
    Screen('TextSize', window, 30);%ver tamaño    
    Screen('DrawText', window, 'generando imagenes oracion',init.CX*.2,init.height*.2,0);
    t=GetSecs;Screen('Flip', window,t+init.ifi);    

    woff=Screen(window,'OpenOffscreenWindow');
    Screen('fillrect',woff,init.colback)
    Screen('TextFont', woff, 'Courier New');
    fontsize=18;
    for i=1:length(DATA)  
        Screen('fillrect',woff,init.colback)
        texto=DATA(i).oracion;
        postexto=texto_centrado(woff,texto,init,init.CX,init.CY);
        DATA(i).imagen=Screen('getimage',woff,postexto([1 3 2 4]));            
        DATA(i).posoracion=postexto;   
    end
    Screen(woff,'Close')    
catch ME
    ME
    sca
    keyboard
end
end

function DATA=genera_imagenes_pregunta(window,DATA,init)
    Screen('fillrect',window,init.colback)    
    Screen('TextSize', window, 30);%ver tamaño    
    Screen('DrawText', window, 'generando imagenes pregunta',init.CX*.2,init.height*.2,0);
    t=GetSecs;Screen('Flip', window,t+init.ifi);    

    woff=Screen(window,'OpenOffscreenWindow');
    Screen('fillrect',woff,init.colback)
    Screen('TextFont', woff, 'Courier New');
    fontsize=18;
    for i=1:length(DATA)  
        Screen('fillrect',woff,init.colback)
        texto=DATA(i).pregunta; 
        if ~isempty(texto)
            postexto=texto_centrado(woff,texto,init,init.CX,init.CY);
            DATA(i).impregunta=Screen('getimage',woff,postexto([1 3 2 4]));            
            DATA(i).pospregunta=postexto;        
        end
    end
    Screen(woff,'Close')    
end

function DATA=genera_imagenes_target(window,DATA,init)
    Screen('fillrect',window,init.colback)    
    Screen('TextSize', window, 30);%ver tamaño    
    Screen('DrawText', window, 'generando imagenes target',init.CX*.2,init.height*.2,0);
    t=GetSecs;Screen('Flip', window,t+init.ifi);    

    woff=Screen(window,'OpenOffscreenWindow');
    Screen('fillrect',woff,init.colback)
    Screen('TextFont', woff, 'Courier New');
    fontsize=18;
    for i=1:length(DATA)  
        Screen('fillrect',woff,init.colback)
        texto=DATA(i).target;
        if ~isempty(texto)
            postexto=texto_centrado(woff,texto,init,init.CX,init.CY);
            DATA(i).imtarget=Screen('getimage',woff,postexto([1 3 2 4]));            
            DATA(i).postarget=postexto;                        
        end
    end
    Screen(woff,'Close')    
end

function DATA=genera_imagenes_opciones(window,DATA,init)
    Screen('fillrect',window,init.colback)    
    Screen('TextSize', window, 30);%ver tamaño    
    Screen('DrawText', window, 'generando imagenes opciones',init.CX*.2,init.height*.2,0);
    t=GetSecs;Screen('Flip', window,t+init.ifi);    

    woff=Screen(window,'OpenOffscreenWindow');
    Screen('fillrect',woff,init.colback)
    Screen('TextFont', woff, 'Courier New');
    fontsize=18;
    for i=1:length(DATA)   
        Screen('fillrect',woff,init.colback)
        texto=DATA(i).opcion1;
        if ~isempty(texto)
            postexto=texto_centrado(woff,texto,init,init.CX,init.CY);
            DATA(i).imopcion1=Screen('getimage',woff,postexto([1 3 2 4]));            
            DATA(i).posopcion1=postexto;                
        end
        
        a=imaqmem;a.AvailPhys
        Screen('fillrect',woff,init.colback)
        texto=DATA(i).opcion2;
        if ~isempty(texto)
            postexto=texto_centrado(woff,texto,init,init.CX,init.CY);
            DATA(i).imopcion2=Screen('getimage',woff,postexto([1 3 2 4]));            
            DATA(i).posopcion2=postexto;                
        end
        
    end
    Screen(woff,'Close')    
end

function DATA=lee_archivo(xlsfilename)
    %%leo la planilla de excel con los datos
    [NUMERIC,TXT,RAW]=xlsread(xlsfilename);
    for i=1:size(NUMERIC,1)
        DATA(i).ind=NUMERIC(i,1);
        DATA(i).oracion=TXT{i+1,2};
        DATA(i).tipo=NUMERIC(i,3);
        DATA(i).pregunta=TXT{i+1,4};
        DATA(i).target=TXT{i+1,5};        
        DATA(i).opcion1=TXT{i+1,6};        
        DATA(i).opcion2=TXT{i+1,7};        
%         if size(NUMERIC,2)>3
%             DATA(i).predicti=NUMERIC(i,4);        
%         end
    end
end

function postexto=texto_centrado(window2,text,init,xx,yy)
    
% abro una offscreen window, dibujo el texto y mido donde quedó
try
    
    woff2=Screen(window2,'OpenOffscreenWindow');
    Screen('TextFont', woff2, 'Courier New');
    Screen('textstyle',woff2, init.fontstyle);%0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend.    
    Screen('TextSize', woff2, init.fontsize);%ver tamaño    
    Screen('FillRect', woff2, 0);          
    Screen('DrawText', woff2, text,1,1,255);    
    A=Screen('getimage',woff2);     
    xpos=sum(A,1);xpos=(xpos(1,:,1));
    ypos=sum(A,2);ypos=(ypos(:,1,1));    
    right   = max(find(xpos>0));%, 1, 'last' );
    left    = min(find(xpos>0))-1;%, 1 );
    lower   = max(find(ypos>0));%, 1, 'last' );
    upper   = min(find(ypos>0))-1;%, 1 );
    ancho=right-left;
    alto=lower-upper;    
    centro_real_x=round((right+left)/2);
    centro_real_y=round((lower+upper)/2);
    corrimiento_x=centro_real_x-1;
    corrimiento_y=centro_real_y-1;
 
    
% % ya se donde dibujarlo, lo dibujo!!!
    Screen('TextFont', window2, 'Courier New');
    Screen('textstyle',window2,init.fontstyle);%0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend.    
    Screen('TextSize', window2, init.fontsize);%ver tamaño

    Screen('DrawText', window2, text,xx-corrimiento_x,yy-corrimiento_y, init.coltext);
    A=Screen('getimage',window2);     
    colorfondo=init.colback;
    ypos=sum(A(:,:,1)~=colorfondo,2);
    xpos=sum(A(:,:,1)~=colorfondo);    
    right   = max(find(xpos>0))    +1;%le dejo un bordecito de un pixel para cada lado
    left    = min(find(xpos>0))-1  -1;
    lower   = max(find(ypos>0))    +1;
    upper   = min(find(ypos>0))-1  -1;
    postexto=[left right upper lower];
    
%    postexto=[xx-corrimiento_x xx-corrimiento_x+ancho yy-corrimiento_y+alto/2 yy-corrimiento_y+alto*3/2 alto lower upper centro_real_y corrimiento_y yy] 
    Screen(woff2,'Close')

catch ME
    sca
    ME 
    keyboard
end
end