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
              final filteredPersonnel = personnelList
                  .where((p) => p.name.toLowerCase().contains(searchTerm.toLowerCase()))
                  .toList();

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

                  // Right panel - Sites
                  Expanded(
                    flex: 2,
                    child: ListView.builder(
                      itemCount: sites.length,
                      itemBuilder: (context, index) {
                        final site = sites[index];
                        final assignedPersonnel = personnelList.where((p) => p.siteId == site.id).toList();
                        final roleCounts = PersonnelService.countByRole(assignedPersonnel);

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(site.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📍 ${site.location}'),
                                const SizedBox(height: 4),
                                ...roleCounts.entries.map((entry) => Text('🔹 ${entry.key}: ${entry.value}')),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SiteDetailScreen(siteId: site.id),
                                ),
                              );
                              // Detaydan dönünce yenile
                              setState(() {
                                _futureSites = SiteService.fetchSites();
                                _futurePersonnel = PersonnelService.fetchAllPersonnel();
                              });
                            },
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
    );
  }
}
