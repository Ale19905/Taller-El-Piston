import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/material.dart';
import 'data/app_database.dart';

const navy = Color(0xFF153A56);
const blue = Color(0xFF54B8E8);
const paleBlue = Color(0xFFE9F6FC);
const amber = Color(0xFFF3A83B);
const ink = Color(0xFF182B38);
const muted = Color(0xFF71818B);
const bg = Color(0xFFF5F8FA);

late final AppDatabase db;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  db = AppDatabase();
  runApp(const ElPistonApp());
}

class ElPistonApp extends StatelessWidget {
  const ElPistonApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'El Pistón',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: blue),
          appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: navy, elevation: 0),
          cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFEAF1F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFD3DEE6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFD3DEE6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: blue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          ),
        ),
        home: const AppShell(),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  final titles = ['Resumen', 'Órdenes', 'Clientes', 'Repuestos', 'Reportes'];
  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onOrders: () => setState(() => tab = 1),
        onNewOrder: () => createOrder(
          context,
          () async => setState(() {}),
        ),
      ),
      OrdersPage(), CustomersPage(), InventoryPage(), ReportsPage()
    ];
    return Scaffold(
      appBar: AppBar(title: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.build_rounded, color: Colors.white, size: 20)),
        const SizedBox(width: 10), Text(titles[tab], style: const TextStyle(fontWeight: FontWeight.w800)),
      ])),
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i),
        backgroundColor: Colors.white, indicatorColor: paleBlue,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Órdenes'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reportes'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
    const DashboardPage({
    super.key,
    required this.onOrders,
    required this.onNewOrder,
  });

  final VoidCallback onOrders;
  final VoidCallback onNewOrder;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  Future<void> refresh() async => setState(() {});
  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: refresh, child: ListView(
    padding: const EdgeInsets.fromLTRB(18, 4, 18, 24), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [navy, Color(0xFF245C7D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TALLER EL PISTÓN', style: TextStyle(color: Color(0xFFB8DDF0), letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10), const Text('Todo en marcha.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4), const Text('Controla el trabajo de hoy desde aquí.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 18), FilledButton.icon(onPressed: widget.onNewOrder,
            style: FilledButton.styleFrom(backgroundColor: blue, foregroundColor: navy),
            icon: const Icon(Icons.add), label: const Text('Nueva orden')),
        ])),
      const SizedBox(height: 20),
      FutureBuilder<List<QueryRow>>(future: db.dashboard(), builder: (context, snap) {
        if (snap.hasError) {
          return Text('Error de base de datos: ${snap.error}');
        }
        if (!snap.hasData) return const LoadingCard();
        final r = snap.data!.first;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Órdenes abiertas',
                  value: '${r.read<int>('open_count')}',
                  icon: Icons.build_circle_outlined,
                  tint: paleBlue,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: MetricCard(
                  label: 'Stock bajo',
                  value: '${r.read<int>('low_count')}',
                  icon: Icons.warning_amber_rounded,
                  tint: const Color(0xFFFFF2DC),
                ),
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 11),
      FutureBuilder<List<QueryRow>>(future: db.dashboard(), builder: (context, snap) => snap.hasData
        ? MetricCard(label: 'Facturado este mes', value: money(snap.data!.first.read<double>('billed_month')), icon: Icons.payments_outlined, tint: const Color(0xFFEAF5EF), wide: true)
        : const LoadingCard()),
      const SizedBox(height: 23),
      SectionTitle('Trabajo por mecánico'),
      const SizedBox(height: 10),
      FutureBuilder<List<QueryRow>>(future: db.mechanicWorkload(), builder: (context, snap) {
        if (snap.hasError) {
          return Text('Error de base de datos: ${snap.error}');
        }
        if (!snap.hasData) return const LoadingCard();
        return Column(children: snap.data!.map((r) => Padding(padding: const EdgeInsets.only(bottom: 9),
          child: CardPad(child: Row(children: [
            CircleAvatar(backgroundColor: paleBlue, child: const Icon(Icons.person_outline, color: navy)),
            const SizedBox(width: 12), Expanded(child: Text(r.read<String>('name'), style: const TextStyle(fontWeight: FontWeight.w700))),
            Text('${r.read<int>('assigned')} asignadas', style: const TextStyle(color: muted, fontSize: 12)),
            IconButton(onPressed: () => renameMechanic(context, r.read<int>('id'), r.read<String>('name'), refresh),
              icon: const Icon(Icons.edit_outlined, size: 18, color: muted), tooltip: 'Cambiar nombre'),
          ])))).toList());
      }),
      const SizedBox(height: 12), SectionTitle('Órdenes recientes', action: 'Ver todas', onTap: widget.onOrders),
      const SizedBox(height: 10), FutureBuilder<List<QueryRow>>(future: db.orders(), builder: (context, snap) {
        if (snap.hasError) {
          return Text('Error de base de datos: ${snap.error}');
        }
        if (!snap.hasData) return const LoadingCard();
        final open = snap.data!.where((r) => !const ['Entregada','Cancelada'].contains(r.read<String>('status'))).take(3).toList();
        if (open.isEmpty) return const EmptyCard('No hay órdenes abiertas.');
       return Column(
          children: open.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: OrderTile(
            row: r,
            onTap: () => openOrder(context, r.read<int>('id'), refresh),
          ),
        )).toList(),
      );
      }),
    ]));
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override State<OrdersPage> createState() => _OrdersPageState();
}
class _OrdersPageState extends State<OrdersPage> {
  String filter = 'Abiertas';
  Future<void> refresh() async => setState(() {});
  @override Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(18, 3, 18, 12), child: Row(children: [
      Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, 
      child: Row(children: ['Abiertas','Todas','Entregada','Cancelada']
      .map((label) => Padding(
          padding: const EdgeInsets.only(right: 7),
          child: ChoiceChip(
            label: Text(label),
            selected: filter==label,
            onSelected: (_) => setState(() => filter = label),
            ),
            ))
            .toList()
        )
      )
    ),
      IconButton.filled(onPressed: () => createOrder(context, refresh), icon: const Icon(Icons.add), tooltip: 'Nueva orden'),
    ])),
    Expanded(child: FutureBuilder<List<QueryRow>>(future: db.orders(status: filter=='Abiertas' ? null : filter), builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      var rows = snap.data!;
      if (filter=='Abiertas') rows = rows.where((r) => !const ['Entregada','Cancelada'].contains(r.read<String>('status'))).toList();
      if (rows.isEmpty) return const EmptyCard('Todavía no hay órdenes aquí.');
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 9),
          itemBuilder: (context, i) => OrderTile(
            row: rows[i],
            onTap: () => openOrder(context, rows[i].read<int>('id'), refresh),
          ),
        ),
      );
    })),
  ]);
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});
  @override State<CustomersPage> createState() => _CustomersPageState();
}
class _CustomersPageState extends State<CustomersPage> {
  Future<void> refresh() async => setState(() {});
  @override Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(18,3,18,12), child: Row(children: [
      const Expanded(child: Text('Clientes y vehículos', style: TextStyle(color: muted))),
      IconButton.filled(
        onPressed: () => createVehicle(context, refresh),
        tooltip: 'Agregar vehículo',
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.directions_car_outlined),
            Positioned(
              top: -5,
              right: -7,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: navy, size: 12),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 7), IconButton.filled(onPressed: ()=>createCustomer(context, refresh), icon: const Icon(Icons.person_add_alt_1), tooltip:'Nuevo cliente'),
    ])),
    Expanded(child: FutureBuilder<List<QueryRow>>(future: db.customers(), builder: (context, snap) {
      if (!snap.hasData) return const Center(child:CircularProgressIndicator());
      if (snap.data!.isEmpty) return const EmptyCard('Agrega clientes para empezar.');
      return ListView.separated(padding: const EdgeInsets.fromLTRB(18,0,18,20), itemCount: snap.data!.length,
        separatorBuilder: (_,__)=>const SizedBox(height:8), itemBuilder: (context,i) {
          final c=snap.data![i]; final id=c.read<int>('id');
          return CardPad(child: Column(children: [
            Row(children: [CircleAvatar(backgroundColor:paleBlue,child:const Icon(Icons.person_outline,color:navy)), const SizedBox(width:12),
              Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.read<String>('name'),style:const TextStyle(fontWeight:FontWeight.w800)),
                Text(c.read<String>('phone'),style:const TextStyle(color:muted,fontSize:12))])),
              IconButton(onPressed:()=>openHistory(context, customerId:id, title:c.read<String>('name')), icon:const Icon(Icons.history,color:navy),tooltip:'Historial'),
            ]),
            FutureBuilder<List<QueryRow>>(future: db.vehiclesForCustomer(id), builder:(context, vs) {
              if (!vs.hasData || vs.data!.isEmpty) return const SizedBox.shrink();
              return Column(children: vs.data!.map((v)=>InkWell(onTap:()=>openHistory(context,vehicleId:v.read<int>('id'),title:v.read<String>('plate')),
                child: Padding(padding:const EdgeInsets.only(top:12,left:4),child:Row(children:[const Icon(Icons.directions_car_outlined,size:18,color:blue),const SizedBox(width:8),
                  Expanded(child:Text('${v.read<String>('plate')} · ${v.read<String>('make')} ${v.read<String>('model')}',style:const TextStyle(fontSize:13))),
                  Text('${v.read<int>('mileage')} km',style:const TextStyle(color:muted,fontSize:11)), const Icon(Icons.chevron_right,size:18,color:muted)])))).toList());
            }),
          ]));
        });
    })),
  ]);
}

