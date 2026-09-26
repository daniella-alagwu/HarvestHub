import 'package:flutter/material.dart';

import '../../../application/access_control/role_guard.dart';
import '../../../data/models/user_role.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const routeName = '/admin';

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRoles: {UserRole.admin},
      child: _AdminDashboardContent(),
    );
  }
}

class _AdminDashboardContent extends StatefulWidget {
  const _AdminDashboardContent();

  @override
  State<_AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<_AdminDashboardContent> {
  int _selectedIndex = 0;
  String _peopleTab = 'Customers';
  String _catalogTab = 'Products';

  final _customers = const [
    {'name': 'Maya Chen', 'detail': 'maya@example.com', 'state': 'Active'},
    {'name': 'Jon Bell', 'detail': 'jon@example.com', 'state': 'Active'},
    {'name': 'Iris Willis', 'detail': 'iris@example.com', 'state': 'Review'},
  ];
  final _farmers = const [
    {
      'name': 'Maple Row Farm',
      'detail': 'North Market · 18 products',
      'state': 'Verified'
    },
    {
      'name': 'Sunday Market',
      'detail': 'East Market · 12 products',
      'state': 'Review'
    },
    {
      'name': 'Green Valley',
      'detail': 'Central Market · 24 products',
      'state': 'Verified'
    },
  ];
  final _products = const [
    {
      'name': 'Heirloom Tomatoes',
      'detail': 'Maple Row Farm · Vegetables',
      'state': '32 in stock'
    },
    {
      'name': 'Garden Kale',
      'detail': 'Sunday Market · Vegetables',
      'state': '8 in stock'
    },
    {
      'name': 'Free-range Eggs',
      'detail': 'Green Valley · Dairy',
      'state': '0 in stock'
    },
    {
      'name': 'Sweet Basil',
      'detail': 'Maple Row Farm · Herbs',
      'state': '14 in stock'
    },
  ];
  final _markets = const [
    {
      'name': 'PSU Farmers Market',
      'detail': 'Saturday · 9:00 AM - 1:00 PM',
      'state': '12 farmers'
    },
    {
      'name': 'Sunday Market',
      'detail': 'Sunday · 8:00 AM - 12:00 PM',
      'state': '8 farmers'
    },
    {
      'name': 'Central Harvest Hall',
      'detail': 'Wednesday · 10:00 AM - 3:00 PM',
      'state': '6 farmers'
    },
  ];

  String get _title =>
      ['Marketplace overview', 'People', 'Catalog', 'Markets'][_selectedIndex];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _appBar(wide),
        drawer: wide ? null : Drawer(child: _drawer()),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.fromLTRB(wide ? 32 : 16, 8, wide ? 32 : 16, 28),
              child: _page(wide),
            ),
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded), label: 'Overview'),
                  NavigationDestination(
                      icon: Icon(Icons.people_outline), label: 'People'),
                  NavigationDestination(
                      icon: Icon(Icons.inventory_2_outlined), label: 'Catalog'),
                  NavigationDestination(
                      icon: Icon(Icons.storefront_outlined), label: 'Markets'),
                ],
              ),
      );
    });
  }

  PreferredSizeWidget _appBar(bool wide) => AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.deepGreen,
        elevation: 0,
        automaticallyImplyLeading: !wide,
        titleSpacing: wide ? 28 : 0,
        title: Row(children: [
          if (wide)
            Image.asset('assets/splash_screen/logo_full_combined.png',
                height: 30,
                width: 118,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft),
          if (wide) const SizedBox(width: 24),
          Text(_title,
              style: AppTextStyles.headingMedium
                  .copyWith(color: AppColors.deepGreen, fontSize: 17)),
        ]),
        actions: const [
          Icon(Icons.notifications_none_rounded),
          SizedBox(width: 16),
          CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.softGreen,
              child: Icon(Icons.admin_panel_settings_outlined,
                  size: 19, color: AppColors.deepGreen)),
          SizedBox(width: 18),
        ],
      );

  Widget _page(bool wide) {
    switch (_selectedIndex) {
      case 1:
        return _peoplePage();
      case 2:
        return _catalogPage();
      case 3:
        return _marketsPage();
      default:
        return _overview(wide);
    }
  }

  Widget _overview(bool wide) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _hero(),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: wide ? 4 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: wide ? 2.2 : 1.65,
          children: [
            _metric('Farmers', '286', '+8.2%', Icons.agriculture_outlined,
                AppColors.mainGreen),
            _metric('Products', '1,942', '+12.4%', Icons.eco_outlined,
                AppColors.mainGreen),
            _metric('Categories', '24', 'Stable', Icons.category_outlined,
                AppColors.autumnRust),
            _metric('Orders', '3,806', '+16.4%', Icons.receipt_long_outlined,
                AppColors.wheatGold),
          ],
        ),
        const SizedBox(height: 20),
        _section('Marketplace health', 'This month'),
        Card(
            child: Column(children: [
          _health('Active farmer rate', '91%', Icons.person_outline,
              AppColors.mainGreen),
          _health('Order fulfilment', '96.8%', Icons.check_circle_outline,
              AppColors.mainGreen),
          _health('Market coverage', '12 cities', Icons.location_on_outlined,
              AppColors.autumnRust),
        ])),
        const SizedBox(height: 20),
        _section('Recent orders', 'View all',
            onTap: () => setState(() => _selectedIndex = 3)),
        Card(
            child: Column(children: const [
          _OrderRow(
              id: '#1048',
              customer: 'Maya Chen',
              status: 'Ready for pickup',
              amount: 'Rs 18.85'),
          _OrderRow(
              id: '#1047',
              customer: 'Jon Bell',
              status: 'Pending',
              amount: 'Rs 32.40'),
          _OrderRow(
              id: '#1046',
              customer: 'Iris Willis',
              status: 'Confirmed',
              amount: 'Rs 21.10'),
        ])),
      ]);

  Widget _hero() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.deepGreen,
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Revenue this month',
                    style: AppTextStyles.bodyMuted
                        .copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('Rs 84,260',
                    style: AppTextStyles.headingLarge
                        .copyWith(color: Colors.white, fontSize: 28)),
                Text('+16.4% from August',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.softGreen)),
              ])),
          const Icon(Icons.bar_chart_rounded,
              color: AppColors.wheatGold, size: 48),
        ]),
      );

  Widget _peoplePage() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tabs(['Customers', 'Farmers'], _peopleTab,
            (value) => setState(() => _peopleTab = value)),
        const SizedBox(height: 14),
        _search('Search ${_peopleTab.toLowerCase()}'),
        const SizedBox(height: 12),
        Card(
            child: Column(
                children: (_peopleTab == 'Customers' ? _customers : _farmers)
                    .map(_personRow)
                    .toList())),
      ]);

  Widget _catalogPage() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tabs(['Products', 'Categories'], _catalogTab,
            (value) => setState(() => _catalogTab = value)),
        const SizedBox(height: 14),
        _search('Search ${_catalogTab.toLowerCase()}'),
        const SizedBox(height: 12),
        if (_catalogTab == 'Products')
          Card(child: Column(children: _products.map(_productRow).toList()))
        else
          _categoryGrid(),
      ]);

  Widget _marketsPage() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Markets', style: AppTextStyles.headingMedium),
          FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add market'))
        ]),
        const SizedBox(height: 14),
        Card(child: Column(children: _markets.map(_marketRow).toList())),
        const SizedBox(height: 20),
        _section('Report shortcuts', null),
        Row(children: [
          Expanded(
              child: _shortcut('Revenue report', Icons.payments_outlined,
                  AppColors.wheatGold)),
          const SizedBox(width: 10),
          Expanded(
              child: _shortcut('Order report', Icons.receipt_long_outlined,
                  AppColors.mainGreen))
        ]),
      ]);

  Widget _tabs(List<String> labels, String selected,
          ValueChanged<String> onChanged) =>
      Row(
          children: labels
              .map((label) => Expanded(
                  child: Padding(
                      padding:
                          EdgeInsets.only(right: label == labels.first ? 6 : 0),
                      child: ChoiceChip(
                          label: Text(label),
                          selected: selected == label,
                          onSelected: (_) => onChanged(label),
                          showCheckmark: false,
                          labelStyle: TextStyle(
                              color: selected == label
                                  ? Colors.white
                                  : AppColors.deepGreen,
                              fontWeight: FontWeight.w700),
                          selectedColor: AppColors.deepGreen,
                          backgroundColor: AppColors.surface))))
              .toList());

  Widget _search(String hint) => TextField(
      decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          isDense: true));

  Widget _metric(String label, String value, String change, IconData icon,
          Color color) =>
      Card(
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: AppTextStyles.caption),
                          Icon(icon, color: color, size: 18)
                        ]),
                    Text(value,
                        style:
                            AppTextStyles.headingMedium.copyWith(fontSize: 19)),
                    Text(change,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.success))
                  ])));

  Widget _section(String title, String? action, {VoidCallback? onTap}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: AppTextStyles.headingMedium),
        if (action != null)
          TextButton(
              onPressed: onTap,
              child: Text(action,
                  style: const TextStyle(
                      color: AppColors.mainGreen, fontWeight: FontWeight.w700)))
      ]);

  Widget _health(String label, String value, IconData icon, Color color) =>
      ListTile(
          leading: Icon(icon, color: color),
          title: Text(label, style: AppTextStyles.bodyRegular),
          trailing: Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)));

  Widget _personRow(Map<String, String> item) => ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.softGreen,
          child: Icon(Icons.person_outline, color: AppColors.deepGreen),
        ),
        title: Text(item['name']!,
            style: AppTextStyles.bodyRegular
                .copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(item['detail']!),
        trailing: _pill(item['state']!),
      );

  Widget _productRow(Map<String, String> item) => ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.eco_outlined, color: AppColors.mainGreen),
        ),
        title: Text(item['name']!,
            style: AppTextStyles.bodyRegular
                .copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(item['detail']!),
        trailing: Text(item['state']!,
            style: TextStyle(
                color: item['state'] == '0 in stock'
                    ? AppColors.error
                    : AppColors.mainGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );

  Widget _marketRow(Map<String, String> item) => ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFF0D5),
          child: Icon(Icons.storefront_outlined, color: AppColors.autumnRust),
        ),
        title: Text(item['name']!,
            style: AppTextStyles.bodyRegular
                .copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(item['detail']!),
        trailing: Text(item['state']!, style: AppTextStyles.caption),
      );

  Widget _categoryGrid() => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final category in [
            'Fruits',
            'Vegetables',
            'Organic',
            'Dairy',
            'Grains',
            'Herbs'
          ])
            SizedBox(
              width: 156,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Icon(Icons.category_outlined,
                        color: AppColors.mainGreen, size: 19),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(category,
                            style: AppTextStyles.bodyRegular
                                .copyWith(fontWeight: FontWeight.w600))),
                  ]),
                ),
              ),
            ),
        ],
      );

  Widget _shortcut(String label, IconData icon, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: AppTextStyles.bodyRegular
                        .copyWith(fontWeight: FontWeight.w600))),
          ]),
        ),
      );

  Widget _pill(String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: AppColors.softGreen, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.mainGreen,
              fontSize: 10,
              fontWeight: FontWeight.w700)));

  Widget _drawer() => SafeArea(
        child: Container(
          color: AppColors.deepGreen,
          child: Column(
            children: [
              const SizedBox(height: 24),
              Image(
                  image: const AssetImage(
                      'assets/splash_screen/logo_full_combined.png'),
                  height: 38),
              const SizedBox(height: 36),
              ...['Overview', 'People', 'Catalog', 'Markets']
                  .asMap()
                  .entries
                  .map(
                    (entry) => ListTile(
                      selected: entry.key == _selectedIndex,
                      selectedTileColor: Colors.white12,
                      leading: Icon(
                        [
                          Icons.grid_view_rounded,
                          Icons.people_outline,
                          Icons.inventory_2_outlined,
                          Icons.storefront_outlined
                        ][entry.key],
                        color: Colors.white,
                      ),
                      title: Text(entry.value,
                          style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        setState(() => _selectedIndex = entry.key);
                        Navigator.pop(context);
                      },
                    ),
                  ),
            ],
          ),
        ),
      );
}

class _OrderRow extends StatelessWidget {
  const _OrderRow(
      {required this.id,
      required this.customer,
      required this.status,
      required this.amount});
  final String id;
  final String customer;
  final String status;
  final String amount;

  @override
  Widget build(BuildContext context) => ListTile(
      leading: Text(id,
          style: const TextStyle(
              color: AppColors.deepGreen,
              fontWeight: FontWeight.w700,
              fontSize: 12)),
      title: Text(customer,
          style:
              AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(status),
      trailing: Text(amount,
          style:
              AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w700)));
}
