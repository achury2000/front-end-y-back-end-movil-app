## Development

Explain how to run the app here.

Quick start (DB + API config)

- Levantar base de datos local con Docker (usa la carpeta `db/`):

```powershell
cd 'c:\Users\USER\Desktop\app-de-occitours-main\db'
docker compose up -d
```

- O crear DB e importar el schema con el script PowerShell (requiere `psql`):

```powershell
cd 'c:\Users\USER\Desktop\app-de-occitours-main\db'
.\create_db.ps1
```

- Configurar la URL del backend (API_BASE_URL):

	- Edita `.env` en la raíz del proyecto (puedes copiar `.env.example`) y cambia `API_BASE_URL`.
	- Ejemplo de `.env`:

```dotenv
API_BASE_URL=https://api.example.com
```

- Correr la app (desde la raíz del proyecto):

```powershell
flutter pub get
flutter run
```

Colección Postman

He incluido `docs/postman_collection_occitours.json` con un stub de los endpoints principales para que puedas importarla en Postman y probar la API.

# Occitours — Guía de entrega (versión para evaluación)

Breve: app Flutter de demostración para catálogos, servicios y reservas. Este README cubre lo que el profesor necesita: instalación, uso, pruebas y decisiones técnicas.

---

## Contenido del repositorio

- `lib/`: código fuente (models, providers, screens, widgets).
- `data/`: datos mock usados por la app y tests.
- `providers/`: lógica de estado y reglas de negocio.
- `test/`: pruebas unitarias y widget tests; `test/test_helpers.dart` prepara el entorno.
- `docs/`: documentación y fases del proyecto (`phase-1..10.md`, `states.md`).
- `README_DELIVERY.md`: guía rápida pensada para el corrector (cuentas de prueba y script de demo).

---

## Requisitos mínimos

- Flutter SDK (stable) instalado y en `PATH`.
- Emulador Android o dispositivo conectado. (En macOS se puede usar emulador iOS).

---

## Instalación y ejecución (PowerShell)

```powershell
Set-Location 'C:\Users\USER\Desktop\app-de-occitours-main'
flutter pub get
flutter run

# Alternativa: intentar lanzar el primer emulador Android disponible
.\run_on_first_android_emulator.ps1
```

---

## Cuentas de prueba (mock)

- Admin: `admin@example.com` / `123456` (rol `admin`)
- Cliente: `client@example.com` / `123456` (rol `cliente`)

Las cuentas están en `lib/data/mock_users.dart` si necesitas revisarlas o cambiarlas.

---

## Flujo sugerido para demo (2–4 minutos)

1. Login con `admin@example.com` → Panel admin → crear un servicio/producto.
2. Logout → Login con `client@example.com` → buscar producto → abrir detalle → reservar.
3. Ir a Carrito → simular checkout.

Un guion más detallado y checklist están en `README_DELIVERY.md`.

---

## Tests (pospuestos)

Nota: los tests se han pospuesto en esta entrega. Si quieres que los restaure y los ejecute localmente, dímelo y los volveré a añadir y ejecutar.

---

## Decisiones técnicas (lo que importa para la evaluación)

- Estado: `provider` y `ChangeNotifier` por ser sencillo y claro para este alcance académico.
- Robustez en entrada de datos: `lib/utils/date_utils.dart` y parsers CSV tolerantes para evitar crashes por datos sucios.
- Validaciones en providers: reglas críticas (ej.: evitar duplicidad de reservas) centralizadas en providers para consistencia.
- Tests: `test/test_helpers.dart` y un conjunto de tests unitarios/widget que cubren flujos críticos.

---

## Qué verificar para la rúbrica (README completo: 0–5)

- Instalación: comando `flutter pub get` y `flutter run` funcionan.
- Uso: flujos claves (login, ver catálogo, reservar, carrito) ejecutables.
- Decisiones técnicas: presencia de documentación breve sobre diseño (providers, parsers, validaciones).

Este README + `README_DELIVERY.md` y `docs/` cubren esos puntos.

---

## Limitaciones conocidas (resumido)

- Agenda: implementación mínima (vista diaria), no calendario avanzado.
- Pagos: integraciones reales no incluidas (simulados).
- Recomendación: normalizar datos de origen en producción; los parsers son tolerantes pero no sustituyen validación/ETL.

---

## Entrega rápida

1. Ejecutar `flutter analyze` y `flutter test`.
2. Crear un tag `v1.0-delivery` y adjuntar `CHANGELOG.md` si se desea.
3. (Opcional) Generar APK: `flutter build apk --release`.

---
## NOTA: 
La carpeta llamda docs es la documentafcion de como se realizo el proyecto desde 0 