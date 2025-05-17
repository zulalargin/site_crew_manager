// 🔄 ESKİ YAPI GERİ YÜKLENDİ - Search, filtreler, layout, detay ekranı, dropdown, renklendirme her şey dahil
import 'package:flutter/material.dart';

import '../model/personel_model.dart';
import '../model/site_model.dart';
import '../services/personel_services.dart';
import '../services/site_services.dart';
import 'site_detail_screen.dart';

class SiteListScreen extends StatefulWidget {
  @override
  _SiteListScreenState createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  late Future<List<SiteModel>> _futureSites;
  late Future<List<PersonnelModel>> _futurePersonnel;
  String searchTerm = '';
  String? selectedLocation;
  String personnelFilter = 'All';

  @override
  void initState() {
    super.initState();
    _futureSites = SiteService.fetchSites();
    _futurePersonnel = PersonnelService.fetchAllPersonnel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sites & Personnel')),
      body: FutureBuilder<List<SiteModel>>(
        future: _futureSites,
        builder: (context, siteSnapshot) {
          if (!siteSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final sites = siteSnapshot.data!;

          return FutureBuilder<List<PersonnelModel>>(
            future: _futurePersonnel,
            builder: (context, personnelSnapshot) {
              if (!personnelSnapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final allPersonnel = personnelSnapshot.data!;

              final sitesByLocation = <String, List<SiteModel>>{};
              for (var site in sites) {
                sitesByLocation.putIfAbsent(site.location, () => []).add(site);
              }

              final filteredEntries = selectedLocation == null
                  ? sitesByLocation.entries
                  : sitesByLocation.entries.where((e) => e.key == selectedLocation);

              final filteredPersonnel = allPersonnel.where((p) {
                final matchesSearch = p.name.toLowerCase().contains(searchTerm.toLowerCase());
                final matchesFilter = switch (personnelFilter) {
                  'Boşta' => p.siteId == null && (p.status?.toLowerCase() != 'on_leave'),
                  'İzinde' => p.status?.toLowerCase() == 'on_leave',
                  _ => true,
                };
                return matchesSearch && matchesFilter;
              }).toList();

              return Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: '🔍 Search personnel...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    onChanged: (value) => setState(() => searchTerm = value),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Wrap(
                                  spacing: 8,
                                  children: ['All', 'Boşta', 'İzinde']
                                      .map((label) => ChoiceChip(
                                    label: Text(label),
                                    selected: personnelFilter == label,
                                    onSelected: (_) => setState(() => personnelFilter = label),
                                  ))
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredPersonnel.length,
                                  itemBuilder: (context, index) {
                                    final person = filteredPersonnel[index];
                                    final isOnLeave = person.status?.toLowerCase() == 'on_leave';
                                    final isUnassigned = person.siteId == null && !isOnLeave;

                                    SiteModel? assignedSite;
                                    if (isOnLeave) {
                                      assignedSite = SiteModel.leave;
                                    } else {
                                      assignedSite = sites.firstWhere(
                                            (s) => s.id == person.siteId,
                                        orElse: () => SiteModel(
                                          id: -99,
                                          name: 'Tanımsız',
                                          location: '',
                                          workerCount: 0,
                                          engineerCount: 0,
                                        ),
                                      );
                                    }

                                    Color? tileColor;
                                    Color? textColor;
                                    FontWeight fontWeight = FontWeight.normal;

                                    if (isOnLeave) {
                                      tileColor = Colors.grey[300];
                                      textColor = Colors.grey[800];
                                    } else if (isUnassigned) {
                                      tileColor = Colors.green[100];
                                      textColor = Colors.green[900];
                                      fontWeight = FontWeight.bold;
                                    } else {
                                      textColor = Colors.black;
                                    }

                                    return ListTile(
                                      onTap: () => _showEditPersonnelDialog(person, allPersonnel),
                                      tileColor: tileColor,
                                      title: Text(
                                        person.name,
                                        style: TextStyle(fontSize: 14, color: textColor, fontWeight: fontWeight),
                                      ),
                                      trailing: SizedBox(
                                        width: 140,
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<SiteModel?>(
                                            isExpanded: true,
                                            value: isOnLeave ? SiteModel.leave : (assignedSite.id < 0 ? null : assignedSite),
                                            hint: const Text('Assign', style: TextStyle(fontSize: 13)),
                                            iconEnabledColor: Colors.black,
                                            dropdownColor: Colors.white,
                                            style: const TextStyle(fontSize: 13, color: Colors.black),
                                            items: [
                                              DropdownMenuItem<SiteModel?>(value: null, child: _noHighlightText('Boşta')),
                                              DropdownMenuItem<SiteModel?>(value: SiteModel.leave, child: _noHighlightText('İzinde')),
                                              ...sites.map((site) => DropdownMenuItem<SiteModel?>(
                                                value: site,
                                                child: _noHighlightText(site.name),
                                              )),
                                            ],
                                            onChanged: (selectedSite) async {
                                              String? newStatus;
                                              int? newSiteId;

                                              if (selectedSite == null) {
                                                newSiteId = null;
                                                newStatus = 'ACTIVE';
                                              } else if (selectedSite.id == -1) {
                                                newSiteId = null;
                                                newStatus = 'ON_LEAVE';
                                              } else {
                                                newSiteId = selectedSite.id;
                                                newStatus = 'ACTIVE';
                                              }

                                              final success = await PersonnelService.assignSiteAndStatus(
                                                person.id,
                                                newSiteId,
                                                newStatus,
                                              );

                                              if (success) {
                                                setState(() {
                                                  _futureSites = SiteService.fetchSites();
                                                  _futurePersonnel = PersonnelService.fetchAllPersonnel();
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('${person.name} güncellendi')),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Güncelleme başarısız')),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const VerticalDivider(),
                        Expanded(
                          flex: 2,
                          child: ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: DropdownButton<String>(
                                  value: selectedLocation,
                                  hint: const Text('📍 Select location'),
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('All Locations')),
                                    ...sitesByLocation.keys.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))),
                                  ],
                                  onChanged: (value) => setState(() => selectedLocation = value),
                                ),
                              ),
                              ...filteredEntries.map((entry) {
                                final location = entry.key;
                                final locationSites = entry.value;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Text('📍 $location', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                    ...locationSites.map((site) {
                                      final count = allPersonnel.where((p) => p.siteId == site.id).length;

                                      return ListTile(
                                        title: Text(site.name),
                                        subtitle: Text('👥 $count personnel'),
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SiteDetailScreen(siteId: site.id),
                                            ),
                                          );
                                          setState(() {
                                            _futureSites = SiteService.fetchSites();
                                            _futurePersonnel = PersonnelService.fetchAllPersonnel();
                                          });
                                        },
                                      );
                                    }),
                                    const Divider(thickness: 1),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showEditPersonnelDialog(PersonnelModel person, List<PersonnelModel> allPersonnel) {
    final nameController = TextEditingController(text: person.name);
    final roleController = TextEditingController(text: person.role);
    final positionController = TextEditingController(text: person.position ?? '');
    final nationalityController = TextEditingController(text: person.nationality ?? '');
    final visaStatusController = TextEditingController(text: person.visaStatus ?? '');
    final salaryController = TextEditingController(text: person.salary?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${person.name} - Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'İsim'), controller: nameController),
              TextField(decoration: InputDecoration(labelText: 'Rol'), controller: roleController),
              TextField(decoration: InputDecoration(labelText: 'Pozisyon'), controller: positionController),
              TextField(decoration: InputDecoration(labelText: 'Uyruk'), controller: nationalityController),
              TextField(decoration: InputDecoration(labelText: 'Vize Durumu'), controller: visaStatusController),
              TextField(decoration: InputDecoration(labelText: 'Maaş'), controller: salaryController, keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final updated = PersonnelModel(
                id: person.id,
                name: nameController.text.trim(),
                role: roleController.text.trim(),
                position: positionController.text.trim(),
                nationality: nationalityController.text.trim(),
                visaStatus: visaStatusController.text.trim(),
                salary: double.tryParse(salaryController.text.trim()),
                siteId: person.siteId,
                status: person.status,
              );
              final success = await PersonnelService.updatePersonnelInfo(updated);
              if (success) {
                Navigator.pop(context);
                final updatedFuture = PersonnelService.fetchAllPersonnel();
                setState(() {
                  _futurePersonnel = updatedFuture;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${person.name} güncellendi')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Güncelleme başarısız')));
              }
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _noHighlightText(String text) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final int count;
  final String emoji;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.count,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

extension SiteModelHelpers on SiteModel {
  static final SiteModel leave = SiteModel(
    id: -1,
    name: 'İzinde',
    location: '',
    workerCount: 0,
    engineerCount: 0,
  );
}
