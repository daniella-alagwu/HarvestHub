import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../data/models/admin_profile.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/logout.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static const routeName = '/admin';

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _repository = AdminRepository();
  bool _redirecting = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminProfile?>(
      stream: _repository.watchCurrentAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingView();
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load Admin access. Check the Admin profile and '
                  'Firestore rules.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final profile = snapshot.data;
        if (profile == null) {
          _redirectToLogin();
          return const _LoadingView();
        }
        return _AdminWorkspace(profile: profile, repository: _repository);
      },
    );
  }

  void _redirectToLogin() {
    if (_redirecting || !mounted) return;
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    });
  }
}

class _AdminWorkspace extends StatefulWidget {
  const _AdminWorkspace({required this.profile, required this.repository});

  final AdminProfile profile;
  final AdminRepository repository;

  @override
  State<_AdminWorkspace> createState() => _AdminWorkspaceState();
}

class _AdminWorkspaceState extends State<_AdminWorkspace> {
  String _section = 'overview';
  String _peopleType = 'customers';
  String _catalogType = 'products';
  String _operationsType = 'orders';
  String _controlType = 'approvals';
  String _contentType = 'about';
  String _auditFilter = '';
  DateTimeRange? _auditDateRange;
  String _peopleQuery = '';
  String _catalogQuery = '';
  String _orderStatusFilter = 'all';
  late Stream<Map<String, dynamic>> _reportStream;

  bool get _isSuperAdmin => widget.profile.isSuperAdmin;
  bool _can(String permission) => widget.profile.can(permission);

