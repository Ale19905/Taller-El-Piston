import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' as flutter;
import 'package:path_provider/path_provider.dart';

/// The workshop database is a local SQLite file managed by Drift. The schema
/// is written explicitly so the app does not depend on generated code.
class AppDatabase extends GeneratedDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (_) async {
          await customStatement('''CREATE TABLE mechanics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            active INTEGER NOT NULL DEFAULT 1
          )''');
          await customStatement('''CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            address TEXT NOT NULL DEFAULT ''
          )''');
          await customStatement('''CREATE TABLE vehicles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
            plate TEXT NOT NULL UNIQUE,
            make TEXT NOT NULL,
            model TEXT NOT NULL,
            year INTEGER NOT NULL,
            mileage INTEGER NOT NULL DEFAULT 0
          )''');
          await customStatement('''CREATE TABLE service_orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicle_id INTEGER NOT NULL REFERENCES vehicles(id),
            mechanic_id INTEGER NOT NULL REFERENCES mechanics(id),
            entered_at TEXT NOT NULL,
            issue TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'Recibida',
            delivered_at TEXT NOT NULL DEFAULT ''
          )''');
          await customStatement('''CREATE TABLE labor_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
            description TEXT NOT NULL,
            price REAL NOT NULL
          )''');
          await customStatement('''CREATE TABLE parts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            code TEXT NOT NULL UNIQUE,
            sale_price REAL NOT NULL,
            stock INTEGER NOT NULL DEFAULT 0,
            low_stock_threshold INTEGER NOT NULL DEFAULT 3
          )''');
          await customStatement('''CREATE TABLE order_parts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
            part_id INTEGER NOT NULL REFERENCES parts(id),
            quantity INTEGER NOT NULL,
            unit_price REAL NOT NULL
          )''');
          await customStatement('''CREATE TABLE payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
            amount REAL NOT NULL,
            paid_at TEXT NOT NULL
          )''');
          await customStatement('CREATE INDEX idx_orders_vehicle ON service_orders(vehicle_id)');
          await customStatement('CREATE INDEX idx_orders_mechanic ON service_orders(mechanic_id, status)');
          await customStatement('CREATE INDEX idx_orders_date ON service_orders(entered_at)');
          await customStatement("INSERT INTO mechanics(name) VALUES ('Mecánico 1'), ('Mecánico 2')");
        
