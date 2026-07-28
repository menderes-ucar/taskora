class CoinConstants {
  CoinConstants._();

  // --- Genel Sabitler ---
  static const int createJobCost = 0;        // İşveren ilan açarken 0 Coin harcar
  static const int sendProposalCost = 1;     // Freelancer varsayılan teklif maliyeti
  static const double proposalRefundRate = 0.50; // %50 İade oranı

  // --- Kategoriye Göre Maliyet Hesabı (send_proposal_page için) ---
  static int getCost(String category) {
    // Kategori bazlı özel maliyet istenirse buraya eklenebilir, varsayılan 1 Coin
    return sendProposalCost;
  }
}