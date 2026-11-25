# Lab 5 — Respuestas (Administración de Bases de Datos Oracle II)

Alejandro Marti · 2026-11-25 · Capturas y logs de evidencia en `docs/bitacora/lab5/evidencia/` (citados por su nombre final).

## 1. Preguntas de comprobación

### Punto de partida y entorno de pruebas (Partes A y B)

**1.** En mi copia de seguridad del Lab 3 (22/10), el paso de comprobación ya indicaba que no había archivos fuera de sitio, igual que al final del Lab 4 (`*_00-backup-lab4.script.log`). La diferencia real estaba en el inventario de rutas: en el Lab 3 los ficheros de datos figuraban en una carpeta de configuración del motor (`/opt/oracle/product/26ai/dbhomeFree/dbs/academia01.dbf…`), mientras que en el Lab 4 ya aparecían en la carpeta estándar de la base de datos (`/opt/oracle/oradata/FREE/FREEPDB1/`). Como en mi contenedor la primera carpeta era en realidad un acceso directo (enlace simbólico) hacia el disco persistente, los archivos ya estaban a salvo físicamente, pero en una ruta poco ortodoxa. Al moverlos a la carpeta correcta de la PDB, la ruta lógica y la física coinciden y el backup queda limpio sin depender de accesos directos.

**2.** Según el log `*_01-perfil-tiendasur.script.log`, en la tabla `CLIENTE` caben unas 66 filas por cada bloque de memoria/disco (100 000 filas entre 1 517 bloques), mientras que en `PEDIDO` caben unas 188 filas por bloque (1 000 000 filas entre 5 320 bloques). Esto ocurre porque cada fila de `PEDIDO` pesa solo 32 bytes (guarda códigos numéricos, fechas e importes cortos), mientras que cada `CLIENTE` ocupa 102 bytes (textos largos como DNI, nombre, apellidos, email, teléfono y ciudad). Al ocupar un tercio de espacio, en un bloque estándar de 8 KB caben casi el triple de pedidos que de clientes.

**3.** La primera vez que lanzamos una consulta, Oracle tiene que hacer un trabajo extra de "arranque en frío": analizar y compilar la consulta desde cero (*hard parse*) y leer los datos directamente desde el disco duro para subirlos a la memoria RAM (caché). En la segunda ejecución, los datos ya están en memoria y el plan de ejecución ya está calculado; así medimos el coste real y repetible de la consulta en condiciones normales (*lecturas lógicas*), lo que nos permite comparar de forma justa qué opción es más rápida.

### Estructura y tipos de índices (Partes C y D)

**4.** En `*_02-anatomia-indice.script.log` vemos que el índice `IX_PED_CLIENTE` es un árbol de 3 niveles de altura, con 2 216 nodos hoja (el nivel inferior donde están los punteros a los datos) y 6 nodos rama intermedios. Cada nodo rama apunta de media a 370 nodos hijos, y cada hoja guarda unas 451 entradas (dejando un 10 % libre por si llegan datos nuevos). Si la tabla creciera hasta mil millones de filas, el índice tendría más de 2,2 millones de hojas, pero su altura solo subiría a 4 niveles (es decir, solo 5 lecturas para encontrar cualquier fila entre mil millones). Esto demuestra que los índices B-Tree crecen de forma logarítmica y se mantienen muy rápidos aunque la tabla se vuelva gigantesca.

**5.** Al inspeccionar por dentro el índice de clave primaria de clientes (`config/*_02-volcado-indice.trc.txt`), vemos que para el cliente `1` guarda 6 bytes de dirección física (`00 00 03 1b 00 00`). Los 4 primeros bytes indican el número de bloque (`0x31B` en hexadecimal = bloque 795) y los 2 últimos indican la posición dentro de ese bloque (fila 0), lo cual coincide exactamente con lo que devuelve la consulta de comprobación. No necesita guardar el número de fichero porque el *tablespace* `TBS_TIENDASUR` es de tipo `BIGFILE` (consta de un único archivo gigante), así que con saber el bloque y la fila le basta para localizar el dato.

