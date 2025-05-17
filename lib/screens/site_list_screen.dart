import 'package:flutter/material.dart';
import '../model/site_model.dart';
import '../model/personel_model.dart';
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
          if (!siteSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final sites = siteSnapshot.data!;

          return FutureBuilder<List<PersonnelModel>>(
            future: _futurePersonnel,
            builder: (context, personnelSnapshot) {
              if (!personnelSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final personnelList = personnelSnapshot.data!;

              final sitesByLocation = <String, List<SiteModel>>{};
              for (var site in sites) {
                sitesByLocation.putIfAbsent(site.location, () => []).add(site);
              }

              final filteredEntries = selectedLocation == null
                  ? sitesByLocation.entries
                  : sitesByLocation.entries.where((e) => e.key == selectedLocation);

              final filteredPersonnel = personnelList.where((p) {
                final matchesSearch = p.name.toLowerCase().contains(searchTerm.toLowerCase());
                final matchesFilter = switch (personnelFilter) {
                  'Boşta' => p.siteId == null,
                  'İzinde' => p.role.toLowerCase().contains('leave') || (p.position?.toLowerCase().contains('leave') ?? false),
                  _ => true,
                };
                return matchesSearch && matchesFilter;
              }).toList();

              return Row(
                children: [
                  // Left panel - Personnel
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
                            children: [
                              'All', 'Boşta', 'İzinde'
                            ].map((label) => ChoiceChip(
                              label: Text(label),
                              selected: personnelFilter == label,
                              onSelected: (_) => setState(() => personnelFilter = label),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredPersonnel.length,
                            itemBuilder: (context, index) {
                              final person = filteredPersonnel[index];

                              SiteModel? assignedSite;
                              try {
                                assignedSite = sites.firstWhere((s) => s.id == person.siteId);
                              } catch (_) {
                                assignedSite = null;
                              }

                              return ListTile(
                                tileColor: person.siteId == null ? Colors.green.withOpacity(0.15) : null,
                                title: Text(
                                  person.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: person.siteId == null ? Colors.green[800] : Colors.black,
                                    fontWeight: person.siteId == null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: 140,
                                  child: DropdownButton<SiteModel?>(
                                    isExpanded: true,
                                    value: assignedSite,
                                    hint: const Text('Assign', style: TextStyle(fontSize: 13)),
                                    items: [
                                      const DropdownMenuItem<SiteModel?>(
                                        value: null,
                                        child: Text('Boşta', style: TextStyle(fontSize: 13)),
                                      ),
                                      ...sites.map((site) {
                                        return DropdownMenuItem<SiteModel?>(
                                          value: site,
                                          child: Text(site.name, style: const TextStyle(fontSize: 13)),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (selectedSite) async {
                                      final newSiteId = selectedSite?.id;
                                      final success = await PersonnelService.assignSite(person.id, newSiteId);
                                      if (success) {
                                        setState(() {
                                          _futureSites = SiteService.fetchSites();
                                          _futurePersonnel = PersonnelService.fetchAllPersonnel();
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${person.name} ${selectedSite == null ? 'boşta' : '${selectedSite.name}'} olarak güncellendi'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Güncelleme başarısız')),
                                        );
                                      }
                                    },
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

                  // Right panel - Sites grouped by location
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
                                child: Text(
                                  '📍 $location',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...locationSites.map((site) {
                                final count = personnelList.where((p) => p.siteId == site.id).length;

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
              );
            },
          );
        },
      ),
    );
  }
}