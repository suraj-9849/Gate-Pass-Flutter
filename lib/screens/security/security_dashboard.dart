import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../models/gate_pass_model.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<GatePass> _activePasses = [];
  List<GatePass> _scannedPasses = [];
  bool _isLoading = false;
  bool _showManualEntry = false;
  final TextEditingController _qrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    
    try {
      final futures = await Future.wait([
        gatePassProvider.loadActivePasses(),
        gatePassProvider.loadScannedPasses(),
      ]);
      
      setState(() {
        _activePasses = futures[0] as List<GatePass>;
        _scannedPasses = futures[1] as List<GatePass>;
      });
    } catch (e) {
      debugPrint('Error loading security data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processQRCode(String qrCode) async {
    if (qrCode.trim().isEmpty) return;
    
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    final success = await gatePassProvider.scanGatePass(qrCode.trim());
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gate pass processed successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
      _qrController.clear();
      setState(() => _showManualEntry = false);
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or expired gate pass'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Security Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: AppTheme.primaryYellow,
                  child: Text(
                    authProvider.user?.name.substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    authProvider.logout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.user?.name ?? 'Security',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Security Officer',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppTheme.error),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: _showManualEntry ? _ManualEntryView() : _MainDashboardView(),
      floatingActionButton: _showManualEntry 
          ? null 
          : FloatingActionButton.extended(
              onPressed: () => setState(() => _showManualEntry = true),
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.edit),
              label: const Text('Manual Entry'),
            ),
    );
  }

  Widget _MainDashboardView() {
    return Column(
      children: [
        // Welcome Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Validate gate passes manually',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Stats Cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Today\'s Scans',
                  value: _scannedPasses.length.toString(),
                  icon: Icons.check_circle,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Active Passes',
                  value: _activePasses.length.toString(),
                  icon: Icons.schedule,
                  color: AppTheme.info,
                ),
              ),
            ],
          ),
        ),
        
        // Manual Entry Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryYellow, AppTheme.primaryYellow.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryYellow.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.edit,
                size: 48,
                color: Colors.black,
              ),
              const SizedBox(height: 12),
              Text(
                'Manual QR Entry',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter gate pass QR code manually to validate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: () => setState(() => _showManualEntry = true),
                text: 'Start Entry',
                backgroundColor: Colors.black,
                textColor: AppTheme.primaryYellow,
                width: double.infinity,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tab Bar and Views (same as before)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryYellow,
            labelColor: AppTheme.primaryYellow,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Recent Scans'),
              Tab(text: 'Active Passes'),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _RecentScansTab(),
                    _ActivePassesTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _ManualEntryView() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _showManualEntry = false),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                'Manual QR Entry',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Manual Entry Form
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code,
                  size: 80,
                  color: AppTheme.primaryYellow,
                ),
                const SizedBox(height: 24),
                Text(
                  'Enter QR Code',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type or paste the gate pass QR code',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                CustomTextField(
                  controller: _qrController,
                  label: 'QR Code',
                  hintText: 'Enter or paste QR code here',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                CustomButton(
                  onPressed: () => _processQRCode(_qrController.text),
                  text: 'Process Gate Pass',
                  width: double.infinity,
                  icon: Icons.send,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Same helper widgets as before...
  Widget _RecentScansTab() {
    if (_scannedPasses.isEmpty) {
      return _EmptyState(
        icon: Icons.history,
        title: 'No Recent Scans',
        subtitle: 'Processed gate passes will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scannedPasses.length,
        itemBuilder: (context, index) {
          final pass = _scannedPasses[index];
          return _ScannedPassCard(gatePass: pass);
        },
      ),
    );
  }

  Widget _ActivePassesTab() {
    if (_activePasses.isEmpty) {
      return _EmptyState(
        icon: Icons.schedule,
        title: 'No Active Passes',
        subtitle: 'Currently valid gate passes will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activePasses.length,
        itemBuilder: (context, index) {
          final pass = _activePasses[index];
          return _ActivePassCard(
            gatePass: pass,
            onProcess: () => _processQRCode(pass.qrCode!),
          );
        },
      ),
    );
  }
}

// Helper Widgets...
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannedPassCard extends StatelessWidget {
  final GatePass gatePass;

  const _ScannedPassCard({required this.gatePass});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.success.withOpacity(0.2),
              child: Icon(Icons.check, color: AppTheme.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gatePass.student?.name ?? 'Student',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    gatePass.reason,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Processed: ${gatePass.usedAt != null ? DateFormat('MMM dd, HH:mm').format(gatePass.usedAt!) : 'Recently'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Processed',
                style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePassCard extends StatelessWidget {
  final GatePass gatePass;
  final VoidCallback onProcess;

  const _ActivePassCard({
    required this.gatePass,
    required this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.info.withOpacity(0.2),
                  child: Text(
                    gatePass.student?.name.substring(0, 1).toUpperCase() ?? 'S',
                    style: TextStyle(
                      color: AppTheme.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gatePass.student?.name ?? 'Student',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        gatePass.reason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      color: AppTheme.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Valid until: ${DateFormat('MMM dd, yyyy HH:mm').format(gatePass.validUntil)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            if (gatePass.teacher != null) ...[
              const SizedBox(height: 4),
              Text(
                'Approved by: ${gatePass.teacher!.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            CustomButton(
              onPressed: onProcess,
              text: 'Process Gate Pass',
              icon: Icons.send,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}