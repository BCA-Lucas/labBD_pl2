-- 1. Asegurarse de que el usuario existe en la tabla Usuariofinal
INSERT INTO discosfinal.Usuariofinal (Nombre_Usuario, Nombre, Email, Password)
VALUES ('user1', 'User One', 'user1@example.com', 'password123')
ON CONFLICT (Nombre_Usuario) DO NOTHING;

-- 2. Asegurarse de que el grupo 'grupo1' esté insertado en Grupofinal
INSERT INTO discosfinal.Grupofinal (Nombre, URL)
VALUES ('grupo1', 'http://grupo1.com')
ON CONFLICT (Nombre) DO NOTHING;

-- 3. Insertar el disco en Discofinal
INSERT INTO discosfinal.Discofinal (Titulo, anno_publicacion, URL_Portada, nombre_grupo)
VALUES ('Disco Nuevo', '2024', NULL, 'grupo1')
ON CONFLICT (Titulo, anno_publicacion, nombre_grupo) DO NOTHING;

-- 5. Insertar el disco en la tabla UdeseaDfinal
INSERT INTO discosfinal.UdeseaDfinal (Nombre_Usuario, titulo_disco, anno_disco)
VALUES ('user1', 'Disco Nuevo', '2024')
ON CONFLICT (Nombre_Usuario, titulo_disco, anno_disco) DO NOTHING;

-- 6. Corregir la función PL/pgSQL fn_insertar_edicion_si_no_existe() para que haga referencia correctamente a la columna 'País'
CREATE OR REPLACE FUNCTION fn_insertar_edicion_si_no_existe()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM discosfinal.Edicionesfinal
        WHERE País = NEW.País
          AND anno_Edición = NEW.anno_edicion
          AND Formato = NEW.Formato
    ) THEN
        -- Insertar la edición si no existe
        INSERT INTO discosfinal.Edicionesfinal (anno_disco, titulo_disco, Formato, anno_Edición, País)
        VALUES (NEW.anno_disco, NEW.titulo_disco, NEW.Formato, NEW.anno_edicion, NEW.País);
        RAISE NOTICE 'Edición insertada: %', NEW.titulo_disco;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Crear trigger para auditoría
CREATE TABLE IF NOT EXISTS discosfinal.Auditoria (
    id SERIAL PRIMARY KEY,
    tabla_afectada TEXT,
    tipo_evento TEXT,
    usuario TEXT,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Trigger de auditoría que registra las acciones de INSERT, UPDATE, DELETE
CREATE OR REPLACE FUNCTION fn_auditoria() 
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO discosfinal.Auditoria (tabla_afectada, tipo_evento, usuario)
    VALUES (TG_TABLE_NAME, TG_OP, CURRENT_USER);
    RAISE NOTICE 'Evento de auditoría: % en tabla: %', TG_OP, TG_TABLE_NAME;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 9. Crear triggers para cada tabla que se quiera auditar (por ejemplo, en la tabla discosfinal.Usuariofinal)
CREATE TRIGGER auditoria_usuariofinal
AFTER INSERT OR UPDATE OR DELETE ON discosfinal.Usuariofinal
FOR EACH ROW EXECUTE FUNCTION fn_auditoria();

-- 10. Crear trigger que se dispara cuando se inserta un disco en Usuario_tiene_edicion
CREATE OR REPLACE FUNCTION fn_borrar_deseado_si_insertado() 
RETURNS TRIGGER AS $$
BEGIN
    -- Comprobar si el disco insertado está en la lista de deseados
    IF EXISTS (
        SELECT 1
        FROM discosfinal.UdeseaDfinal
        WHERE Nombre_Usuario = NEW.Nombre_Usuario
        AND titulo_disco = NEW.titulo_disco
        AND anno_disco = NEW.anno_disco
    ) THEN
        -- Borrar el disco de la lista de deseados
        DELETE FROM discosfinal.UdeseaDfinal
        WHERE Nombre_Usuario = NEW.Nombre_Usuario
        AND titulo_disco = NEW.titulo_disco
        AND anno_disco = NEW.anno_disco;
        RAISE NOTICE 'Disco % eliminado de la lista de deseos', NEW.titulo_disco;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 11. Crear trigger para ejecutar la función fn_borrar_deseado_si_insertado
CREATE TRIGGER borrar_deseado_si_insertado
AFTER INSERT ON discosfinal.UtieneEfinal
FOR EACH ROW EXECUTE FUNCTION fn_borrar_deseado_si_insertado();

-- 12. Función para borrar canciones huérfanas (sin disco asociado)
CREATE OR REPLACE FUNCTION fn_borrar_canciones_huerfanas() 
RETURNS TRIGGER AS $$
BEGIN
    -- Borrar canciones que no tienen un disco relacionado en Discofinal
    DELETE FROM discosfinal.Cancionesfinal
    WHERE NOT EXISTS (
        SELECT 1
        FROM discosfinal.Discofinal df
        WHERE df.Titulo = Cancionesfinal.titulo_disco
        AND df.anno_publicacion = Cancionesfinal.anno_publicacion_disco
    );
    RAISE NOTICE 'Canciones huérfanas eliminadas';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 13. Crear trigger para ejecutar la función fn_borrar_canciones_huerfanas cuando se eliminen discos
CREATE TRIGGER borrar_canciones_huerfanas
AFTER DELETE ON discosfinal.Discofinal
FOR EACH ROW EXECUTE FUNCTION fn_borrar_canciones_huerfanas();
