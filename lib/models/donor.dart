class Donor {
  final String uid;
  final String displayName;
  final String bloodGroup;
  final String location;
  final String phoneNumber;

  Donor({
    required this.uid,
    required this.displayName,
    required this.bloodGroup,
    required this.location,
    required this.phoneNumber,
  });

  factory Donor.fromMap(Map<String, dynamic> data, String id) {
    return Donor(
      uid: id,
      displayName: data['displayName'] ?? 'Anonymous',
      bloodGroup: data['bloodGroup'] ?? 'N/A',
      location: data['location'] ?? 'Unknown',
      phoneNumber: data['phoneNumber'] ?? '',
    );
  }
}
