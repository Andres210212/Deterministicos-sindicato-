%% SOLVER ESTRUCTURAL Y DE FATIGA - RETO JOHN DEERE (VERSIÓN AUDITADA IFI)
clc; clear all; close all; tic;

%% --- PASO 1: DEFINICIÓN DE GEOMETRÍA Y MATERIALES ---
% Coordenadas de los nodos (mm) [ID, X, Y] extraídas de Excel
% Coordenadas de los nodos (mm) [ID, X, Y] extraídas de Excel
N = [
    1	-442.4448	-433.0611
    2	16579.5256	-3.9498
    3	15358.8802	-9.9333
    4	14279.3234	0.0000
    5	13242.0142	0.0000
    6	12241.4174	6.5372
    7	11185.0772	0.0000
    8	10180.6551	0.0000
    9	9168.3946	0.0000
    10	8314.6681	0.0000
    11	7154.1209	0.0000
    12	6649.7976	0.0000
    13	5522.9715	0.0000
    14	4400.0000	0.0000
    15	3488.1439	0.0000
    16	2600.0000	0.0000
    17	1726.6193	0.0000
    18	800.0000	0.0000
    19	0.0000	0.0000
    20	838.3615	871.3918
    21	1743.6050	816.6392
    22	2612.3467	772.8371
    23	3528.5408	710.7841
    24	4400.9327	645.0809
    25	5543.4376	579.3778
    26	6671.3418	506.3743
    27	7177.1539	492.8809
    28	8327.7810	486.7768
    29	9185.4102	489.8288
    30	10203.4777	502.3598
    31	11195.6903	505.1083
    32	12261.4460	499.1491
    33	13250.4242	491.6663
    34	14297.5378	356.3110
    35	15365.0141	190.8533
];

% Opciones de Tubos: [ID, D_ext (mm), D_int (mm)]
Tubos = [
    1, 100, 95;   % Opción A (Económica)
    2, 100, 90;   % Opción B
    3, 120, 110;  % Opción C
    4, 140, 130;  % Opción D (Reforzada - CORREGIDA de 4000 a 140)
];

seleccion =4; % Probamos con la más ligera primero
Dext = Tubos(seleccion, 2);
Dint = Tubos(seleccion, 3);
Area_mm2 = (pi/4) * (Dext^2 - Dint^2);

M = [1, 200000, Area_mm2]; % E en MPa, A en mm2

