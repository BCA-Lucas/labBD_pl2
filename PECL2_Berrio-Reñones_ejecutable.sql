\pset pager off
SET client_encoding = 'UTF8';

-- Introducir ruta de trabajo
\cd 'C:/labBd_GII_github/data'

BEGIN;

\echo 'Creando el esquema para la BBDD de discos'
CREATE SCHEMA IF NOT EXISTS discos;
CREATE SCHEMA IF NOT EXISTS discosfinal;

\echo 'Creando tablas temporales en el esquema discos'
CREATE TABLE IF NOT EXISTS discos.Usuario (
    nombrecompleto TEXT,
    nombreusuario TEXT,
    email TEXT,
    contrasenna TEXT
);

CREATE TABLE IF NOT EXISTS discos.canciones (
    id_cancion TEXT,
    titulo TEXT,
    duracion TEXT
);

CREATE TABLE IF NOT EXISTS discos.ediciones (
    id_edicion TEXT,
    anioo TEXT,
    pais TEXT,
    formato TEXT
);

CREATE TABLE IF NOT EXISTS discos.discos (
    id TEXT,
    nombre_disco TEXT,
    anio TEXT,
    id_grupo TEXT,
    nombre_grupo TEXT,
    url_grupo TEXT,
    generos TEXT,
    formato TEXT
);

CREATE TABLE IF NOT EXISTS discos.Usuario_desea_disco (
    nombre_usuario TEXT,
    nombre_disco TEXT,
    anio_lanzamiento TEXT
);

CREATE TABLE IF NOT EXISTS discos.Usuario_tiene_edicion (
    nombre_usuario TEXT,
    nombre_disco TEXT,
    anio_lanzamiento TEXT,
    anio_edicion TEXT,
    pais_edicion TEXT,
    formato TEXT,
    estado TEXT
);

-- Introducir datos para la tabla 
\COPY discos.Usuario FROM './usuarios.csv' WITH (FORMAT csv, HEADER, DELIMITER E';', NULL 'NULL', ENCODING 'UTF-8');
\COPY discos.canciones FROM './canciones.csv' WITH (FORMAT csv, HEADER, DELIMITER E';', NULL 'NULL', ENCODING 'UTF-8');
\COPY discos.ediciones FROM './ediciones.csv' WITH (FORMAT csv, HEADER, DELIMITER E';', NULL 'NULL', ENCODING 'UTF-8');
\COPY discos.discos FROM './discos.csv' WITH (FORMAT csv, HEADER, DELIMITER E';', NULL 'NULL', ENCODING 'UTF-8');
\COPY discos.Usuario_desea_disco FROM './usuario_desea_disco.csv' WITH (FORMAT csv, HEADER, DELIMITER E';', NULL 'NULL', ENCODING 'UTF-8');
\COPY discos.Usuario_tiene_edicion FROM './usuario_tiene_edicion.csv' WITH (FORMAT csv, HEADER, DELIMITER E';', NULL 'NULL', ENCODING 'UTF-8');


\echo 'Creando tablas en el esquema discosfinal'

-- Crear la tabla Usuariofinal y luego insertar los datos
CREATE TABLE IF NOT EXISTS discosfinal.Usuariofinal (
    Nombre_Usuario TEXT PRIMARY KEY,
    Nombre TEXT,
    Email TEXT UNIQUE,
    Password TEXT
);

-- Insertar los datos en Usuariofinal
INSERT INTO discosfinal.Usuariofinal (Nombre_Usuario, Nombre, Email, Password)
SELECT nombreusuario, nombrecompleto, email, contrasenna
FROM discos.Usuario
ON CONFLICT (Email) DO NOTHING;

-- Crear la tabla Grupofinal y luego insertar los datos
CREATE TABLE IF NOT EXISTS discosfinal.Grupofinal (
    Nombre TEXT PRIMARY KEY,
    URL TEXT
);

-- Insertar los datos en Grupofinal
INSERT INTO discosfinal.Grupofinal (Nombre, URL)
SELECT DISTINCT LOWER(nombre_grupo), url_grupo
FROM discos.discos
ON CONFLICT (Nombre) DO NOTHING;

