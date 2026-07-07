class SmsEvent {
  final String key;
  final String sender;
  final String body;
  final DateTime receivedAt;
  final String operationType;
  final double amount;
  final String phone;
  final String transactionId;
  final String walletCompany;

  SmsEvent({
    required this.key,
    required this.sender,
    required this.body,
    required this.receivedAt,
    required this.operationType,
    required this.amount,
    required this.phone,
    required this.transactionId,
    required this.walletCompany,
  });

  Map<String, dynamic> toSupabase({required String userId}) {
    return {
      'user_id': userId,
      'message_key': key,
      'sender': sender,
      'body': body,
      'received_at': receivedAt.toIso8601String(),
      'operation_type': operationType,
      'amount': amount,
      'phone': phone,
      'transaction_id': transactionId,
      'wallet_company': walletCompany,
      'status': 'pending',
      'source': 'sms_reader_app',
    };
  }
}