**6.** Comparativa de tipos de índice (`*_03-tipos-indice.script.log`):
- **Índice Único (consulta Q13 por DNI):** Leer toda la tabla de golpe cuesta 1 486 lecturas de bloques, mientras que con el índice único cuesta solo 3 lecturas. Además, garantiza que la base de datos rechace automáticamente cualquier DNI duplicado (`ORA-00001`).
- **Índice Compuesto y Cubriente (consulta Q7):** Con un índice simple por cliente hace 15 lecturas y además tiene que ordenar los resultados en memoria. Con un índice compuesto `(id_cliente, fecha)` baja a 7 lecturas y los datos ya salen ordenados. Con un índice *cubriente* (que incluye todas las columnas que pide el `SELECT`), baja a 3 lecturas porque ni siquiera necesita ir a leer la tabla.
- **Índice Bitmap (consulta Q14):** Sin índices cuesta 4 073 lecturas; combinando 4 índices *bitmap* baja a 528. Además, ocupa poquísimo (114 hojas frente a las 1 954 de un índice normal). Eso sí, solo sirve para bases de datos analíticas (*Data Warehouse*) donde los datos se cargan por lotes, porque si muchos usuarios modifican filas a la vez (*OLTP*), estos índices bloquean rangos enteros de registros.

### Orden físico de los datos y consultas eficientes (Partes E y F)

**7.** En `*_04-agrupamiento-equilibrio.script.log` comprobamos el *Clustering Factor* (CF), que mide si los datos en la tabla están ordenados igual que el índice. El índice por fecha (`IX_PED_FECHA`) tiene un CF muy bajo (5 220, casi igual al número de bloques de la tabla) porque los pedidos se fueron guardando en disco según iban ocurriendo en el tiempo. En cambio, el índice por cliente (`IX_PED_CLIENTE`) tiene un CF pésimo (999 041, casi igual al millón de filas) porque cada cliente hace pedidos en momentos distintos y sus filas están repartidas al azar por todo el disco: leer por este índice obliga a saltar de un bloque a otro constantemente. Reconstruir el índice (`REBUILD`) no arregla esto, porque el problema es cómo están ordenados los datos dentro de la tabla.

**8.** Cuando un índice está mal agrupado (CF malo), solo sale rentable si buscamos muy pocas filas: si pedimos el 0,1 % de la tabla lee 975 bloques (mejor que leer los 5 232 bloques de la tabla entera), pero al pedir el 0,5 % ya lee 4 875 bloques, y al pedir el 1 % lee 9 920 bloques (casi el doble que leer la tabla entera de principio a fin). El punto de equilibrio está en torno al 0,5 % de los datos; por eso Oracle deja de usar el índice a partir del 0,2 % y prefiere hacer un barrido completo. En cambio, con un índice bien agrupado (CF bueno), el índice sigue compensando incluso pidiendo el 60 % de la tabla.

**9.** En `*_05-sargabilidad.script.log`, buscar apellidos con `'Gonz%'` permite usar el índice (`INDEX RANGE SCAN` sobre `IX_CLI_APELLIDOS`) porque el comodín va al final. Sin embargo, como hay 2 056 clientes que empiezan por "Gonz" (un 2,1 % de la tabla) y están dispersos por todos los bloques, usar el índice cuesta 2 024 lecturas frente a las 1 486 que cuesta leer la tabla entera de golpe. Como supera el umbral de rentabilidad (~1,5 % en esta tabla), el índice acaba siendo más lento que no usarlo.

### Coste al escribir datos y mantenimiento de índices (Partes G y H)

**10.** En `*_06-indices.script.log` medimos cuánto cuesta insertar 2 000 pedidos nuevos: con 4 índices se modifican 10,1 bloques por fila y se generan 1 323 bytes de registro de cambios (*redo*); con 9 índices el coste se duplica (20,2 bloques y 2 578 bytes); y con nuestra propuesta final de 5 índices (versión V005) se queda en 12,2 bloques y 1 685 bytes (cada índice extra suma unos 2 bloques de trabajo al insertar). Para optimizarlo:
- Descarté indexar columnas con muy pocos valores distintos, como el canal de venta (3 valores) o el estado (4 valores), sustituyendo este último por un **índice parcial** que solo indexa los pedidos pendientes (ocupando 54 hojas en vez de 2 933).
- Eliminé índices que Oracle marcó como sin uso (`IX_PED_FEC_CLI`) o redundantes (`IX_PED_IMPORTE`, tras comprobar que ponerlo como `INVISIBLE` no empeoraba las consultas, e `IX_PED_CLIENTE`, porque ya tenemos otro índice que empieza por `id_cliente` y sirve para lo mismo).