-- Crear la tabla Discofinal y luego insertar los datos
CREATE TABLE IF NOT EXISTS discosfinal.Discofinal (
    Titulo TEXT NOT NULL,
    Año_publicacion TEXT NOT NULL,
    URL_Portada TEXT,
    nombre_grupo TEXT,
    PRIMARY KEY (Titulo, Año_publicacion, nombre_grupo),
    UNIQUE (Titulo, Año_publicacion),  -- Agregar restricción UNIQUE
    FOREIGN KEY (nombre_grupo) REFERENCES discosfinal.Grupofinal (Nombre) ON DELETE SET NULL
);

-- Insertar los datos en Discofinal
INSERT INTO discosfinal.Discofinal (Titulo, Año_publicacion, URL_Portada, nombre_grupo)
SELECT DISTINCT nombre_disco, anio, formato, LOWER(nombre_grupo)
FROM discos.discos
WHERE EXISTS (
    SELECT 1
    FROM discosfinal.Grupofinal gf
    WHERE gf.Nombre = LOWER(discos.discos.nombre_grupo)
)
ON CONFLICT (Titulo, Año_publicacion, nombre_grupo) DO NOTHING;


-- Crear la tabla generosdiscofinal y luego insertar los datos
CREATE TABLE IF NOT EXISTS discosfinal.generosdiscofinal (
    genero TEXT,
    titulo_disco TEXT,
    año_publicacion TEXT,
    PRIMARY KEY (genero, titulo_disco, año_publicacion),
    FOREIGN KEY (titulo_disco, año_publicacion) 
        REFERENCES discosfinal.Discofinal (Titulo, Año_publicacion) ON DELETE CASCADE
);

-- Insertar los datos en generosdiscofinal
INSERT INTO discosfinal.generosdiscofinal (genero, titulo_disco, año_publicacion)
SELECT UNNEST(STRING_TO_ARRAY(d.generos, ',')) AS genero, d.nombre_disco, d.anio
FROM discos.discos d
JOIN discosfinal.Discofinal df 
    ON df.titulo = d.nombre_disco 
    AND df.año_publicacion = d.anio
ON CONFLICT (genero, titulo_disco, año_publicacion) DO NOTHING;

-- Crear la tabla Cancionesfinal con clave primaria que incluye Duración
CREATE TABLE IF NOT EXISTS discosfinal.Cancionesfinal (
    titulo_disco TEXT,
    Año_publicacion_disco TEXT,
    Título TEXT,
    Duración TEXT,
    PRIMARY KEY (titulo_disco, Año_publicacion_disco, Título, Duración), -- Incluye duración en la clave primaria
    FOREIGN KEY (titulo_disco, Año_publicacion_disco) 
        REFERENCES discosfinal.Discofinal (Titulo, Año_publicacion) ON DELETE CASCADE
);

-- Insertar solo canciones que no existan previamente en Cancionesfinal
INSERT INTO discosfinal.Cancionesfinal (titulo_disco, Año_publicacion_disco, Título, Duración)
SELECT DISTINCT ON (d.nombre_disco, d.anio, c.titulo) 
    d.nombre_disco, d.anio, c.titulo, c.duracion
FROM discos.canciones c
JOIN discos.discos d 
    ON d.id = c.id_cancion -- O usa la relación adecuada entre discos y canciones
WHERE EXISTS (
    SELECT 1
    FROM discosfinal.Discofinal df
    WHERE df.Titulo = d.nombre_disco 
      AND df.Año_publicacion = d.anio
)
AND NOT EXISTS (
    SELECT 1
    FROM discosfinal.Cancionesfinal cf
    WHERE cf.titulo_disco = d.nombre_disco
      AND cf.Año_publicacion_disco = d.anio
      AND cf.Título = c.titulo
);

-- Crear la tabla Edicionesfinal, sin necesidad de una restricción de unicidad adicional
CREATE TABLE IF NOT EXISTS discosfinal.Edicionesfinal (
    año_disco TEXT,
    titulo_disco TEXT,
    Formato TEXT,
    Año_Edición TEXT,
    País TEXT,
    PRIMARY KEY (año_disco, titulo_disco, Formato, Año_Edición, País),
    FOREIGN KEY (titulo_disco, año_disco) 
        REFERENCES discosfinal.Discofinal(Titulo, Año_publicacion) ON DELETE CASCADE
);

