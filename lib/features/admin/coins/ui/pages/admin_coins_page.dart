import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../auth/domain/entities/auth_user.dart';
import '../../../admin_guard.dart';
import '../../data/admin_coin_service.dart';

class AdminCoinsPage extends StatefulWidget {
  const AdminCoinsPage({super.key});

  @override
  State<AdminCoinsPage> createState() => _AdminCoinsPageState();
}

class _AdminCoinsPageState extends State<AdminCoinsPage> {
  final _coinService = AdminCoinService();
  final _searchController = TextEditingController();

  List<AuthUser> _allUsers = [];
  List<AuthUser> _filteredUsers = [];
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
      final users = await _coinService.getUsersWithBalances();
      setState(() {
        _allUsers = users;
        _applyFilter(_searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.danger, content: Text('Hata: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String query) {
    if (query.trim().isEmpty) {
      _filteredUsers = List.from(_allUsers);
      return;
    }
    final q = query.toLowerCase().trim();
    _filteredUsers = _allUsers.where((u) {
      return u.fullName.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
    }).toList();
  }

  void _showAdjustBalanceDialog(AuthUser user) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool isAdding = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              '${user.fullName} Bakiyesi',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mevcut Bakiye: ₺${user.coins}',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Bakiye Ekle (+)', style: TextStyle(fontWeight: FontWeight.bold)),
                          selectedColor: AppColors.success,
                          backgroundColor: Colors.white24,
                          selected: isAdding,
                          onSelected: (val) => setDialogState(() => isAdding = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Bakiye Düş (-)', style: TextStyle(fontWeight: FontWeight.bold)),
                          selectedColor: AppColors.danger,
                          backgroundColor: Colors.white24,
                          selected: !isAdding,
                          onSelected: (val) => setDialogState(() => isAdding = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Tutar (₺)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    style: const TextStyle(color: AppColors.black),
                    decoration: InputDecoration(
                      hintText: 'İşlem Notu (Opsiyonel)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAdding ? AppColors.success : AppColors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.trim()) ?? 0;
                  if (amount <= 0) return;

                  final finalAmount = isAdding ? amount : -amount;
                  final note = noteController.text.trim().isEmpty ? 'Admin manuel bakiye güncellemesi' : noteController.text.trim();

                  Navigator.pop(ctx);

                  try {
                    await _coinService.adjustUserBalance(
                      userId: user.id,
                      currentBalance: user.coins.toDouble(),
                      amountToAdd: finalAmount,
                      adminNote: note,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.success,
                          content: Text('Kullanıcı bakiyesi başarıyla güncellendi! 🎉'),
                        ),
                      );
                    }

                    _fetchUsers();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: AppColors.danger, content: Text('Hata: $e')),
                      );
                    }
                  }
                },
                child: const Text('Onayla', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: const Text('Bakiye Yönetimi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchUsers,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (q) => setState(() => _applyFilter(q)),
                style: const TextStyle(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: 'İsim veya e-posta ile ara...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryDark),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, i) {
                  final user = _filteredUsers[i];
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: const Icon(Icons.person, color: AppColors.primaryDark),
                      ),
                      title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.black)),
                      subtitle: Text('${user.email} • ${user.role.name.toUpperCase()}', style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₺${user.coins}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryDark, size: 28),
                            onPressed: () => _showAdjustBalanceDialog(user),
                          ),
                        ],
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
}