class InventoryPage extends StatefulWidget { const InventoryPage({super.key}); @override State<InventoryPage> createState()=>_InventoryPageState(); }
class _InventoryPageState extends State<InventoryPage> {
  Future<void> refresh() async=>setState((){});
  @override Widget build(BuildContext context)=>Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(18,3,18,12),child:Row(children:[
      Expanded(child:FutureBuilder<List<QueryRow>>(future:db.lowStock(),builder:(context,s)=>Text(s.hasData?'${s.data!.length} repuestos por reponer':'Inventario del taller',style:const TextStyle(color:muted)))),
      IconButton.filled(onPressed:()=>createPart(context,refresh),icon:const Icon(Icons.add),tooltip:'Agregar repuesto'),
    ])),
    Expanded(child:FutureBuilder<List<QueryRow>>(future:db.parts(),builder:(context,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator()); if(s.data!.isEmpty)return const EmptyCard('Agrega repuestos para controlar existencias.');
      return RefreshIndicator(onRefresh:refresh,child:ListView.separated(padding:const EdgeInsets.fromLTRB(18,0,18,20),itemCount:s.data!.length,
        separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(context,i){final p=s.data![i]; final low=p.read<int>('stock')<=p.read<int>('low_stock_threshold');
          return CardPad(child:Row(children:[Container(width:45,height:45,decoration:BoxDecoration(color:low?const Color(0xFFFFF2DC):paleBlue,borderRadius:BorderRadius.circular(14)),
              child:Icon(low?Icons.warning_amber_rounded:Icons.settings_outlined,color:low?amber:navy)),const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.read<String>('name'),style:const TextStyle(fontWeight:FontWeight.w800)),
              Text('${p.read<String>('code')} · ${money(p.read<double>('sale_price'))}',style:const TextStyle(color:muted,fontSize:12)),
              if(low)const Text('Stock bajo · toca + para reponer',style:TextStyle(color:Color(0xFFB77813),fontSize:11,fontWeight:FontWeight.w600))])),
            Text('${p.read<int>('stock')}',style:TextStyle(fontWeight:FontWeight.w900,fontSize:20,color:low?const Color(0xFFB77813):navy)),
            IconButton(onPressed:()=>restock(context,p.read<int>('id'),p.read<String>('name'),refresh),icon:const Icon(Icons.add_circle_outline,color:blue),tooltip:'Reponer stock'),
          ]));}));
    })),
  ]);
}

