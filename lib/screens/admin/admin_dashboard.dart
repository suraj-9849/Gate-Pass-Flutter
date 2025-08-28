import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<User> _pendingTeachers = [];
  List<User> _allUsers = [];
  bool _isLoading = false;
  User? _selectedUser;
  String? _newRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    
    try {
      final futures = await Future.wait([
        gatePassProvider.loadPendingTeachers(),
        gatePassProvider.loadAllUsers(),
      ]);
      
      setState(() {
        _pendingTeachers = futures[0] as List<User>;
        _allUsers = futures[1] as List<User>;
      });
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveTeacher(String teacherId) async {
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    final success = await gatePassProvider.approveTeacher(teacherId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher approved successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve teacher'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _rejectTeacher(String teacherId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: const Text('Are you sure you want to reject this teacher application? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    final success = await gatePassProvider.rejectTeacher(teacherId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher application rejected'),
          backgroundColor: AppTheme.info,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reject teacher'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    final success = await gatePassProvider.changeUserRole(userId, newRole);
    
    if (success) {
      setState(() {
        _selectedUser = null;
        _newRole = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User role updated successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update user role'),
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
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: AppTheme.primaryYellow,
                  child: Text(
                    authProvider.user?.name.substring(0, 1).toUpperCase() ?? 'A',
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
                          authProvider.user?.name ?? 'Administrator',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Super Admin',
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
                      'Welcome, ${authProvider.user?.name ?? 'Administrator'}!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage users and system settings',
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
                    title: 'Total Users',
                    value: _allUsers.length.toString(),
                    icon: Icons.people,
                    color: AppTheme.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Students',
                    value: _allUsers.where((u) => u.isStudent).length.toString(),
                    icon: Icons.school,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Teachers',
                    value: _allUsers.where((u) => u.isTeacher && u.isApproved).length.toString(),
                    icon: Icons.person,
                    color: AppTheme.primaryYellow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pending',
                    value: _pendingTeachers.length.toString(),
                    icon: Icons.pending,
                    color: AppTheme.warning,
                  ),
                ),
              ],
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
              tabs: [
                Tab(text: 'Pending Approvals (${_pendingTeachers.length})'),
                Tab(text: 'All Users (${_allUsers.length})'),
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
                      _PendingApprovalsTab(),
                      _AllUsersTab(),
                    ],
                  ),
          ),
        ],
      ),
      
      // Role Change Modal
      bottomSheet: _selectedUser != null ? _RoleChangeForm() : null,
    );
  }

  // Pending Approvals Tab
  Widget _PendingApprovalsTab() {
    if (_pendingTeachers.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle,
        title: 'No Pending Approvals',
        subtitle: 'All teacher registrations have been processed.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingTeachers.length,
        itemBuilder: (context, index) {
          final teacher = _pendingTeachers[index];
          return _PendingTeacherCard(
            user: teacher,
            onApprove: () => _approveTeacher(teacher.id),
            onReject: () => _rejectTeacher(teacher.id),
          );
        },
      ),
    );
  }

  // All Users Tab
  Widget _AllUsersTab() {
    if (_allUsers.isEmpty) {
      return const _EmptyState(
        icon: Icons.people,
        title: 'No Users Found',
        subtitle: 'No users are currently registered in the system.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allUsers.length,
        itemBuilder: (context, index) {
          final user = _allUsers[index];
          return _UserCard(
            user: user,
            onRoleChange: () => setState(() => _selectedUser = user),
          );
        },
      ),
    );
  }

  // Role Change Form
  Widget _RoleChangeForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
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
                    'Change User Role',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedUser = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedUser?.name ?? '',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _selectedUser?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current Role: ${_selectedUser?.roleDisplayName ?? ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Role Selection
                  Text(
                    'New Role',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _newRole ?? _selectedUser?.role,
                      hint: const Text('Select new role'),
                      isExpanded: true,
                      underline: const SizedBox(),
                      onChanged: (role) => setState(() => _newRole = role),
                      items: const [
                        DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                        DropdownMenuItem(value: 'TEACHER', child: Text('Teacher')),
                        DropdownMenuItem(value: 'SECURITY', child: Text('Security')),
                        DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Super Admin')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  CustomButton(
                    onPressed: _newRole != null && _newRole != _selectedUser?.role
                        ? () => _changeUserRole(_selectedUser!.id, _newRole!)
                        : null,
                    text: 'Update Role',
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
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
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

class _PendingTeacherCard extends StatelessWidget {
  final User user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingTeacherCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
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
                  backgroundColor: AppTheme.warning.withOpacity(0.2),
                  child: Icon(Icons.person, color: AppTheme.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user.email,
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
            const SizedBox(height: 12),
            Text(
              'Registered: ${DateFormat('MMM dd, yyyy HH:mm').format(user.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: onReject,
                    text: 'Reject',
                    backgroundColor: AppTheme.error,
                    textColor: Colors.white,
                    icon: Icons.close,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    onPressed: onApprove,
                    text: 'Approve',
                    backgroundColor: AppTheme.success,
                    textColor: Colors.white,
                    icon: Icons.check,
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

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onRoleChange;

  const _UserCard({
    required this.user,
    required this.onRoleChange,
  });

  @override
  Widget build(BuildContext context) {
    Color roleColor = AppTheme.info;
    IconData roleIcon = Icons.person;
    
    switch (user.role) {
      case 'SUPER_ADMIN':
        roleColor = Colors.purple;
        roleIcon = Icons.admin_panel_settings;
        break;
      case 'TEACHER':
        roleColor = AppTheme.info;
        roleIcon = Icons.school;
        break;
      case 'STUDENT':
        roleColor = AppTheme.success;
        roleIcon = Icons.person;
        break;
      case 'SECURITY':
        roleColor = AppTheme.warning;
        roleIcon = Icons.security;
        break;
    }

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
                  backgroundColor: roleColor.withOpacity(0.2),
                  child: Icon(roleIcon, color: roleColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user.email,
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
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.roleDisplayName,
                    style: TextStyle(
                      color: roleColor,
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
                Expanded(
                  child: Text(
                    'Joined: ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                if (!user.isApproved && !user.isStudent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Not Approved',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            CustomButton(
              onPressed: onRoleChange,
              text: 'Change Role',
              isOutlined: true,
              icon: Icons.edit,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}