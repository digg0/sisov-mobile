class PropertyModel {
  final String id;
  final String farmName;
  final String city;
  final String state;

  PropertyModel({
    required this.id,
    required this.farmName,
    required this.city,
    required this.state
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'],
      farmName: json['farmName'],
      city: json['city'],
      state: json['state'],
    );
  }
}