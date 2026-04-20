class BloodRequest {
  final String id;
  final String bloodGroup;
  final String location;
  final String phoneNumber;
  final String bloodAmount;
  final String bloodNeededDate;

  BloodRequest({
    required this.id,
    required this.bloodGroup,
    required this.location,
    required this.phoneNumber,
    required this.bloodAmount,
    required this.bloodNeededDate,
  });

  factory BloodRequest.fromMap(Map<String, dynamic> data, String id) {
    return BloodRequest(
      id: id,
      bloodGroup: data['bloodGroup'] ?? '',
      location: data['location'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      bloodAmount: data['bloodAmount'] ?? '1',
      bloodNeededDate: data['bloodNeededDate'] ?? '',
    );
  }
}
