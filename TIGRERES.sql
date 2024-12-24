-- Crear la tabla de auditoría
CREATE TABLE IF NOT EXISTS discosfinal.Auditoria (
    id SERIAL PRIMARY KEY,
    tabla_afectada TEXT NOT NULL,
    tipo_evento TEXT NOT NULL,
    usuario TEXT NOT NULL,
    fecha_hora TIMESTAMP DEFAULT NOW()
);

-- Trigger de auditoría para registrar inserciones, modificaciones y eliminaciones
CREATE OR REPLACE FUNCTION auditoria_funcion()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO discosfinal.Auditoria (tabla_afectada, tipo_evento, usuario, fecha_hora)
    VALUES (TG_TABLE_NAME, TG_OP, current_user, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Asociar el trigger de auditoría con las tablas relevantes
CREATE TRIGGER auditoria_trigger
AFTER INSERT OR UPDATE OR DELETE ON discosfinal.Usuariofinal
FOR EACH ROW EXECUTE FUNCTION auditoria_funcion();

CREATE TRIGGER auditoria_trigger_disco
AFTER INSERT OR UPDATE OR DELETE ON discosfinal.Discofinal
FOR EACH ROW EXECUTE FUNCTION auditoria_funcion();

CREATE TRIGGER auditoria_trigger_ediciones
AFTER INSERT OR UPDATE OR DELETE ON discosfinal.Edicionesfinal
FOR EACH ROW EXECUTE FUNCTION auditoria_funcion();

-- Trigger para eliminar un disco de la lista de deseos cuando el usuario lo adquiera
CREATE OR REPLACE FUNCTION eliminar_deseo()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM discosfinal.UdeseaDfinal
    WHERE Nombre_Usuario = NEW.Nombre_Usuario
      AND titulo_disco = NEW.titulo_disco
      AND anno_disco = NEW.anno_disco;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER eliminar_deseo_trigger
AFTER INSERT ON discosfinal.UtieneEfinal
FOR EACH ROW EXECUTE FUNCTION eliminar_deseo();

-- Trigger para eliminar canciones huérfanas
CREATE OR REPLACE FUNCTION eliminar_canciones_huerfanas()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM discosfinal.Cancionesfinal
    WHERE NOT EXISTS (
        SELECT 1
        FROM discosfinal.Discofinal
        WHERE titulo = Cancionesfinal.titulo_disco
          AND anno_publicacion = Cancionesfinal.anno_publicacion_disco
    );
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER eliminar_canciones_huerfanas_trigger
AFTER DELETE OR UPDATE ON discosfinal.Discofinal
FOR EACH ROW EXECUTE FUNCTION eliminar_canciones_huerfanas();
