DB - migraciones y seeds

Archivos incluidos:
- `0001_init_cart_orders.sql` — crea tablas `refresh_tokens`, `carrito`, `cart_items`, `orders`, `order_items`.
- `seed_minimal.sql` — inserta roles mínimos (`user`, `admin`) y 3 servicios de ejemplo.

Recomendación de uso local (Windows PowerShell):

# 1) Usando `psql` contra la base de datos existente
-- Ajusta las variables a tu entorno (host, puerto, usuario, bd). Ejemplo:
psql -h localhost -p 5432 -U postgres -d occitours_clean -f db/0001_init_cart_orders.sql
psql -h localhost -p 5432 -U postgres -d occitours_clean -f db/seed_minimal.sql

-- Si tu usuario en `.env` tiene permisos CREATE puedes ejecutar con ese usuario en vez de `postgres`.

# 2) Usando Docker Compose (si usas el servicio Postgres en Docker)
-- Si tienes un servicio Postgres que mapea un volumen, copia los archivos `.sql` al directorio de init (por ejemplo `docker-entrypoint-initdb.d`) o ejecuta `psql` dentro del contenedor:
docker exec -i <pg_container_name> psql -U postgres -d occitours_clean < /workspace/db/0001_init_cart_orders.sql

Notas importantes:
- En entornos donde el usuario DB no tenga permisos para crear tablas (ERROR: permiso denegado al esquema public), debes ejecutar las migraciones con un usuario que sí tenga permisos (por ejemplo `postgres`) o pedir al administrador que aplique los archivos SQL.
- No correr las migraciones con credenciales de producción sin revisarlas.
# Base de datos local (PostgreSQL) para Occitours

Este directorio contiene artefactos para levantar una instancia local de PostgreSQL usada durante el desarrollo.

Contenido:
- `docker-compose.yml`: servicio `db` (Postgres) y `pgadmin` para administración web.
- `schema.sql`: script de inicialización con tablas básicas y seeds mínimos.

Instrucciones rápidas (PowerShell):

1. Levantar Postgres y pgAdmin

```powershell
# desde la raíz del repo, donde está db/docker-compose.yml
docker compose -f db/docker-compose.yml up -d
docker ps
```

2. Conectarse con `psql` (si tienes cliente psql instalado):

```powershell
psql -h localhost -p 5432 -U occi_user -d occitours_dev
# contraseña: secretpassword (cambiar en producción)
```

3. Acceder a pgAdmin en `http://localhost:8080` con las credenciales `admin@local` / `admin`.

4. Notas:
- El archivo `schema.sql` se monta como script de inicialización y se ejecuta la primera vez que arranca el contenedor si la base de datos está vacía.
- Cambia las credenciales en `docker-compose.yml` o utiliza variables de entorno en producción.
- Si ya tienes un `schema_final.sql` más completo, pégalo en `db/schema.sql` o reemplaza el archivo antes de levantar los servicios.
