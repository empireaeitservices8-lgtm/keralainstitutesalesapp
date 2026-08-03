class EodModel {
  final String id;
  final int totalVisits;
  final int leadsCreated;
  final int followUpsScheduled;
  final int pendingVisits;
  final String remarks;
  final String dailySummary;
  final DateTime submissionTime;
  final bool isSubmitted;

  EodModel({
    required this.id,
    required this.totalVisits,
    required this.leadsCreated,
    required this.followUpsScheduled,
    required this.pendingVisits,
    required this.remarks,
    required this.dailySummary,
    required this.submissionTime,
    this.isSubmitted = false,
  });

  factory EodModel.empty() {
    return EodModel(
      id: '',
      totalVisits: 0,
      leadsCreated: 0,
      followUpsScheduled: 0,
      pendingVisits: 0,
      remarks: '',
      dailySummary: '',
      submissionTime: DateTime.now(),
    );
  }
}
