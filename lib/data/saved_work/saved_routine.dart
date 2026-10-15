import 'submission_checklist.dart';
import '../processing/file_names.dart';
import 'saved_job.dart';
import 'submission_requirements.dart';

class SavedRoutine {
  SavedRoutine(
    this.id,
    this.title,
    List<SavedStep> steps,
    this.requirements, {
    List<SubmissionChecklistItem> checklist = const [],
  }) : checklist = List.unmodifiable(checklist.map((item) => item.fresh)),
       steps = List.unmodifiable(steps) {
    if (!SavedJob.validId(id) ||
        title.trim().isEmpty ||
        title.length > 120 ||
        steps.isEmpty ||
        steps.length > 4) {
      throw const FormatException('Invalid routine.');
    }
    SubmissionChecklistItem.validate(checklist);
    for (final step in steps) {
      FileNames.validate(step.outputName);
    }
  }
  final List<SubmissionChecklistItem> checklist;
  final String id, title;
  final List<SavedStep> steps;
  final SubmissionRequirements requirements;
  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'checklist': checklist
        .map((item) => {'id': item.id, 'label': item.label})
        .toList(),
    'id': id,
    'title': title,
    'steps': steps.map((s) => s.toJson()).toList(),
    'requirements': requirements.toJson(),
  };
  factory SavedRoutine.fromJson(Map<String, dynamic> json) {
    if (![1, 2].contains(json['schemaVersion'])) {
      throw const FormatException('Unsupported routine version.');
    }
    return SavedRoutine(
      json['id'] as String,
      json['title'] as String,
      (json['steps'] as List)
          .map((s) => SavedStep.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      SubmissionRequirements.fromJson(
        Map<String, dynamic>.from(json['requirements'] as Map),
      ),
      checklist: json['schemaVersion'] == 2
          ? (json['checklist'] as List)
                .map(
                  (item) => SubmissionChecklistItem(
                    id: item['id'] as String,
                    label: item['label'] as String,
                  ),
                )
                .toList()
          : const [],
    );
  }
}
