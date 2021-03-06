function [todo a]=analiza_datos_limpios2(archivo)

if ~exist(archivo,'file')
    disp('Error: Archivo no encontrado.')
    return
end

disp(['An?lisis del archivo: ' archivo])


[linea textline]=busca_texto_en_archivo(archivo, {'ELCLCFG'});
if strfind(textline,'RTABLE')>0
    MODO='RTABLE';%remoto
elseif  strfind(textline,'BTABLE')>0
    MODO='BTABLE';%binocular
elseif strfind(textline,'MTABLE')>0
    MODO='MTABLE';%monocular
end
disp(['Modo: ' MODO]);


%busca los textos "SAMPLES\tGAZE" o "EVENTS\tGAZE" o "SYNCTIME" en el asc para ver desde donde empezar
[linea]=busca_texto_en_archivo(archivo, {'SAMPLES	GAZE' 'EVENTS	GAZE' 'SYNCTIME'});
if isempty(linea)
    disp('Llegu? a EOF y no encontr? ning?n texto!!')
    disp('Pongo Startline: 200')
    S=200;
else
    S=linea+5;
    disp(['Start line: ' num2str(S)])
end


%abre el archivo llamado filename y mete todas las lineas de texto en la celda C
filename=archivo;
fid = fopen(filename);
% S=70; % La linea del  *.asc desde la que empieza a convertir a strings.
C = textscan(fid, '%s','HeaderLines',S,'delimiter', '\n');
fclose(fid);
a=C{1};
clear C;

%busca samples
todo.samples=busca_samples(a);
%busca eventos de cada tipo
todo.resac=busca_eventos(a,'ESACC R');
todo.lesac=busca_eventos(a,'ESACC L');
todo.refix=busca_eventos(a,'EFIX R');
todo.lefix=busca_eventos(a,'EFIX L');
todo.rebli=busca_eventos(a,'EBLINK R');
todo.lebli=busca_eventos(a,'EBLINK L');
[todo.msgtime todo.msgline]=busca_eventos(a,'MSG');
todo.msg=a(todo.msgline);   
todo.driftcorrect=busca_driftcorrect(archivo);

todo.headerlines=S;

% disp ' '
% disp 'podriamos hacer un campo mas con todo.msgsample, la linea de la matriz'
% disp ' de samples en la que aparece cada mensaje, para ahorrar un monton de find...'
% disp ' tipo: find(todo.samples(:,1)>todo.msgtime(i),1) pero mas eficiente'
% disp 'podriamos hacerlo para todos los eventos... o tal vez sea mucho'
% disp ' '

%para que no aparezca msg numerito en todo.msg
for i=1:length(todo.msg)
    [A, count, errmsg, nextindex]=sscanf(todo.msg{i},'MSG%f');%todo esto para buscar nextindex
    %nextindex es el indice del caracter despues de leer MSG y un float
    todo.msg{i}=todo.msg{i}(nextindex+1:end);
end

todo=remueve_blinks_y_sacadas(todo);

save todo todo
end



function matriz=busca_samples(data)
disp('ver que extraiga los datos de binocular tambien')
matriz=nan(length(data),4);
for i=1:length(data);
    temp=sscanf(char(data(i)),'%f');
    if length(temp)==4
        matriz(i,:)=temp;
    elseif length(temp)==1
        matriz(i,:)=nan;
        matriz(i,1)=temp;
    end
end
Index=find(isnan(matriz(:,1)));
matriz(Index,:)=[];

disp([num2str(length(matriz)) ' samples encontrados.'])    

end

function [matriz indices] = busca_eventos(data,event_name)


switch event_name
   case {'EFIX L','EFIX R' }
      numeros=6;
   case {'ESACC L','ESACC R'}
      numeros=9;
   case {'EBLINK L','EBLINK R'}
      numeros=3;
   case 'MSG'
      numeros=1;
    otherwise
       disp('nose')
end




indices=mystrmatch(event_name,data);
matriz=nan(length(indices),numeros);
for i=1:length(indices);
%    data{indices(i)}
    temp=sscanf(data{indices(i)},[event_name ' %f %f %f %f %f %f %f %f %f']);
    matriz(i,1:length(temp))=temp;
end
disp([num2str(length(indices)) ' eventos ' event_name ' encontrados.'])    


