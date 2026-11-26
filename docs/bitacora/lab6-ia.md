He leído la política de uso de IA de la asignatura.

# Declaración de uso de IA · Lab 6 · E044

<!--
CÓMO SE RELLENA (léelo y borra este comentario si quieres; el script de evaluación lo ignora)
- La PRIMERA línea es obligatoria y no se toca: «He leído la política de uso de IA de la asignatura.»
- Copia este archivo como docs/bitacora/lab6-ia.md (junto a lab6-respuestas.md) y pon tu código en el título.
  Cada laboratorio tiene el suyo: en el Lab 7 será docs/bitacora/lab7-ia.md.
- Si NO has usado IA: deja solo la línea «No he usado IA.» y borra la entrada de ejemplo.
- Si la has usado: borra la línea «No he usado IA.» y escribe UNA entrada por cada uso, con los 7 campos.
  Un campo vacío es una entrada incompleta (D3: −0,5 por entrada).
- Preguntar a la IA como tutor o corregir la ortografía de un texto propio está permitido: decláralo también.
  Si no copiaste código, escribe «no aplica» en «Código recibido» y en «Evidencia de ejecución» (no cuentan como vacíos).
  Los demás campos son siempre obligatorios.
- Una entrada con TODOS los campos vacíos (la de ejemplo sin tocar) no cuenta: se ignora.
- El código copiado de una IA puntúa si lo EJECUTAS en tu contenedor, lo EXPLICAS con tus palabras,
  dices para qué lo usaste y adjuntas aquí el código y el prompt LITERAL.
-->

## Entrada 1
- **Herramienta:**
Claude Opus 5.5 Medio 
- **Prompt (literal, copiado tal cual):**
```text
Me sale esto pero si que tengo la carpeta descargada: alejandrolinux@DESKTOP-QI5HJ62:~/oracle-database-lab$ unzip -o ~/Descargas/P2_Lab6_v1.3_Estudiante.zip -d ~/lab6-kit
unzip:  cannot find or open /home/alejandrolinux/Descargas/P2_Lab6_v1.3_Estudiante.zip, /home/alejandrolinux/Descargas/P2_Lab6_v1.3_Estudiante.zip.zip or /home/alejandrolinux/Descargas/P2_Lab6_v1.3_Estudiante.zip.ZIP.

```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```sql
ls /mnt/c/Users/*/Downloads/P2_Lab6*.zip
unzip -o /mnt/c/Users/*/Downloads/P2_Lab6_v1.3_Estudiante.zip -d ~/lab6-kit
ls ~/lab6-kit
cp -r ~/lab6-kit/repo-kit/. ~/oracle-database-lab/

```
- **Dónde lo usé (parte, script o pregunta):** 
A.1
- **Propósito (para qué lo necesitaba):**
No conseguia descargar el .zip 
- **Qué hace (con mis palabras; línea a línea si es SQL corto):**
Lo que pasaba es que WSL no comparte carpeta de Descargas con Windows asi que lo que hizo fue descargarlo desde WSL 
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** 
ejecutado en mi terminal antes de que existiera ninguna evidencia del Lab 6; el resultado es el kit copiado en scripts/lab6/ (commit de la Parte A)
## Entrada 2
- **Herramienta:** Claude Opus 5.5 Medio
- **Prompt (literal, copiado tal cual):**
```text
vale, empiezo con la Parte A del lab 6, dame un resumen de los comandos que tengo que ejecutar para completar esta parte
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
cd ~/oracle-database-lab
git switch main && git pull && git status
git tag -l "lab*-final"
bash scripts/lab5/16-verificacion-final.sh | tail -3
unzip -o ~/Descargas/P2_Lab6_v1.3_Estudiante.zip -d ~/lab6-kit
cp -r ~/lab6-kit/repo-kit/. ~/oracle-database-lab/
grep -q EVID_LAB6 scripts/deployment/env/00-config.sh || echo 'export EVID_LAB6="docs/bitacora/lab6/evidencia"   # evidencia del Lab 6: script/, spool/, config/' >> scripts/deployment/env/00-config.sh
source scripts/deployment/env/00-config.sh && mkdir -p "$EVID_LAB6"/{script,spool,config} && chmod +x scripts/lab6/*.sh scripts/ops/*.sh && ls scripts/lab6
grep -q APP_ACADEMIA_PWD config/.env || printf 'APP_ACADEMIA_PWD=""\nANA_GARCIA_PWD=""\n' >> config/.env
grep -q '^ESTUDIANTE=' config/.env || echo 'ESTUDIANTE=""' >> config/.env
nano config/.env
git check-ignore config/.env && echo "config/.env está fuera de Git"
bash scripts/ops/alumno.sh
source config/.env && cp docs/plantillas/IA.md docs/bitacora/lab6-ia.md && sed -i "s/E0NN/$ESTUDIANTE/" docs/bitacora/lab6-ia.md
nano docs/bitacora/lab6-ia.md
ls -d .claude CLAUDE.md AGENTS.md .cursor 2>/dev/null && echo "ATENCIÓN: archivos de agente" || echo "Sin archivos de agente"
bash scripts/ops/backup-estado.sh lab6-inicio | tee "$EVID_LAB6/script/$(ts)_00-backup-lab6-inicio.script.log"
git switch -c chore/10-administracion-operativa
git add scripts/ config/.env.example docs/plantillas/ docs/bitacora/lab6-ia.md login.sql .gitignore "$EVID_LAB6/script/"*_00-*
git commit -m "chore(ops): add Lab 6 kit, AI declaration and back up starting point" -m "Refs #10"
git log -1 --stat
```
- **Dónde lo usé (parte, script o pregunta):** Parte A (A.1 a A.6)
- **Propósito (para qué lo necesitaba):** tener en orden los comandos de la Parte A del enunciado para completarla sin saltarme pasos
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** 
Simplemente lista todos los comandos utiles del documento para tener un seguimiento de por donde voy en todo momento
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** docs/bitacora/lab6/evidencia/script/20261126T105727Z_00-backup-lab6-inicio.script.log
## Entrada 3
- **Herramienta:** Claude Opus 5.5 Medio
- **Prompt (literal, copiado tal cual):**
```text
Revisa que haya hecho bien la migración del zip y esté todo correcto para continuar
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
cp -r repo-kit/. .
rm -r repo-kit "P2_Lab 6 Oracle DBA Operations v1.2 - Estudiante.docx" "P2_Lab 6 Oracle DBA Operations v1.2 - Estudiante.pdf"
git status --short
```
- **Dónde lo usé (parte, script o pregunta):** Parte A.2
- **Propósito (para qué lo necesitaba):** había descomprimido el zip del kit dentro del repositorio por no poner -d en unzip, y tenía que copiar el kit a su sitio y quitar del repo la carpeta repo-kit y los dos enunciados para que no entraran en el commit
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** 
Copia la descarga del zip a otro directorio y lo borra del que no era
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** ejecutado en mi terminal antes de que existiera ninguna evidencia del Lab 6; el resultado es el repositorio sin repo-kit/ ni los enunciados y el kit en su sitio (commit de la Parte A)