**11.** Al analizar cómo crecen los índices según el orden en que llegan los datos (`*_07*-grafico-*.script.log`):
- **Datos aleatorios (`IX_AZAR`):** Las hojas se van partiendo por la mitad (50/50), quedando 596 hojas llenas al 75 % de media, con huecos irregulares.
- **Datos siempre crecientes (`IX_CRECIENTE`, como un ID secuencial o fecha actual):** Oracle detecta el patrón y parte las hojas al 90/10, dejando casi todo lleno al 99,9 % (399 hojas muy compactas).
- **Patrón tipo cola (`IX_COLA`, se insertan datos nuevos por un lado y se borran los viejos por el otro):** Acaba con 425 hojas donde toda la mitad izquierda está vacía (41 % de entradas borradas) y solo la derecha tiene datos, desperdiciando mucho espacio.

**12.** Para limpiar esa fragmentación del índice tipo cola sin cortar el servicio (`*_07c-remedios.script.log`), usamos `COALESCE`, que compacta las hojas vacías en caliente y sin bloquear a los usuarios: pasó de 425 a 201 hojas y redujo una consulta de 226 lecturas a solo 2. El comando `SHRINK SPACE` hace lo mismo y además devuelve el espacio libre al *tablespace* (bajando de 4 MB a 1,69 MB). En cambio, `REBUILD ONLINE` consigue un resultado similar pero consumiendo el doble de espacio temporal y generando mucho más *redo*. A nivel de diseño, la solución definitiva para datos tipo cola es particionar la tabla por fechas.

### Puntos de control, archivos de control y registros de transacciones (Partes I a L)

**13.** En `*_08-scn-checkpoint.script.log` comprobamos el *SCN* (el reloj interno de versiones de Oracle). Tanto el *control file* (el mapa general de la base de datos) como las cabeceras de los ficheros de datos marcaban el mismo SCN (`3 531 805`), lo que indica que están sincronizados. Al forzar un `CHECKPOINT`, ambos avanzaron a `3 537 736`. Si al arrancar coinciden y la base se cerró bien, Oracle sabe que no hubo ningún corte abrupto y arranca directo; si los ficheros tienen un SCN más antiguo, sabe que debe recuperar los últimos cambios usando los *redo logs*. La base plantilla `PDB$SEED` se queda congelada en un SCN antiguo porque es de solo lectura.

**14.** Crear una tercera copia del archivo de control (`control03.ctl`, en `*_09-multiplexar-controlfile.script.log`) nos salva si alguien borra o corrompe uno de los archivos por error (como probamos en el simulacro B). Sin embargo, como las tres copias están guardadas dentro de la misma carpeta del mismo disco (`/opt/oracle/oradata/FREE`), si se rompe ese disco duro lo perderemos todo. En un entorno real (producción), cada copia debe guardarse en discos físicos distintos.

**15.** En `*_10-redo.script.log` vemos los estados de los grupos de *Redo Log* (donde Oracle apunta todo lo que ocurre por si se va la luz):
- `CURRENT`: El archivo en el que Oracle está escribiendo en este mismo instante.
- `ACTIVE`: Archivos ya llenos que contienen cambios recientes que aún no se han volcado del todo a los ficheros de datos principales; siguen siendo vitales si hay un apagón.
- `INACTIVE`: Archivos cuyos cambios ya están guardados a salvo en los ficheros de datos; Oracle ya puede sobrescribirlos.
Por seguridad, Oracle prohíbe borrar el grupo `CURRENT` (`ORA-01623`), borrar su último archivo (`ORA-01609`) o quedarse con menos de dos grupos operativos (`ORA-01624`).