class ReportsPage extends StatefulWidget { const ReportsPage({super.key}); @override State<ReportsPage> createState()=>_ReportsPageState(); }
class _ReportsPageState extends State<ReportsPage> {
  DateTimeRange range=DateTimeRange(start:DateTime(DateTime.now().year,DateTime.now().month,1),end:DateTime.now());
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(18,4,18,24),children:[
    const Text('Una vista clara de la operación.',style:TextStyle(color:muted)), const SizedBox(height:15),
    CardPad(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Facturación',style:TextStyle(fontWeight:FontWeight.w800,fontSize:17)),
      const SizedBox(height:5),Text('${dateShort(range.start)} — ${dateShort(range.end)}',style:const TextStyle(color:muted,fontSize:12)),
      const SizedBox(height:10),FutureBuilder<double>(future:db.billedBetween(range.start,range.end.add(const Duration(days:1))),builder:(context,s)=>Text(money(s.data??0),style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900,color:navy))),
      Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()async{final picked=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime.now(),initialDateRange:range);
        if(picked!=null)setState(()=>range=picked);},icon:const Icon(Icons.date_range),label:const Text('Cambiar período'))),
    ])),
    const SizedBox(height:12),SectionTitle('Órdenes por mecánico'),const SizedBox(height:8),
    FutureBuilder<List<QueryRow>>(future:db.mechanicWorkload(),builder:(context,s){if(!s.hasData)return const LoadingCard();return Column(children:s.data!.map((r)=>Padding(padding:const EdgeInsets.only(bottom:8),child:CardPad(child:Row(children:[const Icon(Icons.engineering_outlined,color:blue),const SizedBox(width:10),Expanded(child:Text(r.read<String>('name'),style:const TextStyle(fontWeight:FontWeight.w700))),Text('${r.read<int>('assigned')} abiertas',style:const TextStyle(color:muted)),IconButton(onPressed:()=>renameMechanic(context,r.read<int>('id'),r.read<String>('name'),()async=>setState((){})),icon:const Icon(Icons.edit_outlined,size:18,color:muted),tooltip:'Cambiar nombre')])))).toList());}),
    const SizedBox(height:13),SectionTitle('Saldos pendientes'),const SizedBox(height:8),
    FutureBuilder<List<QueryRow>>(future:db.customerBalances(),builder:(context,s){if(!s.hasData)return const LoadingCard();if(s.data!.isEmpty)return const EmptyCard('No hay saldos pendientes.');return Column(children:s.data!.map((r)=>Padding(padding:const EdgeInsets.only(bottom:8),child:CardPad(child:Row(children:[const Icon(Icons.account_balance_wallet_outlined,color:amber),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(r.read<String>('name'),style:const TextStyle(fontWeight:FontWeight.w700)),Text(r.read<String>('phone'),style:const TextStyle(color:muted,fontSize:12))])),Text(money(r.read<double>('balance')),style:const TextStyle(fontWeight:FontWeight.w800,color:navy))])))).toList());}),
    const SizedBox(height:13),SectionTitle('Repuestos por agotarse'),const SizedBox(height:8),
    FutureBuilder<List<QueryRow>>(future:db.lowStock(),builder:(context,s){if(!s.hasData)return const LoadingCard();if(s.data!.isEmpty)return const EmptyCard('El stock está en buen nivel.');return Column(children:s.data!.map((r)=>Padding(padding:const EdgeInsets.only(bottom:8),child:CardPad(child:Row(children:[const Icon(Icons.warning_amber_rounded,color:amber),const SizedBox(width:10),Expanded(child:Text(r.read<String>('name'),style:const TextStyle(fontWeight:FontWeight.w700))),Text('${r.read<int>('stock')} uds.',style:const TextStyle(color:muted))])))).toList());}),
  ]);
}

