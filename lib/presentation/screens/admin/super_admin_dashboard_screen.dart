import 'package:flutter/material.dart';

import '../../../application/access_control/role_guard.dart';
import '../../../data/models/user_role.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/text_styles.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  static const routeName = '/super-admin';

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRoles: {UserRole.superAdmin},
      child: _SuperAdminDashboardContent(),
    );
  }
}

class _SuperAdminDashboardContent extends StatefulWidget {
  const _SuperAdminDashboardContent();

  @override
  State<_SuperAdminDashboardContent> createState() =>
      _SuperAdminDashboardContentState();
}

class _SuperAdminDashboardContentState
    extends State<_SuperAdminDashboardContent> {
  int _selectedIndex = 0;

  final _admins = <Map<String, String>>[
    {
      'name': 'Priya Nair',
      'email': 'priya@harvesthub.app',
      'scope': 'Full platform',
      'status': 'Active'
    },
    {
      'name': 'Arjun Rao',
      'email': 'arjun@harvesthub.app',
      'scope': 'Orders and catalog',
      'status': 'Active'
    },
    {
      'name': 'Meera Shah',
      'email': 'meera@harvesthub.app',
      'scope': 'Customer support',
      'status': 'Pending'
    },
  ];

  final _auditEvents = <Map<String, String>>[
    {
      'event': 'Admin role updated',
      'actor': 'Priya Nair',
      'time': '12 minutes ago'
    },
    {
      'event': 'New market approved',
      'actor': 'Arjun Rao',
      'time': '1 hour ago'
    },
    {
      'event': 'Product moderation rule changed',
      'actor': 'Priya Nair',
      'time': 'Yesterday'
    },
  ];

  String get _title => [
        'Overview',
        'Admin accounts',
        'Access policies',
        'Audit log'
      ][_selectedIndex];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      return Scaffold(
        backgroundColor: AppColors.background,
        drawer: wide ? null : Drawer(child: _buildNavigation(isDrawer: true)),
        body: Row(children: [
          if (wide) SizedBox(width: 238, child: _buildNavigation()),
          Expanded(child: _buildContent(wide)),
        ]),
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
                      icon: Icon(Icons.badge_outlined), label: 'Admins'),
                  NavigationDestination(
                      icon: Icon(Icons.policy_outlined), label: 'Policies'),
                  NavigationDestination(
                      icon: Icon(Icons.history_rounded), label: 'Audit'),
                ],
              ),
      );
    });
  }

  Widget _buildNavigation({bool isDrawer = false}) {
    final items = [
      (Icons.grid_view_rounded, 'Overview'),
      (Icons.badge_outlined, 'Admin accounts'),
      (Icons.policy_outlined, 'Access policies'),
      (Icons.history_rounded, 'Audit log'),
    ];
    return Container(
      color: AppColors.deepGreen,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Image.asset('assets/splash_screen/logo_full_combined.png',
              height: 38, fit: BoxFit.contain, alignment: Alignment.centerLeft),
        ),
        const SizedBox(height: 38),
        Text('SUPER ADMIN',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.wheatGold,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final selected = _selectedIndex == entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              selected: selected,
              selectedTileColor: Colors.white.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              leading: Icon(entry.value.$1,
                  color: selected ? AppColors.wheatGold : Colors.white70,
                  size: 20),
              title: Text(entry.value.$2,
                  style: AppTextStyles.bodyRegular.copyWith(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w400)),
              onTap: () {
                setState(() => _selectedIndex = entry.key);
                if (isDrawer) Navigator.of(context).pop();
              },
            ),
          );
        }),
        const Spacer(),
        const Divider(color: Colors.white24),
        ListTile(
          dense: true,
          leading:
              const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
          title: Text('Sign out',
              style: AppTextStyles.bodyRegular.copyWith(color: Colors.white70)),
          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ]),
    );
  }

  Widget _buildContent(bool wide) {
    return SafeArea(
        child: Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(wide ? 32 : 20, 20, wide ? 32 : 20, 14),
        child: Row(children: [
          if (!wide)
            IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer()),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Control centre', style: AppTextStyles.bodyMuted),
                Text(_title,
                    style: AppTextStyles.headingLarge.copyWith(fontSize: 25))
              ])),
          const CircleAvatar(
              backgroundColor: AppColors.softGreen,
              child: Icon(Icons.shield_outlined, color: AppColors.deepGreen)),
        ]),
      ),
      Expanded(
          child: SingleChildScrollView(
              padding:
                  EdgeInsets.fromLTRB(wide ? 32 : 20, 8, wide ? 32 : 20, 28),
              child: _buildPage())),
    ]));
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 1:
        return _buildAdminAccounts();
      case 2:
        return _buildPolicies();
      case 3:
        return _buildAuditLog();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: AppColors.deepGreen,
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Platform control, kept simple.',
                        style: AppTextStyles.headingMedium
                            .copyWith(color: Colors.white, fontSize: 19)),
                    const SizedBox(height: 6),
                    Text(
                        'Only Super Admin can change access and platform-wide rules.',
                        style: AppTextStyles.bodyMuted
                            .copyWith(color: Colors.white70))
                  ])),
              const Icon(Icons.shield_rounded,
                  color: AppColors.wheatGold, size: 52)
            ])),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: _summaryCard('Admin accounts', '${_admins.length}',
                  Icons.badge_outlined, AppColors.mainGreen)),
          const SizedBox(width: 12),
          Expanded(
              child: _summaryCard('Pending reviews', '04',
                  Icons.pending_actions_outlined, AppColors.autumnRust))
        ]),
        const SizedBox(height: 20),
        Text('System health', style: AppTextStyles.headingMedium),
        const SizedBox(height: 10),
        Card(
            child: Column(children: [
          _healthRow('Authentication', 'Operational', AppColors.success),
          _healthRow('Marketplace data', 'Operational', AppColors.success),
          _healthRow('Notifications', 'Needs review', AppColors.warning)
        ])),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Recent activity', style: AppTextStyles.headingMedium),
          TextButton(
              onPressed: () => setState(() => _selectedIndex = 3),
              child: const Text('View audit'))
        ]),
        Card(
            child: Column(children: [
          _auditRow(_auditEvents.first),
          _auditRow(_auditEvents[1])
        ])),
      ]);

  Widget _buildAdminAccounts() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _toolbar(
            'Search admin accounts', 'Invite admin', () => _showInviteDialog()),
        const SizedBox(height: 16),
        Card(
            child: Column(children: [
          ..._admins
              .map(_adminRow)
              .expand((row) => [row, const Divider(height: 1)])
              .toList()
            ..removeLast()
        ])),
      ]);

  Widget _buildPolicies() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Role boundaries', style: AppTextStyles.headingMedium),
        const SizedBox(height: 10),
        Card(
            child: Column(children: [
          _policyRow(
              'Administrator',
              'Customers, farmers, products, orders and reports',
              Icons.admin_panel_settings_outlined,
              AppColors.mainGreen),
          _policyRow(
              'Super Admin',
              'Admin accounts, access policies and audit history',
              Icons.shield_outlined,
              AppColors.autumnRust),
          _policyRow(
              'Customer / Farmer',
              'Marketplace actions within their own account',
              Icons.people_outline,
              AppColors.wheatGold),
        ])),
        const SizedBox(height: 20),
        Text('Platform controls', style: AppTextStyles.headingMedium),
        const SizedBox(height: 10),
        Card(
            child: Column(children: [
          _switchRow('Require admin approval for new farmers', true),
          _switchRow('Enable marketplace maintenance mode', false),
          _switchRow('Allow new market submissions', true)
        ])),
      ]);

  Widget _buildAuditLog() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Every privileged change is recorded here.',
            style: AppTextStyles.bodyMuted),
        const SizedBox(height: 16),
        Card(child: Column(children: _auditEvents.map(_auditRow).toList())),
      ]);

  Widget _toolbar(String hint, String action, VoidCallback onAction) => Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(action),
          ),
        ],
      );

  Widget _summaryCard(String label, String value, IconData icon, Color color) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 14),
              Text(value,
                  style: AppTextStyles.headingLarge.copyWith(fontSize: 24)),
              Text(label, style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
      );

  Widget _healthRow(String label, String state, Color color) => ListTile(
        leading: Icon(Icons.circle, size: 10, color: color),
        title: Text(label,
            style: AppTextStyles.bodyRegular
                .copyWith(fontWeight: FontWeight.w600)),
        trailing: Text(state,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  Widget _adminRow(Map<String, String> admin) => ListTile(
      leading: const CircleAvatar(
          backgroundColor: AppColors.softGreen,
          child: Icon(Icons.person_outline, color: AppColors.deepGreen)),
      title: Text(admin['name']!,
          style:
              AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text('${admin['email']} · ${admin['scope']}'),
      trailing: Text(admin['status']!,
          style: TextStyle(
              color: admin['status'] == 'Active'
                  ? AppColors.success
                  : AppColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.w700)));

  Widget _policyRow(String title, String detail, IconData icon, Color color) =>
      ListTile(
          leading: Icon(icon, color: color),
          title: Text(title,
              style: AppTextStyles.bodyRegular
                  .copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(detail));

  Widget _switchRow(String title, bool value) => SwitchListTile(
      value: value,
      onChanged: (_) {},
      title: Text(title, style: AppTextStyles.bodyRegular));

  Widget _auditRow(Map<String, String> event) => ListTile(
      leading: const Icon(Icons.history_rounded, color: AppColors.deepGreen),
      title: Text(event['event']!,
          style:
              AppTextStyles.bodyRegular.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text('${event['actor']} · ${event['time']}'));

  void _showInviteDialog() => showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
              title: const Text('Invite administrator'),
              content: const Text(
                  'Admin invitation is ready to connect to Firebase Authentication.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ]));
}
