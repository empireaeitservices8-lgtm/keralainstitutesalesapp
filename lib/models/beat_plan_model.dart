import 'package:json_annotation/json_annotation.dart';

part 'beat_plan_model.g.dart';

@JsonSerializable()
class BeatPlanModel {
  final String id;
  @JsonKey(name: 'customer_name')
  final String customerName;
  final String address;
  final int sequence;
  @JsonKey(name: 'schedule_time')
  final String scheduleTime;
  @JsonKey(name: 'distance_km')
  final double distanceKm;
  final double latitude;
  final double longitude;
  
  @JsonKey(name: 'is_visited')
  final bool isVisited;
  @JsonKey(name: 'check_in_time')
  final DateTime? checkInTime;
  @JsonKey(name: 'selfie_path')
  final String? selfiePath;
  @JsonKey(name: 'visit_notes')
  final String? visitNotes;
  @JsonKey(name: 'order_value')
  final double? orderValue;
  @JsonKey(name: 'follow_up_date')
  final String? followUpDate;
  @JsonKey(name: 'attachment_path')
  final String? attachmentPath;
  final String status;

  @JsonKey(name: 'assigned_bde_email')
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

  factory BeatPlanModel.fromJson(Map<String, dynamic> json) => _$BeatPlanModelFromJson(json);
  Map<String, dynamic> toJson() => _$BeatPlanModelToJson(this);

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