class OrderDetailPage extends StatefulWidget { const OrderDetailPage({super.key,required this.orderId}); final int orderId; @override State<OrderDetailPage> createState()=>_OrderDetailPageState(); }
class _OrderDetailPageState extends State<OrderDetailPage> {
  Future<void> refresh() async=>setState((){});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Detalle de orden')),
    body:FutureBuilder<List<QueryRow>>(future:db.orderDetail(widget.orderId),builder:(context,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.data!.isEmpty)return const EmptyCard('La orden no está disponible.');final o=s.data!.first;
      final laborTotal=o.read<double>('labor_total');final partsTotal=o.read<double>('parts_total');final paid=o.read<double>('paid_total');final total=laborTotal+partsTotal;final double remaining=(total-paid).clamp(0,double.infinity).toDouble();
      return ListView(padding:const EdgeInsets.fromLTRB(18,4,18,28),children:[
        CardPad(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('#${o.read<int>('id')} · ${o.read<String>('plate')}',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900,color:navy))),StatusPill(status:o.read<String>('status'))]),
          const SizedBox(height:5),Text('${o.read<String>('make')} ${o.read<String>('model')} · ${o.read<int>('mileage')} km',style:const TextStyle(color:muted)),
          const SizedBox(height:12),const Text('Problema reportado',style:TextStyle(fontWeight:FontWeight.w700,fontSize:12,color:muted)),Text(o.read<String>('issue')),
          const SizedBox(height:12),Text('Cliente: ${o.read<String>('customer')} · ${o.read<String>('phone')}'),Text('Mecánico: ${o.read<String>('mechanic')}'),Text('Ingreso: ${dateShort(DateTime.parse(o.read<String>('entered_at')))}'),
          if(!const ['Entregada','Cancelada'].contains(o.read<String>('status'))) ...[
            const SizedBox(height:14),DropdownButtonFormField<String>(initialValue:o.read<String>('status'),decoration:const InputDecoration(labelText:'Estado de la orden'),items:const ['Recibida','En diagnóstico','En reparación','Lista para entregar','Entregada','Cancelada'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)async{if(v!=null){await db.setStatus(widget.orderId,v);await refresh();}}),
          ]
        ])),
        const SizedBox(height:13),SectionTitle('Mano de obra',action:'Agregar',onTap:()=>addLabor(context,widget.orderId,refresh)),const SizedBox(height:8),
        FutureBuilder<List<QueryRow>>(future:db.labor(widget.orderId),builder:(context,l)=>l.hasData&&l.data!.isNotEmpty?Column(children:l.data!.map((x)=>LineCard(title:x.read<String>('description'),detail:'Mano de obra',value:money(x.read<double>('price')))).toList()):const EmptyCard('Todavía no se agregó trabajo.')),
        const SizedBox(height:13),SectionTitle('Repuestos usados',action:'Agregar',onTap:()=>addPartToOrder(context,widget.orderId,refresh)),const SizedBox(height:8),
        FutureBuilder<List<QueryRow>>(future:db.usedParts(widget.orderId),builder:(context,p)=>p.hasData&&p.data!.isNotEmpty?Column(children:p.data!.map((x)=>LineCard(title:x.read<String>('name'),detail:'${x.read<int>('quantity')} × ${money(x.read<double>('unit_price'))}',value:money(x.read<int>('quantity')*x.read<double>('unit_price')))).toList()):const EmptyCard('Todavía no se agregaron repuestos.')),
        const SizedBox(height:13),CardPad(child:Column(children:[SummaryLine(label:'Mano de obra',value:money(laborTotal)),SummaryLine(label:'Repuestos',value:money(partsTotal)),const Divider(height:20),SummaryLine(label:'Total de la orden',value:money(total),bold:true),SummaryLine(label:'Pagado',value:money(paid)),SummaryLine(label:'Saldo pendiente',value:money(remaining),bold:true)])),
        const SizedBox(height:10),FilledButton.icon(onPressed:remaining<=0?null:()=>addPayment(context,widget.orderId,remaining,refresh),style:FilledButton.styleFrom(backgroundColor:navy,padding:const EdgeInsets.symmetric(vertical:14)),icon:const Icon(Icons.payments_outlined),label:Text(remaining<=0?'Orden saldada':'Registrar pago')),
        const SizedBox(height:11),SectionTitle('Pagos registrados'),const SizedBox(height:8),FutureBuilder<List<QueryRow>>(future:db.payments(widget.orderId),builder:(context,p)=>p.hasData&&p.data!.isNotEmpty?Column(children:p.data!.map((x)=>LineCard(title:money(x.read<double>('amount')),detail:dateShort(DateTime.parse(x.read<String>('paid_at'))),value:'')).toList()):const EmptyCard('Sin pagos registrados.')),
      ]);
    }));
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key,this.customerId,this.vehicleId,required this.title});
  final int? customerId; final int? vehicleId; final String title;
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('Historial · $title')),
    body:FutureBuilder<List<QueryRow>>(future:db.history(customerId:customerId,vehicleId:vehicleId),builder:(context,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.data!.isEmpty)return const EmptyCard('Todavía no hay servicios registrados.');
      return ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount:s.data!.length,separatorBuilder:(_,__) => const SizedBox(height:8),
        itemBuilder:(context,i){final r=s.data![i];
        return InkWell(onTap: () => openOrder(
          context,
          r.read<int>('id'),
          () async {},
        ),child:CardPad(child:Row(children:[const Icon(Icons.receipt_long_outlined,color:blue),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r.read<String>('plate')} · ${r.read<String>('make')} ${r.read<String>('model')}',style:const TextStyle(fontWeight:FontWeight.w800)),Text('${dateShort(DateTime.parse(r.read<String>('entered_at')))} · ${r.read<String>('status')}',style:const TextStyle(color:muted,fontSize:12)),Text(r.read<String>('issue'),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12))])),Text(money(r.read<double>('total')),style:const TextStyle(fontWeight:FontWeight.w800,color:navy))])));});
    }));
}

Future<void> openOrder(BuildContext context,int id,Future<void> Function() refresh) async {
  await Navigator.push(context,MaterialPageRoute(builder:(_)=>OrderDetailPage(orderId:id)));
  await refresh();
}
void openHistory(BuildContext context,{int? customerId,int? vehicleId,required String title})=>Navigator.push(context,MaterialPageRoute(builder:(_)=>HistoryPage(customerId:customerId,vehicleId:vehicleId,title:title)));

Future<void> createOrder(BuildContext context,Future<void> Function() onDone) async {
  final vehicles=await db.vehicles();final mechanics=await db.mechanics();
  if(!context.mounted)return;
  if(vehicles.isEmpty){showNote(context,'Agrega primero un cliente y su vehículo.');return;}
  int vehicleId=vehicles.first.read<int>('id');int mechanicId=mechanics.first.read<int>('id');
  final issue=TextEditingController();final mileage=TextEditingController(text:'${vehicles.first.read<int>('mileage')}');
  final key=GlobalKey<FormState>();
  final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,backgroundColor:bg,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal)=>Padding(
    padding:EdgeInsets.fromLTRB(20,22,20,MediaQuery.of(ctx).viewInsets.bottom+20),child:SingleChildScrollView(child:Form(key:key,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Nueva orden',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:navy)),const SizedBox(height:18),
      DropdownButtonFormField<int>(initialValue:vehicleId,decoration:const InputDecoration(labelText:'Vehículo'),items:vehicles.map((v)=>DropdownMenuItem(value:v.read<int>('id'),child:Text('${v.read<String>('plate')} · ${v.read<String>('customer')}'))).toList(),onChanged:(v){if(v!=null){setModal(()=>vehicleId=v);final selected=vehicles.firstWhere((x)=>x.read<int>('id')==v);mileage.text='${selected.read<int>('mileage')}';}}),
      const SizedBox(height:12),DropdownButtonFormField<int>(initialValue:mechanicId,decoration:const InputDecoration(labelText:'Asignar a'),items:mechanics.map((m)=>DropdownMenuItem(value:m.read<int>('id'),child:Text(m.read<String>('name')))).toList(),onChanged:(v){if(v!=null)setModal(()=>mechanicId=v);}),
      const SizedBox(height:12),
      formField(mileage, 'Kilometraje de ingreso', numeric: true),
      const SizedBox(height: 12),
      formField(issue, 'Problema reportado', maxLines: 3),
      const SizedBox(height:17),
      FilledButton(onPressed:(){if(key.currentState!.validate())Navigator.pop(ctx,true);},style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(50),backgroundColor:navy),child:const Text('Crear orden')),
    ]))))));
  if(ok==true){await db.createOrder(vehicleId:vehicleId,mechanicId:mechanicId,issue:issue.text,mileage:int.parse(mileage.text));await onDone();}
}

