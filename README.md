# El Pistón

Aplicación Android local para organizar la operación diaria del taller mecánico El Pistón. Está construida con Flutter y Drift/SQLite; funciona sin conexión y conserva los registros en el almacenamiento privado de la aplicación.

## Ejecutar en Android

Requisitos: Flutter estable, Android SDK configurado y un dispositivo con depuración USB habilitada.

```bash
flutter pub get
flutter run -d <id-del-dispositivo>
```

La base se crea en el directorio de documentos privado de Android como `el_piston.sqlite`. No se necesita una cuenta ni conexión a internet para operar.

## Funciones

- Alta de clientes y de varios vehículos por cliente; consulta del historial de cliente o vehículo.
- Órdenes de servicio con problema reportado, kilometraje de entrada, mecánico asignado y estados: recibida, en diagnóstico, en reparación, lista para entregar, entregada y cancelada.
- Registro de mano de obra y de repuestos utilizados. El uso de repuestos descuenta existencias dentro de una transacción local.
- Inventario de repuestos con código, precio, existencias y umbral de alerta configurable; permite registrar reposiciones.
- Pagos parciales, total facturado, saldo de cada orden y clientes con deuda.
- Resumen de órdenes abiertas, carga por mecánico, stock bajo e importe facturado en un período.

## Decisiones de diseño

- Interfaz en español, organizada en Inicio, Órdenes, Clientes, Stock y Reportes para que las tareas comunes estén a un toque.
- Azul marino (`#153A56`) para navegación y acciones principales, azul claro (`#54B8E8`) para destacar acciones, y ámbar para avisos de stock.
- Umbral inicial de alerta: 3 unidades por repuesto. Se define al dar de alta cada artículo y puede ajustarse en futuras versiones.
- El reporte de facturación suma mano de obra y repuestos de las órdenes marcadas como entregadas dentro del período seleccionado. Los saldos se calculan por orden y se agrupan por cliente.
- Los dos mecánicos iniciales aparecen como “Mecánico 1” y “Mecánico 2”; el ícono de edición del resumen permite poner sus nombres reales.
- Los importes usan el símbolo `$` como formato inicial; se puede adaptar a la moneda que use el taller.
- Drift ejecuta y gestiona el esquema SQLite local. Las consultas SQL explícitas mantienen el esquema sencillo y no requieren archivos generados por `build_runner`.

## Datos y privacidad

Todos los datos permanecen en el dispositivo. Android los elimina si se desinstala la aplicación o si se borran sus datos; antes de instalar una versión que borre esos datos, realiza una copia desde Android. La app no incluye sincronización entre dispositivos.
