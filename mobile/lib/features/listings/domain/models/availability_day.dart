class AvailabilityDay {
  const AvailabilityDay({
    required this.date,
    required this.isAvailable,
    this.note,
  });

  final DateTime date;
  final bool isAvailable;
  final String? note;
}
