import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/organization_member_model.adrt.dart';
import '../../data/organization_service.dart';
import '../../../../shared/models/organization_invitation_model.dart';
import '../../providers/organization_context_provider.dart';

class OrganizationPage extends ConsumerStatefulWidget {
  const OrganizationPage({super.key});

  @override
  ConsumerState<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends ConsumerState<OrganizationPage> {
  late final OrganizationService _service;
  bool _loading = true;
  bool _actionLoading = false;
  String _role = 'none';
  Map<String, dynamic>? _organization;
  List<OrganizationMemberModel> _members = const [];
  List<OrganizationInvitationModel> _invitations = const [];
  String? _error;

  bool get _canManage => _role == 'owner' || _role == 'admin';

  @override
  void initState() {
    super.initState();
    _service = ref.read(organizationServiceProvider);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final organization = await _service.getCurrentOrganization();
      if (organization == null) {
        if (!mounted) return;
        setState(() {
          _organization = null;
          _members = const [];
          _invitations = const [];
          _role = 'none';
          _loading = false;
        });
        return;
      }

      final results = await Future.wait([
        _service.getCurrentOrganizationRole(),
        _service.getMembers(),
        _service.getInvitations(),
      ]);

      if (!mounted) return;
      setState(() {
        _organization = organization;
        _role = results[0] as String;
        _members = results[1] as List<OrganizationMemberModel>;
        _invitations = results[2] as List<OrganizationInvitationModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();
    var selectedRole = 'member';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Üye Davet Et'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      hintText: 'ornek@firma.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: const [
                      DropdownMenuItem(value: 'member', child: Text('Üye')),
                      DropdownMenuItem(value: 'admin', child: Text('Yönetici')),
                      DropdownMenuItem(value: 'billing', child: Text('Finans')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedRole = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    final email = emailController.text.trim();
                    if (email.isEmpty) return;
                    Navigator.pop(dialogContext, '$selectedRole|$email');
                  },
                  child: const Text('Davet Gönder'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    if (result == null || !mounted) return;

    final parts = result.split('|');
    if (parts.length != 2) return;

    setState(() => _actionLoading = true);
    try {
      final invitation = await _service.inviteMember(
        email: parts[1],
        role: parts[0],
      );

      await Clipboard.setData(ClipboardData(text: invitation.token));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Davet oluşturuldu. Güvenli davet tokenı panoya kopyalandı.'),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Davet oluşturulamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _revoke(OrganizationInvitationModel invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daveti iptal et'),
        content: Text('${invitation.email} için oluşturulan davet iptal edilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('İptal Et')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await _service.revokeInvitation(invitation.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Davet iptal edilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _acceptInvitationDialog() async {
    final controller = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Davet Kabul Et'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Davet tokenı',
            hintText: 'Davet tokenını yapıştırın',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kabul Et'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (token == null || token.isEmpty || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await _service.acceptInvitation(token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organizasyon daveti kabul edildi.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Davet kabul edilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _changeRole(OrganizationMemberModel member, String role) async {
    if (member.userId == _service.currentUserId) return;
    setState(() => _actionLoading = true);
    try {
      await _service.updateMemberRole(userId: member.userId, role: role);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol değiştirilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _removeMember(OrganizationMemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Üyeyi kaldır'),
        content: Text('${member.name} organizasyondan kaldırılsın mı?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaldır')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actionLoading = true);
    try {
      await _service.removeMember(member.userId);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Üye kaldırılamadı: $e')));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _transferOwnership(OrganizationMemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sahipliği devret'),
        content: Text('Organizasyon sahipliği ${member.name} hesabına devredilecek. Devam edilsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Devret')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actionLoading = true);
    try {
      await _service.transferOwnership(member.userId);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sahiplik devredilemedi: $e')));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _leaveOrganization() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Organizasyondan ayrıl'),
        content: const Text('Bu organizasyondan ayrılmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ayrıl')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actionLoading = true);
    try {
      await _service.leaveOrganization();
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Organizasyondan ayrılamadı: $e')));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_organization == null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Organizasyon'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business_outlined, size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                const Text(
                  'Henüz bir organizasyona bağlı değilsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Size gönderilen bir davet varsa token ile kabul edebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _actionLoading ? null : _acceptInvitationDialog,
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Davet Kabul Et'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final organizationName = _organization!['name']?.toString() ?? 'Organizasyon';
    final plan = _organization!['plan']?.toString() ?? 'free';

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Organizasyon'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final tenant = ref.watch(organizationContextProvider);
              if (tenant.organizations.length < 2) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<String>(
                tooltip: 'Organizasyon değiştir',
                icon: const Icon(Icons.swap_horiz_rounded),
                enabled: !tenant.isLoading && !_actionLoading,
                onSelected: (organizationId) async {
                  if (organizationId == tenant.activeOrganizationId) return;
                  setState(() => _actionLoading = true);
                  try {
                    await ref
                        .read(organizationContextProvider.notifier)
                        .switchOrganization(organizationId);
                    await _load();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Organizasyon değiştirilemedi: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _actionLoading = false);
                  }
                },
                itemBuilder: (context) {
                  return tenant.organizations.map((organization) {
                    final id = organization['organization_id']?.toString() ?? '';
                    final name = organization['name']?.toString() ?? 'Organizasyon';
                    final role = organization['member_role']?.toString() ?? '';
                    final active = id == tenant.activeOrganizationId;
                    return PopupMenuItem<String>(
                      value: id,
                      child: Row(
                        children: [
                          Icon(
                            active ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text('$name • $role')),
                        ],
                      ),
                    );
                  }).toList();
                },
              );
            },
          ),
          IconButton(
            onPressed: _loading || _actionLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: Colors.white70)),
        ),
      )
          : Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _OrganizationHeader(name: organizationName, plan: plan, role: _role),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Üyeler',
                  icon: Icons.groups_rounded,
                  trailing: Text('${_members.length}', style: const TextStyle(color: Colors.white70)),
                  child: Column(
                    children: _members
                        .map(
                          (member) => _MemberTile(
                        member: member,
                        currentRole: _role,
                        currentUserId: _service.currentUserId,
                        onRoleChange: (role) => _changeRole(member, role),
                        onRemove: () => _removeMember(member),
                        onTransferOwnership: () => _transferOwnership(member),
                      ),
                    )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Bekleyen Davetler',
                  icon: Icons.mail_outline_rounded,
                  trailing: _canManage
                      ? IconButton(
                    onPressed: _actionLoading ? null : _showInviteDialog,
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                  )
                      : const SizedBox.shrink(),
                  child: _invitations.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Bekleyen davet yok.', style: TextStyle(color: Colors.white60)),
                  )
                      : Column(
                    children: _invitations
                        .map((invitation) => _InvitationTile(
                      invitation: invitation,
                      canManage: _canManage,
                      onRevoke: () => _revoke(invitation),
                    ))
                        .toList(),
                  ),
                ),
                if (!_canManage) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _actionLoading ? null : _acceptInvitationDialog,
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Başka bir davet tokenı kullan'),
                  ),
                ],
                if (_role != 'owner' && _role != 'none') ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _actionLoading ? null : _leaveOrganization,
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: const Text('Organizasyondan Ayrıl'),
                  ),
                ],
              ],
            ),
          ),
          if (_actionLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrganizationHeader extends StatelessWidget {
  final String name;
  final String plan;
  final String role;

  const _OrganizationHeader({required this.name, required this.plan, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryDark,
            child: Icon(Icons.business_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${plan.toUpperCase()} • ${role.toUpperCase()}', style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget trailing;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              trailing,
            ],
          ),
          const Divider(color: Colors.white10),
          child,
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final OrganizationMemberModel member;
  final String currentRole;
  final String? currentUserId;
  final Future<void> Function(String role) onRoleChange;
  final VoidCallback onRemove;
  final VoidCallback onTransferOwnership;

  const _MemberTile({
    required this.member,
    required this.currentRole,
    required this.currentUserId,
    required this.onRoleChange,
    required this.onRemove,
    required this.onTransferOwnership,
  });

  bool get _isCurrentUser => member.userId == currentUserId;
  bool get _canEdit => !_isCurrentUser &&
      member.status == 'active' &&
      (currentRole == 'owner' || (currentRole == 'admin' && member.role != 'owner' && member.role != 'admin'));

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryDark,
        backgroundImage: member.avatarUrl?.isNotEmpty == true ? NetworkImage(member.avatarUrl!) : null,
        child: member.avatarUrl?.isNotEmpty == true ? null : const Icon(Icons.person, color: Colors.white70),
      ),
      title: Text(member.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      subtitle: Text('${member.email} • ${member.role}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: _canEdit
          ? PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white70),
        onSelected: (value) {
          if (value == 'remove') onRemove();
          if (value == 'owner') onTransferOwnership();
          if (value == 'admin' || value == 'member' || value == 'billing') onRoleChange(value);
        },
        itemBuilder: (context) => [
          if (currentRole == 'owner') ...[
            const PopupMenuItem(value: 'admin', child: Text('Yönetici yap')),
            const PopupMenuItem(value: 'member', child: Text('Üye yap')),
            const PopupMenuItem(value: 'billing', child: Text('Finans yap')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'owner', child: Text('Sahipliği devret')),
          ] else ...[
            const PopupMenuItem(value: 'member', child: Text('Üye yap')),
            const PopupMenuItem(value: 'billing', child: Text('Finans yap')),
          ],
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'remove', child: Text('Üyeyi kaldır')),
        ],
      )
          : Text(member.role, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _InvitationTile extends StatelessWidget {
  final OrganizationInvitationModel invitation;
  final bool canManage;
  final VoidCallback onRevoke;

  const _InvitationTile({required this.invitation, required this.canManage, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final expired = invitation.isExpired || invitation.status == 'expired';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(expired ? Icons.timer_off_outlined : Icons.mail_outline, color: expired ? Colors.orange : Colors.white70),
      title: Text(invitation.email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      subtitle: Text(
        '${invitation.role} • ${expired ? 'Süresi doldu' : 'Bekliyor'}',
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      trailing: canManage && invitation.status == 'pending' && !expired
          ? IconButton(onPressed: onRevoke, icon: const Icon(Icons.close_rounded, color: AppColors.danger))
          : null,
    );
  }
}
