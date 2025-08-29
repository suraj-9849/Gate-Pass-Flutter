import 'package:flutter/material.dart';
import 'package:gate_pass_flutter/screens/profile/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../models/gate_pass_model.dart';
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
  late AnimationController _pulseController;
  Timer? _autoRefreshTimer;

  List<User> _pendingTeachers = [];
  List<User> _allUsers = [];
  List<GatePass> _approvedStudentPasses = [];
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  List<String> _filterOptions = ['All', 'Students', 'Teachers', 'Security'];

  // Role change functionality
  User? _selectedUser;
  String? _newRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed from 4 to 3 tabs
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _loadData();

    // Auto-refresh every 30 seconds for real-time notifications
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await Future.wait([
        _loadPendingTeachers(),
        _loadAllUsers(),
        _loadApprovedStudentPasses(),
        _loadNotifications(),
      ]);
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingTeachers() async {
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final teachers = await gatePassProvider.loadPendingTeachers(token: authProvider.token);
    setState(() => _pendingTeachers = teachers);
  }

  Future<void> _loadAllUsers() async {
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final users = await gatePassProvider.loadAllUsers(token: authProvider.token);
    setState(() => _allUsers = users);
  }

  Future<void> _loadApprovedStudentPasses() async {
    // Load approved student gate passes with their current status
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final activePasses = await gatePassProvider.loadActivePasses(token: authProvider.token);
      final scannedPasses = await gatePassProvider.loadScannedPasses(token: authProvider.token);
      
      final allApprovedPasses = <GatePass>[];
      allApprovedPasses.addAll(activePasses.where((pass) => pass.isApproved));
      allApprovedPasses.addAll(scannedPasses);
      
      // Remove duplicates and sort by creation date
      final uniquePasses = <String, GatePass>{};
      for (final pass in allApprovedPasses) {
        uniquePasses[pass.id] = pass;
      }
      
      setState(() {
        _approvedStudentPasses = uniquePasses.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      debugPrint('Error loading approved student passes: $e');
    }
  }

  Future<void> _loadNotifications() async {
    // Load notifications about scans and other activities
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // This would be an API call to get notifications
      // For now, we'll create mock notifications based on recent scans
      final mockNotifications = <NotificationItem>[];
      
      for (final pass in _approvedStudentPasses) {
        if (pass.status == 'USED' && pass.usedAt != null) {
          mockNotifications.add(NotificationItem(
            id: 'scan_${pass.id}',
            type: NotificationType.scan,
            title: 'Student Scanned',
            message: '${pass.student?.name} was scanned by security',
            timestamp: pass.usedAt!,
            isRead: false,
            studentName: pass.student?.name,
            teacherName: pass.teacher?.name,
          ));
        }
      }
      
      setState(() {
        _notifications = mockNotifications
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  List<User> _getFilteredUsers() {
    var filtered = _allUsers.where((user) {
      final matchesSearch = user.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user.rollNo?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Students' && user.role == 'STUDENT') ||
          (_selectedFilter == 'Teachers' && user.role == 'TEACHER') ||
          (_selectedFilter == 'Security' && user.role == 'SECURITY');

      return matchesSearch && matchesFilter;
    }).toList();

    return filtered..sort((a, b) => a.name.compareTo(b.name));
  }

  List<GatePass> _getFilteredApprovedPasses() {
    return _approvedStudentPasses.where((pass) {
      final studentName = pass.student?.name.toLowerCase() ?? '';
      final teacherName = pass.teacher?.name.toLowerCase() ?? '';
      final reason = pass.reason.toLowerCase();
      final rollNo = pass.student?.rollNo?.toLowerCase() ?? '';

      return studentName.contains(_searchQuery.toLowerCase()) ||
          teacherName.contains(_searchQuery.toLowerCase()) ||
          reason.contains(_searchQuery.toLowerCase()) ||
          rollNo.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.error.withOpacity(0.1),
              AppTheme.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildQuickStats(),
              _buildNotificationBanner(),
              _buildTabBar(),
              Expanded(child: _buildTabViews()),
              if (_selectedUser != null) _buildRoleChangeModal(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.error, AppTheme.error.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Control',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                Text(
                  'System Management',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          // Notification Bell
          Stack(
            children: [
              IconButton(
                onPressed: () => _showNotifications(),
                icon: Icon(
                  Icons.notifications,
                  color: AppTheme.textPrimary,
                  size: 28,
                ),
              ),
              if (_notifications.where((n) => !n.isRead).isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '${_notifications.where((n) => !n.isRead).length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          // Refresh button
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withOpacity(0.4 * _pulseController.value),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _isLoading ? null : _loadData,
                  icon: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.error,
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: AppTheme.textPrimary,
                          size: 28,
                        ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Admin Profile Button
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.error, AppTheme.error.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.error.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Text(
                          authProvider.user?.name.substring(0, 1).toUpperCase() ?? 'A',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.admin_panel_settings, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search users, students, passes...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: Icon(Icons.clear, color: AppTheme.textSecondary),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButton<String>(
              value: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
              underline: const SizedBox(),
              icon: Icon(Icons.filter_list, color: AppTheme.textSecondary),
              items: _filterOptions.map((filter) {
                return DropdownMenuItem(
                  value: filter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatsCard(
              title: 'Total Users',
              value: _allUsers.length.toString(),
              icon: Icons.people,
              gradient: LinearGradient(
                colors: [AppTheme.info, AppTheme.info.withOpacity(0.7)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatsCard(
              title: 'Pending',
              value: _pendingTeachers.length.toString(),
              icon: Icons.pending,
              gradient: LinearGradient(
                colors: [AppTheme.warning, AppTheme.warning.withOpacity(0.7)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatsCard(
              title: 'Approved',
              value: _approvedStudentPasses.length.toString(),
              icon: Icons.check_circle,
              gradient: LinearGradient(
                colors: [AppTheme.success, AppTheme.success.withOpacity(0.7)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatsCard(
              title: 'Scanned Today',
              value: _approvedStudentPasses
                  .where((p) => p.status == 'USED' && 
                         p.usedAt != null && 
                         DateUtils.isSameDay(p.usedAt!, DateTime.now()))
                  .length
                  .toString(),
              icon: Icons.qr_code_scanner,
              gradient: LinearGradient(
                colors: [AppTheme.error, AppTheme.error.withOpacity(0.7)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBanner() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    if (unreadCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: AppTheme.info, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$unreadCount new notification${unreadCount > 1 ? 's' : ''}',
              style: TextStyle(
                color: AppTheme.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _showNotifications,
            child: Text('View', style: TextStyle(color: AppTheme.info)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pending_actions, size: 16),
                const SizedBox(width: 4),
                Flexible(child: Text('Pending (${_pendingTeachers.length})', overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Flexible(child: Text('Users (${_getFilteredUsers().length})', overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_turned_in, size: 16),
                const SizedBox(width: 4),
                Flexible(child: Text('Students (${_getFilteredApprovedPasses().length})', overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabViews() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTeachersTab(),
          _buildUsersTab(),
          _buildApprovedStudentsTab(), // New tab for approved students
        ],
      ),
    );
  }

  Widget _buildPendingTeachersTab() {
    if (_pendingTeachers.isEmpty) {
      return _EmptyState(
        icon: Icons.pending_actions,
        title: 'No Pending Teachers',
        subtitle: 'All teacher applications have been reviewed',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.cardColor,
      child: ListView.builder(
        itemCount: _pendingTeachers.length,
        itemBuilder: (context, index) {
          return _PendingTeacherCard(
            teacher: _pendingTeachers[index],
            onApprove: () => _approveTeacher(_pendingTeachers[index].id),
            onReject: () => _rejectTeacher(_pendingTeachers[index].id),
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    final filteredUsers = _getFilteredUsers();

    if (filteredUsers.isEmpty) {
      return _EmptyState(
        icon: Icons.people,
        title: 'No Users Found',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try adjusting your search terms'
            : 'No users match the selected filter',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.error,
      child: ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          return _UserCard(
            user: filteredUsers[index],
            onRoleChange: () => setState(() => _selectedUser = filteredUsers[index]),
          );
        },
      ),
    );
  }

  Widget _buildApprovedStudentsTab() {
    final filteredPasses = _getFilteredApprovedPasses();

    if (filteredPasses.isEmpty) {
      return _EmptyState(
        icon: Icons.assignment_turned_in,
        title: 'No Approved Students Found',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try different search terms'
            : 'No approved student passes available',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.error,
      child: ListView.builder(
        itemCount: filteredPasses.length,
        itemBuilder: (context, index) {
          return _ApprovedStudentCard(gatePass: filteredPasses[index]);
        },
      ),
    );
  }

  Widget _buildRoleChangeModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Change User Role',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedUser?.name ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _selectedUser?.email ?? '',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Current Role: ${_selectedUser?.roleDisplayName ?? ''}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New Role',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _selectedUser = null;
                        _newRole = null;
                      }),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _newRole != null && _newRole != _selectedUser?.role
                          ? () => _changeUserRole(_selectedUser!.id, _newRole!)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Change Role'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return ListTile(
                      leading: Icon(
                        notification.type == NotificationType.scan
                            ? Icons.qr_code_scanner
                            : Icons.info,
                        color: notification.isRead
                            ? AppTheme.textSecondary
                            : AppTheme.info,
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.message),
                          Text(
                            DateFormat('MMM dd, HH:mm').format(notification.timestamp),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _markNotificationAsRead(notification.id),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _markNotificationAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    try {
      final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await gatePassProvider.changeUserRole(
        userId,
        newRole,
        token: authProvider.token,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role changed to $newRole successfully'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _selectedUser = null;
          _newRole = null;
        });
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to change role'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _approveTeacher(String teacherId) async {
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await gatePassProvider.approveTeacher(
      teacherId,
      token: authProvider.token,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Teacher approved successfully'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    }
  }

  Future<void> _rejectTeacher(String teacherId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Teacher'),
        content: const Text('Are you sure you want to reject this teacher application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await gatePassProvider.rejectTeacher(
        teacherId,
        token: authProvider.token,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Teacher application rejected'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    }
  }
}

// Helper Classes and Widgets
class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? studentName;
  final String? teacherName;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.studentName,
    this.teacherName,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      studentName: studentName,
      teacherName: teacherName,
    );
  }
}

enum NotificationType { scan, approval, rejection }

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ),
          FittedBox(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
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
    );
  }
}

class _PendingTeacherCard extends StatelessWidget {
  final User teacher;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingTeacherCard({
    required this.teacher,
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
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  child: Text(
                    teacher.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.warning,
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
                        teacher.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        teacher.email,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                    'PENDING',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Applied: ${DateFormat('MMM dd, yyyy').format(teacher.createdAt)}',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
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
  final VoidCallback? onRoleChange;

  const _UserCard({
    required this.user,
    this.onRoleChange,
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(user.role),
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
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.rollNo != null && user.rollNo!.isNotEmpty)
                    Text(
                      'Roll: ${user.rollNo}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.roleDisplayName,
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (onRoleChange != null)
                  IconButton(
                    onPressed: onRoleChange,
                    icon: Icon(Icons.edit, size: 16, color: AppTheme.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'STUDENT':
        return AppTheme.info;
      case 'TEACHER':
        return AppTheme.success;
      case 'SECURITY':
        return AppTheme.warning;
      case 'SUPER_ADMIN':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }
}

class _ApprovedStudentCard extends StatelessWidget {
  final GatePass gatePass;

  const _ApprovedStudentCard({required this.gatePass});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(gatePass.status).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(gatePass.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(gatePass.status),
                    color: _getStatusColor(gatePass.status),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gatePass.student?.name ?? 'Unknown Student',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (gatePass.student?.rollNo != null)
                        Text(
                          'Roll: ${gatePass.student!.rollNo}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        'Approved by: ${gatePass.teacher?.name ?? 'Unknown Teacher'}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(gatePass.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    gatePass.statusDisplayName.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(gatePass.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              gatePass.reason,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Valid until: ${DateFormat('MMM dd, HH:mm').format(gatePass.validUntil)}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (gatePass.status == 'USED' && gatePass.usedAt != null) ...[
                  Icon(Icons.qr_code_scanner, size: 14, color: AppTheme.info),
                  const SizedBox(width: 4),
                  Text(
                    'Scanned: ${DateFormat('HH:mm').format(gatePass.usedAt!)}',
                    style: TextStyle(
                      color: AppTheme.info,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            if (gatePass.remarks != null && gatePass.remarks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Remarks: ${gatePass.remarks}',
                  style: TextStyle(
                    color: AppTheme.info,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppTheme.success;
      case 'USED':
        return AppTheme.info;
      case 'EXPIRED':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'USED':
        return Icons.qr_code_scanner;
      case 'EXPIRED':
        return Icons.access_time;
      default:
        return Icons.pending;
    }
  }
}