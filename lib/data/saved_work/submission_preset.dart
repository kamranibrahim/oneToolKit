import 'saved_job.dart';

class SubmissionPreset {
  const SubmissionPreset(
    this.title,
    this.description,
    this.operation,
    this.outputStem,
    this.documents,
  );
  final String title, description, outputStem;
  final SavedOperation operation;
  final List<String> documents;
  static const values = [
    SubmissionPreset(
      'Scanned document',
      'Turn ordered photos into one PDF, then review every page.',
      SavedOperation.imagesToPdf,
      'scanned_document',
      ['Document pages'],
    ),
    SubmissionPreset(
      'Combined PDF',
      'Combine existing PDFs in the order you choose.',
      SavedOperation.mergePdf,
      'combined_documents',
      ['Main document', 'Supporting document'],
    ),
    SubmissionPreset(
      'Application ZIP',
      'Package your selected documents into one ZIP.',
      SavedOperation.zip,
      'application_documents',
      ['Application document', 'Supporting document'],
    ),
  ];
}
