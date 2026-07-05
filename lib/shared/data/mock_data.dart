import '../enums/contract_status.dart';
import '../enums/job_status.dart';
import '../enums/payment_status.dart';
import '../enums/proposal_status.dart';
import '../enums/user_role.dart';
import '../models/contract_model.dart';
import '../models/job_model.dart';
import '../models/message_model.dart';
import '../models/portfolio_item_model.dart';
import '../models/proposal_model.dart';
import '../models/user_model.dart';

class MockData {
  static const UserModel freelancerUser = UserModel(
    id: 'u1',
    name: 'Ahmet Yılmaz',
    email: 'ahmet@mail.com',
    role: UserRole.freelancer,
    title: 'Mobil Uygulama Geliştirici',
    rating: 4.8,
    bio:
    'Flutter ile modern, performanslı ve sürdürülebilir mobil uygulamalar geliştiriyorum. UI tarafında temiz iş çıkarmaya ve ölçeklenebilir yapı kurmaya önem veriyorum.',
    completedJobs: 18,
    reviewCount: 26,
    skills: [
      'Flutter',
      'Firebase',
      'UI/UX',
      'Riverpod',
      'REST API',
    ],
  );

  static const UserModel employerUser = UserModel(
    id: 'u2',
    name: 'Emre Kaya',
    email: 'emre@mail.com',
    role: UserRole.employer,
    title: 'Startup Kurucusu',
    rating: 4.9,
    bio: 'Yeni dijital ürünler geliştiren bir girişim kurucusuyum.',
    completedJobs: 9,
    reviewCount: 12,
    skills: ['Product', 'Growth', 'Startup'],
  );

  static final List<JobModel> jobs = [
    JobModel(
      id: 'j1',
      employerId: 'u2',
      title: 'Mobil Uygulama Geliştirme',
      description:
      'Flutter ile modern arayüze sahip bir mobil uygulama geliştirebilecek freelancer aranıyor.',
      budget: 15000,
      category: 'Mobil',
      deliveryDays: 20,
      status: JobStatus.open,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    JobModel(
      id: 'j2',
      employerId: 'u2',
      title: 'Logo ve Marka Kimliği Tasarımı',
      description:
      'Yeni girişimimiz için modern logo, renk paleti ve temel marka kimliği hazırlanacak.',
      budget: 5000,
      category: 'Grafik Tasarım',
      deliveryDays: 7,
      status: JobStatus.open,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    JobModel(
      id: 'j3',
      employerId: 'u2',
      title: 'Landing Page UI/UX Tasarımı',
      description:
      'SaaS ürünümüz için dönüşüm odaklı landing page tasarımı yapılacak.',
      budget: 8000,
      category: 'UI/UX',
      deliveryDays: 10,
      status: JobStatus.inProgress,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static final List<ProposalModel> proposals = [
    ProposalModel(
      id: 'p1',
      jobId: 'j1',
      freelancerId: 'u1',
      freelancerName: 'Ahmet Yılmaz',
      amount: 14000,
      deliveryDays: 18,
      coverLetter:
      'Flutter konusunda deneyimliyim. Projeyi temiz mimariyle ve modern UI ile geliştirebilirim.',
      status: ProposalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    ProposalModel(
      id: 'p2',
      jobId: 'j2',
      freelancerId: 'u1',
      freelancerName: 'Ahmet Yılmaz',
      amount: 4500,
      deliveryDays: 6,
      coverLetter:
      'Marka kimliği ve logo tasarımında sade ama premium işler çıkarabilirim.',
      status: ProposalStatus.accepted,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<PortfolioItemModel> portfolio = [
    PortfolioItemModel(
      id: 'pt1',
      freelancerId: 'u1',
      title: 'Task Management Mobile App',
      category: 'Mobil Uygulama',
      description:
      'Görev planlama, bildirim ve ilerleme takibi özelliklerine sahip modern bir mobil uygulama tasarımı ve geliştirmesi.',
      imageUrls: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    PortfolioItemModel(
      id: 'pt2',
      freelancerId: 'u1',
      title: 'Restaurant Ordering UI',
      category: 'UI/UX',
      description:
      'Restoran sipariş akışı için sade, hızlı ve kullanıcı dostu arayüz tasarımı.',
      imageUrls: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    PortfolioItemModel(
      id: 'pt3',
      freelancerId: 'u1',
      title: 'Fitness Tracker App',
      category: 'Mobil Uygulama',
      description:
      'Kalori, su tüketimi ve egzersiz takibi yapan sağlık odaklı uygulama.',
      imageUrls: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static final List<MessageModel> messages = [
    MessageModel(
      id: 'm1',
      conversationId: 'u1_u2',
      senderId: 'u2',
      receiverId: 'u1',
      text: 'Merhaba Ahmet, mobil uygulama ilanı için teklifini gördüm.',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    MessageModel(
      id: 'm2',
      conversationId: 'u1_u2',
      senderId: 'u1',
      receiverId: 'u2',
      text: 'Merhaba, teşekkür ederim. Proje detaylarını konuşabiliriz.',
      createdAt:
      DateTime.now().subtract(const Duration(hours: 5, minutes: 40)),
    ),
    MessageModel(
      id: 'm3',
      conversationId: 'u1_u2',
      senderId: 'u2',
      receiverId: 'u1',
      text: 'Teslim süresi ve ekran sayısı tarafını netleştirelim.',
      createdAt:
      DateTime.now().subtract(const Duration(hours: 5, minutes: 10)),
    ),
  ];

  static final List<ContractModel> contracts = [
    ContractModel(
      id: 'c1',
      jobId: 'j2',
      jobTitle: 'Logo ve Marka Kimliği Tasarımı',
      employerId: 'u2',
      freelancerId: 'u1',
      freelancerName: 'Ahmet Yılmaz',
      agreedAmount: 4500,
      deliveryDays: 6,
      status: ContractStatus.active,
      paymentStatus: PaymentStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static UserModel? getUserById(String id) {
    if (freelancerUser.id == id) return freelancerUser;
    if (employerUser.id == id) return employerUser;
    return null;
  }

  static List<PortfolioItemModel> getPortfolioByFreelancerId(
      String freelancerId,
      ) {
    return portfolio
        .where((item) => item.freelancerId == freelancerId)
        .toList();
  }

  static String getConversationId({
    required String userA,
    required String userB,
  }) {
    final sorted = [userA, userB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}