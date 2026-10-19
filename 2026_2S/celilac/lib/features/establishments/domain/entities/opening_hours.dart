class OpeningHours {
  const OpeningHours({
    required this.weekday,
    required this.opensAt,
    required this.closesAt,
  });

  final int weekday;
  final Duration opensAt;
  final Duration closesAt;

  bool contains(DateTime moment) {
    if (moment.weekday != weekday) {
      return false;
    }
    final time = Duration(hours: moment.hour, minutes: moment.minute);
    return time >= opensAt && time < closesAt;
  }
}
