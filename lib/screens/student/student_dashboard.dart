import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../models/gate_pass_model.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showRequestForm = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      authProvider.ensureTokenSet();
      gatePassProvider.loadStudentPasses(token: authProvider.token);
      gatePassProvider.loadTeachers(token: authProvider.token);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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
                          authProvider.user?.name ?? 'Student',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          authProvider.user?.email ?? '',
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
      body: Column(
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
                      'Welcome, ${authProvider.user?.name ?? 'Student'}!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your gate pass requests',
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
            child: Consumer<GatePassProvider>(
              builder: (context, gatePassProvider, child) {
                final passes = gatePassProvider.studentPasses;
                final pending = passes.where((p) => p.isPending).length;
                final approved = passes.where((p) => p.isApproved).length;
                
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Requests',
                        value: passes.length.toString(),
                        icon: Icons.assignment,
                        color: AppTheme.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Pending',
                        value: pending.toString(),
                        icon: Icons.pending,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Approved',
                        value: approved.toString(),
                        icon: Icons.check_circle,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
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
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
              ],
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AllPassesTab(),
                _PendingPassesTab(),
                _ApprovedPassesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showRequestForm = true),
        backgroundColor: AppTheme.primaryYellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
      
      // Modals
      bottomSheet: _showRequestForm ? _NewRequestForm() : null,
    );
  }

  // Helper method to show QR dialog
  void _showQRDialog(String qrCode) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Gate Pass QR Code',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: qrCode,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Show this to security at the gate',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: () => Navigator.pop(context),
                text: 'Close',
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stat Card Widget
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

// All Passes Tab
class _AllPassesTab extends StatelessWidget {
  const _AllPassesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<GatePassProvider>(
      builder: (context, gatePassProvider, child) {
        if (gatePassProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final passes = gatePassProvider.studentPasses;
        
        if (passes.isEmpty) {
          return const _EmptyState(
            icon: Icons.assignment,
            title: 'No Gate Pass Requests',
            subtitle: 'You haven\'t made any requests yet.\nTap the + button to create your first request.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: passes.length,
          itemBuilder: (context, index) {
            final pass = passes[index];
            return _GatePassCard(
              gatePass: pass,
              onQRTap: pass.qrCode != null 
                  ? () => (context.findAncestorStateOfType<_StudentDashboardState>())
                      ?._showQRDialog(pass.qrCode!)
                  : null,
            );
          },
        );
      },
    );
  }
}

// Pending Passes Tab
class _PendingPassesTab extends StatelessWidget {
  const _PendingPassesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<GatePassProvider>(
      builder: (context, gatePassProvider, child) {
        if (gatePassProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingPasses = gatePassProvider.studentPasses
            .where((pass) => pass.isPending)
            .toList();
        
        if (pendingPasses.isEmpty) {
          return const _EmptyState(
            icon: Icons.pending,
            title: 'No Pending Requests',
            subtitle: 'You don\'t have any pending gate pass requests.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingPasses.length,
          itemBuilder: (context, index) {
            final pass = pendingPasses[index];
            return _GatePassCard(gatePass: pass);
          },
        );
      },
    );
  }
}

// Approved Passes Tab
class _ApprovedPassesTab extends StatelessWidget {
  const _ApprovedPassesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<GatePassProvider>(
      builder: (context, gatePassProvider, child) {
        if (gatePassProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final approvedPasses = gatePassProvider.studentPasses
            .where((pass) => pass.isApproved)
            .toList();
        
        if (approvedPasses.isEmpty) {
          return const _EmptyState(
            icon: Icons.check_circle,
            title: 'No Approved Requests',
            subtitle: 'Your approved gate passes will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: approvedPasses.length,
          itemBuilder: (context, index) {
            final pass = approvedPasses[index];
            return _GatePassCard(
              gatePass: pass,
              onQRTap: pass.qrCode != null 
                  ? () => (context.findAncestorStateOfType<_StudentDashboardState>())
                      ?._showQRDialog(pass.qrCode!)
                  : null,
            );
          },
        );
      },
    );
  }
}

// Empty State Widget
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    super.key,
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
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade400,
            ),
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

// Gate Pass Card Widget
class _GatePassCard extends StatelessWidget {
  final GatePass gatePass;
  final VoidCallback? onQRTap;

  const _GatePassCard({
    super.key,
    required this.gatePass,
    this.onQRTap,
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
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    gatePass.reason,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StatusBadge(status: gatePass.status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Details
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Request Date',
              value: DateFormat('MMM dd, yyyy HH:mm').format(gatePass.requestDate),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.access_time,
              label: 'Valid Until',
              value: DateFormat('MMM dd, yyyy HH:mm').format(gatePass.validUntil),
            ),
            if (gatePass.teacher != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.person,
                label: 'Teacher',
                value: gatePass.teacher!.name,
              ),
            ],
            if (gatePass.remarks?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.note,
                label: 'Remarks',
                value: gatePass.remarks!,
              ),
            ],
            
