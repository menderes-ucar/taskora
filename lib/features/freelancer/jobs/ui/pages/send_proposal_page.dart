import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../shared/enums/proposal_status.dart';
import '../../../../../shared/models/proposal_model.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../proposals/logic/proposals_provider.dart';



class SendProposalPage extends ConsumerStatefulWidget {
  final String jobId;
  final String jobTitle;

  const SendProposalPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  ConsumerState<SendProposalPage> createState() => _SendProposalPageState();
}

class _SendProposalPageState extends ConsumerState<SendProposalPage> {
  final _formKey = GlobalKey<FormState>();

  final amountController = TextEditingController();
  final deliveryDaysController = TextEditingController();
  final coverLetterController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    deliveryDaysController.dispose();
    coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    try {
      final alreadySent = await ref
          .read(proposalsProvider.notifier)
          .hasFreelancerAlreadyProposed(
        jobId: widget.jobId,
        freelancerId: currentUser.id,
      );

      if (alreadySent) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu ilana zaten teklif gönderdiniz'),
            ),
          );
        }
        return;
      }

      final proposal = ProposalModel(
        id: '',
        jobId: widget.jobId,
        freelancerId: currentUser.id,
        freelancerName: currentUser.name,
        amount: double.tryParse(amountController.text.trim()) ?? 0,
        deliveryDays: int.tryParse(deliveryDaysController.text.trim()) ?? 1,
        coverLetter: coverLetterController.text.trim(),
        status: ProposalStatus.pending,
        createdAt: DateTime.now(),
      );

      await ref.read(proposalsProvider.notifier).addProposal(proposal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teklif başarıyla gönderildi'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Teklif Ver'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _ProposalHero(jobTitle: widget.jobTitle),
            const SizedBox(height: 16),
            SectionCard(
              title: 'İş',
              child: Text(
                widget.jobTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _FormSectionTitle('Teklif Detayları'),
            const SizedBox(height: 10),
            _StyledTextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              hintText: 'Teklif tutarı',
              validator: (value) =>
              value == null || value.trim().isEmpty ? 'Tutar girin' : null,
            ),
            const SizedBox(height: 14),
            _StyledTextField(
              controller: deliveryDaysController,
              keyboardType: TextInputType.number,
              hintText: 'Teslim süresi (gün)',
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Teslim süresi girin'
                  : null,
            ),
            const SizedBox(height: 14),
            _StyledTextField(
              controller: coverLetterController,
              maxLines: 6,
              hintText: 'Teklif açıklaması / ön yazı',
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Açıklama girin'
                  : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Teklifi Gönder',
              icon: Icons.send_rounded,
              onPressed: _submitProposal,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProposalHero extends StatelessWidget {
  final String jobTitle;

  const _ProposalHero({
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0E2238),
            Color(0xFF103847),
            Color(0xFF0BA99C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SEND PROPOSAL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            jobTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bütçeni, teslim süreni ve neden uygun olduğunu net şekilde sun.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primaryDark),
        ),
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  final String text;

  const _FormSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: AppColors.black,
      ),
    );
  }
}