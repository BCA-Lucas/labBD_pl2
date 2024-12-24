-- Eliminar los usuarios existentes si existen
DROP ROLE IF EXISTS admin CASCADE;
DROP ROLE IF EXISTS gestor CASCADE;
DROP ROLE IF EXISTS cliente CASCADE;
DROP ROLE IF EXISTS invitado CASCADE;

-- Crear el usuario admin (con permisos completos, incluyendo la creación de tablas)
CREATE ROLE admin WITH LOGIN PASSWORD 'admin';
ALTER ROLE admin WITH SUPERUSER;  -- Le otorga permisos completos, incluyendo crear tablas

-- Crear el usuario gestor (sin permisos para crear tablas)
CREATE ROLE gestor WITH LOGIN PASSWORD 'gestor';
ALTER ROLE gestor WITH LOGIN;

-- Crear el usuario cliente (sin permisos para crear tablas)
CREATE ROLE cliente WITH LOGIN PASSWORD 'cliente';
ALTER ROLE cliente WITH LOGIN;

-- Crear el usuario invitado (sin permisos para crear tablas)
CREATE ROLE invitado WITH LOGIN PASSWORD 'invitado';
ALTER ROLE invitado WITH LOGIN;

-- Conceder permisos al admin (completos, incluyendo la creación de tablas)
GRANT ALL PRIVILEGES ON DATABASE discos TO admin;
GRANT ALL PRIVILEGES ON SCHEMA discos TO admin;
GRANT ALL PRIVILEGES ON SCHEMA discosfinal TO admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA discos TO admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA discosfinal TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA discos TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA discosfinal TO admin;

-- Conceder permisos al gestor (sin la capacidad de crear tablas)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA discos TO gestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA discosfinal TO gestor;

-- Conceder permisos al cliente (solo para consultar e insertar en algunas tablas)
GRANT SELECT, INSERT ON discosfinal.UtieneEfinal TO cliente;
GRANT SELECT, INSERT ON discosfinal.UdeseaDfinal TO cliente;

-- Conceder permisos al invitado (solo para consultar)
GRANT SELECT ON discosfinal.Grupofinal TO invitado;
GRANT SELECT ON discosfinal.Discofinal TO invitado;
GRANT SELECT ON discosfinal.Cancionesfinal TO invitado;