Future<void> createCustomer(BuildContext context,Future<void> Function() done) async {
  final name=TextEditingController(),phone=TextEditingController(),address=TextEditingController();
  final ok=await editSheet(context,title:'Nuevo cliente',fields:[('Nombre',name),('Teléfono',phone),('Dirección (opcional)',address)],requiredCount:2);
  if (!ok || !context.mounted) return;

    try {
      await db.saveCustomer(
        name: name.text,
        phone: phone.text,
        address: address.text,
      );
      await done();
      if (context.mounted) showNote(context, 'Cliente guardado.');
    } catch (e) {
      if (context.mounted) {
        showNote(context, 'No se pudo guardar el cliente: $e');
      }
    }
}

Future<void> createVehicle(BuildContext context,Future<void> Function() done) async {
  final customers=await db.customers(); if(!context.mounted)return;
  if(customers.isEmpty){showNote(context,'Agrega primero un cliente.');return;}
  int customerId=customers.first.read<int>('id');final plate=TextEditingController(),make=TextEditingController(),model=TextEditingController(),year=TextEditingController(text:'${DateTime.now().year}'),mileage=TextEditingController(text:'0');final key=GlobalKey<FormState>();
  final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,backgroundColor:bg,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal)=>Padding(padding:EdgeInsets.fromLTRB(20,22,20,MediaQuery.of(ctx).viewInsets.bottom+20),child:SingleChildScrollView(child:Form(key:key,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Agregar vehículo',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:navy)),const SizedBox(height:18),DropdownButtonFormField<int>(initialValue:customerId,decoration:const InputDecoration(labelText:'Cliente'),items:customers.map((c)=>DropdownMenuItem(value:c.read<int>('id'),child:Text(c.read<String>('name')))).toList(),onChanged:(v){if(v!=null)setModal(()=>customerId=v);}),const SizedBox(height:12),formField(plate,'Matrícula'),const SizedBox(height:10),formField(make,'Marca'),const SizedBox(height:10),formField(model,'Modelo'),const SizedBox(height:10),formField(year,'Año',numeric:true),const SizedBox(height:10),formField(mileage,'Kilometraje',numeric:true),const SizedBox(height:16),FilledButton(onPressed:(){if(key.currentState!.validate())Navigator.pop(ctx,true);},style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(50),backgroundColor:navy),child:const Text('Guardar vehículo'))]))))));
  if(ok==true){
    try{
      await db.saveVehicle(customerId:customerId,plate:plate.text,make:make.text,model:model.text,year:int.parse(year.text),mileage:int.parse(mileage.text));await done();
    }    
    catch (e) {
        if (context.mounted) {
          showNote(context, 'No se pudo guardar el vehículo: $e');
        }
    }
  }
}

Future<void> createPart(BuildContext context,Future<void> Function() done) async {
  final name=TextEditingController(),code=TextEditingController(),price=TextEditingController(),stock=TextEditingController(text:'0'),threshold=TextEditingController(text:'3');
  final ok=await editSheet(context,title:'Nuevo repuesto',fields:[('Nombre',name),('Código',code),('Precio de venta',price),('Existencias',stock),('Avisar cuando queden',threshold)],numericLabels:{'Precio de venta','Existencias','Avisar cuando queden'});
  if(ok){try{await db.savePart(name:name.text,code:code.text,price:double.parse(price.text.replaceAll(',','.')),stock:int.parse(stock.text),threshold:int.parse(threshold.text));await done();}catch(_){if(context.mounted)showNote(context,'Verifica los datos y que el código sea único.');}}
}
Future<void> restock(BuildContext context,int id,String name,Future<void> Function() done) async {
  final qty=TextEditingController(text:'1');final value=await showDialog<int>(context:context,builder:(ctx)=>AlertDialog(title:Text('Reponer $name'),content:TextField(controller:qty,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Unidades a ingresar')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,int.tryParse(qty.text)),child:const Text('Reponer'))]));
  if(value!=null&&value>0){await db.restock(id,value);await done();}
}
Future<void> renameMechanic(BuildContext context,int id,String current,Future<void> Function() done) async {
  final name=TextEditingController(text:current);
  final result=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Nombre del mecánico'),content:TextField(controller:name,decoration:const InputDecoration(labelText:'Nombre'),textCapitalization:TextCapitalization.words),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,name.text.trim().isNotEmpty),child:const Text('Guardar'))]));
  if(result==true){await db.renameMechanic(id,name.text);await done();}
}
Future<void> addLabor(BuildContext context,int orderId,Future<void> Function() done) async {
  final desc=TextEditingController(),price=TextEditingController();final ok=await editSheet(context,title:'Agregar mano de obra',fields:[('Trabajo realizado',desc),('Precio',price)],numericLabels:{'Precio'});
  if(ok){try{await db.addLabor(orderId,desc.text,double.parse(price.text.replaceAll(',','.')));await done();}catch(_){if(context.mounted)showNote(context,'Ingresa una descripción y un precio válido.');}}
}
Future<void> addPartToOrder(BuildContext context,int orderId,Future<void> Function() done) async {
  final parts=await db.parts();final available=parts.where((p)=>p.read<int>('stock')>0).toList();if(!context.mounted)return;
  if(available.isEmpty){showNote(context,'No hay repuestos disponibles.');return;}
  int partId=available.first.read<int>('id');final quantity=TextEditingController(text:'1');
  final value=await showDialog<int>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal)=>AlertDialog(title:const Text('Usar repuesto'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<int>(initialValue:partId,decoration:const InputDecoration(labelText:'Repuesto'),items:available.map((p)=>DropdownMenuItem(value:p.read<int>('id'),child:Text('${p.read<String>('name')} · ${p.read<int>('stock')} uds.'))).toList(),onChanged:(v){if(v!=null)setModal(()=>partId=v);}),const SizedBox(height:12),TextField(controller:quantity,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Cantidad'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,int.tryParse(quantity.text)),child:const Text('Agregar'))])));
  if(value!=null){try{await db.consumePart(orderId,partId,value);await done();}catch(e){if(context.mounted)showNote(context,e.toString().replaceFirst('Bad state: ',''));}}
}
Future<void> addPayment(BuildContext context,int orderId,double remaining,Future<void> Function() done) async {
  final amount=TextEditingController(text:remaining.toStringAsFixed(2));final ok=await editSheet(context,title:'Registrar pago',fields:[('Importe',amount)],numericLabels:{'Importe'});
  if(ok){final value=double.tryParse(amount.text.replaceAll(',','.'));if(value==null||value<=0||value>remaining){if(context.mounted)showNote(context,'El importe debe ser mayor que cero y no superar el saldo.');return;}await db.addPayment(orderId,value);await done();}
}

String fieldHint(String label) => switch (label) {
  'Nombre' => 'Ej. Ana Martínez',
  'Teléfono' => 'Número de contacto',
  'Dirección (opcional)' => 'Calle y colonia',
  'Matrícula' => 'Ej. ABC-123',
  'Marca' => 'Ej. Toyota',
  'Modelo' => 'Ej. Corolla',
  'Año' => 'Ej. 2018',
  'Kilometraje' => 'Kilómetros actuales',
  'Kilometraje de ingreso' => 'Kilómetros actuales',
  'Problema reportado' => 'Describe brevemente la falla',
  'Código' => 'Código único del repuesto',
  'Precio de venta' || 'Precio' || 'Importe' => 'Ej. 250.00',
  'Existencias' => 'Unidades disponibles',
  'Avisar cuando queden' => 'Nivel mínimo de stock',
  'Trabajo realizado' => 'Describe el servicio realizado',
  _ => 'Escribe aquí',
};

Widget labeledField({
  required String label,
  required TextEditingController controller,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
        validator: validator,
      ),
    ],
  );
}

Future<bool> editSheet(
  BuildContext context, {
  required String title,
  required List<(String, TextEditingController)> fields,
  int requiredCount = 999,
  Set<String> numericLabels = const {},
}) async {
  final key = GlobalKey<FormState>();

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: bg,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        22,
        20,
        MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
              const SizedBox(height: 18),
              ...fields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                final label = field.$1;
                final numeric = numericLabels.contains(label);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: labeledField(
                    label: label,
                    controller: field.$2,
                    hint: fieldHint(label),
                    keyboardType: numeric
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    validator: (value) {
                      final text = (value ?? '').trim();

                      if (text.isEmpty && index >= requiredCount) return null;
                      if (text.isEmpty) return 'Este campo es obligatorio';

                      if (numeric &&
                          double.tryParse(text.replaceAll(',', '.')) == null) {
                        return 'Ingresa un número válido';
                      }

                      return null;
                    },
                  ),
                );
              }),
              FilledButton(
                onPressed: () {
                  if (key.currentState!.validate()) {
                    Navigator.pop(ctx, true);
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: navy,
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return result == true;
}

Widget formField(
  TextEditingController controller,
  String label, {
  bool numeric = false,
  int maxLines = 1,
}) {
  return labeledField(
    label: label,
    controller: controller,
    hint: fieldHint(label),
    keyboardType: numeric ? TextInputType.number : TextInputType.text,
    maxLines: maxLines,
    validator: (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return 'Campo obligatorio';
      if (numeric && int.tryParse(text) == null) {
        return 'Ingresa un número válido';
      }
      return null;
    },
  );
}

void showNote(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text)),
  );
}

class OrderTile extends StatelessWidget { const OrderTile({super.key,required this.row,required this.onTap}); final QueryRow row;final VoidCallback onTap;
  @override Widget build(BuildContext context){final total=row.read<double>('labor_total')+row.read<double>('parts_total');final paid=row.read<double>('paid_total');return InkWell(onTap:onTap,borderRadius:BorderRadius.circular(18),child:CardPad(child:Row(children:[Container(width:45,height:45,decoration:BoxDecoration(color:paleBlue,borderRadius:BorderRadius.circular(14)),child:const Icon(Icons.directions_car_outlined,color:navy)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('#${row.read<int>('id')} · ${row.read<String>('plate')}',style:const TextStyle(fontWeight:FontWeight.w800))),StatusPill(status:row.read<String>('status'))]),const SizedBox(height:3),Text('${row.read<String>('customer')} · ${row.read<String>('make')} ${row.read<String>('model')}',style:const TextStyle(color:muted,fontSize:12)),Text('${row.read<String>('mechanic')} · ${money((total-paid).clamp(0,double.infinity))} pendiente',style:const TextStyle(fontSize:11,color:muted))])),const Icon(Icons.chevron_right,color:muted)])));}
}

