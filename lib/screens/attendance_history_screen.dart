import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Force refresh today's attendance on open
    AttendanceProvider.instance.loadTodayAttendance(isRefresh: true);

    _tabController.addListener(_handleTabChange);
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
    final Map<String, dynamic> rec = Map<String, dynamic>.from(record);

    final dateStr = (rec['date'] ?? '').toString();
    final checkInTimeStr = (rec['check_in_time'] ?? rec['check_in'] ?? '')
        .toString();
    final checkOutTimeStr = (rec['check_out_time'] ?? rec['check_out'] ?? '')
        .toString();

    final rawHours = rec['hours_worked'] ?? rec['working_hours'];
    double workingHours = 0.0;
    if (rawHours is num) {
      workingHours = rawHours.toDouble().abs();
    } else if (rawHours != null) {
      workingHours = (double.tryParse(rawHours.toString()) ?? 0.0).abs();
    }
    final statusText =
        (rec['status_text'] ??
                rec['status'] ??
                rec['shift_status'] ??
                'pending')
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

    if (workingHours == 0.0 &&
        formattedCheckIn != '--:--' &&
        formattedCheckOut != '--:--') {
      try {
        final dtIn = _parseCardTime(formattedCheckIn);
        final dtOut = _parseCardTime(formattedCheckOut);
        if (dtIn != null && dtOut != null) {
          final diff = dtOut.difference(dtIn).inMinutes;
          if (diff > 0) {
            workingHours = double.parse((diff / 60.0).toStringAsFixed(2));
          }
        }
      } catch (_) {}
    }

    // Parse image paths
    String checkInSelfie = '';
    String checkOutSelfie = '';
    final mediaList = rec['media'] as List<dynamic>?;
    if (mediaList != null) {
      for (var m in mediaList) {
        if (m is Map) {
          final typeText = m['type_text']?.toString();
          final filePath = (m['file_path'] ?? m['url'] ?? m['path'])
              ?.toString();
          if (typeText == 'check-in') {
            checkInSelfie = filePath ?? '';
          } else if (typeText == 'check-out') {
            checkOutSelfie = filePath ?? '';
          }
        }
      }
    }

    Color badgeColor = Colors.orange;
    final upperStatus = statusText.toUpperCase();
    if (upperStatus == 'APPROVED' ||
        upperStatus == 'PRESENT' ||
        upperStatus == 'COMPLETED') {
      badgeColor = Colors.green;
    } else if (upperStatus == 'REJECTED' || upperStatus == 'ABSENT') {
      badgeColor = Colors.red;
    }

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
                      _buildNetworkThumbnail(checkInSelfie, 'Check-In selfie'),
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
                      _buildNetworkThumbnail(
                        checkOutSelfie,
                        'Check-Out selfie',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
                  if (rec['check_in_lat'] != null) const SizedBox(height: 2),
                  if (rec['check_in_lat'] != null)
                    Text(
                      'GPS: ${double.tryParse(rec['check_in_lat'].toString())?.toStringAsFixed(4)}, ${double.tryParse(rec['check_in_lng'].toString())?.toStringAsFixed(4)}',
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
                  '${workingHours.toStringAsFixed(2)} hrs',
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

  Widget _buildNetworkThumbnail(String url, String label) {
    return GestureDetector(
      onTap: () {
        _showImagePreviewDialog(url, label);
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade100,
              child: const Icon(
                Icons.broken_image,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePreviewDialog(String url, String label) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Photo Frame
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Close Button
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.black54,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
