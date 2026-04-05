import 'package:flutter/material.dart';

import '../model/app/public_branding_model.dart';
import 'app_branding_logo.dart';

class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({
    super.key,
    required this.title,
    required this.branding,
    required this.child,
    required this.onLogout,
  });

  final String title;
  final PublicBrandingModel branding;
  final Widget child;
  final VoidCallback onLogout;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  bool _drawerExpanded = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 768;
    final showPermanentDrawer = isTablet || isDesktop;

    return Scaffold(
      drawer: showPermanentDrawer ? null : Drawer(child: _buildDrawer()),
      body: Row(
        children: [
          if (showPermanentDrawer)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _drawerExpanded ? 280 : 92,
              child: Material(
                color: const Color(0xFF0A2540),
                child: _buildDrawer(collapsed: !_drawerExpanded),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  elevation: 1,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: 72,
                      child: Row(
                        children: [
                          if (!showPermanentDrawer)
                            Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
                              ),
                            )
                          else
                            IconButton(
                              icon: Icon(
                                _drawerExpanded ? Icons.menu_open : Icons.menu,
                              ),
                              onPressed: () {
                                setState(() {
                                  _drawerExpanded = !_drawerExpanded;
                                });
                              },
                            ),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text(
                              '${widget.branding.currentYear ?? DateTime.now().year} ${widget.branding.companyName}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer({bool collapsed = false}) {
    final items = <({IconData icon, String label, String route})>[
      (icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: collapsed
                ? Center(
                    child: AppBrandingLogo(
                      branding: widget.branding,
                      showName: false,
                      size: 42,
                      textColor: Colors.white,
                    ),
                  )
                : AppBrandingLogo(
                    branding: widget.branding,
                    size: 42,
                    textColor: Colors.white,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        for (final item in items)
          ListTile(
            leading: Icon(item.icon, color: Colors.white),
            title: collapsed
                ? null
                : Text(item.label, style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pushReplacementNamed(item.route);
            },
          ),
        const Spacer(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.white),
          title: collapsed
              ? null
              : const Text('Logout', style: TextStyle(color: Colors.white)),
          onTap: widget.onLogout,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
