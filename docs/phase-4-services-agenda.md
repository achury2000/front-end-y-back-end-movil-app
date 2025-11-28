# Fase 4 — Servicios y Agenda

Resumen de lo implementado:

- Modelo `Service` (`lib/models/service.dart`): campos `id`, `name`, `description`, `durationMinutes`, `capacity`, `price`, `active`.
- Provider `ServicesProvider` (`lib/providers/services_provider.dart`): CRUD, persistencia via `SharedPreferences` (`services_v1`), auditoría en memoria, búsqueda (`search`), y funciones de export/import CSV.
- UI:
  - `ServicesListScreen` (`lib/screens/services_list_screen.dart`): búsqueda, listado y acceso a crear/editar (FAB visible a `admin`).
  - `ServiceDetailScreen` (`lib/screens/service_detail_screen.dart`): formulario para crear/editar servicios, validaciones básicas y guardado en provider.
  - `ServicesAgendaScreen` (`lib/screens/services_agenda_screen.dart`): vista mínima día-a-día que muestra cuántas reservas hay del servicio en la fecha seleccionada y un diálogo con los horarios del día.
- Tests:
  - `test/unit/services_provider_test.dart`: pruebas unitarias para CRUD e import/export CSV.
  - `test/widget/services_flow_test.dart`: prueba widget para crear servicios (usa un spy provider para evitar acceso a `SharedPreferences`).

Decisiones y notas:
- Registros de auditoría se guardan en memoria en `_audit` y se persisten junto a los recursos principales.
- La agenda es una implementación mínima (placeholder). Para una agenda completa se puede integrar un paquete de calendario (ej. `table_calendar`) y añadir asignación de empleados y control de cupos.
- Tests usan `SharedPreferences.setMockInitialValues({})` y `TestWidgetsFlutterBinding.ensureInitialized()` donde es necesario para evitar dependencias en entorno real.

Recomendaciones siguientes:
- Añadir asignación de empleados por servicio y validación de disponibilidad antes de crear reservas.
- Mejorar la agenda (vista semanal, arrastrar y soltar, crear reserva desde calendario).
- Mejorar cobertura de tests (edge cases de CSV, validaciones de duración y capacidad).

Estado: Fase 4 completada (funcionalidad inicial entregada, tests y análisis OK).