**16.** En `*_11-fra-llena.script.log` simulamos qué pasa si se llena la *FRA* (la carpeta destinada a guardar backups y copias históricas de los *redo logs*), reduciéndola a solo 2 MB. El proceso archivador (`ARCn`) se quedó sin espacio (`ORA-19815` / `ORA-16038`) y dejó de copiar los logs históricos. Cuando Oracle llenó todos sus *redo logs* activos y dio la vuelta para reutilizar los viejos, se bloqueó (`log file switch (archiving needed)`) y congeló cualquier cambio nuevo en la base de datos para no sobrescribir datos sin archivar. En cuanto ampliamos la FRA a 4 096 MB, el archivador retomó su trabajo solo y desbloqueó el sistema al instante.

### Concurrencia, Undo y simulacros de desastre (Partes M a P)

**17.** En `*_12-lectura-consistente.script.log` probamos qué pasa cuando dos usuarios tocan el mismo dato: el usuario A cambia el estado de una fila a `EGRESADO` pero no confirma (`COMMIT`). Mientras tanto, el usuario B lee esa fila sin quedarse bloqueado y sigue viendo el valor antiguo (`ACTIVO`), porque Oracle reconstruye la versión anterior usando el espacio de *Undo* (deshacer). B solo se queda bloqueado (error `ORA-00054`) si intenta modificar o bloquear esa misma fila (`FOR UPDATE`). En Oracle, los lectores nunca bloquean a los escritores ni viceversa.

**18.** Al medir cuánto espacio de *Undo* (datos para poder dar marcha atrás) consumen 10 000 operaciones (`*_12-undo-y-redo.script.log`):
- Un `INSERT` gasta muy poco undo (1 120 KB), porque para deshacerlo solo hay que apuntar "borra esta fila".
- Un `UPDATE` gasta algo más (1 264 KB), porque guarda los valores antiguos de las columnas modificadas.
- Un `DELETE` gasta muchísimo (3 424 KB), porque tiene que guardar toda la fila completa y sus índices por si hay que resucitarla.
Además, hacer un `ROLLBACK` (deshacer) también genera registros *redo*, porque al fin y al cabo deshacer es volver a modificar bloques de datos y Oracle protege cualquier cambio en disco.

**19.** En `*_13-lgwr-dbwn.script.log` comprobamos la regla de oro de las bases de datos (*Write-Ahead Logging*): tras actualizar 20 000 filas y hacer `COMMIT`, el proceso `LGWR` escribió inmediatamente 8 155 KB en los *redo logs*, mientras que el proceso `DBWn` escribió **0 bloques** en los ficheros de datos principales (231 bloques se quedaron modificados solo en la memoria RAM). Esto significa que, al hacer `COMMIT`, tus datos están a salvo gracias al *redo log*, aunque aún no se hayan escrito en las tablas reales. Solo al lanzar un `CHECKPOINT`, `DBWn` volcó los 620 bloques sucios al disco.

**20.** En `*_14a-caida-instancia.script.log` simulamos un apagón brusco (`SHUTDOWN ABORT`). Al volver a arrancar, la fila que tenía `COMMIT` (`102`) conservó su cambio, mientras que la que estaba sin confirmar (`103`) volvió a su estado original. En el registro de alertas (*Alert log*) vimos cómo Oracle ejecuta automáticamente la recuperación en dos fases:
1. **Roll forward (hacia adelante):** El proceso `SMON` lee los *redo logs* desde el último punto de control y rehace todo lo que estaba en memoria antes del apagón (incluidas las transacciones sin confirmar).
2. **Roll back (hacia atrás):** Una vez reconstruido el estado exacto del momento del corte, usa el *Undo* para borrar todo aquello que no tenía `COMMIT`.

**21.** Diferencias entre los dos simulacros de pérdida de datos:
- **Simulacro C (`*_14c-simulacro-restauracion.script.log`):** Hubo que apagar la base de datos, restaurar una copia en frío completa de 1,5 GB y volver a arrancar. Tardó **123 segundos** (RTO) y se perdieron los datos creados en los 3 segundos posteriores a la copia (RPO).
- **Simulacro D (`*_14d-perdida-datafile.script.log`):** Se borró un fichero de datos en caliente, pero como teníamos backups con **RMAN** y los *redo logs* archivados, restauramos solo ese archivo sin apagar el servidor completo y aplicamos los cambios pendientes. Tardó solo **14 segundos** y **no se perdió ni un solo dato** (RPO = 0).

