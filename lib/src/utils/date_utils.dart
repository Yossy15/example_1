/// Utility functions for date formatting in Thai format
class ThaiDateUtils {
  /// Format DateTime to Thai format: "1 ธ.ค. 68 12.38 น."
  static String formatThaiDate(DateTime? date) {
    if (date == null) return 'No date';

    try {
      // Thai month abbreviations
      const List<String> thaiMonths = [
        'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];

      // Get Buddhist year (Gregorian year + 543)
      final buddhistYear = date.year + 543;

      // Get Thai month abbreviation (month index is 0-based)
      final thaiMonth = thaiMonths[date.month - 1];

      // Format time with leading zeros if needed
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      // Return formatted date: "1 ธ.ค. 68 12.38 น."
      return '${date.day} $thaiMonth ${buddhistYear.toString().substring(2)} $hour.$minute น.';
    } catch (e) {
      return 'Invalid date';
    }
  }
}