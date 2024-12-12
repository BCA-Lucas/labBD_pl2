CREATE TABLE auditoria (
    id_auditoria SERIAL PRIMARY KEY,
    tabla_afectada TEXT NOT NULL,
    tipo_evento TEXT NOT NULL,
    usuario TEXT NOT NULL,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Se crea la función que se ejecutará 

CREATE OR REPLACE FUNCTION fn_auditoria() RETURNS TRIGGER AS $fn_auditoria$Ç

  BEGIN
  -- Se determina que acción a activado el trigger e inserta un nuevo valor en la tabla dependiendo
  -- del dicha acción
  -- Junto con la acción se escribe fecha y hora en la que se ha producido la acción
   IF TG_OP='INSERT' THEN
     INSERT INTO auditoria VALUES ('alta',current_timestamp);  -- Cuando hay una inserción
   ELSIF TG_OP='UPDATE'	THEN
     INSERT INTO auditoria VALUES ('modificación',current_timestamp); -- Cuando hay una modificación
   ELSEIF TG_OP='DELETE' THEN
     INSERT INTO auditoria VALUES ('borrado',current_timestamp); -- Cuando hay un borrado
   END IF;	 
   RETURN NULL;
  END;
$fn_auditoria$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_borrar_deseado() RETURNS TRIGGER AS $fn_borrar_deseado$
BEGIN
  -- Se determina que acción ha activado el trigger e inserta un nuevo valor en la tabla dependiendo
  -- de dicha acción
  -- Junto con la acción se escribe fecha y hora en la que se ha producido la acción
  IF TG_OP='INSERT' THEN
    -- Comprobar si el usuario tiene el disco en la lista de deseados
    IF EXISTS (SELECT 1 FROM lista_deseados WHERE usuario_id = NEW.usuario_id AND disco_id = NEW.disco_id) THEN
      -- Borrar el disco de la lista de deseados
      DELETE FROM lista_deseados WHERE usuario_id = NEW.usuario_id AND disco_id = NEW.disco_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$fn_borrar_deseado$ LANGUAGE plpgsql;



-- Se crea el trigger que se dispara cuando hay una inserción, modificación o borrado en la tabla sala

CREATE TRIGGER tg_auditoria after INSERT or UPDATE or DELETE
ON ALL TABLES FOR EACH ROW
EXECUTE PROCEDURE fn_auditoria(); 

CREATE TRIGGER tg_borrar_deseado
AFTER INSERT ON Usuario_tiene_edicion
FOR EACH ROW
EXECUTE FUNCTION fn_borrar_deseado();

-- Función para eliminar canciones huérfanas
CREATE OR REPLACE FUNCTION fn_eliminar_canciones_huerfanas() RETURNS TRIGGER AS $fn_eliminar_canciones_huerfanas$
BEGIN
  -- Eliminar canciones que no están asociadas a ningún disco
  DELETE FROM canciones WHERE disco_id NOT IN (SELECT id FROM discos);
  RETURN NULL;
END;
$fn_eliminar_canciones_huerfanas$ LANGUAGE plpgsql;

-- Trigger que se dispara después de un borrado en la tabla discos
CREATE TRIGGER tg_eliminar_canciones_huerfanas
AFTER DELETE ON discos
FOR EACH ROW
EXECUTE FUNCTION fn_eliminar_canciones_huerfanas();
