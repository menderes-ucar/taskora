import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/organization_service.dart';

import '../../contracts/logic/contracts_provider.dart';
import '../../freelancer/proposals/providers/proposals_provider.dart';
import '../../jobs/domain/providers/job_provider.dart';
import '../../messages/domain/providers/messages_proivder.dart';
import '../../wallet/providers/transactions_provider.dart';
import '../../wallet/providers/wallet_provider.dart';

class OrganizationContext {
  final List<Map<String, dynamic>> organizations;
  final String? activeOrganizationId;
  final bool isLoading;
  final String? error;

  const OrganizationContext({
    this.organizations = const [],
    this.activeOrganizationId,
    this.isLoading = false,
    this.error,
  });

  Map<String, dynamic>? get activeOrganization {
    final id = activeOrganizationId;
    if (id == null) return null;

    for (final organization in organizations) {
      if (organization['organization_id']?.toString() == id) {
        return organization;
      }
    }

    return null;
  }

  OrganizationContext copyWith({
    List<Map<String, dynamic>>? organizations,
    String? activeOrganizationId,
    bool clearActiveOrganization = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OrganizationContext(
      organizations: organizations ?? this.organizations,
      activeOrganizationId: clearActiveOrganization
          ? null
          : (activeOrganizationId ?? this.activeOrganizationId),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final organizationServiceProvider = Provider<OrganizationService>((ref) {
  return OrganizationService();
});

final organizationContextProvider =
StateNotifierProvider<OrganizationContextNotifier, OrganizationContext>(
      (ref) => OrganizationContextNotifier(
    ref,
    ref.read(organizationServiceProvider),
  ),
);

class OrganizationContextNotifier
    extends StateNotifier<OrganizationContext> {
  final Ref _ref;
  final OrganizationService _service;
  bool _disposed = false;

  OrganizationContextNotifier(this._ref, this._service)
      : super(const OrganizationContext()) {
    load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (_disposed) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final organizations = await _service.getMyOrganizations();
      final activeId = await _service.getCurrentOrganizationId();

      if (_disposed) return;

      state = OrganizationContext(
        organizations: organizations,
        activeOrganizationId: activeId,
      );
    } catch (e, stack) {
      debugPrint('[OrganizationContext] load failed: $e\n$stack');

      if (_disposed) return;

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void _invalidateTenantProviders() {
    _ref.invalidate(jobsProvider);
    _ref.invalidate(proposalsProvider);
    _ref.invalidate(contractsProvider);
    _ref.invalidate(messagesProvider);
    _ref.invalidate(walletProvider);
    _ref.invalidate(transactionsProvider);

    // openJobsProvider is derived from jobsProvider, so invalidating
    // jobsProvider is sufficient and avoids redundant recomputation.
  }

  Future<void> switchOrganization(String organizationId) async {
    if (_disposed || organizationId == state.activeOrganizationId) {
      return;
    }

    final normalizedId = organizationId.trim();
    if (normalizedId.isEmpty) {
      state = state.copyWith(
        error: 'Geçerli bir organizasyon seçilmelidir.',
      );
      return;
    }

    final allowed = state.organizations.any(
          (organization) =>
      organization['organization_id']?.toString() == normalizedId,
    );

    if (!allowed) {
      state = state.copyWith(
        error: 'Bu organizasyona erişim yetkiniz yok.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _service.switchActiveOrganization(normalizedId);

      if (_disposed) return;

      // Server is authoritative. Do not invalidate tenant-bound caches
      // until the switch has been confirmed by a fresh server read.
      final organizations = await _service.getMyOrganizations();
      final activeId = await _service.getCurrentOrganizationId();

      if (_disposed) return;

      if (activeId != normalizedId) {
        throw StateError(
          'Organizasyon değişikliği sunucu tarafından doğrulanamadı.',
        );
      }

      state = OrganizationContext(
        organizations: organizations,
        activeOrganizationId: activeId,
      );

      _invalidateTenantProviders();
    } catch (e, stack) {
      debugPrint('[OrganizationContext] switch failed: $e\n$stack');

      if (_disposed) return;

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      rethrow;
    }
  }
}
