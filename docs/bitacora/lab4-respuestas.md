#Pregunta 1: A y D, justificacion: un cierre limpio generea una copia consistente que puede restraurase y arrancarse directamente sin 
#necesidad de aplicar un "redo"

#Pregunta 2: B, justificacion: al no estar disponible la opción de mover en línea en esta edición, se debe poner el tablespace offline, 
#copiar el archivo físicamente, renombrar la ruta en el control file y volver a ponerlo online

#Pregunta 3: A y B, justificacion: la fecha de creación pertenece a la base de datos, 
#mientras que la fecha de arranque corresponde específicamente a la instancia temporal en ejecución.

#Pregunta 4: A yC, justificacion: en este estado los parámetros ya están cargados en memoria permitiendo consultar v$parameter, 
#siendo además la etapa indicada para crear la base de datos o restaurar el control file

#Pregunta 5:B, justificacion: la etapa MOUNT es la requerida para realizar tareas administrativas estructurales de la base de datos
