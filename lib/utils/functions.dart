class Functions {
  static final Functions _instance = Functions._internal();
  Functions._internal();
  factory Functions() {
    return _instance;
  }

  // Format a number to Vietnamese currency style (e.g., 1.234.567 VNĐ)
  String formatVnCurrency(num price) {
    final str = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }
    try {
      final DateTime date = DateTime.parse(dateString);
      String day = date.day.toString().padLeft(2, '0');
      String month = date.month.toString().padLeft(2, '0');
      String year = date.year.toString();
      return '$day/$month/$year';
    } catch (e) {
      return dateString;
    }
  }
}
