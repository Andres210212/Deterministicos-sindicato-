clc
clear
close all

% =========================================================
% CONFIGURACIÓN DEL ANÁLISIS primer analisis
% =========================================================
Fs = 1000; % Tasa de muestreo en Hz
intervalo_promedio = 1; % Intervalo en segundos
ventanas = Fs * intervalo_promedio; 
numBins = 20; % Número de divisiones para la cuadrícula 3D

% --- VARIABLES PARA EL RESUMEN GLOBAL ---
ondas_procesadas = 0;
nombres_archivos = {};
picos_maximos = [];
rms_individuales = [];
a_combinada = []; % Aquí pegaremos todas las ondas una tras otra

for i = 1:4
    
    % 1. Cargar datos
    filename = sprintf('ts%d.txt', i);
    
    if ~isfile(filename)
        fprintf('Archivo %s no encontrado. Saltando...\n', filename);
        continue;
    end
    
    ondas_procesadas = ondas_procesadas + 1;
    nombres_archivos{ondas_procesadas} = filename;
    
    data = load(filename);
    t = data(:,1);
    a = data(:,2); % Aceleración (ya viene en g)
    
    % --- RECOLECTAR DATOS PARA EL RESUMEN ---
    % Guardamos el pico máximo de esta onda
    picos_maximos(ondas_procesadas) = max(abs(a));
    % Guardamos el RMS (que representa la fuerza/energía promedio real que siente)
    rms_individuales(ondas_procesadas) = rms(a);
    % Concatenamos las señales
    a_combinada = [a_combinada; a];
    
    % 2. Aceleración promedio en intervalo (Promedio Móvil)
    accel_promedio = movmean(a, ventanas);
    
    % 3. FFT (Frecuencias Dominantes)
    a_detrend = a - mean(a);
    L = length(a_detrend);
    Y = fft(a_detrend);
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(floor(L/2)))/L;
    
    % 4. Análisis Rainflow Generalizado
    rf_matrix = rainflow(a);
    ciclos = rf_matrix(:,1); % Conteo (0.5 o 1 ciclo)
    rangos = rf_matrix(:,2); % Rango del ciclo (en g)
    medias = rf_matrix(:,3); % Media del ciclo (en g)
    
    % --- Mostrar Resultados Rápidos en Consola ---
    fprintf('--- Reporte General: %s ---\n', filename);
    fprintf('Aceleración RMS: %.4f g\n', rms_individuales(ondas_procesadas));
    fprintf('Pico Máximo de Aceleración: %.4f g\n', picos_maximos(ondas_procesadas));
    fprintf('Ciclos Totales Extraídos: %.1f\n\n', sum(ciclos));
    
    % 5. Gráficas Individuales
    figure('Name', ['Análisis Detallado ', filename], 'Color', 'w', 'Position', [100, 50, 900, 900])
    
    % Gráfica 1: Tiempo vs Aceleración
    subplot(3,1,1)
    plot(t, a, 'Color', [0.2 0.4 0.8 0.4]) 
    hold on; plot(t, accel_promedio, 'Color', 'r', 'LineWidth', 1.5); hold off
    title(['Aceleración vs Tiempo: ', filename])
    xlabel('Tiempo (s)'); ylabel('Amplitud (g)')
    legend('Señal Original', ['Promedio Móvil (', num2str(intervalo_promedio), 's)'])
    grid on
    
    % Gráfica 2: Espectro de Frecuencia (FFT)
    subplot(3,1,2)
    plot(f, P1, 'Color', [0.85 0.325 0.098], 'LineWidth', 1)
    title('Espectro de Frecuencias (FFT)')
    xlabel('Frecuencia (Hz)'); ylabel('Amplitud (g)')
    xlim([0 Fs/2]) 
    grid on
    
    % Gráfica 3: Matriz Rainflow 3D
    subplot(3,1,3)
    edges_medias = linspace(min(medias), max(medias), numBins+1);
    edges_rangos = linspace(min(rangos), max(rangos), numBins+1);
    [~, ~, ~, loc_medias, loc_rangos] = histcounts2(medias, rangos, edges_medias, edges_rangos);
    indices_validos = (loc_medias > 0) & (loc_rangos > 0);
    matriz_conteos = accumarray([loc_medias(indices_validos), loc_rangos(indices_validos)], ...
                                 ciclos(indices_validos), [numBins, numBins]);
    h = bar3(matriz_conteos);
    for k = 1:length(h)
        zdata = h(k).ZData; h(k).CData = zdata; h(k).FaceColor = 'interp';
    end
    title('Histograma de Matriz Rainflow')
    xticks(linspace(1, numBins, 5)); xticklabels(num2str(linspace(min(rangos), max(rangos), 5)', '%.1f'))
    yticks(linspace(1, numBins, 5)); yticklabels(num2str(linspace(min(medias), max(medias), 5)', '%.1f'))
    xlabel('Rango del Ciclo (g)'); ylabel('Media del Ciclo (g)'); zlabel('Número de Ciclos')
    colormap('parula'); colorbar; view(-45, 30); grid on
    
end

% =========================================================
% 6. REPORTE Y GRÁFICAS DEL RESUMEN GLOBAL
% =========================================================
if ondas_procesadas > 0
    
    % Cálculos Finales Globales
    fuerza_promedio_general = mean(rms_individuales); % Promedio de la fuerza sostenida
    promedio_picos_maximos = mean(picos_maximos);     % Promedio de los impactos más fuertes
    pico_absoluto_peor = max(picos_maximos);          % El impacto más fuerte de todos los archivos
    rms_onda_combinada = rms(a_combinada);            % El RMS de juntar todos los archivos en uno solo
    
    % Imprimir el Resumen en Consola
    fprintf('=======================================================\n');
    fprintf('               RESUMEN GLOBAL DE FATIGA\n');
    fprintf('=======================================================\n');
    fprintf('Archivos procesados:               %d\n', ondas_procesadas);
    fprintf('Fuerza promedio sentida (RMS):     %.4f g\n', fuerza_promedio_general);
    fprintf('Promedio de las fuerzas máximas:   %.4f g\n', promedio_picos_maximos);
    fprintf('-------------------------------------------------------\n');
    fprintf('Pico absoluto registrado:          %.4f g\n', pico_absoluto_peor);
    fprintf('RMS de la señal combinada total:   %.4f g\n', rms_onda_combinada);
    fprintf('=======================================================\n');
    
    % Gráfica de Resumen Visual
    figure('Name', 'Resumen Comparativo de Ondas', 'Color', 'w', 'Position', [150, 150, 800, 400])
    
    % Gráfica de Picos
    subplot(1,2,1)
    b1 = bar(picos_maximos, 'FaceColor', [0.85 0.325 0.098]);
    title('Comparativa de Picos Máximos')
    ylabel('Fuerza Máxima (g)')
    set(gca, 'XTickLabel', nombres_archivos)
    yline(promedio_picos_maximos, '--k', 'Promedio', 'LineWidth', 1.5)
    grid on
    
    % Gráfica de Fuerza Sostenida (RMS)
    subplot(1,2,2)
    b2 = bar(rms_individuales, 'FaceColor', [0 0.447 0.741]);
    title('Comparativa de Fuerza Sostenida (RMS)')
    ylabel('Fuerza Promedio (g)')
    set(gca, 'XTickLabel', nombres_archivos)
    yline(fuerza_promedio_general, '--k', 'Promedio', 'LineWidth', 1.5)
    grid on
end
%====== se corren separados de diferencia estos dos bloques
% =========================================================
% CONFIGURACIÓN DEL ANÁLISIS Segundo analisis
% =========================================================
Fs = 1000; % Tasa de muestreo en Hz
numBins = 20; % Número de divisiones para la cuadrícula 3D

% --- VARIABLES PARA EL RESUMEN GLOBAL ---
ondas_procesadas = 0;
nombres_archivos = {};
picos_maximos = [];
rms_individuales = [];

for i = 1:4
    
    % 1. Cargar datos
    filename = sprintf('ts%d.txt', i);
    
    if ~isfile(filename)
        fprintf('Archivo %s no encontrado. Saltando...\n', filename);
        continue;
    end
    
    ondas_procesadas = ondas_procesadas + 1;
    nombres_archivos{ondas_procesadas} = filename;
    
    data = load(filename);
    t = data(:,1);
    a_cruda = data(:,2); 
    
    % =====================================================
    % 2. TREN DE LIMPIEZA
    % =====================================================
    a_sin_gravedad = a_cruda - mean(a_cruda); % Quitar peso estático
    a = sgolayfilt(a_sin_gravedad, 3, 51);    % Quitar ruido conservando picos
    
    % --- RECOLECTAR DATOS ---
    picos_maximos(ondas_procesadas) = max(abs(a)); 
    rms_individuales(ondas_procesadas) = rms(a);   
    
    % 3. FFT (Frecuencias Dominantes)
    L = length(a);
    Y = fft(a);
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(floor(L/2)))/L;
    
    % 4. Análisis Rainflow
    rf_matrix = rainflow(a);
    ciclos = rf_matrix(:,1); 
    rangos = rf_matrix(:,2); 
    medias = rf_matrix(:,3); 
    
    % 5. Gráficas Individuales (Simplificadas)
    figure('Name', ['Análisis de Señal Limpia: ', filename], 'Color', 'w', 'Position', [100, 50, 900, 900])
    
    % Gráfica 1: ONDA LIMPIA Y CENTRADA
    subplot(3,1,1)
    plot(t, a, 'Color', [0 0.447 0.741], 'LineWidth', 1) 
    yline(0, '--k', 'Centro (0g)', 'LineWidth', 1.5) 
    title(['Aceleración Dinámica Pura: ', filename])
    xlabel('Tiempo (s)'); ylabel('Amplitud (g)')
    grid on
    
    % Gráfica 2: Espectro de Frecuencia (FFT)
    subplot(3,1,2)
    plot(f, P1, 'Color', [0.85 0.325 0.098], 'LineWidth', 1)
    title('Espectro de Frecuencias (FFT de la onda limpia)')
    xlabel('Frecuencia (Hz)'); ylabel('Amplitud (g)')
    xlim([0 Fs/2]) 
    grid on
    
    % Gráfica 3: Matriz Rainflow 3D
    subplot(3,1,3)
    edges_medias = linspace(min(medias), max(medias), numBins+1);
    edges_rangos = linspace(min(rangos), max(rangos), numBins+1);
    [~, ~, ~, loc_medias, loc_rangos] = histcounts2(medias, rangos, edges_medias, edges_rangos);
    indices_validos = (loc_medias > 0) & (loc_rangos > 0);
    matriz_conteos = accumarray([loc_medias(indices_validos), loc_rangos(indices_validos)], ...
                                 ciclos(indices_validos), [numBins, numBins]);
    h = bar3(matriz_conteos);
    for k = 1:length(h)
        zdata = h(k).ZData; h(k).CData = zdata; h(k).FaceColor = 'interp';
    end
    title('Histograma Rainflow Dinámico')
    xticks(linspace(1, numBins, 5)); xticklabels(num2str(linspace(min(rangos), max(rangos), 5)', '%.1f'))
    yticks(linspace(1, numBins, 5)); yticklabels(num2str(linspace(min(medias), max(medias), 5)', '%.1f'))
    xlabel('Rango (g)'); ylabel('Media (g)'); zlabel('Ciclos')
    colormap('parula'); colorbar; view(-45, 30); grid on
    
end

% =========================================================
% 6. GRÁFICAS DEL RESUMEN GLOBAL
% =========================================================
if ondas_procesadas > 0
    fuerza_promedio_general = mean(rms_individuales); 
    promedio_picos_maximos = mean(picos_maximos);     
    
    figure('Name', 'Resumen Comparativo Dinámico', 'Color', 'w', 'Position', [150, 150, 800, 400])
    
    % Gráfica de Picos Máximos
    subplot(1,2,1)
    bar(picos_maximos, 'FaceColor', [0.85 0.325 0.098]);
    title('Picos Dinámicos Máximos')
    ylabel('Fuerza Extra Máxima (g)')
    set(gca, 'XTickLabel', nombres_archivos)
    yline(promedio_picos_maximos, '--k', 'Promedio', 'LineWidth', 1.5)
    grid on
    
    % Gráfica de Fuerza Sostenida (RMS)
    subplot(1,2,2)
    bar(rms_individuales, 'FaceColor', [0 0.447 0.741]);
    title('Fuerza Dinámica Sostenida (RMS)')
    ylabel('Energía Promedio de Vibración (g)')
    set(gca, 'XTickLabel', nombres_archivos)
    yline(fuerza_promedio_general, '--k', 'Promedio', 'LineWidth', 1.5)
    grid on
end