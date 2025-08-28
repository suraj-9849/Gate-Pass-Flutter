import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../models/gate_pass_model.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  GatePass? _selectedRequest;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GatePassProvider>(context, listen: false);
      provider.loadPendingApprovals();
      provider.loadApprovedRequests();
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
        title: const Text('Teacher Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: AppTheme.primaryYellow,
                  child: Text(
                    authProvider.user?.name.substring(0, 1).toUpperCase() ?? 'T',
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
                          authProvider.user?.name ?? 'Teacher',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          authProvider.user?.roleDisplayName ?? 'Teacher',
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
                      'Welcome, ${authProvider.user?.name ?? 'Teacher'}!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review and approve student gate pass requests',
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
                final pending = gatePassProvider.pendingApprovals.length;
                final approved = gatePassProvider.approvedRequests.length;
                
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Pending Approval',
                        value: pending.toString(),
                        icon: Icons.pending_actions,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'My Approvals',
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
                Tab(text: 'Pending Requests'),
                Tab(text: 'My Approvals'),
              ],
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PendingRequestsTab(
                  onRequestTap: (request) => setState(() => _selectedRequest = request),
                ),
                _ApprovedRequestsTab(),
              ],
            ),
          ),
        ],
      ),
      
      // Review Modal
      bottomSheet: _selectedRequest != null ? _ReviewRequestForm() : null,
    );
  }

  // Review Request Form
  Widget _ReviewRequestForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: _ReviewFormContent(
        gatePass: _selectedRequest!,
        onClose: () => setState(() => _selectedRequest = null),
        onSubmit: () => setState(() => _selectedRequest = null),
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

// Pending Requests Tab
class _PendingRequestsTab extends StatelessWidget {
  final Function(GatePass) onRequestTap;

  const _PendingRequestsTab({required this.onRequestTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<GatePassProvider>(
      builder: (context, gatePassProvider, child) {
        if (gatePassProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingRequests = gatePassProvider.pendingApprovals;
        
        if (pendingRequests.isEmpty) {
          return _EmptyState(
            icon: Icons.pending_actions,
            title: 'No Pending Requests',
            subtitle: 'No students have requested gate passes from you yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => gatePassProvider.loadPendingApprovals(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final request = pendingRequests[index];
              return _PendingRequestCard(
                gatePass: request,
                onTap: () => onRequestTap(request),
              );
            },
          ),
        );
      },
    );
  }
}

// Approved Requests Tab
class _ApprovedRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GatePassProvider>(
      builder: (context, gatePassProvider, child) {
        if (gatePassProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final approvedRequests = gatePassProvider.approvedRequests;
        
        if (approvedRequests.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle,
            title: 'No Approved Requests',
            subtitle: 'Requests you approve will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => gatePassProvider.loadApprovedRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvedRequests.length,
            itemBuilder: (context, index) {
              final request = approvedRequests[index];
              return _ApprovedRequestCard(gatePass: request);
            },
          ),
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

// Pending Request Card
class _PendingRequestCard extends StatelessWidget {
  final GatePass gatePass;
  final VoidCallback onTap;

  const _PendingRequestCard({
    required this.gatePass,
    required this.onTap,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryYellow.withOpacity(0.2),
                      child: Text(
                        gatePass.student?.name.substring(0, 1).toUpperCase() ?? 'S',
                        style: TextStyle(
                          color: AppTheme.primaryYellow,
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
                            gatePass.student?.email ?? '',
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
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pending',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Reason
                Text(
                  'Reason: ${gatePass.reason}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Details
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(gatePass.requestDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Until ${DateFormat('MMM dd, HH:mm').format(gatePass.validUntil)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Action Button
                CustomButton(
                  onPressed: onTap,
                  text: 'Review Request',
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Approved Request Card
class _ApprovedRequestCard extends StatelessWidget {
  final GatePass gatePass;

  const _ApprovedRequestCard({required this.gatePass});

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
                CircleAvatar(
                  backgroundColor: AppTheme.success.withOpacity(0.2),
                  child: Icon(
                    Icons.check,
                    color: AppTheme.success,
                    size: 20,
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
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    gatePass.statusDisplayName,
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
            
            // Details
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Valid until ${DateFormat('MMM dd, yyyy HH:mm').format(gatePass.validUntil)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (gatePass.remarks?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Your remarks: ${gatePass.remarks}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Review Form Content
class _ReviewFormContent extends StatefulWidget {
  final GatePass gatePass;
  final VoidCallback onClose;
  final VoidCallback onSubmit;

  const _ReviewFormContent({
    required this.gatePass,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  State<_ReviewFormContent> createState() => _ReviewFormContentState();
}

class _ReviewFormContentState extends State<_ReviewFormContent> {
  final _remarksController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    if (_remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add remarks for approval'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
      final success = await gatePassProvider.approveGatePass(
        widget.gatePass.id,
        _remarksController.text.trim(),
      );

      if (success) {
        widget.onSubmit();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gate pass approved successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve gate pass'),
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

  Future<void> _handleReject() async {
    if (_remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add remarks for rejection'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
      final success = await gatePassProvider.rejectGatePass(
        widget.gatePass.id,
        _remarksController.text.trim(),
      );

      if (success) {
        widget.onSubmit();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gate pass rejected'),
            backgroundColor: AppTheme.info,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject gate pass'),
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
    return Column(
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
                  'Review Gate Pass Request',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Student Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryYellow.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryYellow,
                            child: Text(
                              widget.gatePass.student?.name.substring(0, 1).toUpperCase() ?? 'S',
                              style: const TextStyle(
                                color: Colors.white,
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
                                  widget.gatePass.student?.name ?? 'Student',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.gatePass.student?.email ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (widget.gatePass.student?.rollNo != null)
                                  Text(
                                    'Roll No: ${widget.gatePass.student!.rollNo}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Request Details
                _DetailSection(
                  title: 'Request Details',
                  children: [
                    _DetailItem(
                      label: 'Reason',
                      value: widget.gatePass.reason,
                      icon: Icons.description,
                    ),
                    _DetailItem(
                      label: 'Request Date',
                      value: DateFormat('MMM dd, yyyy HH:mm').format(widget.gatePass.requestDate),
                      icon: Icons.calendar_today,
                    ),
                    _DetailItem(
                      label: 'Valid Until',
                      value: DateFormat('MMM dd, yyyy HH:mm').format(widget.gatePass.validUntil),
                      icon: Icons.access_time,
                    ),
                    _DetailItem(
                      label: 'Submitted',
                      value: DateFormat('MMM dd, yyyy HH:mm').format(widget.gatePass.createdAt),
                      icon: Icons.send,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Remarks Field
                CustomTextField(
                  controller: _remarksController,
                  label: 'Add Remarks (Required)',
                  hintText: 'Add comments or instructions for the student...',
                  maxLines: 3,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Remarks are required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onPressed: _isLoading ? null : _handleReject,
                        text: _isLoading ? 'Processing...' : 'Reject',
                        backgroundColor: AppTheme.error,
                        textColor: Colors.white,
                        icon: Icons.close,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        onPressed: _isLoading ? null : _handleApprove,
                        text: _isLoading ? 'Processing...' : 'Approve',
                        backgroundColor: AppTheme.success,
                        textColor: Colors.white,
                        icon: Icons.check,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Detail Section Widget
class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

// Detail Item Widget
class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}