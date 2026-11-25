# Runbook — Pérdida de un datafile de aplicación (FREEPDB1)


**Para:** la persona de guardia, aunque no haya hecho el simulacro. **Duración esperada:** unos minutos (RTO medido en el simulacro D: 14 s; 15 s desde el fallo).

## 1. Síntoma
Las consultas a tablas de un tablespace (p. ej. `TBS_ACADEMIA`) fallan con:
- `ORA-01116: error in opening database file n`
- `ORA-01110: data file n: '/opt/oracle/oradata/FREE/FREEPDB1/…dbf'`
- `ORA-27041: unable to open file`
- A veces Oracle cierra la PDB entera: `ORA-63999: data file suffered media failure` en el alert log y FREEPDB1 queda `MOUNTED`.

## 2. Comprobaciones previas (no tocar nada todavía)
```sql
SELECT log_mode FROM v$database;                       -- debe ser ARCHIVELOG; si no, ver §5
SELECT name, open_mode FROM v$pdbs;                    -- ¿FREEPDB1 READ WRITE o MOUNTED?
SELECT file#, name, status, error FROM v$datafile_header WHERE error IS NOT NULL;
```
```
RMAN> LIST BACKUP OF DATAFILE n;                       -- tiene que haber copia
```
Alert log: `tail -200 /opt/oracle/diag/rdbms/free/FREE/trace/alert_FREE.log | grep -E 'ORA-|datafile'`.

## 3. Reparación

**Camino 1 — la PDB sigue abierta (solo cae ese tablespace).** En SQL*Plus como SYSDBA:
```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE n OFFLINE;      -- aísla el fallo; el resto del servicio sigue
```
Si da ORA-01089, la PDB se está cerrando: esperar a que quede `MOUNTED` y seguir por el camino 2.

**Camino 2 — Oracle cerró la PDB (ORA-63999, FREEPDB1 MOUNTED):** no hay nada que poner offline.

**En los dos caminos**, con `rman target /` dentro del contenedor:
```
RESTORE DATAFILE n;
RECOVER DATAFILE n;
```
Después, en SQL*Plus como SYSDBA:
```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE n ONLINE;
-- si FREEPDB1 estaba MOUNTED:
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
```
La CDB y el resto de PDB siguen en servicio en los dos caminos.

## 4. Verificación
```sql
SELECT name, open_mode FROM v$pdbs WHERE name = 'FREEPDB1';         -- READ WRITE
SELECT file#, status FROM v$datafile WHERE file# = n;               -- ONLINE
SELECT estado FROM admin_academia.aca_estudiantes WHERE estudiante_id = 104;  -- fila de control: cambio posterior a la copia presente (RPO 0)
```

## 5. Si no se puede
- Base en NOARCHIVELOG: solo se puede restaurar la copia en frío completa (`scripts/ops/restaurar-estado.sh`) y se pierde todo lo posterior.
- Datafile de SYSTEM/UNDO de la raíz: `SHUTDOWN ABORT` → `STARTUP MOUNT` → `RESTORE` → `RECOVER` → `ALTER DATABASE OPEN`.
- Sin copia RMAN del archivo: escalar.

## 6. A quién avisar
Responsable de la base de datos (DBA de guardia) y profesor Richard Avilés López y equipo de la aplicación afectada. Anotar en la bitácora: hora del fallo,
hora de vuelta al servicio (RTO), datos perdidos (RPO) y causa.
