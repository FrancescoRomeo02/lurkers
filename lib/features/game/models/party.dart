class Party {
  final String id;
  final String createdAt;
  final String code;
  final String hostId;
  final String status;
  final String winnerId;

  Party({
    required this.id,
    required this.createdAt,
    required this.code,
    this.status = 'inactive',
    this.hostId = '',
    this.winnerId = '',
  });

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: json['id'], 
      createdAt: json['createdAt'], 
      code: json['code'],
      status: json['status'] ?? 'inactive', // Default status is 'inactive'
      hostId: json['hostId'] ?? '',
      winnerId: json['winnerId'] ?? '',
    );
  }

  Map<String, dynamic> toJson(){
    return{
      'id': id,
      'createAt': createdAt,
      'code': code,
      'status': status,
      'hostId': hostId,
      'winnerId': winnerId,
    };
  }
  
}