/// Small helpers shared by the Drift repositories.
int nowMs() => DateTime.now().millisecondsSinceEpoch;

String? normalizeText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
