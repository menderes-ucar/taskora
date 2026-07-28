import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/coin_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../coin/data/services/coin_service.dart';

class AdminCoinManagementPage extends ConsumerStatefulWidget {
  const AdminCoinManagementPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminCoinManagementPage> createState() =>
      _AdminCoinManagementPageState();
}

class _AdminCoinManagementPageState
    extends ConsumerState<AdminCoinManagementPage> {
  late SupabaseCoinService _coinService;
  List<CoinPrice> _coinPrices = [];
  int _messageCoinCost = 5;
  bool _isLoading = true;

  final _userIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _coinService = SupabaseCoinService(Supabase.instance.client);
    _loadCoinData();
  }

  Future<void> _loadCoinData() async {
    setState(() => _isLoading = true);
    try {
      final prices = await _coinService.getAllCoinPrices();
      final msgCost = await _coinService.getMessageCoinCost();

      setState(() {
        _coinPrices = prices;
        _messageCoinCost = msgCost;
      });
    } catch (e) {
      _showError('Veri yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCoinToUser() async {
    if (_userIdController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _reasonController.text.isEmpty) {
      _showError('Tüm alanları doldurunuz');
      return;
    }

    try {
      final amount = int.parse(_amountController.text);
      await _coinService.adminAddCoin(
        _userIdController.text,
        amount,
        _reasonController.text,
      );

      _userIdController.clear();
      _amountController.clear();
      _reasonController.clear();

      _showSuccess('Coin başarıyla eklendi!');
    } catch (e) {
      _showError('Coin ekleme hatası: $e');
    }
  }

  Future<void> _updateMessageCoinCost() async {
    try {
      await _coinService.setMessageCoinCost(_messageCoinCost);
      _showSuccess('Mesaj coin fiyatı güncellendi!');
    } catch (e) {
      _showError('Güncelleme hatası: $e');
    }
  }

  Future<void> _updateCoinPrice(CoinPrice price, int newCost) async {
    try {
      final updatedPrice = CoinPrice(
        id: price.id,
        categoryId: price.categoryId,
        categoryName: price.categoryName,
        proposalCost: newCost,
        updatedAt: DateTime.now(),
        updatedBy: Supabase.instance.client.auth.currentUser?.id,
      );

      await _coinService.updateCoinPrice(updatedPrice);
      await _loadCoinData();
      _showSuccess('Kategori fiyatı güncellendi!');
    } catch (e) {
      _showError('Güncelleme hatası: $e');
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
        title: const Text('Coin Yönetimi'),
        actions: [
          IconButton(
            onPressed: _loadCoinData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Kullanıcıya Coin Ekleme
            _buildSection(
              'Kullanıcıya Coin Ekle',
              [
                TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı ID',
                    hintText: 'UUID girin',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Miktar',
                    hintText: '100',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Neden',
                    hintText: 'Coin ekleme sebebi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addCoinToUser,
                  child: const Text('Coin Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Section 2: Mesaj Coin Fiyatı
            _buildSection(
              'Mesaj Coin Fiyatı (Sabit)',
              [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mevcut Fiyat: $_messageCoinCost coin',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showEditDialog(
                          'Mesaj Coin Fiyatı',
                          _messageCoinCost.toString(),
                              (value) async {
                            final newCost = int.parse(value);
                            setState(() => _messageCoinCost = newCost);
                            await _updateMessageCoinCost();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Section 3: Kategori Bazında Teklif Fiyatları
            _buildSection(
              'Kategori Bazında Teklif Fiyatları',
              [
                if (_coinPrices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Fiyatlandırma verisi yok',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _coinPrices.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final price = _coinPrices[index];
                      return _buildCoinPriceItem(price);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCoinPriceItem(CoinPrice price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Teklif Maliyeti: ${price.proposalCost} coin',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditDialog(
                '${price.categoryName} - Teklif Fiyatı',
                price.proposalCost.toString(),
                    (value) async {
                  final newCost = int.parse(value);
                  await _updateCoinPrice(price, newCost);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      String title,
      String currentValue,
      Function(String) onSave,
      ) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Yeni değeri girin'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}
