import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/rating_service.dart';
import '../../shared/models/rating_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class RatingPage extends ConsumerStatefulWidget {
  final String contractId;
  final String recipientId;
  final String recipientName;
  final RatingType ratingType;
  final VoidCallback? onRatingSubmitted;

  const RatingPage({
    Key? key,
    required this.contractId,
    required this.recipientId,
    required this.recipientName,
    required this.ratingType,
    this.onRatingSubmitted,
  }) : super(key: key);

  @override
  ConsumerState<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends ConsumerState<RatingPage> {
  late SupabaseRatingService _ratingService;
  double _rating = 5.0;
  final _reviewController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ratingService = SupabaseRatingService(Supabase.instance.client);
  }

  Future<void> _submitRating() async {
    if (_reviewController.text.isEmpty) {
      _showError('Lütfen bir yorum yazınız');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) throw Exception('Kullanıcı bulunamadı');

      final rating = RatingModel(
        id: const Uuid().v4(),
        contractId: widget.contractId,
        giverId: currentUser.id,
        recipientId: widget.recipientId,
        type: widget.ratingType,
        rating: _rating,
        review: _reviewController.text,
        createdAt: DateTime.now(),
      );

      await _ratingService.createRating(rating);

      _showSuccess('Puanlama başarıyla kaydedildi!');
      widget.onRatingSubmitted?.call();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      _showError('Puanlama hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.recipientName} Puanla'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Deneyiminizi Paylaşın',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.recipientName} ile çalışmanızı nasıl buldunuz?',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Rating stars selector
            _buildRatingSelector(),
            const SizedBox(height: 32),

            // Rating label
            Center(
              child: Text(
                _getRatingLabel(_rating),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getRatingColor(_rating),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Review text field
            const Text(
              'Yorumunuz',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Lütfen detaylı bir yorum yazınız...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRating,
                child: Text(_isLoading ? 'Gönderiliyor...' : 'Puanla ve Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starRating = index + 1;
            return GestureDetector(
              onTap: () => setState(() => _rating = starRating.toDouble()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  starRating <= _rating ? Icons.star : Icons.star_outline,
                  size: 48,
                  color:
                  starRating <= _rating ? Colors.amber : Colors.grey.shade400,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          '${_rating.toInt()} / 5',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getRatingLabel(double rating) {
    if (rating >= 4.5) return 'Mükemmel';
    if (rating >= 4.0) return 'Çok İyi';
    if (rating >= 3.0) return 'İyi';
    if (rating >= 2.0) return 'Orta';
    return 'Kötü';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.0) return Colors.orange;
    if (rating >= 2.0) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
