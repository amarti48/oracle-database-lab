# Lab 4 — Autopsia de la instancia

## 1. Identidad del sistema

| Elemento | Valor medido |
|---|---|
| Instancia | FREE, Oracle AI Database 26ai Free 23.26.3.0.0, arrancada 2026-11-25 17:34 |
| Base de datos | FREE, DBID 1509902213, CDB, **ARCHIVELOG**, READ WRITE, FORCE LOGGING YES, FLASHBACK NO |
| Contenedores | CDB$ROOT, PDB$SEED (810 MB, READ ONLY), FREEPDB1 (1482 MB, READ WRITE) |
| Memoria | SGA 1529 MB (buffer cache 1040 MB, shared pool 448 MB); PGA objetivo 512 MB, máximo asignado 479 MB |
| Procesos | 93 de segundo plano (PMON, SMON, DBW0, LGWR, CKPT, LREG, ARC0-ARC3…) y 6 servidores |
| Archivos | 16 datafiles (4079 MB), 3 tempfiles, 2 control files, 3 grupos de redo de 1 miembro (600 MB), 6 redo archivados (960 MB) |

## 2. Hallazgos

| # | Hallazgo | Evidencia (valor exacto) | Riesgo | Acción | Prioridad |
|---|---|---|---|---|---|
| 1 | Base en ARCHIVELOG **sin FRA** configurada | Sección 4: `db_recovery_file_dest` vacío y `db_recovery_file_dest_size` = 0; 6 archived logs, 960 MB | **Alto.** El redo archivado se acumula fuera de un destino con límite y alertas. Si se llena el destino, ARCn no puede archivar y la base deja de aceptar cambios | Configurar una FRA de 4 GB en el volumen y vigilar su uso (`V$RECOVERY_AREA_USAGE`) | Alta |
| 2 | Solo **2 copias del control file**, en el mismo volumen | Sección 4: `control_files` = control01.ctl, control02.ctl en `/opt/oracle/oradata/FREE` | Medio. Protege de un borrado o una corrupción de un archivo, no de perder el disco | Añadir una tercera copia; en producción, en discos distintos | Media |
| 3 | **Redo online sin multiplexar** | Sección 4: 3 miembros para 3 grupos (1 por grupo, 200 MB cada uno) | Medio-alto. Perder el miembro del grupo CURRENT obliga a una recuperación incompleta | Añadir un segundo miembro a cada grupo | Media |
| 4 | Esquemas de negocio **sin estadísticas** | Sección 6: ALTURA_MAX vacía en ADMIN_CLINICA, ADMIN_FINTECH, ADMIN_LOGISTICA y ADMIN_RETAIL | Medio. El optimizador elige planes sin datos (riesgo de planes malos cuando crezcan) | `DBMS_STATS.GATHER_SCHEMA_STATS` en cada esquema y dejar activa la tarea automática | Media |
| 5 | Índices con **mal factor de agrupamiento** | Sección 6: ADMIN_ACADEMIA, 2 índices con CF cercano al número de filas (altura máxima 2) | Bajo. Los recorridos por rango de esos índices leen casi un bloque por fila | Solo vigilarlo: un REBUILD no lo cambia, porque depende del orden físico de la tabla | Baja |
| 6 | **ADR fuera del volumen** | Evidencia 11: "/opt/oracle/diag vive en la capa del contenedor"; ADR de 29 MB y 213 trazas | Medio. Al recrear el contenedor (como en la prueba de persistencia) se pierde el alert log y con él el historial de incidentes | Montar `/opt/oracle/diag` en un volumen o exportar el alert log periódicamente | Media |
| 7 | Errores ORA- en el alert log (24 h) | Sección 10: 6 errores. ORA-00800 ×4 (Set Priority Failed en VKTM y LGWR), ORA-65025 ×1, ORA-959 ×1 | Bajo. ORA-00800: el contenedor no permite cambiar la prioridad de procesos (ruido conocido de Docker). ORA-65025 y ORA-959: provocados a propósito por los scripts 10 y 14 del laboratorio | Documentar el ORA-00800 como ruido conocido; ninguna acción para los otros dos | Baja |
| 8 | Seguridad de cuentas | Sección 7: ninguna cuenta propia con rol DBA; C##OPS_RO común, solo lectura y sin privilegios ANY de escritura; ADMIN_* con autenticación NONE | Ninguno (correcto) | Mantener el mínimo privilegio | — |
| 9 | Espacio | Sección 5: ningún tablespace por encima del 3 % (TBS_ACADEMIA 2,3 %, 23 de 1024 MB) | Ninguno | Vigilancia normal | — |

## 3. Datos de rendimiento medidos (contexto)

- Buffer cache: la misma consulta pasó de 262 lecturas físicas (caché fría) a 0 (caché caliente), con 247 lecturas lógicas (evidencia 08).
- Parse: 1000 consultas con literales hicieron 1000 análisis duros (1160 ms); con variable de enlace, 1 análisis y 20 ms. Usar binds no es opcional.
- PGA: una ordenación con 64 KB de memoria hizo 6 pasadas a TEMP y tardó 2040 ms frente a 150 ms en memoria.
- Coste por lectura (evidencia 13): lógica 3,1 µs; física aleatoria 11,1 µs, servida en gran parte por la caché de Linux; umbral índice/recorrido completo ≈ 0,82 % de las filas.

## 4. Resumen para dirección (no técnico)

La base de datos funciona, está bien protegida frente a accesos indebidos y todos sus datos están dentro del volumen que se copia.
El punto débil es la recuperación ante fallos: hoy hay pocas copias de los archivos críticos y el espacio de archivado no tiene control.
La próxima fase (Lab 5) corrige esos tres puntos: área de recuperación de 4 GB, tercera copia del control file y redo duplicado.
