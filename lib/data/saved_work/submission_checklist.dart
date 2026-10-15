import 'saved_job.dart';

/// Review is a user's acknowledgement, never an automated content assertion.
class SubmissionChecklistItem {
  SubmissionChecklistItem({
    required this.id,
    required String label,
    List<String> artifactIds = const [],
    this.reviewed = false,
  }) : label = label.trim(),
       artifactIds = List.unmodifiable(artifactIds) {
    if (!SavedJob.validId(id) ||
        this.label.isEmpty ||
        this.label.length > 120 ||
        artifactIds.length > 104 ||
        artifactIds.toSet().length != artifactIds.length ||
        artifactIds.any((id) => !SavedJob.validId(id)) ||
        (reviewed && artifactIds.isEmpty)) {
      throw const FormatException(
        'Enter a document name of 1–120 characters and link a file before reviewing it.',
      );
    }
  }
  final String id, label;
  final List<String> artifactIds;
  final bool reviewed;
  SubmissionChecklistItem copy({
    String? label,
    List<String>? artifactIds,
    bool? reviewed,
  }) => SubmissionChecklistItem(
    id: id,
    label: label ?? this.label,
    artifactIds: artifactIds ?? this.artifactIds,
    // Changing links or label always requires another review.
    reviewed: artifactIds != null || label != null
        ? false
        : reviewed ?? this.reviewed,
  );
  SubmissionChecklistItem get fresh =>
      SubmissionChecklistItem(id: id, label: label);
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'artifactIds': artifactIds,
    'reviewed': reviewed,
  };
  factory SubmissionChecklistItem.fromJson(Map<String, dynamic> json) =>
      SubmissionChecklistItem(
        id: json['id'] as String,
        label: json['label'] as String,
        artifactIds: List<String>.from(json['artifactIds'] as List),
        reviewed: json['reviewed'] as bool,
      );
  static void validate(List<SubmissionChecklistItem> items) {
    if (items.length > 30 ||
        items.map((i) => i.id).toSet().length != items.length) {
      throw const FormatException(
        'Use up to 30 document checklist items with unique IDs.',
      );
    }
  }
}
