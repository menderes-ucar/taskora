enum MessageType {
  text,
  proposal,
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final MessageType type;

  final String? proposalId;
  final double? proposalAmount;
  final int? proposalDeliveryDays;
  final String? proposalDescription;
  final String? proposalStatus;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.type = MessageType.text,
    this.proposalId,
    this.proposalAmount,
    this.proposalDeliveryDays,
    this.proposalDescription,
    this.proposalStatus,
  });

  bool get isTextMessage => type == MessageType.text;
  bool get isProposalMessage => type == MessageType.proposal;

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? createdAt,
    MessageType? type,
    String? proposalId,
    double? proposalAmount,
    int? proposalDeliveryDays,
    String? proposalDescription,
    String? proposalStatus,
    bool clearProposalId = false,
    bool clearProposalAmount = false,
    bool clearProposalDeliveryDays = false,
    bool clearProposalDescription = false,
    bool clearProposalStatus = false,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      proposalId: clearProposalId ? null : (proposalId ?? this.proposalId),
      proposalAmount: clearProposalAmount
          ? null
          : (proposalAmount ?? this.proposalAmount),
      proposalDeliveryDays: clearProposalDeliveryDays
          ? null
          : (proposalDeliveryDays ?? this.proposalDeliveryDays),
      proposalDescription: clearProposalDescription
          ? null
          : (proposalDescription ?? this.proposalDescription),
      proposalStatus: clearProposalStatus
          ? null
          : (proposalStatus ?? this.proposalStatus),
    );
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'].toString(),
      conversationId: (map['conversation_id'] ?? '').toString(),
      senderId: (map['sender_id'] ?? '').toString(),
      receiverId: (map['receiver_id'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
      type: ((map['type'] ?? 'text').toString() == 'proposal')
          ? MessageType.proposal
          : MessageType.text,
      proposalId: map['proposal_id']?.toString(),
      proposalAmount: map['proposal_amount'] == null
          ? null
          : (map['proposal_amount'] as num).toDouble(),
      proposalDeliveryDays: map['proposal_delivery_days'] == null
          ? null
          : (map['proposal_delivery_days'] as num).toInt(),
      proposalDescription: map['proposal_description']?.toString(),
      proposalStatus: map['proposal_status']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'type': type == MessageType.proposal ? 'proposal' : 'text',
      'proposal_id': proposalId,
      'proposal_amount': proposalAmount,
      'proposal_delivery_days': proposalDeliveryDays,
      'proposal_description': proposalDescription,
      'proposal_status': proposalStatus,
    };
  }
}