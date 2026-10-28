/// Severity drives the visual tone of a surfaced alert.
enum AlertSeverity {
  info('info'),
  warning('warning'),
  critical('critical'),
  success('success');

  const AlertSeverity(this.value);

  final String value;
}

/// A derived alert or recommendation produced by an engine, ready to render.
class FinanceAlert {
  const FinanceAlert({
    required this.severity,
    required this.title,
    required this.message,
    this.category,
    this.impactMinor,
    this.currencyCode,
  });

  final AlertSeverity severity;
  final String title;
  final String message;
  final String? category;
  final int? impactMinor;
  final String? currencyCode;
}