            // Actions
            if (gatePass.isApproved && gatePass.qrCode != null) ...[
              const SizedBox(height: 16),
              CustomButton(
                onPressed: onQRTap,
                text: 'Show QR Code',
                icon: Icons.qr_code,
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Status Badge Widget
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'PENDING':
        backgroundColor = AppTheme.warning.withOpacity(0.1);
        textColor = AppTheme.warning;
        icon = Icons.pending;
        break;
      case 'APPROVED':
        backgroundColor = AppTheme.success.withOpacity(0.1);
        textColor = AppTheme.success;
        icon = Icons.check_circle;
        break;
      case 'REJECTED':
        backgroundColor = AppTheme.error.withOpacity(0.1);
        textColor = AppTheme.error;
        icon = Icons.cancel;
        break;
      case 'USED':
        backgroundColor = AppTheme.info.withOpacity(0.1);
        textColor = AppTheme.info;
        icon = Icons.done_all;
        break;
      case 'EXPIRED':
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade600;
        icon = Icons.timer_off;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade600;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toLowerCase().split('_').map((word) => 
              word[0].toUpperCase() + word.substring(1)).join(' '),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// New Request Form
class _NewRequestForm extends StatefulWidget {
  const _NewRequestForm({super.key});

  @override
  State<_NewRequestForm> createState() => _NewRequestFormState();
}

class _NewRequestFormState extends State<_NewRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _requestDateController = TextEditingController();
  final _validUntilController = TextEditingController();
  
  Teacher? _selectedTeacher;
  List<Teacher> _teachers = [];
  bool _isLoading = false;
  bool _loadingTeachers = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _requestDateController.dispose();
    _validUntilController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _loadingTeachers = true;
      _errorMessage = null;
    });
    
    try {
      final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.token == null) {
        throw Exception('No authentication token found');
      }
      
      authProvider.ensureTokenSet();
      await gatePassProvider.loadTeachers(token: authProvider.token);
      
      final teachersList = gatePassProvider.teachers;
      
      setState(() {
        _teachers = List.from(teachersList);
        _loadingTeachers = false;
        _errorMessage = null;
      });
      
      if (_teachers.isEmpty) {
        setState(() {
          _errorMessage = 'No approved teachers found. Please contact your administrator.';
        });
      }
      
    } catch (e) {
      setState(() {
        _loadingTeachers = false;
        _errorMessage = 'Failed to load teachers: $e';
        _teachers = [];
      });
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        controller.text = DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedTeacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a teacher'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final requestDate = DateFormat('MMM dd, yyyy HH:mm').parse(_requestDateController.text);
      final validUntil = DateFormat('MMM dd, yyyy HH:mm').parse(_validUntilController.text);
      
      final success = await gatePassProvider.createGatePass(
        reason: _reasonController.text.trim(),
        teacherId: _selectedTeacher!.id,
        requestDate: requestDate,
        validUntil: validUntil,
        token: authProvider.token,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gate pass request submitted successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit request. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'New Gate Pass Request',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error Message Display
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error, color: AppTheme.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: AppTheme.error),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CustomButton(
                                  onPressed: _loadTeachers,
                                  text: 'Retry',
                                  backgroundColor: AppTheme.error,
                                  textColor: Colors.white,
                                  width: 100,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Teacher Selection
                    Text(
                      'Select Teacher',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _loadingTeachers
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Loading teachers...'),
                                ],
                              ),
                            )
                          : _teachers.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Icon(Icons.warning, color: AppTheme.warning, size: 30),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'No teachers available',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const Text(
                                        'Please contact your administrator',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      CustomButton(
                                        onPressed: _loadTeachers,
                                        text: 'Reload',
                                        width: 100,
                                      ),
                                    ],
                                  ),
                                )
                              : DropdownButton<Teacher>(
                                  value: _selectedTeacher,
                                  hint: Text('Choose your teacher (${_teachers.length} available)'),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  onChanged: (teacher) => setState(() => _selectedTeacher = teacher),
                                  items: _teachers.map((teacher) => DropdownMenuItem(
                                    value: teacher,
                                    child: Text('${teacher.name} (${teacher.email})'),
                                  )).toList(),
                                ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Reason
                    CustomTextField(
                      controller: _reasonController,
                      label: 'Reason for Leaving',
                      hintText: 'Enter the reason for your gate pass',
                      maxLines: 3,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a reason';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Request Date
                    CustomTextField(
                      controller: _requestDateController,
                      label: 'Request Date & Time',
                      hintText: 'Select date and time',
                      suffixIcon: Icons.calendar_today,
                      onSuffixTap: () => _selectDateTime(_requestDateController),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please select request date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Valid Until
                    CustomTextField(
                      controller: _validUntilController,
                      label: 'Valid Until',
                      hintText: 'Select validity date and time',
                      suffixIcon: Icons.calendar_today,
                      onSuffixTap: () => _selectDateTime(_validUntilController),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please select validity date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    CustomButton(
                      onPressed: (_isLoading || _loadingTeachers || _teachers.isEmpty) 
                          ? null 
                          : _submitRequest,
                      text: _isLoading 
                          ? 'Submitting...' 
                          : _loadingTeachers 
                              ? 'Loading Teachers...' 
                              : 'Submit Request',
                      isLoading: _isLoading || _loadingTeachers,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}