-- Insertar los datos en Edicionesfinal, evitando duplicados por la clave primaria completa
INSERT INTO discosfinal.Edicionesfinal (año_disco, titulo_disco, Formato, Año_Edición, País)
SELECT d.anio, d.nombre_disco, e.formato, e.anioo, e.pais
FROM discos.ediciones e
JOIN discos.discos d ON d.id = e.id_edicion
WHERE EXISTS (
    SELECT 1
    FROM discosfinal.Discofinal df
    WHERE df.Titulo = d.nombre_disco AND df.Año_publicacion = d.anio
)
-- Evitar duplicados por la clave primaria completa
ON CONFLICT (Formato, Año_Edición, País) DO NOTHING;

-- Crear la tabla UdeseaDfinal y luego insertar los datos
CREATE TABLE IF NOT EXISTS discosfinal.UdeseaDfinal (
    Nombre_Usuario TEXT,
    titulo_disco TEXT,
    año_disco TEXT,
    PRIMARY KEY (Nombre_Usuario, titulo_disco, año_disco),
    FOREIGN KEY (Nombre_Usuario) 
        REFERENCES discosfinal.Usuariofinal (Nombre_Usuario) ON DELETE CASCADE,
    FOREIGN KEY (titulo_disco, año_disco) 
        REFERENCES discosfinal.Discofinal (Titulo, Año_publicacion) ON DELETE CASCADE
);

-- Insertando solo si el nombre_usuario existe en la tabla Usuariofinal
INSERT INTO discosfinal.UdeseaDfinal (Nombre_Usuario, titulo_disco, año_disco)
SELECT u.nombre_usuario, d.nombre_disco, d.anio
FROM discos.Usuario_desea_disco u
JOIN discos.discos d ON d.nombre_disco = u.nombre_disco AND d.anio = u.anio_lanzamiento
WHERE EXISTS (
    SELECT 1 FROM discosfinal.Usuariofinal uf WHERE uf.Nombre_Usuario = u.nombre_usuario
)
ON CONFLICT (Nombre_Usuario, titulo_disco, año_disco) DO NOTHING;

-- Delete duplicate rows in Edicionesfinal based on país, año_edicion, and Formato
DELETE FROM discosfinal.Edicionesfinal
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM discosfinal.Edicionesfinal
    GROUP BY País, Año_Edición, Formato
);

-- Add a unique constraint on pais, año_edicion, and Formato in Edicionesfinal
ALTER TABLE discosfinal.Edicionesfinal DROP CONSTRAINT IF EXISTS unique_pais_anio_edicion_formato_n;
ALTER TABLE discosfinal.Edicionesfinal ADD CONSTRAINT unique_pais_anio_edicion_formato_n UNIQUE (País, Año_Edición, Formato);

-- Crear la tabla UtieneEfinal y luego insertar los datos
CREATE TABLE IF NOT EXISTS discosfinal.UtieneEfinal (
    Nombre_Usuario TEXT,
    pais TEXT,
    año_edicion TEXT,
    Formato TEXT,
    estado TEXT,
    PRIMARY KEY (Nombre_Usuario, pais, año_edicion, Formato),
    FOREIGN KEY (Nombre_Usuario) 
        REFERENCES discosfinal.Usuariofinal (Nombre_Usuario) ON DELETE CASCADE,
    FOREIGN KEY (pais, año_edicion, Formato) 
        REFERENCES discosfinal.Edicionesfinal (País, Año_Edición, Formato) ON DELETE CASCADE
);

-- Insertar los datos en UtieneEfinal
INSERT INTO discosfinal.UtieneEfinal (Nombre_Usuario, pais, año_edicion, Formato, estado)
SELECT ute.nombre_usuario, ef.País, ef.Año_Edición, ef.Formato, ute.estado
FROM discos.Usuario_tiene_edicion ute
JOIN discosfinal.Edicionesfinal ef ON ef.titulo_disco = ute.nombre_disco
AND ef.año_disco = ute.anio_lanzamiento
AND ef.Año_Edición = ute.anio_edicion
AND ef.País = ute.pais_edicion
WHERE EXISTS (
    SELECT 1
    FROM discosfinal.Usuariofinal uf
    WHERE uf.Nombre_Usuario = ute.nombre_usuario
)
ON CONFLICT (Nombre_Usuario, pais, año_edicion, Formato) DO NOTHING;

/*

select * from discos.Usuario;
SELECT * FROM discos.canciones;
SELECT * FROM discos.ediciones;
SELECT * FROM discos.discos;
SELECT * FROM discos.Usuario_tiene_edicion;
SELECT * FROM discos.Usuario_tiene_disco;
*/

