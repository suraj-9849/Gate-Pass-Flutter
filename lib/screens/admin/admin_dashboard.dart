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
  List<GatePass> _allGatePasses = [];
  bool _isLoading = false;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  List<String> _filterOptions = ['All', 'Students', 'Teachers', 'Security'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _loadData();

    // Auto-refresh every 45 seconds for admin dashboard
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
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

    final gatePassProvider =
        Provider.of<GatePassProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final futures = await Future.wait([
        gatePassProvider.loadPendingTeachers(token: authProvider.token),
        gatePassProvider.loadAllUsers(token: authProvider.token),
        _loadAllGatePasses(),
      ]);

      setState(() {
        _pendingTeachers = futures[0] as List<User>;
        _allUsers = futures[1] as List<User>;
        _allGatePasses = futures[2] as List<GatePass>;
      });
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<GatePass>> _loadAllGatePasses() async {
    // This would typically come from an admin-specific API endpoint
    // For now, we'll simulate getting all gate passes
    try {
      final gatePassProvider =
          Provider.of<GatePassProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Combine student passes, active passes, and scanned passes
      final studentPasses =
          await gatePassProvider.loadStudentPasses(token: authProvider.token);
      final activePasses =
          await gatePassProvider.loadActivePasses(token: authProvider.token);
      final scannedPasses =
          await gatePassProvider.loadScannedPasses(token: authProvider.token);

      final allPasses = <GatePass>[];
      allPasses.addAll(activePasses);
      allPasses.addAll(scannedPasses);

      // Remove duplicates based on ID
      final uniquePasses = <String, GatePass>{};
      for (final pass in allPasses) {
        uniquePasses[pass.id] = pass;
      }

      return uniquePasses.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
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

  List<GatePass> _getFilteredGatePasses() {
    return _allGatePasses.where((pass) {
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
              _buildTabBar(),
              Expanded(child: _buildTabViews()),
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
            child: const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 24),
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
          // Refresh button
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success
                          .withOpacity(0.4 * _pulseController.value),
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
          // ADD THIS: Admin Profile Button
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
                          authProvider.user?.name
                                  .substring(0, 1)
                                  .toUpperCase() ??
                              'A',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 16),
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
                  hintText: 'Search users, gate passes...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon:
                              Icon(Icons.clear, color: AppTheme.textSecondary),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
              title: 'Pending Teachers',
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
              title: 'Total Passes',
              value: _allGatePasses.length.toString(),
              icon: Icons.assignment,
              gradient: LinearGradient(
                colors: [AppTheme.success, AppTheme.success.withOpacity(0.7)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatsCard(
              title: 'Active Today',
              value: _allGatePasses
                  .where(
                      (p) => DateUtils.isSameDay(p.createdAt, DateTime.now()))
                  .length
                  .toString(),
              icon: Icons.today,
              gradient: LinearGradient(
                colors: [AppTheme.error, AppTheme.error.withOpacity(0.7)],
              ),
            ),
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
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pending_actions, size: 16),
                const SizedBox(width: 4),
                Text('Pending (${_pendingTeachers.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text('Users (${_getFilteredUsers().length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment, size: 16),
                const SizedBox(width: 4),
                Text('Passes (${_getFilteredGatePasses().length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics, size: 16),
                const SizedBox(width: 4),
                const Text('Analytics'),
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
          _buildGatePassesTab(),
          _buildAnalyticsTab(),
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
      color: AppTheme.error,
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
          return _UserCard(user: filteredUsers[index]);
        },
      ),
    );
  }

  Widget _buildGatePassesTab() {
    final filteredPasses = _getFilteredGatePasses();

    if (filteredPasses.isEmpty) {
      return _EmptyState(
        icon: Icons.assignment,
        title: 'No Gate Passes Found',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try different search terms'
            : 'No gate passes available',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.error,
      child: ListView.builder(
        itemCount: filteredPasses.length,
        itemBuilder: (context, index) {
          return _GatePassCard(gatePass: filteredPasses[index]);
        },
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final todayPasses = _allGatePasses
        .where((p) => DateUtils.isSameDay(p.createdAt, DateTime.now()))
        .length;
    final approvedPasses = _allGatePasses.where((p) => p.isApproved).length;
    final pendingPasses = _allGatePasses.where((p) => p.isPending).length;
    final rejectedPasses = _allGatePasses.where((p) => p.isRejected).length;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _AnalyticsCard(
                  title: 'Today\'s Passes',
                  value: todayPasses.toString(),
                  icon: Icons.today,
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnalyticsCard(
                  title: 'Approved',
                  value: approvedPasses.toString(),
                  icon: Icons.check_circle,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AnalyticsCard(
                  title: 'Pending',
                  value: pendingPasses.toString(),
                  icon: Icons.pending,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnalyticsCard(
                  title: 'Rejected',
                  value: rejectedPasses.toString(),
                  icon: Icons.cancel,
                  color: AppTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTopTeachersCard(),
          const SizedBox(height: 20),
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildTopTeachersCard() {
    final teacherStats = <String, Map<String, dynamic>>{};

    for (final pass in _allGatePasses.where((p) => p.teacher != null)) {
      final teacherId = pass.teacher!.id;
      final teacherName = pass.teacher!.name;

      if (teacherStats.containsKey(teacherId)) {
        teacherStats[teacherId]!['count']++;
        if (pass.isApproved) teacherStats[teacherId]!['approved']++;
      } else {
        teacherStats[teacherId] = {
          'name': teacherName,
          'count': 1,
          'approved': pass.isApproved ? 1 : 0,
        };
      }
    }

    final sortedTeachers = teacherStats.entries.toList()
      ..sort((a, b) => b.value['count'].compareTo(a.value['count']));

    return Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: AppTheme.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Top Teachers by Gate Pass Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedTeachers.take(5).map((entry) {
              final teacher = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          teacher['name']
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warning,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher['name'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${teacher['approved']} approved / ${teacher['count']} total',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        teacher['count'].toString(),
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final recentPasses = _allGatePasses.take(10).toList();

    return Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppTheme.info, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recentPasses.map((pass) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(pass.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pass.student?.name ?? 'Unknown'} → ${pass.teacher?.name ?? 'Unknown Teacher'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${pass.statusDisplayName} • ${DateFormat('MMM dd, HH:mm').format(pass.createdAt)}',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppTheme.success;
      case 'REJECTED':
        return AppTheme.error;
      case 'USED':
        return AppTheme.info;
      case 'PENDING':
      default:
        return AppTheme.warning;
    }
  }

  Future<void> _approveTeacher(String teacherId) async {
    final gatePassProvider =
        Provider.of<GatePassProvider>(context, listen: false);
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
        content: const Text(
            'Are you sure you want to reject this teacher application?'),
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
      final gatePassProvider =
          Provider.of<GatePassProvider>(context, listen: false);
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

// Helper Widgets
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
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
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
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  const _UserCard({required this.user});

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
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isApproved
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.isApproved ? 'Approved' : 'Pending',
                    style: TextStyle(
                      color:
                          user.isApproved ? AppTheme.success : AppTheme.warning,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
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

class _GatePassCard extends StatelessWidget {
  final GatePass gatePass;

  const _GatePassCard({required this.gatePass});

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
                        '${gatePass.student?.name ?? 'Unknown Student'} → ${gatePass.teacher?.name ?? 'Unknown Teacher'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (gatePass.student?.rollNo != null)
                        Text(
                          'Roll: ${gatePass.student!.rollNo}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Icon(Icons.calendar_today,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(gatePass.requestDate),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Until ${DateFormat('MMM dd, HH:mm').format(gatePass.validUntil)}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (gatePass.remarks != null && gatePass.remarks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
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
      case 'REJECTED':
        return AppTheme.error;
      case 'USED':
        return AppTheme.info;
      case 'PENDING':
      default:
        return AppTheme.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'USED':
        return Icons.done_all;
      case 'PENDING':
      default:
        return Icons.pending;
    }
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
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
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
