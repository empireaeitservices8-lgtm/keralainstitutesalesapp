class BeatPlanModel {
  final String id;
  final String customerName;
  final String address;
  final int sequence;
  final String scheduleTime;
  final double distanceKm;
  final double latitude;
  final double longitude;
  
  // Visit status/log
  final bool isVisited;
  final DateTime? checkInTime;
  final String? selfiePath;
  final String? visitNotes;
  final double? orderValue;
  final String? followUpDate;
  final String? attachmentPath;
  final String status; // 'Pending' | 'Completed'

  // Assignment details
  final String assignedBdeEmail;
  final String team;
  final String district;
  final String zone;

  BeatPlanModel({
    required this.id,
    required this.customerName,
    required this.address,
    required this.sequence,
    required this.scheduleTime,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    this.isVisited = false,
    this.checkInTime,
    this.selfiePath,
    this.visitNotes,
    this.orderValue,
    this.followUpDate,
    this.attachmentPath,
    this.status = 'Pending',
    required this.assignedBdeEmail,
    required this.team,
    required this.district,
    required this.zone,
  });

  BeatPlanModel copyWith({
    bool? isVisited,
    DateTime? checkInTime,
    String? selfiePath,
    String? visitNotes,
    double? orderValue,
    String? followUpDate,
    String? attachmentPath,
    String? status,
    String? assignedBdeEmail,
    String? team,
    String? district,
    String? zone,
  }) {
    return BeatPlanModel(
      id: id,
      customerName: customerName,
      address: address,
      sequence: sequence,
      scheduleTime: scheduleTime,
      distanceKm: distanceKm,
      latitude: latitude,
      longitude: longitude,
      isVisited: isVisited ?? this.isVisited,
      checkInTime: checkInTime ?? this.checkInTime,
      selfiePath: selfiePath ?? this.selfiePath,
      visitNotes: visitNotes ?? this.visitNotes,
      orderValue: orderValue ?? this.orderValue,
      followUpDate: followUpDate ?? this.followUpDate,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      status: status ?? this.status,
      assignedBdeEmail: assignedBdeEmail ?? this.assignedBdeEmail,
      team: team ?? this.team,
      district: district ?? this.district,
      zone: zone ?? this.zone,
    );
  }
}
