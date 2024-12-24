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
    anno_publicacion TEXT NOT NULL,
    URL_Portada TEXT,
    nombre_grupo TEXT,
    PRIMARY KEY (Titulo, anno_publicacion, nombre_grupo),
    UNIQUE (Titulo, anno_publicacion),  -- Agregar restricción UNIQUE
    FOREIGN KEY (nombre_grupo) REFERENCES discosfinal.Grupofinal (Nombre) ON DELETE SET NULL
);

-- Insertar los datos en Discofinal
INSERT INTO discosfinal.Discofinal (Titulo, anno_publicacion, URL_Portada, nombre_grupo)
SELECT DISTINCT nombre_disco, anio, formato, LOWER(nombre_grupo)
FROM discos.discos
WHERE EXISTS (
    SELECT 1
    FROM discosfinal.Grupofinal gf
    WHERE gf.Nombre = LOWER(discos.discos.nombre_grupo)
)
ON CONFLICT (Titulo, anno_publicacion, nombre_grupo) DO NOTHING;


-- Crear la tabla generosdiscofinal y luego insertar los datos
CREATE TABLE IF NOT EXISTS discosfinal.generosdiscofinal (
    genero TEXT,
    titulo_disco TEXT,
    anno_publicacion TEXT,
    PRIMARY KEY (genero, titulo_disco, anno_publicacion),
    FOREIGN KEY (titulo_disco, anno_publicacion) 
        REFERENCES discosfinal.Discofinal (Titulo, anno_publicacion) ON DELETE CASCADE
);

-- Insertar los datos en generosdiscofinal
INSERT INTO discosfinal.generosdiscofinal (genero, titulo_disco, anno_publicacion)
SELECT UNNEST(STRING_TO_ARRAY(d.generos, ',')) AS genero, d.nombre_disco, d.anio
FROM discos.discos d
JOIN discosfinal.Discofinal df 
    ON df.titulo = d.nombre_disco 
    AND df.anno_publicacion = d.anio
ON CONFLICT (genero, titulo_disco, anno_publicacion) DO NOTHING;

-- Crear la tabla Cancionesfinal con clave primaria que incluye Duración
CREATE TABLE IF NOT EXISTS discosfinal.Cancionesfinal (
    titulo_disco TEXT,
    anno_publicacion_disco TEXT,
    Título TEXT,
    Duración TEXT,
    PRIMARY KEY (titulo_disco, anno_publicacion_disco, Título, Duración), -- Incluye duración en la clave primaria
    FOREIGN KEY (titulo_disco, anno_publicacion_disco) 
        REFERENCES discosfinal.Discofinal (Titulo, anno_publicacion) ON DELETE CASCADE
);

-- Insertar solo canciones que no existan previamente en Cancionesfinal
INSERT INTO discosfinal.Cancionesfinal (titulo_disco, anno_publicacion_disco, Título, Duración)
SELECT DISTINCT ON (d.nombre_disco, d.anio, c.titulo) 
    d.nombre_disco, d.anio, c.titulo, 
    COALESCE(c.duracion, '00:00') AS duracion -- Reemplaza los valores nulos por '00:00'
FROM discos.canciones c
JOIN discos.discos d 
    ON d.id = c.id_cancion
WHERE EXISTS (
    SELECT 1
    FROM discosfinal.Discofinal df
    WHERE df.Titulo = d.nombre_disco 
      AND df.anno_publicacion = d.anio
)
AND NOT EXISTS (
    SELECT 1
    FROM discosfinal.Cancionesfinal cf
    WHERE cf.titulo_disco = d.nombre_disco
      AND cf.anno_publicacion_disco = d.anio
      AND cf.Título = c.titulo
);

-- Crear la tabla Edicionesfinal, sin necesidad de una restricción de unicidad adicional
CREATE TABLE IF NOT EXISTS discosfinal.Edicionesfinal (
    anno_disco TEXT,
    titulo_disco TEXT,
    Formato TEXT,
    anno_Edición TEXT,
    País TEXT,
    PRIMARY KEY (anno_disco, titulo_disco, Formato, anno_Edición, País),
    FOREIGN KEY (titulo_disco, anno_disco) 
        REFERENCES discosfinal.Discofinal(Titulo, anno_publicacion) ON DELETE CASCADE
);