**22.** Revisión de errores en el diagnóstico final (`*_15-healthcheck.spool.log`):
- `ORA-63999`, `ORA-01110` y `ORA-01113`: Son rastros normales del simulacro D cuando borramos el archivo 16 y lo recuperamos; tras el arreglo la base quedó abierta y operativa.
- `ORA-65019` (*FREEPDB1 already open*): El script de revisión intentó abrir la base de datos cuando ya estaba abierta.
- `ORA-00800` (*Set Priority Failed*): Un aviso habitual al ejecutar Oracle dentro de contenedores Docker, ya que el contenedor restringe que los procesos cambien su prioridad en el sistema operativo.
- **Conclusión de salud:** No hay ningún fallo real pendiente en el sistema.

## 2. Simulacro de examen 1Z0-182

| Pregunta | Resp. | Explicación sencilla | Tema |
|---|---|---|---|
| **S1** | **B** | El *Clustering Factor* es casi igual al número de filas: cada entrada del índice obliga a leer un bloque distinto del disco (`IX_PED_CLIENTE`). | E |
| **S2** | **A, C** | Como los emails están guardados en minúsculas, la consulta usa `UPPER(email)`: o se crea un índice basado en función sobre `UPPER(email)` (`IX_CLI_UPPER_EMAIL`) o se reescribe como `email = LOWER(:e)`. | D/F |
| **S3** | **B** | Oracle tuvo que convertir el texto a número en cada fila (`TO_NUMBER`), anulando el uso del índice por conversión implícita. | F |
| **S4** | **B** | Los índices *Bitmap* son ideales cuando una columna tiene pocos valores distintos y los datos se cargan por la noche por lotes. | D |
| **S5** | **B** | Al filtrar solo por ciudad (segunda columna de un índice compuesto), Oracle pudo aprovecharlo mediante un `INDEX SKIP SCAN`. | D |
| **S6** | **B** | Marcar un índice como `INVISIBLE` permite probar si hace falta sin borrarlo; si algo empeora, se vuelve a poner `VISIBLE` al instante. | G |
| **S7** | **A, C** | Tanto `COALESCE` como `SHRINK SPACE` desfragmentan el índice en caliente sin cortar el acceso a la tabla. | H |
| **S8** | **B** | Un índice `REVERSE` dispersa los valores secuenciales, por lo que no sirve para buscar rangos (`BETWEEN` o `>`), obligando a leer toda la tabla. | H |
| **S9** | **C** | Si modificas una columna que no forma parte de ningún índice, Oracle no tiene que actualizar ningún árbol extra. | G |
| **S10** | **B** | La altura del árbol depende del tamaño de las claves indexadas: claves más pequeñas permiten meter más punteros por bloque y reducir niveles. | C |
| **S11** | **A, C** | En una tabla organizada por índice (*IOT*), toda la fila vive dentro del propio índice de clave primaria, ahorrando saltos a la tabla. | D |
| **S12** | **B** | Para saber si los archivos están al día, Oracle compara el SCN guardado en el *control file* con el de la cabecera de cada *datafile*. | I |
| **S13** | **C** | El proceso `CKPT` actualiza las cabeceras y el *control file*, mientras que `DBWn` es quien escribe los bloques de datos en disco. | I/N |
| **S14** | **B, E** | En estado `NOMOUNT` la base aún no está abierta: solo se pueden consultar vistas de la instancia en memoria (`v$instance`, `v$parameter`). | Lab 4 |
| **S15** | **B** | Activar o desactivar el modo `ARCHIVELOG` exige tener la base de datos montada pero cerrada (`MOUNT`). | L |
| **S16** | **B** | `ALTER DATABASE CLEAR LOGFILE` limpia y recrea un grupo de *redo* corrupto siempre que ya esté `INACTIVE` y archivado. | K |
| **S17** | **A, C** | Tanto la lectura consistente (ver datos antes de un cambio sin confirmar) como *Flashback Query* (consultar el pasado) dependen del *Undo*. | M |
| **S18** | **B** | Los cambios en el *Undo* también se apuntan en el *Redo Log* para poder reconstruirlos tras un apagón y deshacer transacciones abiertas. | M |
| **S19** | **A** | Al hacer `COMMIT`, `LGWR` vacía el *redo* al disco inmediatamente, pero `DBWn` deja los bloques de datos en memoria para escribirlos más tarde. | N |
| **S20** | **A** | Si exiges un tiempo de recuperación tras caída (*MTTR*) muy bajo, Oracle hace *checkpoints* más frecuentes para tener menos trabajo pendiente. | I |
| **S21** | **B** | Si la *FRA* se llena, `ARCn` no puede guardar copias de los *redo logs* y la base de datos se congela hasta que liberes espacio. | L |
| **S22** | **B** | Poner un fichero dañado en modo `OFFLINE` permite aislar el problema y seguir trabajando con el resto de la base de datos. | O |
| **S23** | **B** | El tablespace `SYSTEM` es vital y no se puede poner offline; hay que bajar la base a `MOUNT`, restaurar con RMAN, recuperar y abrir. | O |
| **S24** | **B** | Si no tienes modo `ARCHIVELOG` activo, no puedes recuperar cambios recientes: solo puedes volver atrás hasta la última copia en frío. | O |
| **S25** | **B, D** | Para evitar el error *Snapshot too old* (`ORA-01555`), hay que ampliar el espacio de *Undo* y el tiempo de retención (`UNDO_RETENTION`). | M |
| **S26** | **A** | La vista `V$RECOVERY_AREA_USAGE` muestra qué porcentaje de la *FRA* está ocupado por cada tipo de archivo. | L |