/*

select * from discosfinal.Usuariofinal;
SELECT * FROM discosfinal.cancionesfinal;
SELECT * FROM discosfinal.edicionesfinal;
SELECT * FROM discosfinal.Discofinal;
SELECT * FROM discosfinal.UdeseaDfinal;
SELECT * FROM discosfinal.UtieneEfinal_edicion; 
SELECT * FROM discosfinal.generosdiscofinal;
*/

\echo 'Confirmando cambios'

ROLLBACK;

\echo 'Consultas solicitadas en el ejercicio'

\echo 'Consulta 1: Mostrar los discos que tengan más de 5 canciones'
SELECT cf.titulo_disco, cf.Año_publicacion_disco, COUNT(cf.Título) AS num_canciones
FROM discosfinal.Cancionesfinal cf
GROUP BY cf.titulo_disco, cf.Año_publicacion_disco
HAVING COUNT(cf.Título) > 5;

\echo 'Consulta 2: Mostrar las ediciones en formato Vinyl que tiene el usuario juangomez'
SELECT d.Titulo AS titulo_disco, e.País AS pais_edicion, e.Año_Edición AS año_edicion
FROM discosfinal.UtieneEfinal AS u
JOIN discosfinal.Edicionesfinal AS e ON u.pais = e.País 
    AND u.año_edicion = e.Año_Edición 
    AND u.Formato = e.Formato
JOIN discosfinal.Discofinal AS d ON e.titulo_disco = d.Titulo 
    AND e.año_disco = d.Año_publicacion
WHERE u.Nombre_Usuario = 'juangomez' AND u.Formato = 'Vinyl';

\echo 'Consulta 3: Mostrar el disco con la mayor duración total de canciones'
SELECT d.Titulo AS titulo_disco, d.Año_publicacion,
       SUM(
           (CAST(SPLIT_PART(c.Duración, ':', 1) AS INTEGER) * 60) + 
           CAST(SPLIT_PART(c.Duración, ':', 2) AS INTEGER)
       ) AS duracion_total_segundos
FROM discosfinal.Cancionesfinal AS c
JOIN discosfinal.Discofinal AS d ON c.titulo_disco = d.Titulo
    AND c.Año_publicacion_disco = d.Año_publicacion
WHERE c.Duración IS NOT NULL 
  AND c.Duración <> '' 
  AND POSITION(':' IN c.Duración) > 0
GROUP BY d.Titulo, d.Año_publicacion
ORDER BY duracion_total_segundos DESC
LIMIT 1;

\echo 'Consulta 4: Mostrar los nombres de los grupos cuyos discos desea el usuario juangomez'
SELECT DISTINCT gf.Nombre AS nombre_grupo
FROM discosfinal.Discofinal df
JOIN discosfinal.Grupofinal gf ON df.nombre_grupo = gf.Nombre
JOIN discosfinal.UdeseaDfinal ud ON df.Titulo = ud.titulo_disco 
    AND df.Año_publicacion = ud.año_disco
JOIN discosfinal.Usuariofinal uf ON uf.Nombre_Usuario = ud.Nombre_Usuario
WHERE uf.Nombre_Usuario = 'juangomez';

\echo 'Consulta 5: Mostrar los discos publicados entre 1970 y 1972 junto con sus ediciones ordenados por el año de publicación'
SELECT df.Titulo, df.Año_publicacion, ef.País, ef.Año_Edición, ef.Formato
FROM discosfinal.Discofinal df
JOIN discosfinal.Edicionesfinal ef ON df.Titulo = ef.titulo_disco 
    AND df.Año_publicacion = ef.año_disco
WHERE CAST(df.Año_publicacion AS INTEGER) BETWEEN 1970 AND 1972
ORDER BY CAST(df.Año_publicacion AS INTEGER);

\echo 'Consulta 6: Listar el nombre de todos los grupos que han publicado discos del género Electronic'
SELECT DISTINCT gf.Nombre AS nombre_grupo
FROM discosfinal.Grupofinal gf
JOIN discosfinal.Discofinal df ON gf.Nombre = df.nombre_grupo
JOIN discosfinal.generosdiscofinal g ON df.Titulo = g.titulo_disco AND df.Año_publicacion = g.año_publicacion
WHERE g.genero LIKE '%Electronic%';

\echo 'Consulta 7: Mostrar los discos publicados antes del año 2000 con duración total de canciones'
SELECT df.Titulo, df.Año_publicacion,
       SUM(
           (CAST(SPLIT_PART(c.Duración, ':', 1) AS INTEGER) * 60) + 
           CAST(SPLIT_PART(c.Duración, ':', 2) AS INTEGER)
       ) AS duracion_total_segundos
