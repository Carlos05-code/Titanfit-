String formatDuration(int? minutes) {
  if (minutes == null) return '0m';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours > 0) return '${hours}h ${mins}m';
  return '${mins}m';
}

String formatCalories(int? calories) {
  if (calories == null) return '0';
  return '$calories';
}

String formatDate(DateTime date) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String formatTimeOfDay(DateTime date) {
  final hour = date.hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';
  final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$h:$minute $period';
}

String greeting([DateTime? clock]) {
  final hour = (clock ?? DateTime.now()).hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
