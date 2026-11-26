# Guardia Nocturna — Lab 6 (E044)

## INC-601 · Bloqueo de fila en la ficha del estudiante 101

- **Detección:** A las 22:00 UTC, Ana García, de secretaría, avisó de que su pantalla se quedaba bloqueada al intentar guardar los cambios de la ficha del estudiante 101 en `FREEPDB1`.

- **Impacto:** Durante unos 2 minutos, aproximadamente desde las 21:59:58 hasta las 22:02:03 UTC, el personal de secretaría no pudo modificar el registro del estudiante 101.

- **Diagnóstico:** En el fichero `20261126T220008Z_08-diagnostico.script.log` se encontró que la sesión `220` (`ANA_GARCIA`) estaba esperando por el evento `enq: TX - row lock contention`, de tipo `Application`. El bloqueo afectaba a la fila 5 del bloque 782 de la tabla `ACA_ESTUDIANTES`. La sesión que estaba provocando el bloqueo era la `215,9` (`APP_ACADEMIA`), perteneciente al módulo `matriculas` y con la acción `cierre-periodo`. Esta sesión mantenía un bloqueo exclusivo (`LMODE = 6`) y tenía un registro de undo todavía sin confirmar.

- **Causa raíz:** El proceso de matrículas había actualizado la fila correspondiente al estudiante 101, pero dejó la transacción abierta sin hacer `COMMIT` ni `ROLLBACK`. Al quedar la transacción abierta, otras sesiones no podían modificar esa misma fila.

- **Intervención:** A las 22:02:03 UTC se terminó la sesión que estaba bloqueando mediante:

  `ALTER SYSTEM KILL SESSION '215,9' IMMEDIATE;`

  Esto hizo que Oracle realizara el rollback de la operación pendiente. El resto de la instancia no se vio afectado.

- **Validación:** En `20261126T220234Z_08-diagnostico.script.log` se comprobó que ya no había sesiones bloqueadas (`BLOQ` vacío). Después, en `20261126T220311Z_08-validacion-inc601.script.log`, se confirmó que la operación de secretaría se había completado correctamente y que el estudiante 101 aparecía con estado `ACTIVO`.

- **Acción preventiva:** Sería conveniente revisar el control de las transacciones en el módulo `matriculas`, concretamente en `cierre-periodo`, para asegurarse de que las transacciones se cierran correctamente. También se podrían configurar límites de inactividad mediante `IDLE_TIME` o alertas que avisen cuando exista un bloqueo durante demasiado tiempo.

---

## INC-602 · Error ORA-12514 por servicio detenido

- **Detección:** A las 22:03 UTC, el equipo de matrículas informó de que aparecía el error `ORA-12514` al intentar crear nuevas conexiones desde la aplicación.

- **Impacto:** Durante unos 2 minutos, desde las 22:03 hasta las 22:05 UTC, las nuevas sesiones de la aplicación de matrículas no pudieron conectarse a `FREEPDB1`. Las sesiones que ya estaban abiertas continuaron funcionando.

- **Diagnóstico:** En `20261126T220334Z_08-diagnostico.script.log`, concretamente en la sección 6, se comprobó que `FREEPDB1` estaba abierta, pero el servicio `academia_app` aparecía como `ARRANCADO = NO`. Al comparar `CDB_SERVICES` con `V$ACTIVE_SERVICES`, se vio que el servicio no estaba activo y por eso LREG no lo había registrado en el listener. En ese momento el listener solo anunciaba `freepdb1`.

- **Causa raíz:** El servicio `academia_app` había sido detenido sin realizar un procedimiento de mantenimiento coordinado ni avisar al equipo correspondiente. Además, como no estaba guardado el estado de la PDB con el servicio activo, un reinicio también podría haber provocado que el servicio no arrancase automáticamente.

- **Intervención:** A las 22:05:09 UTC se accedió a `FREEPDB1` y se arrancó el servicio con:

  `EXEC DBMS_SERVICE.START_SERVICE('academia_app');`

  Después se guardó el estado de la PDB mediante:

  `ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;`

- **Validación:** A las 22:05:31 UTC, en `20261126T220531Z_08-validacion-inc602.script.log`, se comprobó que `APP_ACADEMIA` podía volver a conectarse utilizando el servicio `academia_app`. Posteriormente, en `20261126T220701Z_08-diagnostico.script.log`, el servicio aparecía como `ARRANCADO = SI`.

- **Acción preventiva:** Se recomienda añadir a la monitorización una comprobación de los servicios importantes mediante `V$ACTIVE_SERVICES`. También habría que utilizar `SAVE STATE` después de realizar cambios sobre los servicios de las PDB para evitar que se pierdan después de un reinicio.

---

## INC-603 · Bloqueo de la cuenta APP_ACADEMIA (ORA-28000)

- **Detección:** A las 22:07 UTC, el equipo de matrículas informó de que las conexiones estaban siendo rechazadas con el error `ORA-28000`. El problema apareció después de un despliegue y coincidía con una nota del turno de tarde donde se indicaba que se había ejecutado el script trimestral de bajas.

- **Impacto:** La aplicación de matrículas no pudo acceder a la base de datos durante unos 36 segundos, aproximadamente entre las 22:07:00 y las 22:07:36 UTC.

- **Diagnóstico:** En `20261126T220724Z_08-diagnostico.script.log`, sección 7, se comprobó que la cuenta `APP_ACADEMIA` tenía `ACCOUNT_STATUS = LOCKED`. Se trataba de un bloqueo manual realizado a las 22:07 y no de un `LOCKED(TIMED)`. La cuenta utilizaba además el perfil `DEFAULT`, con `INTENTOS_PERMITIDOS = 10`, por lo que se descartó que el bloqueo se debiera a demasiados intentos de contraseña incorrectos.

- **Causa raíz:** El problema estaba en el script trimestral encargado de revisar las bajas. El script no diferenciaba entre las cuentas normales de usuarios, que utilizan el perfil `PRF_PERSONAS`, y las cuentas técnicas utilizadas por las aplicaciones, como las que empiezan por `APP_*`. Como consecuencia, el script terminó bloqueando también la cuenta `APP_ACADEMIA`.

- **Intervención:** Después de comprobar que no se trataba de un problema de seguridad, a las 22:07:36 UTC se desbloqueó únicamente la cuenta afectada mediante:

  `ALTER USER app_academia ACCOUNT UNLOCK;`

  La operación se realizó dentro de `FREEPDB1`.

- **Validación:** En `20261126T220738Z_08-validacion-inc603.script.log` se confirmó que `APP_ACADEMIA` podía volver a acceder a la base de datos mediante el servicio `academia_app`. Además, en `20261126T220937Z_08-diagnostico.script.log`, sección 7, la consulta de cuentas bloqueadas ya no devolvía resultados.

- **Acción preventiva:** El script trimestral debería modificarse para que solamente tenga en cuenta las cuentas nominales asociadas al perfil `PRF_PERSONAS`. También sería recomendable crear una lista de exclusión para las cuentas de servicio y de aplicación, evitando así que puedan bloquearse accidentalmente en futuras ejecuciones.
