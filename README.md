# Occitours - Flutter demo

Proyecto de demostración que implementa gestión de estados para una app móvil de e-commerce/turismo (Occitours).

Instrucciones rápidas:

- Instalar Flutter SDK y tenerlo en PATH.
- Desde la carpeta del proyecto ejecutar:

```bash
flutter pub get
flutter run
```

Ejecutar en un emulador Android automáticamente

Si tienes varios emuladores/ dispositivos y quieres que el proyecto se lance
en el primer emulador Android detectado sin tener que pasar el id manualmente,
puedes usar el script PowerShell incluido:

```powershell
.\run_on_first_android_emulator.ps1
```

El script detecta un dispositivo Android (emulator-XXXX o cualquier dispositivo
con plataforma `android`) y ejecuta `flutter run -d <deviceId>`. Si no hay
dispositivos Android, simplemente ejecuta `flutter run` y te pedirá elegir uno.


 Arquitectura y notas:
 - Stack: Flutter + Provider
 - Datos mock en `lib/data/` y simulación asíncrona con `Future.delayed`
 - Providers en `lib/providers/`
 - Modelos en `lib/models/`

## Fase 6 - Control de stock y CSV

Se añadió control de stock avanzado y utilidades CSV en esta rama:

- Historial de stock por producto (se guarda en `SharedPreferences` con la clave `stock_history_v1`).
- Niveles de reorden (umbral) por producto y pantalla para ver productos con stock bajo.
- Import / Export CSV sencillo para productos desde la UI (`Import/Export Productos`).
- Integración: al marcar una compra como "Recibido" se actualiza el stock y se registra en el historial.

## Ejecutar tests y verificación

Hay tests unitarios que cubren productos, búsquedas y compras. Para ejecutar todo desde PowerShell:

```powershell
Set-Location 'C:\Users\USER\Desktop\app-de-occitours-main'
flutter pub get
flutter analyze
flutter test
```

También hay un script rápido que ejecuta `flutter analyze` y `flutter test`:

```powershell
.\scripts\run_tests.ps1
```

## Probar flujos importantes (manualmente)

1. Iniciar la app en un emulador o dispositivo:

```powershell
Set-Location 'C:\Users\USER\Desktop\app-de-occitours-main'
flutter run
```

2. Como administrador (o usando una cuenta con rol `admin`):
 - Abrir `Panel de Administración` → `Stock bajo (N)` para ver productos con stock bajo.
 - Crear una `Compra` desde `Compras` → `Nueva Compra`.
 - Ir a `Detalle Compra` y seleccionar `Marcar como recibido` → esto actualiza el stock y guarda un registro en el historial.

## Notas finales

Si quieres que pulse la importación CSV para soportar formatos más complejos (comillas, saltos de línea) puedo integrar la dependencia `csv` y mejorar el parser.

## Documentación de Estados
Se añadió `docs/states.md` con la descripción de cada "state" (providers), su API pública y notas para evaluación (Login, Productos, Perfil, Carrito, Programación/Reservas, Reportes).

Para más detalles, abre `docs/states.md`.

