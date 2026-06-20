class MasjidEvent {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String category;

  const MasjidEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.category,
  });
}
