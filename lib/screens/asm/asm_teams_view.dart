import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../models/asm_bde_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/operations_provider.dart';
import '../dashboard/create_bde_sheet.dart';
import 'bde_details_screen.dart';

class AsmTeamsView extends StatefulWidget {
  const AsmTeamsView({super.key});

  @override
  State<AsmTeamsView> createState() => _AsmTeamsViewState();
}

class _AsmTeamsViewState extends State<AsmTeamsView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const Set<String> _dummyIds = {
    '672430000000000000000011',
    '672430000000000000000012',
    '672430000000000000000013',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OperationsProvider.instance.fetchAsmBdes(isRefresh: true);
      OperationsProvider.instance.fetchHierarchyFilters(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AsmBdeModel> _resolveBdes(
    OperationsProvider provider,
    HomeProvider homeProvider,
  ) {
    final List<AsmBdeModel> result = [];
    final Set<String> seenIds = {};
    final Set<String> seenEmpIds = {};
    final Set<String> seenEmails = {};
    final Set<String> seenNames = {};

    void addBde(AsmBdeModel bde) {
      if (_dummyIds.contains(bde.id)) return;
      final isDup = (bde.id.isNotEmpty && bde.id != '0' && seenIds.contains(bde.id.toLowerCase())) ||
          (bde.employeeId.isNotEmpty && seenEmpIds.contains(bde.employeeId.toLowerCase())) ||
          (bde.email.isNotEmpty && seenEmails.contains(bde.email.toLowerCase())) ||
          (bde.name.trim().isNotEmpty && seenNames.contains(bde.name.trim().toLowerCase()));
      if (isDup) return;

      if (bde.id.isNotEmpty && bde.id != '0') seenIds.add(bde.id.toLowerCase());
      if (bde.employeeId.isNotEmpty) seenEmpIds.add(bde.employeeId.toLowerCase());
      if (bde.email.isNotEmpty) seenEmails.add(bde.email.toLowerCase());
      if (bde.name.trim().isNotEmpty) seenNames.add(bde.name.trim().toLowerCase());

      result.add(bde);
    }

    // 1. Authoritative primary source: /api/asm/bdes
    for (final b in provider.asmBdes) {
      addBde(b);
    }

    // If provider has real BDEs, do not append duplicate subordinate records from home dashboard
    if (result.isNotEmpty) {
      return result;
    }

    // 2. Fallbacks only when provider.asmBdes is empty:
    final homeData = homeProvider.state.data;
    final user = AuthProvider.instance.session;

    final rawSub = homeData?.rawJson?['team_subordinate_status'];
    if (rawSub is Map) {
      final rawBdes = rawSub['bdes'] ?? rawSub['BDE'];
      if (rawBdes is List) {
        for (final e in rawBdes.whereType<Map>()) {
          addBde(AsmBdeModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final rawTeam = homeData?.rawJson?['team'];
    if (rawTeam is Map && rawTeam['members'] is List) {
      for (final e in (rawTeam['members'] as List).whereType<Map>()) {
        addBde(AsmBdeModel.fromJson(Map<String, dynamic>.from(e)));
      }
    }

    for (final h in provider.hierarchyBdes) {
      addBde(AsmBdeModel.fromJson(h));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        OperationsProvider.instance,
        HomeProvider.instance,
      ]),
      builder: (context, _) {
        final provider = OperationsProvider.instance;
        final homeProvider = HomeProvider.instance;
        final user = AuthProvider.instance.session;
        final homeData = homeProvider.state.data;

        final defaultDistrict =
            user.district != null && user.district.toString().isNotEmpty
                ? user.district.toString()
                : null;
        final defaultTeam = homeData?.teamName ??
            (user.team != null && user.team.toString().isNotEmpty
                ? user.team.toString()
                : null);

        final allBdes = _resolveBdes(provider, homeProvider);

        final filteredBdes = allBdes.where((bde) {
          if (_searchQuery.trim().isEmpty) return true;
          final q = _searchQuery.trim().toLowerCase();
          return bde.name.toLowerCase().contains(q) ||
              bde.employeeId.toLowerCase().contains(q) ||
              bde.team.toLowerCase().contains(q) ||
              bde.district.toLowerCase().contains(q) ||
              bde.zone.toLowerCase().contains(q) ||
              bde.email.toLowerCase().contains(q) ||
              bde.contactNumber.toLowerCase().contains(q);
        }).toList();

        final activeCount = allBdes
            .where(
              (b) =>
                  b.status.toLowerCase() == 'active' ||
                  b.status.toLowerCase() == 'online',
            )
            .length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'REGIONAL BDE TEAMS',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: InkWell(
                    onTap: () => showCreateBdeSheet(
                      context,
                      defaultDistrict: defaultDistrict,
                      defaultTeam: defaultTeam,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Add BDE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xFF0F766E),
            onRefresh: () async {
              await provider.fetchAsmBdes(isRefresh: true);
              await homeProvider.fetchHomeData(isRefresh: true);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Search Bar & Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText:
                              'Search BDE by name, ID, team or district...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF0F766E),
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.groups_rounded,
                                size: 16,
                                color: Color(0xFF0F766E),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'CREATED BDEs (${filteredBdes.length})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF475569),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: Text(
                              '$activeCount Active',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (provider.isLoadingAsmBdes && allBdes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  )
                else if (filteredBdes.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 48,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.group_off_outlined,
                            size: 36,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No BDEs match "$_searchQuery"'
                              : 'No Regional BDEs Registered Yet',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pull down to refresh or tap below to add a new BDE.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => showCreateBdeSheet(
                            context,
                            defaultDistrict: defaultDistrict,
                            defaultTeam: defaultTeam,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Add BDE Now',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredBdes.map((bde) => _buildBdeCard(context, bde)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'asm_create_bde_fab',
            backgroundColor: const Color(0xFF0F766E),
            elevation: 4,
            onPressed: () => showCreateBdeSheet(
              context,
              defaultDistrict: defaultDistrict,
              defaultTeam: defaultTeam,
            ),
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: const Text(
              'Create BDE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBdeCard(BuildContext context, AsmBdeModel bde) {
    final bool isActive = bde.status.toLowerCase() == 'active' ||
        bde.status.toLowerCase() == 'online';

    final locationSubtitle = [
      if (bde.zone.isNotEmpty) bde.zone,
      if (bde.district.isNotEmpty) bde.district,
      if (bde.team.isNotEmpty) bde.team,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BdeDetailsScreen(bde: bde),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          const Color(0xFF0F766E).withOpacity(0.12),
                      child: Text(
                        bde.name.isNotEmpty
                            ? bde.name.substring(0, 1).toUpperCase()
                            : 'B',
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  bde.name.isNotEmpty
                                      ? bde.name
                                      : 'BDE Executive',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (bde.employeeId.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    bde.employeeId,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            locationSubtitle.isNotEmpty
                                ? locationSubtitle
                                : bde.designation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        bde.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat(
                        icon: Icons.people_alt_outlined,
                        label: 'Leads',
                        value: '${bde.leadsAssigned}',
                        color: const Color(0xFF0F766E),
                      ),
                      Container(
                        height: 18,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      _buildMiniStat(
                        icon: Icons.verified_outlined,
                        label: 'Admissions',
                        value: '${bde.admissionsClosed}',
                        color: const Color(0xFF2563EB),
                      ),
                      Container(
                        height: 18,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      _buildMiniStat(
                        icon: Icons.trending_up_rounded,
                        label: 'Conversion',
                        value: bde.displayConversionRate,
                        color: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

