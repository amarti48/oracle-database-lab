# Respuesta — Lab 6

## S1
**Respuesta: B. MMON**

El proceso MMON es el encargado de comprobar diferentes métricas de la base de datos y generar avisos relacionados con los umbrales de espacio de los tablespaces.

**Comprobado en:** Parte B: spool/*_01-automatizacion (umbrales de espacio de MMON, que salían NONE)

---

## S2
**Respuesta: C. Se aplica a las sesiones que se conecten a partir de ese momento.**

Cuando un parámetro tiene `ISSYS_MODIFIABLE = DEFERRED`, el cambio no afecta a las sesiones que ya están conectadas, sino a las nuevas sesiones que se creen después del cambio.

**Comprobado en:** Parte C: script/*_02-parametros (sort_area_size aparece como DEFERRED)

---

## S3
**Respuesta: B. `CREATE PFILE FROM MEMORY;`**

Esta sentencia crea un fichero PFILE utilizando los parámetros que están actualmente en memoria, incluyendo los valores calculados por Oracle.

**Comprobado en:** Parte C: config/*_02-init_desde_memoria.ora (el PFILE creado desde memoria)

---

## S4
**Respuestas: A.**

- **A.** `ALTER PLUGGABLE DATABASE pdb OPEN READ WRITE;`
- **C.** `ALTER PLUGGABLE DATABASE pdb CLOSE IMMEDIATE;` seguida de `ALTER PLUGGABLE DATABASE pdb OPEN;`

Ambas opciones permiten que una PDB que estaba en `READ ONLY` vuelva a estar abierta en `READ WRITE`.

**Comprobado en:** Parte C — Estados de las PDB.

---

## S5
**Respuesta: C. `DBA_PDB_SAVED_STATES`**

Esta vista permite consultar el estado que se ha guardado para cada PDB, por ejemplo si debe quedar abierta después de un reinicio.

**Comprobado en:** Parte C — Estados de las PDB.

---

## S6
**Respuesta: B. ORA-01035**

Si una PDB está abierta en modo restringido, un usuario que no tenga el privilegio `RESTRICTED SESSION` no puede conectarse a ella y recibe `ORA-01035`.

**Comprobado en:** Parte C — `_02-estados-pdb`.

---

## S7
**Respuesta: A. `DBMS_SERVICE`**

El paquete `DBMS_SERVICE` permite crear, iniciar y detener servicios de base de datos cuando no se utiliza Grid Infrastructure.

**Comprobado en:** Parte D: script/*_03-servicio (servicio academia_app creado y arrancado)

---

## S8
**Respuesta: B. `PADDR = ADDR`**

La relación entre `V$SESSION` y `V$PROCESS` se realiza mediante las columnas `PADDR` de `V$SESSION` y `ADDR` de `V$PROCESS`.

**Comprobado en:** Parte D — `_03-sesiones`.

---

## S9
**Respuesta: C. Sigue abierta: solo se cancela la llamada en curso.**

`ALTER SYSTEM CANCEL SQL` cancela la sentencia que se está ejecutando, pero no hace `COMMIT` ni `ROLLBACK` de la transacción que pudiera tener pendiente la sesión.

**Comprobado en:** Parte D — `_03-sesiones`.

---

## S10
**Respuesta: A. SYS**

Aunque la conexión se realice utilizando `SYSOPER`, el usuario sigue siendo `SYS`. Por eso `SHOW USER` devuelve `SYS`.

**Comprobado en:** Parte D — `_03-sesiones`.

---

## S11
**Respuesta: B. `V$CON_SYSMETRIC`**

Esta vista permite consultar las métricas de sistema de la PDB en la que estamos conectados, incluyendo los valores correspondientes al último minuto.

**Comprobado en:** Parte E — Métricas y rendimiento.

---

## S12
**Respuestas: A y C.**

- **A.** Tiempo de CPU utilizado en llamadas a la base de datos.
- **C.** Tiempo de espera no `Idle` de las sesiones de primer plano.

El `DB time` representa el tiempo empleado por las sesiones de usuario trabajando en la base de datos, incluyendo CPU y esperas que no sean de tipo `Idle`.

**Comprobado en:** Parte E — Métricas y rendimiento.

---

## S13
**Respuesta: B. HR**

Aunque `SYS` realice la operación, la tabla pertenece al usuario `HR`. El que necesita tener cuota sobre el tablespace `USERS` para almacenar objetos de `HR` es el propio usuario `HR`.

**Comprobado en:** Parte F — Cuotas y tablespaces.

---

## S14
**Respuestas: A y C.**

- **A.** Undo.
- **C.** Temporal.

No se pueden conceder cuotas normales sobre tablespaces de tipo `UNDO` o `TEMPORARY`.

**Comprobado en:** Parte F — Cuotas y tablespaces.

---

## S15
**Respuestas: A y C.**

- **A.** La sentencia se suspende hasta que se alcance el tiempo de espera.
- **C.** La suspensión puede consultarse mediante `DBA_RESUMABLE`.

Cuando una sesión tiene `RESUMABLE` activado y se queda sin espacio o cuota, Oracle puede suspender la operación en lugar de fallarla inmediatamente.

**Comprobado en:** Parte F — Espacio, cuotas y operaciones resumibles.

---

## S16
**Respuesta: B. `ENABLE ROW MOVEMENT` y ASSM**

Para utilizar `ALTER TABLE t SHRINK SPACE`, la tabla debe permitir el movimiento de filas y encontrarse en un tablespace gestionado con ASSM.

**Comprobado en:** Parte F — Gestión de espacio de las tablas.

---

## S17
**Respuesta: B. `LOCKED(TIMED)`**

Con `FAILED_LOGIN_ATTEMPTS = 3`, después de alcanzar los tres intentos fallidos la cuenta se bloquea. Como `PASSWORD_LOCK_TIME = 1`, el bloqueo es temporal y aparece como `LOCKED(TIMED)`.

**Comprobado en:** Parte G — Usuarios y perfiles.

---

## S18
**Respuesta: B. Lo conserva.**

Si A recibió el privilegio de sistema mediante `WITH ADMIN OPTION` y después se lo concede a B, revocar el privilegio a A no provoca que B lo pierda. Los privilegios de sistema no se revocan en cascada de esta forma.

**Comprobado en:** Parte G — Privilegios y revocaciones.

---

## S19
**Respuestas: A y B.**

- **A.** `ALTER TABLE ... MOVE` sin `UPDATE INDEXES`.
- **B.** `ALTER INDEX ... UNUSABLE`.

En ambos casos el índice puede quedar marcado como `UNUSABLE` y será necesario reconstruirlo antes de poder utilizarlo normalmente.

**Comprobado en:** Parte H: script/*_07-objetos (el MOVE deja IX_EST_LAB6_ESTADO UNUSABLE)

---

## S20
**Respuesta: B. `DBMS_MONITOR.SESSION_TRACE_ENABLE`**

Este procedimiento permite activar la traza de una sesión concreta utilizando su `SID` y `SERIAL#`.

**Comprobado en:** Parte H: script/*_07-adr-trazas (traza activada con DBMS_MONITOR)

---

## S21
**Respuesta: C. `DIAGNOSTIC_DEST`**

El parámetro `DIAGNOSTIC_DEST` establece la ubicación raíz del Automatic Diagnostic Repository (ADR), donde Oracle almacena información de diagnóstico, trazas y alertas.

**Comprobado en:** Parte H: script/*_07-adr-trazas (traza activada con DBMS_MONITOR)

---

## S22
**Respuesta: C. Identificar al bloqueador (`BLOCKING_SESSION`) y qué está haciendo.**

Ante una espera `enq: TX - row lock contention`, lo primero es localizar qué sesión está bloqueando a la que está esperando y comprobar qué operación está realizando. No tiene sentido reiniciar la instancia o terminar directamente la sesión que está esperando sin conocer antes la causa.

En el incidente `INC-601` se comprobó precisamente este caso: la sesión de secretaría estaba esperando por el bloqueo de otra sesión (`215,9`), que mantenía una transacción abierta.

**Comprobado en:** Guardia nocturna — `INC-601`.
