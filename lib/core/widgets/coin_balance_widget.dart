import 'package:flutter/material.dart';

class CoinBalanceWidget extends StatelessWidget {
  final int coinBalance;
  final VoidCallback? onTap;

  const CoinBalanceWidget({
    Key? key,
    required this.coinBalance,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on,
              color: Colors.amber.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '$coinBalance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