          await _seedDemoData();
        },
        onUpgrade: (_, from, to) async {
          if (from < 2) {
            await _seedDemoData();
          }
        },
      );

  Future<void> _seedDemoData() async {
  final existing = await rows(
    'SELECT COUNT(*) AS total FROM customers',
  );

  // No duplica los datos si ya hay clientes.
  if (existing.first.read<int>('total') > 0) return;

  var activeMechanics = await mechanics();
  if (activeMechanics.isEmpty) {
    await customStatement(
      "INSERT INTO mechanics(name) VALUES ('Mecánico 1'), ('Mecánico 2')",
    );
    activeMechanics = await mechanics();
  }

  final mechanic1 = activeMechanics.first.read<int>('id');
  final mechanic2 = activeMechanics.length > 1
      ? activeMechanics[1].read<int>('id')
      : mechanic1;

  final customer1 = await saveCustomer(
    name: 'Ana Martínez',
    phone: '555-0101',
    address: 'Centro',
  );
  final customer2 = await saveCustomer(
    name: 'Carlos López',
    phone: '555-0102',
    address: 'Norte',
  );

  final vehicle1 = await saveVehicle(
    customerId: customer1,
    plate: 'ABC-123',
    make: 'Toyota',
    model: 'Corolla',
    year: 2018,
    mileage: 85400,
  );
  final vehicle2 = await saveVehicle(
    customerId: customer2,
    plate: 'XYZ-789',
    make: 'Nissan',
    model: 'Versa',
    year: 2021,
    mileage: 42600,
  );

  await savePart(
    name: 'Aceite 5W-30',
    code: 'ACE-5W30',
    price: 180.0,
    stock: 2,
    threshold: 3,
  );
  await savePart(
    name: 'Filtro de aceite',
    code: 'FIL-ACE-01',
    price: 95.0,
    stock: 8,
    threshold: 3,
  );

  final now = DateTime.now();

  final openOrder = await insert('service_orders', {
    'vehicle_id': vehicle1,
    'mechanic_id': mechanic1,
    'entered_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'issue': 'Cambio de aceite y revisión general',
    'status': 'En reparación',
  });
  await addLabor(openOrder, 'Servicio de mantenimiento', 650.0);

  final deliveredOrder = await insert('service_orders', {
    'vehicle_id': vehicle2,
    'mechanic_id': mechanic2,
    'entered_at': now.subtract(const Duration(days: 3)).toIso8601String(),
    'issue': 'Revisión de frenos',
    'status': 'Entregada',
    'delivered_at': now.toIso8601String(),
  });
  await addLabor(deliveredOrder, 'Ajuste de frenos', 450.0);
  await addPayment(deliveredOrder, 200.0);
}    

  static QueryExecutor _openConnection() => LazyDatabase(() async {
        flutter.WidgetsFlutterBinding.ensureInitialized();
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/el_piston.sqlite');
        return NativeDatabase.createInBackground(file,
          setup: (database) => database.execute('PRAGMA foreign_keys = ON;'));
      });

  List<Variable> _vars(List<Object> values) => values.map((value) {
        if (value is int) return Variable<int>(value);
        if (value is double) return Variable<double>(value);
        return Variable<String>(value.toString());
      }).toList();

  Future<List<QueryRow>> rows(String sql, [List<Object> values = const []]) =>
      customSelect(sql, variables: _vars(values)).get();

  Future<void> run(String sql, [List<Object?> values = const []]) =>
    customStatement(sql, values);

  Future<int> insert(String table, Map<String, Object> values) async {
    final columns = values.keys.join(', ');
    final marks = List.filled(values.length, '?').join(', ');
    await run('INSERT INTO $table ($columns) VALUES ($marks)', values.values.toList());
    final result = await rows('SELECT last_insert_rowid() AS id');
    return result.first.read<int>('id');
  }

  Future<List<QueryRow>> customers() => rows('SELECT * FROM customers ORDER BY name');

  Future<int> saveCustomer({required String name, required String phone, String address = ''}) =>
      insert('customers', {'name': name.trim(), 'phone': phone.trim(), 'address': address.trim()});

  Future<int> saveVehicle({required int customerId, required String plate, required String make,
    required String model, required int year, required int mileage}) => insert('vehicles', {
      'customer_id': customerId, 'plate': plate.trim().toUpperCase(), 'make': make.trim(),
      'model': model.trim(), 'year': year, 'mileage': mileage,
    });

  Future<int> savePart({required String name, required String code, required double price,
    required int stock, required int threshold}) => insert('parts', {
      'name': name.trim(), 'code': code.trim().toUpperCase(), 'sale_price': price,
      'stock': stock, 'low_stock_threshold': threshold,
    });

  Future<void> restock(int id, int quantity) => run(
      'UPDATE parts SET stock=stock+? WHERE id=?', [quantity, id]);

  Future<void> renameMechanic(int id, String name) => run(
      'UPDATE mechanics SET name=? WHERE id=?', [name.trim(), id]);

  Future<int> createOrder({required int vehicleId, required int mechanicId, required String issue,
    required int mileage}) async {
    return transaction(() async {
      await run('UPDATE vehicles SET mileage = ? WHERE id = ?', [mileage, vehicleId]);
      return insert('service_orders', {
        'vehicle_id': vehicleId,
        'mechanic_id': mechanicId,
        'entered_at': DateTime.now().toIso8601String(),
        'issue': issue.trim(),
      });
    });
  }

  Future<List<QueryRow>> orders({String? status}) => rows('''
    SELECT o.*, v.plate, v.make, v.model, v.customer_id, c.name AS customer,
      m.name AS mechanic,
      COALESCE((SELECT SUM(price) FROM labor_items l WHERE l.order_id=o.id), 0) AS labor_total,
      COALESCE((SELECT SUM(quantity * unit_price) FROM order_parts p WHERE p.order_id=o.id), 0) AS parts_total,
      COALESCE((SELECT SUM(amount) FROM payments pay WHERE pay.order_id=o.id), 0) AS paid_total
    FROM service_orders o JOIN vehicles v ON v.id=o.vehicle_id
    JOIN customers c ON c.id=v.customer_id JOIN mechanics m ON m.id=o.mechanic_id
    ${status == null || status == 'Todas' ? '' : 'WHERE o.status = ?'}
    ORDER BY CASE o.status WHEN 'Entregada' THEN 1 WHEN 'Cancelada' THEN 2 ELSE 0 END,
      o.entered_at DESC
  ''', status == null || status == 'Todas' ? const [] : [status]);

  Future<List<QueryRow>> orderDetail(int id) async => rows('''
    SELECT o.*, v.plate, v.make, v.model, v.year, v.mileage, v.customer_id,
      c.name AS customer, c.phone, m.name AS mechanic,
      COALESCE((SELECT SUM(price) FROM labor_items l WHERE l.order_id=o.id), 0) AS labor_total,
      COALESCE((SELECT SUM(quantity * unit_price) FROM order_parts p WHERE p.order_id=o.id), 0) AS parts_total,
      COALESCE((SELECT SUM(amount) FROM payments pay WHERE pay.order_id=o.id), 0) AS paid_total
    FROM service_orders o JOIN vehicles v ON v.id=o.vehicle_id
    JOIN customers c ON c.id=v.customer_id JOIN mechanics m ON m.id=o.mechanic_id
    WHERE o.id=?
  ''', [id]);

  Future<List<QueryRow>> labor(int orderId) => rows('SELECT * FROM labor_items WHERE order_id=? ORDER BY id DESC', [orderId]);
  Future<List<QueryRow>> usedParts(int orderId) => rows('''
    SELECT op.*, p.name, p.code FROM order_parts op JOIN parts p ON p.id=op.part_id
    WHERE op.order_id=? ORDER BY op.id DESC
  ''', [orderId]);
  Future<List<QueryRow>> payments(int orderId) => rows('SELECT * FROM payments WHERE order_id=? ORDER BY paid_at DESC', [orderId]);
  Future<List<QueryRow>> mechanics() => rows('SELECT * FROM mechanics WHERE active=1 ORDER BY name');
  Future<List<QueryRow>> vehiclesForCustomer(int id) => rows('SELECT * FROM vehicles WHERE customer_id=? ORDER BY plate', [id]);
  Future<List<QueryRow>> vehicles() => rows('''SELECT v.*, c.name AS customer FROM vehicles v
    JOIN customers c ON c.id=v.customer_id ORDER BY v.plate''');
  Future<List<QueryRow>> parts() => rows('SELECT * FROM parts ORDER BY name');
  Future<List<QueryRow>> lowStock() => rows('SELECT * FROM parts WHERE stock <= low_stock_threshold ORDER BY stock, name');

  Future<void> addLabor(int orderId, String description, double price) =>
      run('INSERT INTO labor_items(order_id, description, price) VALUES (?, ?, ?)', [orderId, description.trim(), price]);

  Future<void> consumePart(int orderId, int partId, int quantity) async {
    await transaction(() async {
      final part = (await rows('SELECT * FROM parts WHERE id=?', [partId])).first;
      final stock = part.read<int>('stock');
      if (quantity < 1 || quantity > stock) throw StateError('No hay existencias suficientes.');
      await run('UPDATE parts SET stock=stock-? WHERE id=?', [quantity, partId]);
      await run('INSERT INTO order_parts(order_id, part_id, quantity, unit_price) VALUES (?, ?, ?, ?)',
        [orderId, partId, quantity, part.read<double>('sale_price')]);
    });
  }

  Future<void> addPayment(int orderId, double amount) => run(
      'INSERT INTO payments(order_id, amount, paid_at) VALUES (?, ?, ?)',
      [orderId, amount, DateTime.now().toIso8601String()]);

  Future<void> setStatus(int id, String status) => run(
      'UPDATE service_orders SET status=?, delivered_at=? WHERE id=?',
      [status, status == 'Entregada' ? DateTime.now().toIso8601String() : '', id]);

  Future<List<QueryRow>> dashboard() => rows('''SELECT
      (SELECT COUNT(*) FROM service_orders WHERE status NOT IN ('Entregada','Cancelada')) AS open_count,
      (SELECT COUNT(*) FROM parts WHERE stock <= low_stock_threshold) AS low_count,
      (SELECT COALESCE(SUM(l.price),0) FROM labor_items l JOIN service_orders o ON o.id=l.order_id
        WHERE substr(o.delivered_at,1,7)=substr(date('now'),1,7)) +
      (SELECT COALESCE(SUM(op.quantity*op.unit_price),0) FROM order_parts op JOIN service_orders o ON o.id=op.order_id
        WHERE substr(o.delivered_at,1,7)=substr(date('now'),1,7)) AS billed_month
    ''');

  Future<List<QueryRow>> mechanicWorkload() => rows('''SELECT m.id, m.name, COUNT(o.id) AS assigned
    FROM mechanics m LEFT JOIN service_orders o ON o.mechanic_id=m.id
      AND o.status NOT IN ('Entregada','Cancelada') WHERE m.active=1 GROUP BY m.id ORDER BY m.name''');

  Future<List<QueryRow>> customerBalances() => rows('''SELECT c.id,c.name,c.phone,
    SUM(COALESCE(t.total,0)+COALESCE(rp.total,0)-COALESCE(p.paid,0)) AS balance
    FROM customers c JOIN vehicles v ON v.customer_id=c.id JOIN service_orders o ON o.vehicle_id=v.id
    LEFT JOIN (SELECT order_id, SUM(price) AS total FROM labor_items GROUP BY order_id) t ON t.order_id=o.id
    LEFT JOIN (SELECT order_id, SUM(quantity*unit_price) AS total FROM order_parts GROUP BY order_id) rp ON rp.order_id=o.id
    LEFT JOIN (SELECT order_id, SUM(amount) AS paid FROM payments GROUP BY order_id) p ON p.order_id=o.id
    WHERE o.status != 'Cancelada' GROUP BY c.id HAVING balance > 0 ORDER BY balance DESC''');

  Future<List<QueryRow>> history({int? customerId, int? vehicleId}) => rows('''
    SELECT o.id,o.entered_at,o.status,o.issue,v.plate,v.make,v.model,c.name AS customer,m.name AS mechanic,
      (COALESCE((SELECT SUM(price) FROM labor_items WHERE order_id=o.id),0)+
       COALESCE((SELECT SUM(quantity*unit_price) FROM order_parts WHERE order_id=o.id),0)) AS total
    FROM service_orders o JOIN vehicles v ON v.id=o.vehicle_id JOIN customers c ON c.id=v.customer_id
    JOIN mechanics m ON m.id=o.mechanic_id
    WHERE (? = 0 OR v.customer_id=?) AND (? = 0 OR v.id=?) ORDER BY o.entered_at DESC
  ''', [customerId ?? 0, customerId ?? 0, vehicleId ?? 0, vehicleId ?? 0]);

  Future<double> billedBetween(DateTime from, DateTime to) async {
    final result = await rows('''SELECT
      COALESCE((SELECT SUM(l.price) FROM labor_items l JOIN service_orders o ON o.id=l.order_id
        WHERE o.status='Entregada' AND o.delivered_at>=? AND o.delivered_at<?),0) +
      COALESCE((SELECT SUM(op.quantity*op.unit_price) FROM order_parts op JOIN service_orders o ON o.id=op.order_id
        WHERE o.status='Entregada' AND o.delivered_at>=? AND o.delivered_at<?),0) AS total''',
      [from.toIso8601String(), to.toIso8601String(), from.toIso8601String(), to.toIso8601String()]);
    return result.first.read<double>('total');
  }
}
