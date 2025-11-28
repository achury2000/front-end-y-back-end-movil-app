# README_DELIVERY.md — Guía para el profesor

Este archivo está pensado como una guía rápida y directa para que el profesor pueda reproducir la demo, probar los flujos críticos y evaluar la entrega sin perder tiempo buscando información.

---

## Cuentas de prueba (mock)

Usa estas cuentas en la pantalla de login. Son datos de ejemplo creados para pruebas locales (no son reales):

- Admin:
  - Email: `admin@example.com`
  - Password: `123456`
  - Rol: `admin`

- Cliente:
  - Email: `client@example.com`
  - Password: `123456`
  - Rol: `cliente`

- Asesor (advisor) (opcional):
  - Email: `advisor@example.com`
  - Password: `123456`
  - Rol: `advisor`

Si por algún motivo las cuentas no funcionan en tu instalación, revisa `lib/data/mock_users.dart` donde están definidas las cuentas mock.

---

## Script de demo (paso a paso — PowerShell)

Objetivo: mostrar al profesor los flujos clave en ~3–5 minutos.

```powershell
# 1) Abrir el proyecto y preparar dependencias
Set-Location 'C:\Users\USER\Desktop\app-de-occitours-main'
flutter pub get

# 2) Iniciar en el primer emulador Android disponible (si existe)
.\run_on_first_android_emulator.ps1

# 3) (Alternativa) Ejecutar la app manualmente
# flutter run

# 4) Flujo demo (manual, en la app)
# - Login con admin@example.com / 123456
# - Ir a Panel de Administración -> Productos / Servicios
# - Crear un servicio (o producto) rápido: nombre, duración, precio
# - Volver a Home, buscar el producto creado y abrir detalle
# - Como cliente: iniciar sesión con client@example.com y reservar el producto
# - Ir a Carrito y simular checkout (flujo simulado)

# 5) Opcional: ejecutar tests rápidos
flutter test test/unit/services_provider_test.dart
flutter test test/widget/services_flow_test.dart
```

Notas de ejecución:
- El demo muestra que la app cubre login, gestión básica por admin, creación de servicios/productos y reserva por cliente.
- Si quieres grabar un video corto, sigue los pasos anteriores en orden: (1) login admin, (2) crear recurso, (3) logout, (4) login cliente, (5) reservar y (6) mostrar carrito.

---
## Problemas conocidos y notas para el corrector

- Agenda: implementación mínima (vista día-a-día). No es un calendario completo.
- Parsers: tolerantes a formatos de fecha/CSV, pero no sustituyen validación en origen.
- Pagos: integraciones de pago no incluidas (flujos simulados).

---

## Materiales adicionales para la entrega

- `CHANGELOG.md`: resumen de cambios (crear si se desea un resumen formal).
- Tag sugerido: `v1.0-delivery`.
- Si el profesor desea, puedo preparar un video de 2–3 minutos y un APK listo para descargar.

---
