import 'package:flutter/material.dart';
import '../model/personel_model.dart';
import '../model/site_model.dart';
import '../services/personel_services.dart';
import '../services/site_services.dart';

class SiteDetailScreen extends StatefulWidget {
  final int siteId;

  const SiteDetailScreen({super.key, required this.siteId});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  late Future<SiteModel> siteFuture;
  late Future<List<SiteModel>> allSitesFuture;
  late Future<List<PersonnelModel>> personnelFuture;

  String? selectedRole;

  @override
  void initState() {
    super.initState();
    siteFuture = SiteService.fetchSiteById(widget.siteId);
    allSitesFuture = SiteService.fetchSites();
    personnelFuture = PersonnelService.fetchPersonnelBySite(widget.siteId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Site Detail')),
      body: FutureBuilder<SiteModel>(
        future: siteFuture,
        builder: (context, siteSnapshot) {
          if (!siteSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final currentSite = siteSnapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏗 ${currentSite.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('📍 ${currentSite.location}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),

                FutureBuilder<List<PersonnelModel>>(
                  future: personnelFuture,
                  builder: (context, personnelSnapshot) {
                    if (!personnelSnapshot.hasData) return const SizedBox.shrink();
                    final personnelList = personnelSnapshot.data!;
                    final workerCount = personnelList.where((p) => p.role == 'Worker').length;
                    final engineerCount = personnelList.where((p) => p.role == 'Engineer').length;

                    return Text(
                      '👷 Workers: $workerCount   🧑‍💼 Engineers: $engineerCount',
                      style: const TextStyle(fontSize: 16),
                    );
                  },
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: FutureBuilder<List<PersonnelModel>>(
                    future: personnelFuture,
                    builder: (context, personnelSnapshot) {
                      if (!personnelSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final allPersonnel = personnelSnapshot.data!;
                      final availableRoles = allPersonnel.map((p) => p.role).toSet().toList();

                      final filteredPersonnel = selectedRole == null
                          ? allPersonnel
                          : allPersonnel.where((p) => p.role == selectedRole).toList();

                      return FutureBuilder<List<SiteModel>>(
                        future: allSitesFuture,
                        builder: (context, allSitesSnapshot) {
                          if (!allSitesSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final allSites = allSitesSnapshot.data!;
                          final otherSites = allSites.where((s) => s.id != currentSite.id).toList();

                          return Column(
                            children: [
                              // 🔄 Scrollable filter with arrows
                              ScrollableRoleFilter(
                                roles: availableRoles.map((role) {
                                  final count = allPersonnel.where((p) => p.role == role).length;
                                  return '$role ($count)';
                                }).toList(),
                                selectedRole: selectedRole,
                                onRoleSelected: (role) => setState(() => selectedRole = role),
                              ),

                              const SizedBox(height: 12),

                              // 👤 Person list
                              Expanded(
                                child: filteredPersonnel.isEmpty
                                    ? const Center(child: Text('No personnel found for selected role.'))
                                    : ListView.builder(
                                  itemCount: filteredPersonnel.length,
                                  itemBuilder: (context, index) {
                                    final p = filteredPersonnel[index];

                                    return ListTile(
                                      leading: const Icon(Icons.person),
                                      title: Text(p.name),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Role: ${p.role}'),
                                          if (p.position != null) Text('Position: ${p.position}'),
                                          if (p.nationality != null) Text('Nationality: ${p.nationality}'),
                                          if (p.visaStatus != null) Text('Visa Status: ${p.visaStatus}'),
                                          if (p.salary != null) Text('Salary: ${p.salary!.toStringAsFixed(2)}'),
                                        ],
                                      ),
                                      trailing: SizedBox(
                                        width: 150,
                                        child: DropdownButton<SiteModel>(
                                          isExpanded: true,
                                          value: currentSite,
                                          underline: const SizedBox(),
                                          items: [
                                            DropdownMenuItem<SiteModel>(
                                              value: currentSite,
                                              child: Text('${currentSite.name} (Current)', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            ...otherSites.map((s) {
                                              return DropdownMenuItem<SiteModel>(
                                                value: s,
                                                child: Text(s.name),
                                              );
                                            }).toList(),
                                          ],
                                          onChanged: (newSite) async {
                                            if (newSite?.id != currentSite.id) {
                                              final success = await PersonnelService.assignSite(p.id, newSite?.id);
                                              if (success) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('${p.name} moved to ${newSite?.name}')),
                                                );
                                                setState(() {
                                                  siteFuture = SiteService.fetchSiteById(widget.siteId);
                                                  personnelFuture = PersonnelService.fetchPersonnelBySite(widget.siteId);
                                                });
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Update failed')),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 🔄 Scrollable role filter with arrows
class ScrollableRoleFilter extends StatefulWidget {
  final List<String> roles;
  final String? selectedRole;
  final Function(String?) onRoleSelected;

  const ScrollableRoleFilter({
    super.key,
    required this.roles,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  State<ScrollableRoleFilter> createState() => _ScrollableRoleFilterState();
}

class _ScrollableRoleFilterState extends State<ScrollableRoleFilter> {
  final ScrollController _scrollController = ScrollController();

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 150,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 150,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: _scrollLeft, icon: const Icon(Icons.arrow_back_ios)),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('All (${widget.roles.length})'),
                    selected: widget.selectedRole == null,
                    onSelected: (_) => widget.onRoleSelected(null),
                  ),
                ),
                ...widget.roles.map((role) {
                  final roleText = role.replaceAll(RegExp(r' \(\d+\)'), '');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(role),
                      selected: widget.selectedRole == roleText,
                      onSelected: (_) => widget.onRoleSelected(roleText),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        IconButton(onPressed: _scrollRight, icon: const Icon(Icons.arrow_forward_ios)),
      ],
    );
  }
}