% --- ACTUALIZACIÓN DE LA TABLA DE CONECTIVIDAD (PASO 1) ---
% [#ID, Nodo_Ini, Nodo_Fin, ID_Material]
% Se asume Material ID 1 para todas las barras.
E = [
    % ESTRUCTURA DE SOPORTE IZQUIERDA (Triángulo de apoyo del tractor)
    1	1	19	1; % Soporte Vertical-ish 
    2	1	18	1; % Tirante diagonal de soporte

    % CORDÓN SUPERIOR (Tensado)
    3	20	21	1; % Segmento 1
    4	21	22	1;
    5	22	23	1;
    6	23	24	1;
    7	24	25	1;
    8	25	26	1;
    9	26	27	1;
    10	27	28	1;
    11	28	29	1;
    12	29	30	1;
    13	30	31	1;
    14	31	32	1;
    15	32	33	1;
    16	33	34	1;
    17	34	35	1; % Segmento final

    % CORDÓN INFERIOR (Comprimido)
    18	19	18	1; % Segmento 1
    19	18	17	1;
    20	17	16	1;
    21	16	15	1;
    22	15	14	1;
    23	14	13	1;
    24	13	12	1;
    25	12	11	1;
    26	11	10	1;
    27	10	9	1;
    28	9	8	1;
    29	8	7	1;
    30	7	6	1;
    31	6	5	1;
    32	5	4	1;
    33	4	3	1;
    34	3	2	1; % Segmento final a la punta

    % POSTES VERTICALES (Estabilidad, alineados por coordenada X)
    35	20	18	1; % Vertical 1
    36	21	17	1;
    37	22	16	1;
    38	23	15	1;
    39	24	14	1;
    40	25	13	1;
    41	26	12	1;
    42	27	11	1;
    43	28	10	1;
    44	29	9	1;
    45	30	8	1;
    46	31	7	1;
    47	32	6	1;
    48	33	5	1;
    49	34	4	1;
    50	35	3	1; % Vertical final

    % DIAGONALES WARREN (Formando 'W's alternadas)
    51	19	20	1; % Diag Inicia '/' (Warren start)
    52	20	17	1; % Diag Inicia '\' (Warren cont.)
    53	17	22	1; % Diag Inicia '/'
    54	22	15	1; % Diag Inicia '\'
    55	15	24	1; % Diag Inicia '/'
    56	24	13	1; % Diag Inicia '\'
    57	13	26	1; % Diag Inicia '/'
    58	26	11	1; % Diag Inicia '\'
    59	11	28	1; % Diag Inicia '/'
    60	28	9	1; % Diag Inicia '\'
    61	9	30	1; % Diag Inicia '/'
    62	30	7	1; % Diag Inicia '\'
    63	7	32	1; % Diag Inicia '/'
    64	32	5	1; % Diag Inicia '\'
    65	5	34	1; % Diag Inicia '/'
    66	34	3	1; % Diag Inicia '\'
    
    % DIAGONALES EXTRA PARA ESTABILIDAD DE POSTES ( Warren+ verticals diagonals )
    67	18	21	1; % Contra-diag '/'
    68	21	16	1; % Contra-diag '\'
    69	16	23	1; % ...
    70	23	14	1;
    71	14	25	1;
    72	25	12	1;
    73	12	27	1;
    74	27	10	1;
    75	10	29	1;
    76	29	8	1;
    77	8	31	1;
    78	31	6	1;
    79	6	33	1;
    80	33	4	1;
    81	4	35	1;
    
    % PUNTA FINAL (Triángulo de cierre en Nodo 2)
    82	35	2	1; % Diagonal de cierre '\'
];

nE = size(E,1); % Ahora son 82 elementos
nN = size(N,1); % Son 35 nodos

%% --- PASO 2 AL 5: CÁLCULOS MATRICIALES (EFICIENTES) ---
Le = sqrt((N(E(:,3),2) - N(E(:,2),2)).^2 + (N(E(:,3),3) - N(E(:,2),3)).^2);
c = (N(E(:,3),2) - N(E(:,2),2)) ./ Le;
s = (N(E(:,3),3) - N(E(:,2),3)) ./ Le;
k = (M(E(:,4),2) .* M(E(:,4),3)) ./ Le;

Ke = zeros(4,4,nE);
L_map = [2*E(:,2)-1, 2*E(:,2), 2*E(:,3)-1, 2*E(:,3)];
K = zeros(2*nN, 2*nN);

for i = 1:nE
    Kezq = k(i) * [c(i)^2, s(i)*c(i); s(i)*c(i), s(i)^2];
    Ke(:,:,i) = [Kezq, -Kezq; -Kezq, Kezq];
    idx = L_map(i,:);
    K(idx,idx) = K(idx,idx) + Ke(:,:,i);
end

%% --- PASO 6: CARGAS (PESO PROPIO + PAYLOAD) ---
F = zeros(2*nN,1);
rho = 7.85e-6; % kg/mm^3
g = 9.81;      % m/s^2 (Kg * m/s^2 = Newtons)

% Distribución de Peso Propio
for i = 1:nE
    W_barra = rho * M(E(i,4),3) * Le(i) * g;
    F(2*E(i,2)) = F(2*E(i,2)) - W_barra/2;
    F(2*E(i,3)) = F(2*E(i,3)) - W_barra/2;
end

% Carga Externa (Boquillas y líquido - Valor crítico para optimización)
Peso_Equipo = 0; % N
nodos_brazo = [19];
F(2*nodos_brazo) = F(2*nodos_brazo) - (Peso_Equipo / length(nodos_brazo));

DoF_C = [1, 2, 37, 38]; 
U = zeros(2*nN,1);
U(DoF_C) = 0;

DoF_A = setdiff(1:2*nN, DoF_C);

%% --- PASO 7 AL 9: SOLUCIÓN Y ESFUERZOS ---

U(DoF_A) = K(DoF_A,DoF_A) \ (F(DoF_A) - K(DoF_A,DoF_C)*U(DoF_C));
% (RESTAURADO) Paso 8: Fuerzas de Reacción en el Tractor
Kca = K(DoF_C,DoF_A);
Kcc = K(DoF_C,DoF_C);
F(DoF_C) = Kca*U(DoF_A) + Kcc*U(DoF_C);
st = zeros(nE,1);
for i = 1:nE
    u_vec = U(L_map(i,:));
    T = [-c(i), -s(i), c(i), s(i)];
    st(i) = (M(E(i,4),2)/Le(i)) * T * u_vec;
end

%% --- PASO 10: RESULTADOS Y VISUALIZACIÓN ---
% Gráfica de estructura original vs deformada (Escalada)
figure('Color','w'); hold on;
escala = 10; % Factor para ver la deformación a simple vista
for i = 1:nE
    n1 = E(i,2); n2 = E(i,3);
    % Original
    plot([N(n1,2) N(n2,2)], [N(n1,3) N(n2,3)], 'k--');
    % Deformada
    plot([N(n1,2)+U(2*n1-1)*escala N(n2,2)+U(2*n2-1)*escala], ...
         [N(n1,3)+U(2*n1)*escala   N(n2,3)+U(2*n2)*escala], 'b-o', 'LineWidth', 2);
end
title(['Deformación Escalada x', num2str(escala)]); grid on; axis equal;

%% --- PASO 11: ANÁLISIS DE FATIGA ---
try
    data_ts = load('ts1_limpio.txt'); 
    acc_signal = data_ts(:,2);
    [max_sigma, idx_critico] = max(abs(st));
    sigma_history = acc_signal * max_sigma;
    
    rf = rainflow(sigma_history);
    
    Sr = 200; % Límite de fatiga más realista para A36 (MPa)
    b = 5;
    Amplitud_Esfuerzo = rf(:,2) / 2;
    Dano = sum(rf(:,1) ./ ((Amplitud_Esfuerzo./Sr).^(-b)));
    
    fprintf('\n--- REPORTE DE INGENIERÍA ---\n');
    fprintf('Tubo Seleccionado: Opción %d (Area: %.2f mm2)\n', seleccion, Area_mm2);
    fprintf('Esfuerzo Máximo Estático: %.2f MPa\n', max_sigma);
    fprintf('Daño Acumulado (Miner): %e\n', Dano);
    
    if Dano >= 1, disp('ESTADO: FALLA CRÍTICA POR FATIGA');
    else, disp('ESTADO: ESTRUCTURA SEGURA'); end
catch
    disp('Error en Paso 11: Verifique ts1.txt');
end
toc