  @override
  void initState() {
    super.initState();
    if (!_can(AdminPermissions.customers)) {
      _peopleType = 'farmers';
    }
    if (!_can(AdminPermissions.products)) _catalogType = 'categories';
    if (!_can(AdminPermissions.categories)) _catalogType = 'products';
    if (!_can(AdminPermissions.orders)) {
      _operationsType = _can(AdminPermissions.markets) ? 'markets' : 'reports';
    }
    _reportStream = _can(AdminPermissions.reports)
        ? widget.repository.watchDashboardReport()
        : const Stream<Map<String, dynamic>>.empty();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 820;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.deepGreen,
          elevation: 0,
          title: Row(children: [
            if (wide)
              Image.asset('assets/splash_screen/logo_full_combined.png',
                  width: 112,
                  height: 30,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft),
            if (wide) const SizedBox(width: 18),
            Expanded(
                child: Text(_title,
                    style: AppTextStyles.headingMedium
                        .copyWith(color: AppColors.deepGreen))),
            if (_isSuperAdmin) _levelBadge('SUPER ADMIN'),
          ]),
          actions: const [LogoutButton(), SizedBox(width: 8)],
        ),
        drawer: wide ? null : Drawer(child: _drawer()),
        body: Row(children: [
          if (wide) SizedBox(width: 220, child: _sideNavigation()),
          Expanded(child: _buildSection(wide)),
        ]),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _bottomIndex,
                onDestinationSelected: _selectBottom,
                destinations: [
                  for (final item in _bottomSections)
                    NavigationDestination(
                      icon: Icon(item.$3),
                      label: item.$2,
                    ),
                ],
              ),
      );
    });
  }

  String get _title => switch (_section) {
        'people' => 'People',
        'catalog' => 'Catalog',
        'operations' => 'Operations',
        'content' => 'Content & feedback',
        'control' => 'Super Admin controls',
        _ => 'Marketplace overview',
      };

  List<(String, String, IconData)> get _bottomSections => [
        ('overview', 'Overview', Icons.dashboard_outlined),
        if (_can(AdminPermissions.customers) || _can(AdminPermissions.farmers))
          ('people', 'People', Icons.people_outline),
        if (_can(AdminPermissions.products) ||
            _can(AdminPermissions.categories))
          ('catalog', 'Catalog', Icons.inventory_2_outlined),
        if (_can(AdminPermissions.orders) ||
            _can(AdminPermissions.markets) ||
            _can(AdminPermissions.reports))
          ('operations', 'Operations', Icons.receipt_long_outlined),
        if (_isSuperAdmin) ('control', 'Control', Icons.shield_outlined),
      ];

  int get _bottomIndex {
    final index = _bottomSections.indexWhere((item) => item.$1 == _section);
    return index < 0 ? 0 : index;
  }

  void _selectBottom(int index) {
    setState(() => _section = _bottomSections[index].$1);
  }

  List<(String, String, IconData)> get _sections => [
        ('overview', 'Overview', Icons.dashboard_outlined),
        if (_can(AdminPermissions.customers) || _can(AdminPermissions.farmers))
          ('people', 'Customers & farmers', Icons.people_outline),
        if (_can(AdminPermissions.products) ||
            _can(AdminPermissions.categories))
          ('catalog', 'Products & categories', Icons.inventory_2_outlined),
        if (_can(AdminPermissions.orders) ||
            _can(AdminPermissions.markets) ||
            _can(AdminPermissions.reports))
          (
            'operations',
            'Orders, markets & reports',
            Icons.receipt_long_outlined
          ),
        if (_can(AdminPermissions.content))
          ('content', 'About, contact & feedback', Icons.article_outlined),
        if (_isSuperAdmin)
          ('control', 'Super Admin controls', Icons.shield_outlined),
      ];

  Widget _sideNavigation() => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 18),
            child: Text(
                widget.profile.name.isEmpty
                    ? 'Administrator'
                    : widget.profile.name,
                style: AppTextStyles.bodyRegular
                    .copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ),
          for (final item in _sections) _navigationTile(item),
        ]),
      );

  Widget _drawer() => SafeArea(
        child: Container(
          color: AppColors.deepGreen,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.all(22),
              child: Image.asset('assets/splash_screen/logo_full_combined.png',
                  height: 38, fit: BoxFit.contain),
            ),
            for (final item in _sections) _navigationTile(item, drawer: true),
          ]),
        ),
      );

  Widget _navigationTile((String, String, IconData) item,
      {bool drawer = false}) {
    final selected = _section == item.$1;
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor:
          drawer ? Colors.white.withValues(alpha: 0.14) : AppColors.softGreen,
      leading: Icon(item.$3,
          color: drawer ? Colors.white : AppColors.deepGreen, size: 20),
      title: Text(item.$2,
          style: AppTextStyles.bodyRegular.copyWith(
              color: drawer ? Colors.white : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
      onTap: () {
        setState(() => _section = item.$1);
        if (drawer) Navigator.pop(context);
      },
    );
  }

  Widget _buildSection(bool wide) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 12, wide ? 28 : 16, 28),
        child: !_sections.any((item) => item.$1 == _section)
            ? _overviewPage()
            : switch (_section) {
                'people' => _peoplePage(),
                'catalog' => _catalogPage(),
                'operations' => _operationsPage(),
                'content' => _contentPage(),
                'control' => _controlPage(),
                _ => _overviewPage(),
              },
      );

  Widget _overviewPage() {
    final canSeeAccounts = _can(AdminPermissions.customers) ||
        _can(AdminPermissions.farmers);
    final canSeeReports = _can(AdminPermissions.reports);

    if (!canSeeAccounts && !canSeeReports) {
      return _empty('Your Admin account has no overview permissions.');
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (canSeeReports) _reportCards(),
      if (canSeeAccounts) ...[
        if (canSeeReports) const SizedBox(height: 20),
        _heading('Marketplace activity', 'Live Firebase data'),
        Card(
            child: Column(children: [
          if (_can(AdminPermissions.customers))
            _summaryStream(
                'Registered customers', 'customer', Icons.person_outline),
          if (_can(AdminPermissions.farmers))
            _summaryStream(
                'Registered farmers', 'farmer', Icons.agriculture_outlined),
        ])),
      ],
      if (canSeeReports) ...[
        const SizedBox(height: 20),
        _heading('Revenue by market', 'SRS report'),
        _revenueByMarket(),
        const SizedBox(height: 20),
        _heading('Most active farmers', null),
        _activeFarmersReport(),
      ],
    ]);
  }

  Widget _reportCards() => StreamBuilder<Map<String, dynamic>>(
        stream: _reportStream,
        builder: (context, snapshot) {
          final report = snapshot.data ?? const <String, dynamic>{};
          final hasReport = snapshot.hasData;
          final metrics = [
            (
              'Total orders',
              hasReport ? '${report['total_orders'] ?? 0}' : '—',
              Icons.receipt_long_outlined,
              AppColors.mainGreen
            ),
            (
              'Revenue',
              hasReport ? _money(report['revenue']) : '—',
              Icons.payments_outlined,
              AppColors.autumnRust
            ),
            (
              'Farmer profiles',
              hasReport ? '${report['active_farmers'] ?? 0}' : '—',
              Icons.agriculture_outlined,
              AppColors.deepGreen
            ),
            (
              'Products',
              hasReport ? '${report['products'] ?? 0}' : '—',
              Icons.eco_outlined,
              AppColors.wheatGold
            ),
          ];
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot.hasError)
                  _errorBanner(
                      'Could not load platform report: ${snapshot.error}'),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(color: AppColors.mainGreen),
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050
                      ? 4
                      : constraints.maxWidth >= 700
                          ? 3
                          : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 128,
                    children: [
                      for (final metric in metrics)
                        _metric(metric.$1, metric.$2, metric.$3, metric.$4)
                    ],
                  );
                }),
              ]);
        },
      );

  Widget _metric(String label, String value, IconData icon, Color color) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: AppTextStyles.headingMedium
                            .copyWith(fontSize: 21)),
                  ),
                ),
                Text(label, style: AppTextStyles.bodyMuted),
              ]),
        ),
      );

  Widget _summaryStream(String label, String role, IconData icon) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.repository.watchUsers(role: role),
        builder: (context, snapshot) => ListTile(
          leading: Icon(icon, color: AppColors.mainGreen),
          title: Text(label, style: AppTextStyles.bodyRegular),
          subtitle: snapshot.hasError
              ? const Text('Could not load account count.')
              : const Text('Live total from Firebase'),
          trailing: snapshot.hasError
              ? const Icon(Icons.error_outline, color: AppColors.error)
              : snapshot.connectionState == ConnectionState.waiting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('${snapshot.data?.length ?? 0}',
                      style: AppTextStyles.headingMedium),
        ),
      );

  Widget _revenueByMarket() => StreamBuilder<Map<String, dynamic>>(
        stream: _reportStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorBanner(
                'Could not load revenue data: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const LinearProgressIndicator(color: AppColors.mainGreen);
          }
          final values =
              snapshot.data?['revenue_by_market'] as Map<String, double>? ??
                  const {};
          if (values.isEmpty) return _empty('No market revenue recorded yet.');
          return Card(
              child: Column(children: [
            for (final entry in values.entries)
              ListTile(
                  title: Text(entry.key),
                  trailing: Text(_money(entry.value),
                      style: AppTextStyles.bodyRegular
                          .copyWith(fontWeight: FontWeight.w700)))
          ]));
        },
      );

  Widget _activeFarmersReport() => StreamBuilder<Map<String, dynamic>>(
        stream: _reportStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorBanner(
                'Could not load farmer activity: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const LinearProgressIndicator(color: AppColors.mainGreen);
          }
          final rows =
              snapshot.data?['most_active_farmers'] as List<dynamic>? ??
                  const [];
          if (rows.isEmpty) {
            return _empty('No farmer orders are recorded in Firebase yet.');
          }
          return Card(
              child: Column(children: [
            for (final row in rows)
              ListTile(
                  leading: const Icon(Icons.agriculture_outlined,
                      color: AppColors.mainGreen),
                  title: Text(row['name'] as String),
                  trailing: Text('${row['orders']} orders'))
          ]));
        },
      );

  Widget _peoplePage() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tabs([
          if (_can(AdminPermissions.customers)) 'Customers',
          if (_can(AdminPermissions.farmers)) 'Farmers',
        ], _peopleType, (value) => setState(() => _peopleType = value)),
        const SizedBox(height: 12),
        _searchField('Search ${_peopleType.toLowerCase()}',
            (value) => setState(() => _peopleQuery = value)),
        const SizedBox(height: 12),
        if (_peopleType == 'customers' && _can(AdminPermissions.customers))
          _customers()
        else if (_can(AdminPermissions.farmers))
          _farmers(),
      ]);

  Widget _customers() => StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.repository.watchUsers(role: 'customer'),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorBanner('Could not load customers. ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const LinearProgressIndicator(color: AppColors.mainGreen);
          }
          final users = (snapshot.data ?? const [])
              .where((user) =>
                  '${user['name']} ${user['email']} ${user['phone']} ${user['address']}'
                      .toLowerCase()
                      .contains(_peopleQuery.toLowerCase()))
              .toList();
          if (users.isEmpty) {
            return _empty(_peopleQuery.trim().isEmpty
                ? 'No customer accounts found.'
                : 'No customers match your search.');
          }
          return Card(
              child: Column(children: [
            for (final user in users) _personTile(user, farmer: false)
          ]));
        },
      );

  Widget _farmers() => StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.repository.watchFarmers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorBanner('Could not load farmers. ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const LinearProgressIndicator(color: AppColors.mainGreen);
          }
          final farmers = (snapshot.data ?? const [])
              .where((farmer) =>
                  '${farmer['business_name']} ${farmer['name']} ${farmer['email']} ${farmer['market_location']}'
                      .toLowerCase()
                      .contains(_peopleQuery.toLowerCase()))
              .toList();
          if (farmers.isEmpty) {
            return _empty(_peopleQuery.trim().isEmpty
                ? 'No farmer accounts found.'
                : 'No farmers match your search.');
          }
          return Card(
              child: Column(children: [
            for (final farmer in farmers) _personTile(farmer, farmer: true)
          ]));
        },
      );

  Widget _personTile(Map<String, dynamic> person, {required bool farmer}) =>
      ListTile(
        leading: CircleAvatar(
            backgroundColor: AppColors.softGreen,
            child: Icon(
                farmer ? Icons.agriculture_outlined : Icons.person_outline,
                color: AppColors.deepGreen)),
        title: Text(
            (farmer ? person['business_name'] : person['name'])
                        ?.toString()
                        .isNotEmpty ==
                    true
                ? (farmer ? person['business_name'] : person['name']).toString()
                : 'Unnamed ${farmer ? 'farmer' : 'customer'}',
            style: AppTextStyles.bodyRegular
                .copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '${person['email'] ?? person['market_location'] ?? ''} · ${person['approval_status'] ?? (person['active_status'] == false ? 'Disabled' : 'Active')}'),
        trailing: !widget.profile.can(
                farmer ? AdminPermissions.farmers : AdminPermissions.customers)
            ? null
            : PopupMenuButton<String>(
                onSelected: (action) async {
                  try {
                    if (farmer && action == 'edit') {
                      await _editFarmer(person);
                    } else if (farmer && action == 'approve') {
                      await widget.repository.setFarmerApproval(
                          farmerId: person['id'] as String,
                          userId: person['user_id'] as String,
                          status: 'approved');
                    } else if (farmer && action == 'reject') {
                      await widget.repository.setFarmerApproval(
                          farmerId: person['id'] as String,
                          userId: person['user_id'] as String,
                          status: 'rejected');
                    } else if (farmer && action == 'toggle') {
                      await _togglePersonActive(person, farmer: true);
                    } else if (!farmer && action == 'edit') {
                      await _editCustomer(person);
                    } else if (!farmer && action == 'toggle') {
                      await _togglePersonActive(person, farmer: false);
                    }
                  } catch (error) {
                    _showError(error);
                  }
                },
                itemBuilder: (_) => farmer
                    ? [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit farmer')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(person['active_status'] == false
                              ? 'Reactivate account'
                              : 'Deactivate account'),
                        ),
                        const PopupMenuItem(
                            value: 'approve', child: Text('Approve farmer')),
                        const PopupMenuItem(
                            value: 'reject', child: Text('Reject farmer')),
                      ]
                    : [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit profile')),
                        PopupMenuItem(
                            value: 'toggle',
                            child: Text(person['active_status'] == false
                                ? 'Reactivate account'
                                : 'Deactivate account')),
                      ],
              ),
      );

  Future<void> _togglePersonActive(
    Map<String, dynamic> person, {
    required bool farmer,
  }) async {
    final isActive = person['active_status'] != false;
    final accountName = farmer
        ? (person['business_name'] as String? ?? 'this farmer account')
        : (person['name'] as String? ?? 'this customer account');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isActive ? 'Deactivate account?' : 'Reactivate account?'),
        content: Text(isActive
            ? 'Deactivate $accountName? The account data will be retained.'
            : 'Allow $accountName to use the app again?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isActive ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = farmer ? person['user_id'] as String : person['id'] as String;
    await widget.repository.updateUser(
      uid: uid,
      changes: {'active_status': !isActive},
      action: '${farmer ? 'farmer' : 'customer'}.${isActive ? 'disabled' : 'enabled'}',
    );
    _showMessage(isActive ? 'Account deactivated.' : 'Account reactivated.');
  }

  Future<void> _editCustomer(Map<String, dynamic> customer) async {
    final name = TextEditingController(text: customer['name'] as String? ?? '');
    final phone =
        TextEditingController(text: customer['phone'] as String? ?? '');
    final address =
        TextEditingController(text: customer['address'] as String? ?? '');
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit customer'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: _required),
            TextFormField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Phone')),
            TextFormField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, formKey.currentState!.validate()),
              child: const Text('Save')),
        ],
      ),
    );
    if (save != true) return;
    try {
      await widget.repository.editCustomer(
        uid: customer['id'] as String,
        name: name.text,
        phone: phone.text,
        address: address.text,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editFarmer(Map<String, dynamic> farmer) async {
    final name = TextEditingController(text: farmer['name'] as String? ?? '');
    final business =
        TextEditingController(text: farmer['business_name'] as String? ?? '');
    final market =
        TextEditingController(text: farmer['market_location'] as String? ?? '');
    final description =
        TextEditingController(text: farmer['description'] as String? ?? '');
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit farmer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Owner name'),
                validator: _required),
            TextFormField(
                controller: business,
                decoration: const InputDecoration(labelText: 'Business name'),
                validator: _required),
            TextFormField(
                controller: market,
                decoration:
                    const InputDecoration(labelText: 'Market/location')),
            TextFormField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4),
          ])),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, formKey.currentState!.validate()),
              child: const Text('Save')),
        ],
      ),
    );
    if (save != true) return;
    try {
      await widget.repository.editFarmer(
        farmerId: farmer['id'] as String,
        userId: farmer['user_id'] as String,
        name: name.text,
        businessName: business.text,
        marketLocation: market.text,
        description: description.text,
      );
    } catch (error) {
      _showError(error);
    }
  }

  AlertDialog _adminFormDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget content,
    required List<Widget> actions,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.softGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.deepGreen, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(fontSize: 20),
          ),
        ),
      ]),
      content: SizedBox(
        width: screenWidth < 560 ? screenWidth - 88 : 472,
        child: content,
      ),
      actions: actions,
    );
  }

  Future<void> _createProduct() async {
    final formKey = GlobalKey<FormState>();
    final item = TextEditingController();
    final category = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController();
    String? selectedFarmer;
    String selectedFarmerName = '';
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.repository.watchFarmers(),
        builder: (context, farmerSnapshot) {
          final farmers =
              (farmerSnapshot.data ?? const <Map<String, dynamic>>[])
                  .where((farmer) =>
                      farmer['approval_status'] == 'approved' &&
                      farmer['active_status'] != false)
                  .toList();
          return StatefulBuilder(
              builder: (context, setDialogState) => _adminFormDialog(
                    context: dialogContext,
                    title: 'Add product',
                    icon: Icons.inventory_2_outlined,
                    content: Form(
                      key: formKey,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextFormField(
                            controller: item,
                            decoration: const InputDecoration(
                              labelText: 'Product name',
                              prefixIcon: Icon(Icons.eco_outlined),
                            ),
                            validator: _required),
                        TextFormField(
                            controller: category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            validator: _required),
                        TextFormField(
                            controller: price,
                            decoration: const InputDecoration(
                              labelText: 'Price per item',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              final parsed = double.tryParse(value ?? '');
                              return parsed == null || parsed <= 0
                                  ? 'Enter a price greater than zero'
                                  : null;
                            }),
                        TextFormField(
                            controller: stock,
                            decoration: const InputDecoration(
                              labelText: 'Stock quantity',
                              prefixIcon: Icon(Icons.inventory_outlined),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final parsed = int.tryParse(value ?? '');
                              return parsed == null || parsed < 0
                                  ? 'Enter zero or a positive whole number'
                                  : null;
                            }),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedFarmer,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Farmer',
                            prefixIcon: const Icon(Icons.agriculture_outlined),
                            helperText: farmerSnapshot.connectionState ==
                                    ConnectionState.waiting
                                ? 'Loading farmers…'
                                : farmerSnapshot.hasError
                                    ? 'Could not load the farmer list.'
                                    : farmers.isEmpty
                                        ? 'No approved, active farmers are available.'
                                        : 'Only approved, active farmers appear.',
                          ),
                          items: [
                            for (final farmer in farmers)
                              DropdownMenuItem(
                                  value: farmer['id'] as String,
                                  child: Text(
                                      farmer['business_name'] as String? ??
                                          'Farmer'))
                          ],
                          onChanged: (value) => setDialogState(() {
                            selectedFarmer = value;
                            selectedFarmerName = farmers
                                    .where((farmer) => farmer['id'] == value)
                                    .firstOrNull?['business_name'] as String? ??
                                '';
                          }),
                          validator: (value) =>
                              value == null ? 'Select a farmer' : null,
                        ),
                      ]),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: farmerSnapshot.hasError ||
                                  farmerSnapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  farmers.isEmpty
                              ? null
                              : () {
                                  if (formKey.currentState!.validate()) {
                                    Navigator.pop(dialogContext, true);
                                  }
                                },
                          child: const Text('Add product')),
                    ],
                  ));
        },
      ),
    );
    if (created != true || selectedFarmer == null) return;
    try {
      await widget.repository.createProduct(
        farmerId: selectedFarmer!,
        farmerName: selectedFarmerName,
        itemName: item.text,
        category: category.text,
        price: double.parse(price.text),
        stock: int.parse(stock.text),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Widget _catalogPage() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tabs([
          if (_can(AdminPermissions.products)) 'Products',
          if (_can(AdminPermissions.categories)) 'Categories',
        ], _catalogType, (value) => setState(() => _catalogType = value)),
        const SizedBox(height: 12),
        if (_catalogType == 'products' && _can(AdminPermissions.products))
          _products()
        else if (_can(AdminPermissions.categories))
          _categoryList(),
      ]);

  Widget _products() => StreamBuilder<List<Product>>(
        stream: widget.repository.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorBanner('Could not load products. ${snapshot.error}');
          }
          final products = (snapshot.data ?? const <Product>[])
              .where((product) =>
                  '${product.itemName} ${product.category ?? ''} ${product.farmerName}'
                      .toLowerCase()
                      .contains(_catalogQuery.toLowerCase()))
              .toList();
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                      child: _searchField('Search products',
                          (value) => setState(() => _catalogQuery = value))),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                      onPressed: _createProduct,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add')),
                ]),
                const SizedBox(height: 10),
                if (products.isEmpty)
                  _empty('No products found.')
                else
                  Card(
                    child: Column(children: [
                  for (final product in products)
                    ListTile(
                      leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: AppColors.softGreen,
                              borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.eco_outlined,
                              color: AppColors.mainGreen)),
                      title: Text(product.itemName,
                          style: AppTextStyles.bodyRegular
                              .copyWith(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${product.category ?? 'Uncategorized'} · ${product.stockQty} in stock · ${_money(product.pricePerUnit)}'),
                      trailing: !_can(AdminPermissions.products)
                          ? null
                          : PopupMenuButton<String>(
                              onSelected: (action) async {
                                if (action == 'edit') {
                                  await _editProduct(product);
                                }
                                if (action == 'delete') {
                                  await _confirmDelete(
                                      'Remove ${product.itemName}?',
                                      () => widget.repository
                                          .deleteProduct(product.id));
                                }
                              },
                              itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit price and stock')),
                                    PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Remove product'))
                                  ]),
                    )
                ])),
              ]);
        },
      );

  Future<void> _editProduct(Product product) async {
    final price = TextEditingController(text: product.pricePerUnit.toString());
    final stock = TextEditingController(text: product.stockQty.toString());
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Edit ${product.itemName}'),
              content: Form(
                  key: formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextFormField(
                        controller: price,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: _required),
                    TextFormField(
                        controller: stock,
                        decoration:
                            const InputDecoration(labelText: 'Stock quantity'),
                        keyboardType: TextInputType.number,
                        validator: _required)
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(
                        context, formKey.currentState!.validate()),
                    child: const Text('Save'))
              ],
            ));
    if (save != true) return;
    try {
      await widget.repository.updateProduct(
          product: product,
          price: double.parse(price.text),
          stock: int.parse(stock.text));
    } catch (error) {
      _showError(error);
    }
  }

  Widget _categoryList() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_can(AdminPermissions.categories))
          Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                  onPressed: () => _editCategory(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add category'))),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.repository.watchCategories(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _errorBanner(
                    'Could not load categories. ${snapshot.error}');
              }
              final categories = snapshot.data ?? const [];
              if (categories.isEmpty) {
                return _empty('No categories have been created.');
              }
              return Card(
                  child: Column(children: [
                for (final category in categories)
                  ListTile(
                      title: Text(
                          category['name'] as String? ?? 'Unnamed category'),
                      trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await _editCategory(
                                  id: category['id'] as String,
                                  name: category['name'] as String? ?? '');
                            }
                            if (value == 'delete') {
                              await _confirmDelete(
                                  'Delete ${category['name']}?',
                                  () => widget.repository.deleteCategory(
                                      category['id'] as String));
                            }
                          },
                          itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Delete'))
                              ]))
              ]));
            }),
      ]);

  Future<void> _editCategory({String? id, String name = ''}) async {
    final controller = TextEditingController(text: name);
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _adminFormDialog(
        context: dialogContext,
        title: id == null ? 'Add category' : 'Edit category',
        icon: Icons.category_outlined,
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category name',
              prefixIcon: Icon(Icons.sell_outlined),
              hintText: 'For example, Vegetables',
            ),
            validator: _required,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            icon: Icon(id == null ? Icons.add_rounded : Icons.save_outlined),
            label: Text(id == null ? 'Add category' : 'Save changes'),
          ),
        ],
      ),
    );
    if (save != true) return;
    try {
      await widget.repository.saveCategory(id: id, name: controller.text);
    } catch (error) {
      _showError(error);
    }
  }

  Widget _operationsPage() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tabs([
          if (_can(AdminPermissions.orders)) 'Orders',
          if (_can(AdminPermissions.markets)) 'Markets',
          if (_can(AdminPermissions.reports)) 'Reports',
        ], _operationsType,
            (value) => setState(() => _operationsType = value.toLowerCase())),
        const SizedBox(height: 12),
        switch (_operationsType) {
          'markets' when _can(AdminPermissions.markets) => _markets(),
          'reports' when _can(AdminPermissions.reports) => _reports(),
          'orders' when _can(AdminPermissions.orders) => _orders(),
          _ =>
            _empty('No operations permissions are assigned to this account.'),
        },
      ]);

  Widget _orders() => StreamBuilder<List<Order>>(
        stream: widget.repository.watchOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorBanner('Could not load orders. ${snapshot.error}');
          }
          final orders = (snapshot.data ?? const <Order>[])
              .where((order) =>
                  _orderStatusFilter == 'all' ||
                  order.status.toLowerCase() == _orderStatusFilter)
              .toList();
          if (orders.isEmpty) return _empty('No orders found.');
          return Column(children: [
            DropdownButtonFormField<String>(
              initialValue: _orderStatusFilter,
              decoration: const InputDecoration(
                  labelText: 'Filter by status', isDense: true),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All orders')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                DropdownMenuItem(
                    value: 'ready for pickup', child: Text('Ready for Pickup')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) =>
                  setState(() => _orderStatusFilter = value ?? 'all'),
            ),
            const SizedBox(height: 10),
            Card(
                child: Column(children: [
              for (final order in orders)
                ListTile(
                  leading: Text(order.title,
                      style: AppTextStyles.bodyRegular.copyWith(
                          color: AppColors.deepGreen,
                          fontWeight: FontWeight.w700)),
                  title: Text(order.itemsSummary,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${order.status} · ${_money(order.total)}'),
                  trailing: PopupMenuButton<String>(
                      onSelected: (status) async {
                        try {
                          await widget.repository.updateOrderStatus(
                              orderId: order.id, status: status);
                        } catch (error) {
                          _showError(error);
                        }
                      },
                      itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'Pending', child: Text('Pending')),
                            PopupMenuItem(
                                value: 'Confirmed', child: Text('Confirm')),
                            PopupMenuItem(
                                value: 'Ready for Pickup',
                                child: Text('Ready for pickup')),
                            PopupMenuItem(
                                value: 'Completed', child: Text('Complete')),
                            PopupMenuItem(
                                value: 'Cancelled', child: Text('Cancel order'))
                          ]),
                )
            ])),
          ]);
        },
      );

  Widget _markets() => StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.repository.watchMarkets(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorBanner('Could not load markets. ${snapshot.error}');
        }
        final markets = snapshot.data ?? const [];
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                      onPressed: () => _editMarket(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add market'))),
              const SizedBox(height: 10),
              if (markets.isEmpty)
                _empty('No markets found.')
              else
                Card(
                    child: Column(children: [
                  for (final market in markets)
                    ListTile(
                        title:
                            Text(market['market_name'] as String? ?? 'Market'),
                        subtitle: Text(market['address'] as String? ?? ''),
                        trailing: PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'edit') {
                                await _editMarket(
                                    id: market['id'] as String,
                                    name:
                                        market['market_name'] as String? ?? '',
                                    address:
                                        market['address'] as String? ?? '',
                                    pickupSlots:
                                        _marketSlots(market['pickup_slots']));
                              }
                              if (action == 'delete') {
                                await _confirmDelete(
                                    'Remove this market?',
                                    () => widget.repository
                                        .deleteMarket(market['id'] as String));
                              }
                            },
                            itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Delete'))
                                ]))
                ]))
            ]);
      });

  List<Map<String, dynamic>> _marketSlots(Object? rawSlots) {
    if (rawSlots is! List) return const [];
    return rawSlots.map((slot) {
      if (slot is Map) {
        return <String, dynamic>{
          'label': slot['label']?.toString() ?? '',
          'is_available': slot['is_available'] is bool
              ? slot['is_available'] as bool
              : slot['isAvailable'] is bool
                  ? slot['isAvailable'] as bool
                  : true,
        };
      }
      return <String, dynamic>{'label': slot.toString(), 'is_available': true};
    }).where((slot) => (slot['label'] as String).trim().isNotEmpty).toList();
  }

  Future<void> _editMarket({
    String? id,
    String name = '',
    String address = '',
    List<Map<String, dynamic>> pickupSlots = const [],
  }) async {
    final nameController = TextEditingController(text: name);
    final addressController = TextEditingController(text: address);
    final slotsController = TextEditingController(
        text: pickupSlots.map((slot) => slot['label']).join('\n'));
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _adminFormDialog(
        context: dialogContext,
        title: id == null ? 'Add market' : 'Edit market',
        icon: Icons.storefront_outlined,
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Market name',
                prefixIcon: Icon(Icons.store_outlined),
              ),
              validator: _required,
            ),
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: _required,
            ),
            TextFormField(
              controller: slotsController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Pickup slots',
                prefixIcon: Icon(Icons.schedule_outlined),
                helperText: 'Enter one pickup slot per line',
                alignLabelWithHint: true,
              ),
              validator: _required,
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            icon: Icon(id == null ? Icons.add_rounded : Icons.save_outlined),
            label: Text(id == null ? 'Add market' : 'Save changes'),
          ),
        ],
      ),
    );
    if (save != true) return;
    final oldAvailability = {
      for (final slot in pickupSlots)
        (slot['label'] as String).trim(): slot['is_available'] == true,
    };
    final updatedSlots = slotsController.text
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .map((label) => <String, dynamic>{
              'label': label,
              'is_available': oldAvailability[label] ?? true,
            })
        .toList();
    try {
      await widget.repository.saveMarket(
          marketId: id,
          name: nameController.text,
          address: addressController.text,
          pickupSlots: updatedSlots,
          active: true);
    } catch (error) {
      _showError(error);
    }
  }

  Widget _reports() => _can(AdminPermissions.reports)
      ? _reportCards()
      : _empty('Reports permission is required.');

  Widget _contentPage() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tabs(['About Us', 'Contact Us', 'Feedback'], _contentType,
              (value) => setState(() => _contentType = value)),
          const SizedBox(height: 12),
          if (_contentType == 'about')
            _editableContent('about')
          else if (_contentType == 'contact')
            _editableContent('contact')
          else
            _feedbackList(),
        ],
      );

  Widget _editableContent(String pageId) => StreamBuilder<Map<String, dynamic>>(
        stream: widget.repository.watchContent(pageId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorBanner(
                'Could not load page content: ${snapshot.error}');
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          final fields = pageId == 'about'
              ? const [('purpose', 'Purpose'), ('objectives', 'Objectives')]
              : const [
                  ('email', 'Email address'),
                  ('phone', 'Phone number'),
                  ('office_address', 'Office address'),
                  ('feedback_prompt', 'Feedback form prompt'),
                ];
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _editContent(pageId, fields, data),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit content'),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(children: [
                    for (final field in fields)
                      ListTile(
                        title: Text(field.$2),
                        subtitle: Text(data[field.$1] as String? ?? 'Not set'),
                      ),
                  ]),
                ),
              ]);
        },
      );

  Future<void> _editContent(
    String pageId,
    List<(String, String)> fields,
    Map<String, dynamic> current,
  ) async {
    final controllers = <String, TextEditingController>{
      for (final field in fields)
        field.$1:
            TextEditingController(text: current[field.$1] as String? ?? ''),
    };
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(pageId == 'about' ? 'Edit About Us' : 'Edit Contact Us'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final field in fields)
                TextFormField(
                  controller: controllers[field.$1],
                  decoration: InputDecoration(labelText: field.$2),
                  minLines: field.$1 == 'purpose' ||
                          field.$1 == 'objectives' ||
                          field.$1 == 'office_address'
                      ? 2
                      : 1,
                  maxLines: field.$1 == 'purpose' ||
                          field.$1 == 'objectives' ||
                          field.$1 == 'office_address'
                      ? 4
                      : 1,
                  validator: _required,
                ),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, formKey.currentState!.validate()),
              child: const Text('Save')),
        ],
      ),
    );
    if (save != true) return;
    try {
      await widget.repository.saveContent(
        pageId: pageId,
        values: {
          for (final entry in controllers.entries)
            entry.key: entry.value.text.trim()
        },
      );
      _showMessage('Page content updated.');
    } catch (error) {
      _showError(error);
    }
  }

  Widget _feedbackList() => StreamBuilder<List<Map<String, dynamic>>>(
        stream: widget.repository.watchFeedback(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorBanner('Could not load feedback. ${snapshot.error}');
          }
          final feedback = snapshot.data ?? const [];
          if (feedback.isEmpty) return _empty('No feedback submissions found.');
          return Card(
              child: Column(children: [
            for (final item in feedback)
              ListTile(
                title: Text(item['subject'] as String? ?? 'Feedback'),
                subtitle: Text(item['message'] as String? ?? ''),
                trailing: PopupMenuButton<String>(
                  onSelected: (status) async {
                    try {
                      await widget.repository.updateFeedbackStatus(
                          feedbackId: item['id'] as String, status: status);
                    } catch (error) {
                      _showError(error);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'reviewed', child: Text('Mark reviewed')),
                    PopupMenuItem(value: 'resolved', child: Text('Resolve')),
                  ],
                ),
              ),
          ]));
        },
      );

  Widget _controlPage() {
    if (!_isSuperAdmin) return _errorBanner('Super Admin access is required.');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _tabs(['Approvals', 'Admins', 'Audit', 'Settings'], _controlType,
          (value) => setState(() => _controlType = value.toLowerCase())),
      const SizedBox(height: 12),
      switch (_controlType) {
        'admins' => _adminAccounts(),
        'audit' => _auditLog(),
        'settings' => _settings(),
        _ => _approvals(),
      },
    ]);
  }

  Widget _approvals() => StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.repository.watchFarmers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorBanner(
              'Could not load approval requests. ${snapshot.error}');
        }
        final farmers = (snapshot.data ?? const [])
            .where((farmer) => farmer['approval_status'] == 'pending')
            .toList();
        if (farmers.isEmpty) {
          return _empty('No farmer registrations are waiting for review.');
        }
        return Card(
            child: Column(children: [
          for (final farmer in farmers) _personTile(farmer, farmer: true)
        ]));
      });

  Widget _adminAccounts() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
                onPressed: _createAdmin,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Create Admin'))),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.repository.watchAdmins(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _errorBanner(
                    'Could not load Admin accounts. ${snapshot.error}');
              }
              final admins = snapshot.data ?? const [];
              return Card(
                  child: Column(children: [
                for (final admin
                    in admins.where((item) => item['level'] != 'super'))
                  ListTile(
                    leading: Icon(
                        admin['level'] == 'super'
                            ? Icons.shield_outlined
                            : Icons.admin_panel_settings_outlined,
                        color: AppColors.deepGreen),
                    title: Text(admin['name'] as String? ?? 'Administrator'),
                    subtitle: Text(
                        '${admin['email'] ?? ''} · ${admin['level'] ?? 'standard'} · ${admin['permissions']?.length ?? 0} permissions'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'permissions') {
                          _editAdminPermissions(admin);
                        }
                        if (action == 'toggle') {
                          _setAdminActive(
                              admin, admin['active_status'] != true);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'permissions',
                            child: Text('Edit permissions')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(admin['active_status'] == true
                              ? 'Disable Admin'
                              : 'Enable Admin'),
                        ),
                      ],
                    ),
                  )
              ]));
            }),
      ]);

  Future<void> _createAdmin() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final selected = <String>{};
    final formKey = GlobalKey<FormState>();
    String? permissionsError;
    String? creationError;
    var isCreating = false;
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            if (isCreating) return;
            final valid = formKey.currentState!.validate();
            if (selected.isEmpty) {
              setDialogState(() {
                permissionsError = 'Select at least one permission.';
              });
              return;
            }
            if (!valid) return;

            setDialogState(() {
              isCreating = true;
              creationError = null;
            });
            try {
              await widget.repository.createAdminAccount(
                name: name.text,
                email: email.text.trim(),
                password: password.text,
                permissions: Set<String>.of(selected),
                superAdmin: false,
              );
              if (!mounted) return;
              Navigator.pop(dialogContext, true);
            } catch (error) {
              if (!mounted) return;
              setDialogState(() {
                isCreating = false;
                creationError = _adminCreationError(error);
              });
            }
          }

          return PopScope(
            canPop: !isCreating,
            child: _adminFormDialog(
              context: dialogContext,
              title: 'Create standard Admin',
              icon: Icons.admin_panel_settings_outlined,
              content: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (creationError != null) ...[
                  _errorBanner(creationError!),
                  const SizedBox(height: 8),
                ],
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: _required,
                  textInputAction: TextInputAction.next,
                ),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _required,
                  textInputAction: TextInputAction.next,
                ),
                TextFormField(
                  controller: password,
                  decoration: const InputDecoration(
                    labelText: 'Temporary password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      (value == null || value.length < 8)
                          ? 'Use at least 8 characters'
                          : null,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => submit(),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Permissions',
                    style: AppTextStyles.bodyRegular
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (permissionsError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        permissionsError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                for (final permission in AdminPermissions.allStandard)
                  CheckboxListTile(
                    value: selected.contains(permission),
                    title: Text(permission),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setDialogState(() {
                      if (value == true) {
                        selected.add(permission);
                      } else {
                        selected.remove(permission);
                      }
                      if (selected.isNotEmpty) permissionsError = null;
                    }),
                  ),
              ]),
            ),
              actions: [
              TextButton(
                onPressed: isCreating
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: isCreating ? null : submit,
                icon: isCreating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: Text(isCreating ? 'Creating...' : 'Create Admin'),
              ),
              ],
            ),
          );
        },
      ),
    );
    if (created != true) {
      name.dispose();
      email.dispose();
      password.dispose();
      return;
    }
    try {
      _showMessage(
          'Admin account created. Give the temporary password to the new Admin securely.');
    } catch (error) {
      _showError(error);
    } finally {
      name.dispose();
      email.dispose();
      password.dispose();
    }
  }

  String _adminCreationError(Object error) {
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          'Firebase denied the Admin profile write. Confirm that the current Firestore rules are deployed and that your account is an active Super Admin.',
        'email-already-in-use' =>
          'An account already uses this email address.',
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' => 'Choose a stronger temporary password.',
        'network-request-failed' =>
          'Could not reach Firebase. Check the internet connection and try again.',
        'operation-not-allowed' =>
          'Email and password sign-in is not enabled for this Firebase project.',
        _ => error.message ?? 'Could not create the Admin account.',
      };
    }
    return 'Could not create the Admin account: $error';
  }

  Future<void> _setAdminActive(Map<String, dynamic> admin, bool active) async {
    final uid = admin['id'] as String;
    if (uid == widget.profile.uid) {
      _showMessage('You cannot change your own current account status.');
      return;
    }
    try {
      await widget.repository.updateAdmin(
        uid: uid,
        changes: {'active_status': active},
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editAdminPermissions(Map<String, dynamic> admin) async {
    final permissions = <String>{
      ...((admin['permissions'] as List<dynamic>? ?? const [])
          .whereType<String>()),
    };
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Permissions for ${admin['name'] ?? 'Admin'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final permission in AdminPermissions.allStandard)
                  CheckboxListTile(
                    value: permissions.contains(permission),
                    title: Text(permission),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (enabled) => setDialogState(() {
                      if (enabled == true) {
                        permissions.add(permission);
                      } else {
                        permissions.remove(permission);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, permissions),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (result == null) return;
    try {
      await widget.repository.editAdminPermissions(
        uid: admin['id'] as String,
        permissions: result,
      );
    } catch (error) {
      _showError(error);
    }
  }

  Widget _auditLog() => StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.repository.watchAuditLogs(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorBanner('Could not load audit log. ${snapshot.error}');
        }
        final logs = (snapshot.data ?? const []).where((log) {
          final searchable =
              '${log['admin_name']} ${log['action']} ${log['target_type']} ${log['target_id']}'
                  .toLowerCase();
          final timestamp = log['timestamp'];
          final createdAt = timestamp is Timestamp ? timestamp.toDate() : null;
          final dateMatches = _auditDateRange == null ||
              (createdAt != null &&
                  !createdAt.isBefore(DateTime(
                    _auditDateRange!.start.year,
                    _auditDateRange!.start.month,
                    _auditDateRange!.start.day,
                  )) &&
                  createdAt.isBefore(DateTime(
                    _auditDateRange!.end.year,
                    _auditDateRange!.end.month,
                    _auditDateRange!.end.day + 1,
                  )));
          return searchable.contains(_auditFilter.toLowerCase()) && dateMatches;
        }).toList();
        return Column(children: [
          TextField(
            onChanged: (value) => setState(() => _auditFilter = value),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Filter by Admin, action, or target',
                isDense: true),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final selected = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(now.year + 1),
                    initialDateRange: _auditDateRange,
                  );
                  if (selected != null && mounted) {
                    setState(() => _auditDateRange = selected);
                  }
                },
                icon: const Icon(Icons.date_range_outlined),
                label: Text(_auditDateRange == null
                    ? 'Filter by date'
                    : '${_shortDate(_auditDateRange!.start)} to ${_shortDate(_auditDateRange!.end)}'),
              ),
            ),
            if (_auditDateRange != null)
              IconButton(
                tooltip: 'Clear date filter',
                onPressed: () => setState(() => _auditDateRange = null),
                icon: const Icon(Icons.clear),
              ),
          ]),
          const SizedBox(height: 10),
          if (logs.isEmpty)
            _empty('No Admin activity matches these filters.')
          else
            Card(
                child: Column(children: [
              for (final log in logs)
                ListTile(
                    leading: const Icon(Icons.history_rounded,
                        color: AppColors.deepGreen),
                    title: Text(log['action'] as String? ?? 'Action'),
                    subtitle: Text(
                        '${log['admin_name'] ?? log['admin_id'] ?? ''} · ${log['target_type'] ?? ''} ${log['target_id'] ?? ''}\n${_auditTimestamp(log['timestamp'])}'))
            ])),
        ]);
      });

  String _shortDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _auditTimestamp(Object? value) {
    if (value is! Timestamp) return 'Time unavailable';
    final date = value.toDate().toLocal();
    return '${_shortDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _settings() => StreamBuilder<Map<String, dynamic>>(
      stream: widget.repository.watchSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? const <String, dynamic>{};
        return Column(children: [
          if (snapshot.hasError)
            _errorBanner('Could not load settings. ${snapshot.error}'),
          if (snapshot.connectionState == ConnectionState.waiting)
            const LinearProgressIndicator(color: AppColors.mainGreen),
          Card(
              child: ListTile(
                  title: const Text('Low stock threshold'),
                  subtitle: Text(settings.containsKey('low_stock_threshold')
                      ? '${settings['low_stock_threshold']} items'
                      : 'Not configured in Firebase'),
                  trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editSetting('low_stock_threshold',
                          settings['low_stock_threshold'])))),
          Card(
              child: ListTile(
                  title: const Text('Pickup slot duration'),
                  subtitle: Text(settings.containsKey('pickup_slot_minutes')
                      ? '${settings['pickup_slot_minutes']} minutes'
                      : 'Not configured in Firebase'),
                  trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editSetting('pickup_slot_minutes',
                          settings['pickup_slot_minutes'])))),
        ]);
      });

  Future<void> _editSetting(String key, Object? current) async {
    final controller = TextEditingController(text: current?.toString() ?? '');
    final save = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                title: Text(key == 'low_stock_threshold'
                    ? 'Low stock threshold'
                    : 'Pickup slot duration'),
                content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(suffixText: 'items / minutes')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        final value = int.tryParse(controller.text);
                        Navigator.pop(context, value != null && value > 0);
                      },
                      child: const Text('Save'))
                ]));
    if (save != true) return;
    try {
      await widget.repository.updateSetting(key, int.parse(controller.text));
    } catch (error) {
      _showError(error);
    }
  }

  Widget _tabs(List<String> values, String selected,
          ValueChanged<String> onChanged) =>
      SegmentedButton<String>(
          segments: [
            for (final value in values)
              ButtonSegment(value: value.toLowerCase(), label: Text(value))
          ],
          selected: {
            selected
          },
          onSelectionChanged: (selection) => onChanged(selection.first),
          showSelectedIcon: false);

  Widget _searchField(String hint, ValueChanged<String> onChanged) => TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: hint,
          isDense: true));

  Widget _heading(String title, String? caption) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: AppTextStyles.headingMedium),
        if (caption != null) Text(caption, style: AppTextStyles.caption)
      ]));

  Widget _levelBadge(String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: AppColors.softGreen, borderRadius: BorderRadius.circular(14)),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.deepGreen,
              fontSize: 9,
              fontWeight: FontWeight.w800)));

  Widget _empty(String text) => Padding(
      padding: const EdgeInsets.all(22),
      child: Center(
          child: Text(text,
              textAlign: TextAlign.center, style: AppTextStyles.bodyMuted)));

  Widget _errorBanner(String text) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: AppColors.error)));

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String _money(Object? value) =>
      '₦${((value is num) ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0).toStringAsFixed(2)}';

  Future<void> _confirmDelete(
      String prompt, Future<void> Function() action) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('Confirm change'),
                content: Text(prompt),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirm'))
                ]));
    if (yes != true) return;
    try {
      await action();
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) =>
      _showMessage('Action failed: $error', error: true);

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating));
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Scaffold(
      backgroundColor: AppColors.background,
      body:
          Center(child: CircularProgressIndicator(color: AppColors.mainGreen)));
}
