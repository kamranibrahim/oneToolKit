import 'submission_checklist.dart';
import 'submission_requirements.dart';
import '../../data/processing/file_names.dart';

enum SavedOperation {
  mergePdf('Merge PDFs'),
  imagesToPdf('Images to PDF'),
  optimizePdf('Optimize PDF'),
  zip('Create ZIP');

  const SavedOperation(this.label);
  final String label;
}

enum SavedJobStatus { queued, running, paused, failed, completed }

class SavedArtifact {
  SavedArtifact({
    required this.id,
    required this.name,
    required this.mime,
    required this.relativePath,
    required this.bytes,
    required this.hash,
    required List<String> sourceIds,
  }) : sourceIds = List.unmodifiable(sourceIds);
  final String id, name, mime, relativePath, hash;
  final int bytes;
  final List<String> sourceIds;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mime': mime,
    'path': relativePath,
    'bytes': bytes,
    'hash': hash,
    'sourceIds': sourceIds,
  };
  factory SavedArtifact.fromJson(Map<String, dynamic> json) => SavedArtifact(
    id: json['id'] as String,
    name: json['name'] as String,
    mime: json['mime'] as String,
    relativePath: json['path'] as String,
    bytes: json['bytes'] as int,
    hash: json['hash'] as String,
    sourceIds: List<String>.from(json['sourceIds'] as List),
  );
}

class SavedStep {
  const SavedStep(this.operation, this.outputName, {this.version = 1});
  final SavedOperation operation;
  final String outputName;
  final int version;
  Map<String, dynamic> toJson() => {
    'operation': operation.name,
    'version': version,
    'outputName': outputName,
  };
  factory SavedStep.fromJson(Map<String, dynamic> json) {
    if ((json['version'] ?? 1) != 1) {
      throw const FormatException('Unsupported task step version.');
    }
    return SavedStep(
      SavedOperation.values.byName(json['operation'] as String),
      json['outputName'] as String,
    );
  }
}

class SavedJob {
  SavedJob({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required List<SavedStep> steps,
    required List<SavedArtifact> artifacts,
    required List<String> currentIds,
    required this.nextStep,
    this.revision = 0,
    this.message,
    List<SubmissionChecklistItem> checklist = const [],
    SubmissionRequirements? requirements,
  }) : checklist = List.unmodifiable(checklist),
       requirements = requirements ?? SubmissionRequirements(),
       steps = List.unmodifiable(steps),
       artifacts = List.unmodifiable(artifacts),
       currentIds = List.unmodifiable(currentIds) {
    if (!validId(id) ||
        title.trim().isEmpty ||
        title.length > 120 ||
        steps.isEmpty ||
        steps.length > 4 ||
        nextStep < 0 ||
        nextStep > steps.length ||
        revision < 0 ||
        artifacts.isEmpty ||
        artifacts.length > 104 ||
        currentIds.isEmpty ||
        currentIds.toSet().length != currentIds.length ||
        (status == SavedJobStatus.completed && nextStep != steps.length)) {
      throw const FormatException('Invalid saved job.');
    }
    SubmissionChecklistItem.validate(checklist);
    for (final step in steps) {
      FileNames.validate(step.outputName);
    }
    final ids = <String>{};
    for (final artifact in artifacts) {
      FileNames.validate(artifact.name);
      if (!validId(artifact.id) ||
          !ids.add(artifact.id) ||
          artifact.bytes < 0 ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(artifact.hash) ||
          artifact.relativePath != 'files/${artifact.id}/${artifact.name}') {
        throw const FormatException('Invalid saved file record.');
      }
    }
    if (checklist.any(
      (item) => item.artifactIds.any((id) => !ids.contains(id)),
    )) {
      throw const FormatException('Checklist refers to an unknown saved file.');
    }
    if (currentIds.any((id) => !ids.contains(id)) ||
        artifacts.any((f) => f.sourceIds.any((id) => !ids.contains(id)))) {
      throw const FormatException('Saved job refers to an unknown file.');
    }
  }
  final List<SubmissionChecklistItem> checklist;
  final SubmissionRequirements requirements;
  final String id, title;
  final DateTime createdAt, updatedAt;
  final SavedJobStatus status;
  final List<SavedStep> steps;
  final List<SavedArtifact> artifacts;
  final List<String> currentIds;
  final int nextStep, revision;
  final String? message;
  static bool validId(String id) => RegExp(
    r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
  ).hasMatch(id);
  List<SavedArtifact> get currentFiles =>
      currentIds.map((id) => artifacts.firstWhere((f) => f.id == id)).toList();
  SavedJob copy({
    List<SubmissionChecklistItem>? checklist,
    SavedJobStatus? status,
    int? nextStep,
    int? revision,
    List<SavedArtifact>? artifacts,
    List<String>? currentIds,
    String? message,
  }) => SavedJob(
    id: id,
    title: title,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    status: status ?? this.status,
    steps: steps,
    artifacts: artifacts ?? this.artifacts,
    currentIds: currentIds ?? this.currentIds,
    nextStep: nextStep ?? this.nextStep,
    revision: revision ?? this.revision,
    message: message,
    requirements: requirements,
    checklist: checklist ?? this.checklist,
  );
  Map<String, dynamic> toJson() => {
    'schemaVersion': 3,
    'checklist': checklist.map((item) => item.toJson()).toList(),
    'requirements': requirements.toJson(),
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'status': status.name,
    'steps': steps.map((s) => s.toJson()).toList(),
    'artifacts': artifacts.map((f) => f.toJson()).toList(),
    'currentIds': currentIds,
    'nextStep': nextStep,
    'revision': revision,
    'message': message,
  };
  factory SavedJob.fromJson(Map<String, dynamic> json) {
    if (![1, 2, 3].contains(json['schemaVersion'])) {
      throw const FormatException(
        'This saved work uses an unsupported version.',
      );
    }
    return SavedJob(
      checklist: json['schemaVersion'] == 3
          ? (json['checklist'] as List)
                .map(
                  (item) => SubmissionChecklistItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      requirements: json['schemaVersion'] != 1
          ? SubmissionRequirements.fromJson(
              Map<String, dynamic>.from(json['requirements'] as Map),
            )
          : SubmissionRequirements(),
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: SavedJobStatus.values.byName(json['status'] as String),
      steps: (json['steps'] as List)
          .map((s) => SavedStep.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      artifacts: (json['artifacts'] as List)
          .map((f) => SavedArtifact.fromJson(Map<String, dynamic>.from(f)))
          .toList(),
      currentIds: List<String>.from(json['currentIds'] as List),
      nextStep: json['nextStep'] as int,
      revision: json['revision'] as int,
      message: json['message'] as String?,
    );
  }
}
