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
$fn_auditoria$ LANGUAGE plpgsql;ç

CREATE OR REPLACE FUNCTION fn_borrar_deseado() RETURNS TRIGGER AS $fn_borrar_deseado$Ç

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
$fn_borrar_deseado$ LANGUAGE plpgsql;



-- Se crea el trigger que se dispara cuando hay una inserción, modificación o borrado en la tabla sala

CREATE TRIGGER tg_auditoria after INSERT or UPDATE or DELETE
  ON ALL TABLES FOR EACH ROW
  EXECUTE PROCEDURE fn_auditoria(); 






-- Se crea el trigger que se dispara cuando hay una inserción, modificación o borrado en la tabla sala

CREATE TRIGGER tg_auditoria after INSERT or UPDATE or DELETE
  ON ALL TABLES FOR EACH ROW
  EXECUTE PROCEDURE fn_auditoria(); 

