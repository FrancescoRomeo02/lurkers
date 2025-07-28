class Party {
  final String id;
  final DateTime createdAt;
  final String partyCode;

  Party({
    required this.id,
    required this.createdAt,
    required this.partyCode,
  });

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: json['id'], 
      createdAt: json['createdAt'], 
      partyCode: json['partyCode'],
    );
  }

  Map<String, dynamic> toJson(){
    return{
      'id': id,
      'createAt': createdAt,
      'partyCode': partyCode,
    };
  }
  
}