% elseif event_name=='EFL'
%     indices=mystrmatch('EFIX L',data);
%     matriz=nan(length(indices),6);
%     contador=0;
%     for i=1:length(data);
%         temp=sscanf(char(data(i)),'EFIX L %f %f %f %f %f %f');
%         if length(temp)==6
%             contador=contador+1;
%            matriz(contador,:)=temp;
%         end
%     end
% 
% elseif event_name=='EFR'
%     indices=mystrmatch('EFIX R',data);
%     matriz=nan(length(indices),6);
%     contador=0;
%     for i=1:length(data);
%         temp=sscanf(char(data(i)),'EFIX R %f %f %f %f %f %f');
%         if length(temp)==6
%             contador=contador+1;
%             matriz(contador,:)=temp;
%         end
%     end
% 
% elseif event_name=='ESR'
%     indices=mystrmatch('ESACC R',data);
%     matriz=nan(length(indices),9);
%     contador=0;
%     for i=1:length(data);
%         temp=sscanf(char(data(i)),'ESACC R %f %f %f %f %f %f %f %f %f');
%         if length(temp)==9
%             contador=contador+1;
%             matriz(contador,:)=temp;
%         end
%     end
% 
% elseif event_name=='EBR'
%     indices=mystrmatch('EBLINK R',data);
%     matriz=nan(length(indices),3);
%     contador=0;
%     for i=1:length(data);
%         temp=sscanf(char(data(i)),'EBLINK R %f %f %f');
%         if length(temp)==3
%             contador=contador+1;
%            matriz(contador,:)=temp;
%         end
%     end
% 
% elseif event_name=='EBL'
%     indices=mystrmatch('EBLINK L',data);
%     matriz=nan(length(indices),3);
%     contador=0;
%     for i=1:length(data);
%         temp=sscanf(char(data(i)),'EBLINK L %f %f %f');
%         if length(temp)==3
%             contador=contador+1;
%             matriz(contador,:)=temp;
%         end
%     end
%     
% elseif event_name=='MSG'
%     matriz=mystrmatch('MSG',data);
%     
% end
end

function [coincidencias]=mystrmatch(string,data)
    coincidencias=[];
    deacuantos=200000;
    pos=0;
    contador=0;
    while pos<length(data);
        if (pos+deacuantos)>length(data)
            indices=(pos+1):length(data);
        else
            indices=pos+(1:deacuantos);
        end
        loqueagrego=pos+strmatch(string,data(indices));
        coincidencias=[coincidencias; loqueagrego];        
        pos=pos+deacuantos;
        contador=contador+1;
%        fprintf(1,'%d %d %d %d\n',contador,indices(1),indices(end),length(loqueagrego))
    end
        
% %esto anda pero es lento pues ejecuta strmatch 10millones de veces    
%     indices=[];
%     for i=1:length(data)
%         temp=data{i};
%         if strmatch(string,temp(1:length(string)))
%             indices(end+1)=i;    
%         end
%     end
%     coincidencias=indices;
end


function [linea tline]=busca_texto_en_archivo(filename, texts)
linea=[];
tline=[];
fid=fopen(filename);
contador=0;
while isempty(ferror(fid)) %mientras no da fin de archivo
    contador=contador+1;
    tline = fgetl(fid);    %leo una linea del archivo
    for i=1:length(texts)% para cada uno de los textos de busqueda
        if ~isempty(strfind(tline,texts{i})) %me fijo si aparece en la linea
%            disp([tline ])
            linea=contador; 
            fclose(fid);
            return %si parece cierro y me voy
        end
    end
%    disp([num2str(contador) tline])
end
fclose(fid);
end

function MODO=modo_eyelink(archivo)
    MODO=[];
    [linea textline]=busca_texto_en_archivo(archivo, {'ELCLCFG'});
    if strfind(textline,'RTABLE')>0
        MODO='RTABLE';%remoto
    elseif  strfind(textline,'BTABLE')>0
        MODO='BTABLE';%binocular
    elseif strfind(textline,'MTABLE')>0
        MODO='MTABLE';%monocular
    end
end

function driftcorrect=busca_driftcorrect(archivo)
    [linea textline]=busca_texto_en_archivo(archivo, {'DRIFTCORRECT'});
    if isempty(linea)
        driftcorrect=nan;
        return
    end
    posicion=strfind(textline,'deg.');
    driftcorrect=sscanf(textline(posicion+4:end),'%f,%f');
end

function todo=remueve_blinks_y_sacadas(todo)
% pupilsize=todo.samples(:,4);
tiempo=todo.samples(:,1);
lesac=todo.lesac;
lebli=todo.lebli;

currsac=1;
i=1;
while i<length(tiempo)
    while tiempo(i)<lesac(currsac,1);
        i=i+1;
    end
    startsac=i;
    while tiempo(i)<lesac(currsac,2);
        i=i+1;
    end
    endsac=i;
    todo.samples(startsac:endsac,2:4)=nan;    
    currsac=currsac+1;
    if currsac>length(lesac);break;end
end

currbli=1;
i=1;
while i<length(tiempo)
    while tiempo(i)<lebli(currbli,1);
        i=i+1;
    end
    startbli=i;
    while tiempo(i)<lebli(currbli,2);
        i=i+1;
    end
    endbli=i;
    todo.samples(startbli:endbli,2:4)=nan;     
    currbli=currbli+1;
    if currbli>length(lebli);break;end
end

end