class StatusPill extends StatelessWidget {const StatusPill({super.key,required this.status});final String status;
 @override Widget build(BuildContext context){final color=switch(status){'Entregada'=>const Color(0xFF31845B),'Cancelada'=>const Color(0xFF8B9398),'En reparación'=>const Color(0xFFBD7813),'Lista para entregar'=>const Color(0xFF3584A9),_=>navy};return Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:color.withValues(alpha:.10),borderRadius:BorderRadius.circular(20)),child:Text(status,style:TextStyle(color:color,fontSize:10,fontWeight:FontWeight.w800)));}
}
class CardPad extends StatelessWidget {const CardPad({super.key,required this.child});final Widget child;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:child);}
class SectionTitle extends StatelessWidget {const SectionTitle(this.title,{super.key,this.action,this.onTap});final String title;final String? action;final VoidCallback? onTap;@override Widget build(BuildContext context)=>Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:ink))),if(action!=null)TextButton(onPressed:onTap,child:Text(action!))]);}
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return CardPad(
      child: SizedBox(
        height: 64,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: muted, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: navy),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: wide ? 22 : 21,
                      fontWeight: FontWeight.w900,
                      color: navy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class LoadingCard extends StatelessWidget {const LoadingCard({super.key});@override Widget build(BuildContext context)=>const CardPad(child:SizedBox(height:35,child:Center(child:LinearProgressIndicator())));}
class EmptyCard extends StatelessWidget {const EmptyCard(this.text,{super.key});final String text;@override Widget build(BuildContext context)=>CardPad(child:Center(child:Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Text(text,textAlign:TextAlign.center,style:const TextStyle(color:muted)))));}
class LineCard extends StatelessWidget {const LineCard({super.key,required this.title,required this.detail,required this.value});final String title,detail,value;@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:7),child:CardPad(child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),Text(detail,style:const TextStyle(color:muted,fontSize:11))])),Text(value,style:const TextStyle(fontWeight:FontWeight.w800,color:navy))])));}
class SummaryLine extends StatelessWidget {const SummaryLine({super.key,required this.label,required this.value,this.bold=false});final String label,value;final bool bold;@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(children:[Expanded(child:Text(label,style:TextStyle(color:bold?ink:muted,fontWeight:bold?FontWeight.w800:FontWeight.normal))),Text(value,style:TextStyle(color:navy,fontWeight:bold?FontWeight.w900:FontWeight.w600,fontSize:bold?16:14))]));}

String money(num value)=>'\$${value.toStringAsFixed(2)}';
String dateShort(DateTime date)=>'${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}';
