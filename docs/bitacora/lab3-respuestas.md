# Respuestas de comprobación — Laboratorio 3

## 8.1.1. Docker
1. **Diferencia entre imagen y contenedor:** Una imagen es como el instalador o la plantilla (como una ISO o una plantilla de VM) que no cambia. El contenedor es esa plantilla ya arrancada y funcionando en memoria. En el ejercicio G2, `hello-world` era la imagen y al hacer `docker run` creamos el contenedor ejecutándose.
2. **Desaparición de `nota.txt` (G5 vs G6):** En G5 creamos el archivo dentro del propio contenedor sin montar nada fuera, así que al borrar el contenedor se perdió todo. En G6 usamos un volumen con `-v`, guardando los datos en el disco de la máquina, por lo que aunque el contenedor se destruya, los datos se quedan guardados.
3. **`docker ps` vs `docker ps -a` y `Exited (0)`:** `docker ps` solo te enseña los contenedores que están funcionando ahora mismo. `docker ps -a` te enseña todos, tanto los que están activos como los parados. `Exited (0)` significa que el contenedor ha terminado su tarea y se ha cerrado bien, sin errores.
4. **Mapeo `-p 8181:8181` y `-p 80:8080`:** El número de la izquierda es el puerto de nuestra máquina y el de la derecha el de dentro del contenedor. Si pones `-p 80:8080`, accederías desde el navegador de tu ordenador usando el puerto 80 (`http://localhost`), pero por dentro Nginx respondería en su puerto 8080.
5. **Ejecución de Oracle vs `hello-world`:** `hello-world` solo saca unas líneas de texto por consola y se apaga solo. Oracle, en cambio, se queda corriendo en segundo plano esperando conexiones de base de datos, por lo que no se cierra a menos que lo pares tú.
6. **Digest de una imagen:** Es como el DNI o la huella digital exacta de esa versión de la imagen. Se guarda porque la etiqueta `:latest` puede cambiar si los creadores suben una actualización, y con el digest te aseguras de que siempre vas a usar exactamente la misma versión.
7. **Borrado real de datos de Oracle:** Lo borraría el comando `docker volume rm oralab-26ai-data`. Al hacer `docker rm oralab-26ai` solo borras el contenedor, pero la información sigue a salvo en el volumen.

## 8.1.2. Git, organización y evidencia
8. **Uso de repositorio, Issue, branch y PR:** Para trabajar igual que se hace en las empresas. Así todo el proyecto queda organizado, con registro en Git y se puede revisar con un Pull Request antes de juntarlo con la rama principal (`main`), en vez de tener archivos sueltos.
9. **`source 00-config.sh` vs `bash 00-config.sh`:** `bash 00-config.sh` ejecuta el script en una subpantalla oculta y cuando termina se borra todo. Con `source 00-config.sh` las variables de entorno se quedan guardadas en nuestra terminal actual para poder usarlas en los siguientes comandos.
10. **Desglose de `20260915T091230Z_02-docker.script.log`:** `20260915` es la fecha (15 de sep de 2026), la `T` separa fecha y hora, `091230` es la hora con minutos y segundos, la `Z` indica hora UTC, `_02-docker` es el paso del lab y `.script.log` el tipo de archivo de evidencia.
11. **Para qué sirve `.gitattributes`:** Sirve para indicarle a Git cómo manejar los saltos de línea. Evita el típico error de Windows `$'r': command not found` cuando ejecutas scripts `.sh` de Linux.
12. **`Create a merge commit` vs `Squash and merge`:** Porque nos interesa guardar el historial de commits paso a paso para ver cómo fuimos haciendo y comprobando cada parte. Con *squash* se juntaría todo en un solo commit y perderíamos ese detalle.

## 8.1.3. Seguridad
13. **Cuatro capas de la estrategia de contraseñas:** 1) Guardar las claves en `config/.env`, 2) poner ese archivo en `.gitignore`, 3) crear un `.env.example` con valores de ejemplo, y 4) hacer que los scripts lean las variables del `.env`. Si te saltas la primera y escribes la clave en un script, acabará subida a GitHub visible para cualquiera.
14. **No escribir contraseñas en `docker run`:** Porque aunque no subas el script a Git, escribir contraseñas directamente en la terminal hace que se queden guardadas en el historial de comandos de Linux (`history`) y en los logs.
15. **Contraseña en commit publicado:** No sirve de nada borrarla en un commit nuevo porque en Git el historial antiguo sigue guardado. Lo que hay que hacer es dar la clave por comprometida, cambiarla por una nueva en la base de datos/`.env` y avisar para limpiar la rama.

## 8.1.4. Oracle y herramientas
16. **SPOOL y `@archivo.sql` dentro del contenedor:** Porque dentro del contenedor las rutas de carpetas no son las mismas que en la máquina real. Por eso ejecutamos SQL*Plus desde fuera enviándole el script por tuberías y guardando la salida con `tee`.
17. **`WHENEVER SQLERROR EXIT SQL.SQLCODE`:** Sirve para que si salta cualquier error en la base de datos, el script se pare al instante. Sin esa línea seguiría ejecutando comandos aunque el primero hubiera fallado, dejando la base de datos a medias.
18. **Migración y por qué no editar `V000`/`V001`:** Una migración es un script numerado con cambios en la base de datos. No se deben modificar si ya se aplicaron porque romperías la coherencia con tus compañeros; si quieres cambiar algo, creas una migración nueva (p. ej. `V002`).
19. **Uso del servicio `FREEPDB1`:** Porque `FREE` es la base de datos contenedora (CDB) para administración, pero las tablas y usuarios de trabajo reales están dentro de la PDB, que aquí se llama `FREEPDB1`.
20. **SQLcl vs SQL*Plus:** SQLcl es más moderno, tiene autocompletado, colores y exporta a JSON/CSV. Hay que saber usar SQL*Plus porque viene siempre preinstalado en cualquier servidor Oracle por antiguo que sea, mientras que SQLcl requiere Java.

## 8.1.5. Entorno de trabajo
21. **Git Bash vs Ubuntu en WSL 2:** Porque Git Bash es una simulación sobre Windows y da fallos. En Ubuntu WSL 2 tenemos un Linux real sin problemas de permisos de archivos y con programas nativos como `tmux` o `shellcheck`.
22. **Uso de `~/` y `bash` frente a `zsh`:** Trabajar en `~/` (disco de Linux) es muchísimo más rápido que en `/mnt/c/` (disco de Windows). Se prefiere `bash` porque es el estándar que traen todos los servidores Linux por defecto.
