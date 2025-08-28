import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../models/gate_pass_model.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';

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
  bool _showScanner = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _tabController.dispose();
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

  Future<void> _scanQRCode(String qrCode) async {
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    final success = await gatePassProvider.scanGatePass(qrCode);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gate pass scanned successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
      setState(() => _showScanner = false);
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or expired gate pass'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _scanQRCode(barcode.rawValue!);
        break;
      }
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
      body: _showScanner ? _QRScannerView() : _MainDashboardView(),
      floatingActionButton: _showScanner 
          ? null 
          : FloatingActionButton.extended(
              onPressed: () => setState(() => _showScanner = true),
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR'),
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
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Column(
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
                    'Scan and validate gate passes',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              );
            },
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
        
        // Quick Scan Card
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
                Icons.qr_code_scanner,
                size: 48,
                color: Colors.black,
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to Scan QR Code',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan student gate pass QR codes to validate entry/exit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: () => setState(() => _showScanner = true),
                text: 'Start Scanning',
                backgroundColor: Colors.black,
                textColor: AppTheme.primaryYellow,
                width: double.infinity,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tab Bar
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
        
        // Tab Views
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

  Widget _QRScannerView() {
    return Column(
      children: [
        // Scanner Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _showScanner = false),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                'Scan QR Code',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Scanner
        Expanded(
          flex: 4,
          child: MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            overlay: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryYellow,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              width: 250,
              height: 250,
            ),
          ),
        ),
        
        // Instructions
        Expanded(
          flex: 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.center_focus_strong,
                  size: 48,
                  color: AppTheme.primaryYellow,
                ),
                const SizedBox(height: 16),
                Text(
                  'Point camera at QR code',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hold steady and ensure the QR code is clearly visible',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _RecentScansTab() {
    if (_scannedPasses.isEmpty) {
      return _EmptyState(
        icon: Icons.qr_code_scanner,
        title: 'No Recent Scans',
        subtitle: 'Scanned gate passes will appear here.',
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
            onScan: () => _scanQRCode(pass.qrCode!),
          );
        },
      ),
    );
  }
}

// Helper Widgets (same as before)
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    'Scanned',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Scanned: ${gatePass.usedAt != null ? DateFormat('MMM dd, yyyy HH:mm').format(gatePass.usedAt!) : 'Recently'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePassCard extends StatelessWidget {
  final GatePass gatePass;
  final VoidCallback onScan;

  const _ActivePassCard({
    required this.gatePass,
    required this.onScan,
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
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Valid until: ${DateFormat('MMM dd, yyyy HH:mm').format(gatePass.validUntil)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (gatePass.teacher != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Approved by: ${gatePass.teacher!.name}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            CustomButton(
              onPressed: onScan,
              text: 'Mark as Used',
              icon: Icons.qr_code_scanner,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}