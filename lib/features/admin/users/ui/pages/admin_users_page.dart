import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/enums/user_role.dart';
import '../../../../../shared/models/user_model.dart';
import '../../../admin_guard.dart';
import '../../data/admin_user_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _userService = AdminUserService();
  final _searchController = TextEditingController();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Hata: $e'),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredUsers = _allUsers);
      return;
    }

    final q = query.toLowerCase().trim();
    setState(() {
      _filteredUsers = _allUsers.where((u) {
        final name = (u.name ?? '').toLowerCase();
        final email = u.email.toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    });
  }

  Future<void> _toggleBan(UserModel user) async {
    final newBanStatus = !(user.isBanned ?? false);
    final actionText = newBanStatus ? 'banlamak' : 'engelini kaldırmak';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          'Kullanıcıyı ${newBanStatus ? "Banla" : "Aktifleştir"}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '${user.email} kullanıcısını $actionText istediğinize emin misiniz?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newBanStatus ? AppColors.danger : AppColors.success,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(newBanStatus ? 'Banla' : 'Engeli Kaldır'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _userService.toggleUserBan(user.id, newBanStatus);
      await _fetchUsers(); // Listeyi tazele
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.danger, content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        backgroundColor: AppColors.dark,
        appBar: AppBar(
          title: const Text('Kullanıcı Yönetimi'),
          backgroundColor: AppColors.dark,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Arama Kutusu
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _filterUsers,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'İsim veya e-posta ile ara...',
                  hintStyle: const TextStyle(color: AppColors.grey),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Kullanıcı Listesi
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                  ? const Center(
                child: Text(
                  'Kullanıcı bulunamadı.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, i) {
                  final user = _filteredUsers[i];
                  final isBanned = user.isBanned ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isBanned
                            ? AppColors.danger.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRoleColor(user.role),
                        child: Icon(
                          _getRoleIcon(user.role),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        user.name?.isNotEmpty == true ? user.name! : 'İsimsiz Kullanıcı',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: isBanned ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.email,
                            style: const TextStyle(color: AppColors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _RoleBadge(role: user.role),
                              if (isBanned) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'BANLI',
                                    style: TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: user.role == UserRole.admin
                          ? const SizedBox.shrink() // Admin kendini banlayamasın
                          : IconButton(
                        icon: Icon(
                          isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                          color: isBanned ? AppColors.success : AppColors.danger,
                        ),
                        onPressed: () => _toggleBan(user),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.employer:
        return AppColors.primary;
      case UserRole.freelancer:
        return Colors.orange;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.security_rounded;
      case UserRole.employer:
        return Icons.business_center_rounded;
      case UserRole.freelancer:
        return Icons.person_rounded;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}