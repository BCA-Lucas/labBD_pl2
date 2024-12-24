\pset pager off
SET client_encoding = 'UTF8';
-- ===========================================
-- CONSULTAS DE PRUEBA PARA VERIFICAR PERMISOS
-- ===========================================

-- Inicia sesión como admin y verifica que tiene acceso total a todas las tablas
-- Pedir conexión al rol 'admin'
\echo 'Conéctate como el usuario admin'
SET ROLE admin;

-- El admin puede hacer SELECT
SELECT * FROM discos.discos LIMIT 1;  -- Debe tener acceso total
-- El admin puede crear una tabla
DO $$ BEGIN
    CREATE TABLE discos.test_table_admin (id SERIAL PRIMARY KEY);
    RAISE NOTICE 'Correcto: El admin puede crear tablas';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error: El admin no puede crear tablas';
END $$;

-- Inicia sesión como gestor y verifica que no puede crear tablas
-- Pedir conexión al rol 'gestor'
\echo 'Conéctate como el usuario gestor'
SET ROLE gestor;
-- El gestor puede hacer SELECT
SELECT * FROM discos.discos LIMIT 1;  -- Debe tener acceso a datos

-- Intentar crear una tabla (esto debe fallar)
DO $$ BEGIN
    CREATE TABLE discos.test_table_gestor (id SERIAL PRIMARY KEY);
    RAISE NOTICE 'Error: El gestor no puede crear tablas';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Correcto: El gestor no puede crear tablas';
END $$;

-- Inicia sesión como cliente y verifica que solo puede insertar y consultar
-- Pedir conexión al rol 'cliente'
\echo 'Conéctate como el usuario cliente'
SET ROLE cliente;
-- El cliente puede hacer SELECT
SELECT * FROM discosfinal.UdeseaDfinal LIMIT 1;  -- Debe poder hacer SELECT
-- Intentar hacer un UPDATE o DELETE (esto debería fallar)
DO $$ BEGIN
    UPDATE discosfinal.UdeseaDfinal SET titulo_disco = 'Nuevo Titulo' WHERE Nombre_Usuario = 'usuario1';
    RAISE NOTICE 'Error: El cliente no puede hacer UPDATE';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Correcto: El cliente no puede hacer UPDATE';
END $$;

-- Inicia sesión como invitado y verifica que solo puede consultar
-- Pedir conexión al rol 'invitado'
\echo 'Conéctate como el usuario invitado'
SET ROLE invitado;
-- El invitado puede hacer SELECT
SELECT * FROM discosfinal.Grupofinal LIMIT 1;  -- Debe poder hacer SELECT
-- Intentar insertar datos (esto debe fallar)
DO $$ BEGIN
    INSERT INTO discosfinal.Grupofinal (Nombre, URL) VALUES ('Nuevo Grupo', 'http://url.com');
    RAISE NOTICE 'Error: El invitado no puede insertar datos';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Correcto: El invitado no puede insertar datos';
END $$;

-- Intentar actualizar datos (esto debe fallar)
DO $$ BEGIN
    UPDATE discosfinal.Grupofinal SET URL = 'http://newurl.com' WHERE Nombre = 'Grupo1';
    RAISE NOTICE 'Error: El invitado no puede actualizar datos';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Correcto: El invitado no puede actualizar datos';
END $$;