Preguntas rápidas de la Parte O: **O1** B · **O2** B, D · **O3** B · **O4** D (tras borrar una tabla con `PURGE`, no se puede recuperar con `FLASHBACK TABLE` porque no pasa por la papelera).

## 3. Simulacro de desastres (Game Day): tiempos y retrospectiva

| Simulacro | Fallo provocado | Tiempo de recuperación (RTO) | Pérdida de datos (RPO) | Evidencia |
|---|---|---|---|---|
| **A** | Apagón brusco (`SHUTDOWN ABORT`) | Unos segundos (no cronometrado: STARTUP normal con recuperación automática) | **0** (ningún dato confirmado perdido) | `14a-caida-instancia` |
| **B** | Borrado de una copia del *control file* (`control03.ctl`) | Unos segundos (no cronometrado: copiar archivo sano, montar y abrir) | **0** | `14b-perdida-controlfile` |
| **C** | Borrado permanente de tabla (`DROP … PURGE`) + copia en frío | **123 s** (parar, descomprimir 1,5 GB y arrancar) | **3 s** (todo lo hecho tras la copia) | `14c-simulacro-restauracion` |
| **D** | Borrado en caliente de un fichero de datos (`academia01.dbf`) | **14 s** (15 s desde el fallo, usando RMAN en caliente) | **0** (recuperado al segundo exacto) | `14d-perdida-datafile` |

**Qué me sorprendió:** En el simulacro D, al borrar un solo fichero de datos de usuario, Oracle cerró por precaución toda la base conectable (`FREEPDB1`) en lugar de aislar únicamente ese *tablespace*. Aun así, restaurar solo ese archivo con RMAN y aplicar los logs pendientes fue **9 veces más rápido** que restaurar la copia completa en frío, y sin perder ni un solo registro.

**Qué mejoraría:**
- Configurar backups periódicos con RMAN de toda la base de datos para no depender nunca de copias en frío lentas (y poder usar `RMAN RECOVER TABLE` ante borrados accidentales con `PURGE`).
- Separar los archivos de control y los miembros de *Redo Log* en discos físicos distintos.
- Configurar una alerta automática cuando la *FRA* supere el 80 % de ocupación para evitar bloqueos.
- Medir con cronómetro exacto también los tiempos de arranque de los simulacros A y B.

**Conclusiones (retrospectiva):** Los cuatro escenarios de fallo se resolvieron siguiendo el procedimiento y sin pérdida de datos confirmados (excepto la pequeña ventana de 3 segundos del simulacro C, inevitable al usar una copia en frío). La clave del éxito fue tener la base en modo `ARCHIVELOG` con la *FRA* configurada y validar siempre un punto de restauración antes de cada prueba. El procedimiento de recuperación ante pérdida de ficheros queda documentado en `docs/runbooks/perdida-datafile.md`, y como siguiente paso queda automatizar los backups con RMAN.
