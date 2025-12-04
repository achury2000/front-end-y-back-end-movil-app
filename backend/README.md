# Backend mínimo para Occitours (desarrollo)

Este backend es un scaffold mínimo para pruebas locales. Usa Node.js + Express y se conecta a la base de datos PostgreSQL configurada en la raíz del proyecto (`.env`).

Endpoints principales:
- `GET /health` — estado
- `POST /auth/login` — login por `email` (desarrollo: devuelve token si el usuario existe)
- `GET /products` — lista de productos (desde tabla `products`)
- `GET /products/:id` — producto por id
- `POST /reservations` — crear reserva (intenta insertar en `reservations`)

Cómo usar localmente:

1. Desde la raíz del proyecto crea o revisa `.env` con las variables DB.
2. Instala dependencias:

```powershell
cd backend
npm install
npm run dev
```

3. Si prefieres arrancar con Docker Compose (usa el `db/docker-compose.yml` que incluye Postgres):

```powershell
# desde la carpeta db
cd db
docker compose up -d
# después, en otra terminal
cd ..\backend
npm install
npm start
```

Notas:
- Este backend es un stub de desarrollo. No uses la lógica de `auth` en producción.
- Las consultas a tablas asumen nombres comunes (`users`, `products`, `reservations`). Si tu esquema difiere, ajusta las rutas.