-- Insertar los datos en Edicionesfinal, evitando duplicados por la clave primaria completa
-- Insertar los datos en Edicionesfinal, evitando duplicados por la clave primaria completa
INSERT INTO discosfinal.Edicionesfinal (anno_disco, titulo_disco, Formato, anno_Edición, País)
SELECT DISTINCT ON (d.anio, d.nombre_disco, e.formato, e.anioo, e.pais)
    d.anio AS anno_disco, d.nombre_disco AS titulo_disco, e.formato, e.anioo AS anno_Edición, e.pais AS País
FROM discos.ediciones e
JOIN discos.discos d ON d.id = e.id_edicion
WHERE EXISTS (
    SELECT 1
    FROM discosfinal.Discofinal df
    WHERE df.Titulo = d.nombre_disco AND df.anno_publicacion = d.anio
);
CREATE TABLE IF NOT EXISTS discosfinal.UdeseaDfinal (
    Nombre_Usuario TEXT,
    titulo_disco TEXT,
    anno_disco TEXT,
    PRIMARY KEY (Nombre_Usuario, titulo_disco, anno_disco),
    FOREIGN KEY (Nombre_Usuario) 
        REFERENCES discosfinal.Usuariofinal (Nombre_Usuario) ON DELETE CASCADE,
    FOREIGN KEY (titulo_disco, anno_disco) 
        REFERENCES discosfinal.Discofinal (Titulo, anno_publicacion) ON DELETE CASCADE
);

-- Insertar los datos solo si el Nombre_Usuario existe en la tabla Usuariofinal
INSERT INTO discosfinal.UdeseaDfinal (Nombre_Usuario, titulo_disco, anno_disco)
SELECT u.nombre_usuario, d.nombre_disco, d.anio
FROM discos.Usuario_desea_disco u
JOIN discos.discos d 
    ON d.nombre_disco = u.nombre_disco 
    AND d.anio = u.anio_lanzamiento
WHERE EXISTS (
    SELECT 1 
    FROM discosfinal.Usuariofinal uf 
    WHERE uf.Nombre_Usuario = u.nombre_usuario
)
ON CONFLICT (Nombre_Usuario, titulo_disco, anno_disco) 
DO NOTHING;

-- Delete duplicate rows in Edicionesfinal based on país, anno_edicion, and Formato
DELETE FROM discosfinal.Edicionesfinal
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM discosfinal.Edicionesfinal
    GROUP BY País, anno_Edición, Formato
);

-- Add a unique constraint on pais, anno_edicion, and Formato in Edicionesfinal
ALTER TABLE discosfinal.Edicionesfinal ADD CONSTRAINT unique_pais_anio_edicion_formato_n UNIQUE (País, anno_Edición, Formato);

-- Crear la tabla UtieneEfinal y luego insertar los datos
CREATE TABLE IF NOT EXISTS discosfinal.UtieneEfinal (
    Nombre_Usuario TEXT,
    pais TEXT,
    anno_edicion TEXT,
    Formato TEXT,
    estado TEXT,
    PRIMARY KEY (Nombre_Usuario, pais, anno_edicion, Formato),
    FOREIGN KEY (Nombre_Usuario) 
        REFERENCES discosfinal.Usuariofinal (Nombre_Usuario) ON DELETE CASCADE,
    FOREIGN KEY (pais, anno_edicion, Formato) 
        REFERENCES discosfinal.Edicionesfinal (País, anno_Edición, Formato) ON DELETE CASCADE
);

-- Insertar los datos en UtieneEfinal
INSERT INTO discosfinal.UtieneEfinal (Nombre_Usuario, pais, anno_edicion, Formato, estado)
SELECT ute.nombre_usuario, ef.País, ef.anno_Edición, ef.Formato, ute.estado
FROM discos.Usuario_tiene_edicion ute
JOIN discosfinal.Edicionesfinal ef ON ef.titulo_disco = ute.nombre_disco
AND ef.anno_disco = ute.anio_lanzamiento
AND ef.anno_Edición = ute.anio_edicion
AND ef.País = ute.pais_edicion
WHERE EXISTS (
    SELECT 1
    FROM discosfinal.Usuariofinal uf
    WHERE uf.Nombre_Usuario = ute.nombre_usuario
)
ON CONFLICT (Nombre_Usuario, pais, anno_edicion, Formato) DO NOTHING;

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

Commit;