FROM discosfinal.Cancionesfinal AS c
JOIN discosfinal.Discofinal AS df ON c.titulo_disco = df.Titulo
    AND c.Año_publicacion_disco = df.Año_publicacion
WHERE CAST(df.Año_publicacion AS INTEGER) < 2000
  AND c.Duración IS NOT NULL 
  AND c.Duración <> '' 
  AND POSITION(':' IN c.Duración) > 0
GROUP BY df.Titulo, df.Año_publicacion
ORDER BY duracion_total_segundos DESC;

\echo 'Consulta 8: Mostrar las ediciones deseadas por Sergio Fernández que tiene Juan Gómez'
SELECT DISTINCT ed.titulo_disco, ed.año_disco, ed.Año_Edición, ed.País, ed.Formato
FROM discosfinal.Usuariofinal AS u1
JOIN discosfinal.UdeseaDfinal AS d ON u1.Nombre_Usuario = d.Nombre_Usuario
JOIN discosfinal.Usuariofinal AS u2 ON u2.Nombre = 'Juan García Gómez'
JOIN discosfinal.UtieneEfinal AS e ON e.Nombre_Usuario = u2.Nombre_Usuario
JOIN discosfinal.Edicionesfinal AS ed 
    ON ed.País = e.pais
    AND ed.Año_Edición = e.año_edicion
    AND ed.Formato = e.Formato
    AND ed.titulo_disco = d.titulo_disco
    AND ed.año_disco = d.año_disco
WHERE u1.Nombre = 'Sergio Fernández Moreno';

\echo 'Consulta 9: Mostrar las ediciones que tiene el usuario luisgarcia en estado NM o M'
SELECT e.titulo_disco AS titulo_disco,
       e.Año_Edición AS año_edicion,
       e.País AS pais_edicion,
       e.Formato AS formato_edicion
FROM discosfinal.UtieneEfinal ut
JOIN discosfinal.Edicionesfinal e 
    ON ut.pais = e.País 
    AND ut.año_edicion = e.Año_Edición 
    AND ut.Formato = e.Formato
WHERE ut.Nombre_Usuario = 'luisgarcia'
  AND (ut.estado = 'NM' OR ut.estado = 'M');

\echo 'Consulta 10: Contar el número de ediciones que tiene cada usuario y mostrar el año más antiguo, más nuevo y el año medio de publicación'
SELECT ut.Nombre_Usuario,
       COUNT(*) AS numero_ediciones,
       MIN(df.Año_publicacion) AS año_mas_antiguo,
       MAX(df.Año_publicacion) AS año_mas_nuevo,
       ROUND(AVG(CAST(df.Año_publicacion AS FLOAT))) AS año_medio
FROM discosfinal.UtieneEfinal ut
JOIN discosfinal.Edicionesfinal e 
    ON ut.pais = e.País 
    AND ut.año_edicion = e.Año_Edición 
    AND ut.Formato = e.Formato
JOIN discosfinal.Discofinal df 
    ON e.titulo_disco = df.Titulo 
    AND e.año_disco = df.Año_publicacion
GROUP BY ut.Nombre_Usuario;

\echo 'Consulta 11: Listar el nombre de los grupos que tienen más de 5 ediciones de sus discos en la base de datos'
SELECT gf.Nombre AS nombre_grupo,
       COUNT(ef.titulo_disco) AS numero_ediciones
FROM discosfinal.Grupofinal gf
JOIN discosfinal.Discofinal df ON gf.Nombre = df.nombre_grupo
JOIN discosfinal.Edicionesfinal ef ON df.Titulo = ef.titulo_disco 
    AND df.Año_publicacion = ef.año_disco
GROUP BY gf.Nombre
HAVING COUNT(ef.titulo_disco) > 5;

\echo 'Consulta 12: Lista el usuario que más discos, contando todas sus ediciones tiene en la base de datos'
SELECT ut.Nombre_Usuario,
       COUNT(*) AS numero_ediciones
FROM discosfinal.UtieneEfinal ut
JOIN discosfinal.Edicionesfinal e 
    ON ut.pais = e.País 
    AND ut.año_edicion = e.Año_Edición 
    AND ut.Formato = e.Formato
GROUP BY ut.Nombre_Usuario
ORDER BY numero_ediciones DESC
LIMIT 1;