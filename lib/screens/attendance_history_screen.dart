import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_endpoints.dart';
import '../constants/colors.dart';
import '../providers/attendance_provider.dart';
import '../utils/helpers.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  static const String path = '/attendance-history';

  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _historyLoaded = false;
  Map<String, String> _cachedSelfies = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _loadLocalSelfies();
    // Force refresh today's attendance and history on open
    _historyLoaded = true;
    AttendanceProvider.instance.loadTodayAttendance(isRefresh: true);
    AttendanceProvider.instance.loadAttendanceHistory(isRefresh: true);

    _tabController.addListener(_handleTabChange);
  }

  Future<void> _loadLocalSelfies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final map = <String, String>{};
      for (final k in keys) {
        if (k.startsWith('attendance_selfie_in_')) {
          final date = k.replaceFirst('attendance_selfie_in_', '');
          final val = prefs.getString(k);
          if (val != null && val.isNotEmpty) map['in_' + date] = val;
        } else if (k.startsWith('attendance_selfie_out_')) {
          final date = k.replaceFirst('attendance_selfie_out_', '');
          final val = prefs.getString(k);
          if (val != null && val.isNotEmpty) map['out_' + date] = val;
        }
      }
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayIn = prefs.getString('attendance_checkin_selfie');
      if (todayIn != null && todayIn.isNotEmpty) map['in_' + todayStr] = todayIn;
      final todayOut = prefs.getString('attendance_checkout_selfie');
      if (todayOut != null && todayOut.isNotEmpty) map['out_' + todayStr] = todayOut;

      if (mounted) {
        setState(() {
          _cachedSelfies = map;
        });
      }
    } catch (_) {}
  }

  void _handleTabChange() {
    if (_tabController.index == 1 && !_historyLoaded) {
      setState(() {
        _historyLoaded = true;
      });
      AttendanceProvider.instance.loadAttendanceHistory(isRefresh: true);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final List<Future<void>> futures = [
      AttendanceProvider.instance.loadTodayAttendance(isRefresh: true),
    ];
    if (_tabController.index == 1 || _historyLoaded) {
      futures.add(
        AttendanceProvider.instance.loadAttendanceHistory(isRefresh: true),
      );
    }
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text(
          'SIGN-IN & ATTENDANCE HISTORY',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: AppColors.accentGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTeal.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              tabs: const [
                Tab(text: 'TODAY\'S LOGS'),
                Tab(text: 'ALL-DAYS HISTORY'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: AttendanceProvider.instance,
            builder: (context, _) {
              final provider = AttendanceProvider.instance;

              return RefreshIndicator(
                color: AppColors.accentTeal,
                onRefresh: _refreshData,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayTab(provider),
                    _buildHistoryTab(provider),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTodayTab(AttendanceProvider provider) {
    if (provider.isLoadingToday && provider.todayRecordsList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentTeal),
      );
    }

    var records = provider.todayRecordsList;
    if (records.isEmpty && provider.todayHomeAttendance != null) {
      final att = provider.todayHomeAttendance!;
      if (att.checkInTime.isNotEmpty && att.checkInTime != '--:--') {
        records = [
          {
            'date': att.date.isNotEmpty
                ? att.date
                : DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'check_in': att.checkInTime,
            'check_out': att.checkOutTime,
            'status': att.shiftStatus,
            'status_text': att.shiftStatus,
            'hours_worked': att.hoursWorked,
          },
        ];
      }
    }

    if (records.isEmpty) {
      return _buildEmptyState('No attendance logs found for today.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[records.length - 1 - index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildHistoryTab(AttendanceProvider provider) {
    if (provider.isLoadingHistory && provider.historyRecords.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentTeal),
      );
    }

    final records = provider.historyRecords;
    if (records.isEmpty) {
      return _buildEmptyState('No historical attendance logs found.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                color: Colors.blueGrey.shade200,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCardTime(String timeStr) {
    if (timeStr.isEmpty || timeStr == '--:--' || timeStr == 'null')
      return '--:--';
    final trimmed = timeStr.trim();
    if (trimmed.toUpperCase().contains('AM') ||
        trimmed.toUpperCase().contains('PM')) {
      return trimmed;
    }
    try {
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) {
        return DateFormat('hh:mm a').format(dt.toLocal());
      }
    } catch (_) {}
    return trimmed;
  }

  DateTime? _parseCardTime(String str) {
    if (str.isEmpty || str == '--:--') return null;
    final upper = str.toUpperCase().trim();
    final now = DateTime.now();
    if (upper.contains('AM') || upper.contains('PM')) {
      final isPm = upper.contains('PM');
      final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = clean.split(':');
      if (parts.isNotEmpty) {
        int hr = int.tryParse(parts[0].trim()) ?? 0;
        int min = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
        if (isPm && hr < 12) hr += 12;
        if (!isPm && hr == 12) hr = 0;
        return DateTime(now.year, now.month, now.day, hr, min);
      }
    }
    return DateTime.tryParse(str);
  }

  Widget _buildAttendanceCard(dynamic record) {
    if (record is! Map) return const SizedBox.shrink();
    Map<String, dynamic> rec = Map<String, dynamic>.from(record);

    final rawSessions =
        (rec['sessions'] is List && (rec['sessions'] as List).isNotEmpty)
        ? (rec['sessions'] as List)
        : ((rec['punches'] is List && (rec['punches'] as List).isNotEmpty)
              ? (rec['punches'] as List)
              : null);
    final List<Map<String, dynamic>> sessionsList = rawSessions != null
        ? rawSessions
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : [];

    if (sessionsList.length == 1) {
      final onlySession = sessionsList.first;
      final parentHours =
          rec['hours_worked'] ??
          rec['hours_worked_formatted'] ??
          rec['working_hours'];
      rec = {...rec, ...onlySession};
      if (UiHelpers.parseWorkingHours(
                onlySession['hours_worked'] ??
                    onlySession['hours_worked_formatted'],
              ) ==
              0.0 &&
          UiHelpers.parseWorkingHours(parentHours) > 0.0) {
        rec['hours_worked'] = parentHours;
        rec['hours_worked_formatted'] = parentHours;
      }
    }

    final dateStr = (rec['date'] ?? '').toString();
    final checkInTimeStr = (rec['check_in_time'] ?? rec['check_in'] ?? '')
        .toString();
    final checkOutTimeStr = (rec['check_out_time'] ?? rec['check_out'] ?? '')
        .toString();

    final rawHours =
        rec['hours_worked'] ??
        rec['hours_worked_formatted'] ??
        rec['working_hours'];
    double workingHours = UiHelpers.parseWorkingHours(rawHours);

    bool useSummedHoursFormat = false;
    if (sessionsList.isNotEmpty) {
      double sumSessionHours = 0.0;
      for (final s in sessionsList) {
        double sh = UiHelpers.parseWorkingHours(
          s['hours_worked'] ??
              s['hours_worked_formatted'] ??
              s['working_hours'],
        );
        if (sh == 0.0) {
          final sIn = _parseCardTime(
            _formatCardTime(
              (s['check_in_time'] ?? s['check_in'] ?? '').toString(),
            ),
          );
          final sOut = _parseCardTime(
            _formatCardTime(
              (s['check_out_time'] ?? s['check_out'] ?? '').toString(),
            ),
          );
          if (sIn != null && sOut != null) {
            final diff = sOut.difference(sIn).inMinutes;
            if (diff > 0) sh = diff / 60.0;
          }
        }
        sumSessionHours += sh;
      }
      if (sumSessionHours > workingHours) {
        workingHours = sumSessionHours;
        useSummedHoursFormat = true;
      }
    }

    final statusText =
        (rec['status_text'] ??
                rec['status'] ??
                rec['shift_status'] ??
                (checkOutTimeStr.isNotEmpty &&
                        checkOutTimeStr != '--:--' &&
                        checkOutTimeStr != 'null'
                    ? 'COMPLETED'
                    : (checkInTimeStr.isNotEmpty &&
                              checkInTimeStr != '--:--' &&
                              checkInTimeStr != 'null'
                          ? 'ONLINE'
                          : 'pending')))
            .toString();

    String formattedDate;
    if (dateStr.isNotEmpty && dateStr != 'null') {
      try {
        formattedDate = DateFormat(
          'dd MMM yyyy',
        ).format(DateTime.parse(dateStr));
      } catch (_) {
        formattedDate = dateStr;
      }
    } else {
      formattedDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    }

    final String formattedCheckIn = _formatCardTime(checkInTimeStr);
    final String formattedCheckOut = _formatCardTime(checkOutTimeStr);

    final dtIn = _parseCardTime(formattedCheckIn);
    final dtOut = _parseCardTime(formattedCheckOut);
    if (workingHours == 0.0 && dtIn != null && dtOut != null) {
      final diff = dtOut.difference(dtIn).inMinutes;
      if (diff > 0) {
        workingHours = diff / 60.0;
      }
    }
    final String formattedHours = UiHelpers.formatWorkingHours(
      workingHours,
      rawFormatted: useSummedHoursFormat
          ? null
          : (rec['hours_worked_formatted'] ?? rec['hours_worked'])?.toString(),
      checkIn: sessionsList.length > 1 ? null : dtIn,
      checkOut: sessionsList.length > 1 ? null : dtOut,
    );

    // Parse image paths
    String checkInSelfie = '';
    String checkOutSelfie = '';
    final mediaList = rec['media'] as List<dynamic>?;
    if (mediaList != null) {
      for (var m in mediaList) {
        if (m is Map) {
          final typeText = m['type_text']?.toString().toLowerCase();
          final filePath = (m['file_path'] ?? m['url'] ?? m['path'])?.toString();
          if (typeText == 'check-in' || typeText == 'check_in') {
            checkInSelfie = filePath ?? '';
          } else if (typeText == 'check-out' || typeText == 'check_out') {
            checkOutSelfie = filePath ?? '';
          }
        }
      }
    }

    if (checkInSelfie.isEmpty) {
      checkInSelfie = (rec['check_in_selfie'] ??
              rec['checkin_selfie'] ??
              rec['selfie'] ??
              rec['check_in_photo'] ??
              rec['check_in_image'] ??
              rec['image'] ??
              rec['photo'] ??
              '')
          .toString();
      if (checkInSelfie == 'null') checkInSelfie = '';
    }
    if (checkOutSelfie.isEmpty) {
      checkOutSelfie = (rec['check_out_selfie'] ??
              rec['checkout_selfie'] ??
              rec['check_out_photo'] ??
              rec['check_out_image'] ??
              '')
          .toString();
      if (checkOutSelfie == 'null') checkOutSelfie = '';
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = dateStr == todayStr || rec['date'] == todayStr;
    final provAttendance = AttendanceProvider.instance.currentAttendance;

    if (checkInSelfie.isEmpty) {
      if (isToday && provAttendance.checkInSelfie.isNotEmpty) {
        checkInSelfie = provAttendance.checkInSelfie;
      } else {
        checkInSelfie = _cachedSelfies['in_' + dateStr] ?? _cachedSelfies['in_' + (rec['date']?.toString() ?? '')] ?? '';
      }
    }
    if (checkOutSelfie.isEmpty) {
      if (isToday && (provAttendance.checkOutSelfie ?? '').isNotEmpty) {
        checkOutSelfie = provAttendance.checkOutSelfie!;
      } else {
        checkOutSelfie = _cachedSelfies['out_' + dateStr] ?? _cachedSelfies['out_' + (rec['date']?.toString() ?? '')] ?? '';
      }
    }

    Color badgeColor = Colors.orange;
    final upperStatus = statusText.toUpperCase();
    if (upperStatus == 'APPROVED' ||
        upperStatus == 'PRESENT' ||
        upperStatus == 'COMPLETED' ||
        upperStatus == 'ONLINE' ||
        upperStatus == 'ACTIVE') {
      badgeColor = Colors.green;
    } else if (upperStatus == 'REJECTED' || upperStatus == 'ABSENT') {
      badgeColor = Colors.red;
    }

    final dynamic latRaw = rec['check_in_lat'] ??
        rec['latitude'] ??
        rec['location_lat'] ??
        (sessionsList.isNotEmpty
            ? (sessionsList.last['latitude'] ??
                sessionsList.last['location_lat'])
            : null);
    final dynamic lngRaw = rec['check_in_lng'] ??
        rec['longitude'] ??
        rec['location_lng'] ??
        (sessionsList.isNotEmpty
            ? (sessionsList.last['longitude'] ??
                sessionsList.last['location_lng'])
            : null);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.accentTeal,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withOpacity(0.2)),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFEFF2F5), height: 24),

          if (sessionsList.length > 1) ...[
            for (int i = 0; i < sessionsList.length; i++) ...[
              if (i > 0) const Divider(color: Color(0xFFEFF2F5), height: 20),
              Builder(
                builder: (context) {
                  final s = sessionsList[i];
                  final sInStr = _formatCardTime(
                    (s['check_in_time'] ?? s['check_in'] ?? '').toString(),
                  );
                  final sOutStr = _formatCardTime(
                    (s['check_out_time'] ?? s['check_out'] ?? '').toString(),
                  );
                  final sDtIn = _parseCardTime(sInStr);
                  final sDtOut = _parseCardTime(sOutStr);
                  final sHoursVal = UiHelpers.parseWorkingHours(
                    s['hours_worked'] ??
                        s['hours_worked_formatted'] ??
                        s['working_hours'],
                  );
                  final bool isSessionActive =
                      sOutStr == '--:--' && sInStr != '--:--';
                  final String sHoursText = isSessionActive && sHoursVal == 0.0
                      ? 'Active'
                      : UiHelpers.formatWorkingHours(
                          sHoursVal,
                          rawFormatted:
                              (s['hours_worked_formatted'] ?? s['hours_worked'])
                                  ?.toString(),
                          checkIn: sDtIn,
                          checkOut: sDtOut,
                        );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Session ${i + 1}',
                            style: const TextStyle(
                              color: AppColors.accentTeal,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            sHoursText,
                            style: TextStyle(
                              color: isSessionActive
                                  ? AppColors.accentTeal
                                  : Colors.blueGrey.shade600,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHECK-IN',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sInStr,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (i == sessionsList.length - 1 &&
                                    checkInSelfie.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildSelfieThumbnail(
                                    checkInSelfie,
                                    'Check-In selfie',
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFEFF2F5),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHECK-OUT',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sOutStr,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (i == sessionsList.length - 1 &&
                                    checkOutSelfie.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildSelfieThumbnail(
                                    checkOutSelfie,
                                    'Check-Out selfie',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ] else ...[
            // Check-In and Check-Out Columns
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHECK-IN',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedCheckIn,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (checkInSelfie.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildSelfieThumbnail(checkInSelfie, 'Check-In selfie'),
                      ],
                    ],
                  ),
                ),
                Container(width: 1, height: 50, color: const Color(0xFFEFF2F5)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHECK-OUT',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedCheckOut,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (checkOutSelfie.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildSelfieThumbnail(
                          checkOutSelfie,
                          'Check-Out selfie',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
          const Divider(color: Color(0xFFEFF2F5), height: 24),

          // Footer: Total Hours, Device info, Coordinates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rec['device_info'] != null)
                    Text(
                      'Device: ${rec['device_info']}',
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 9,
                      ),
                    ),
                  if (latRaw != null && lngRaw != null) const SizedBox(height: 2),
                  if (latRaw != null && lngRaw != null)
                    Text(
                      'GPS: ${double.tryParse(latRaw.toString())?.toStringAsFixed(4)}, ${double.tryParse(lngRaw.toString())?.toStringAsFixed(4)}',
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formattedHours,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieThumbnail(String path, String label) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        _showImagePreviewDialog(trimmed, label);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.8),
          child: _buildUniversalImage(trimmed, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildUniversalImage(String path, {BoxFit fit = BoxFit.cover}) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return _buildImagePlaceholder();
    }

    // 1. Remote HTTP/HTTPS URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTeal),
            ),
          );
        },
      );
    }

    // 2. Local File
    try {
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
        );
      }
    } catch (_) {}

    // 3. Relative server path
    if (trimmed.startsWith('/') || trimmed.startsWith('storage') || trimmed.startsWith('uploads')) {
      final clean = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
      final fullUrl = ApiEndpoints.baseUrl.replaceAll('/api', '') + '/' + clean;
      return Image.network(
        fullUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }

    // Fallback attempt as local file
    return Image.file(
      File(trimmed),
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: const Icon(
        Icons.face_retouching_natural_rounded,
        size: 20,
        color: AppColors.accentTeal,
      ),
    );
  }

  void _showImagePreviewDialog(String path, String label) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Photo Frame
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                  maxWidth: MediaQuery.of(context).size.width * 0.90,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _buildUniversalImage(path, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
              // Close Button
              Positioned(
                top: 0,
                right: 0,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.black87,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
