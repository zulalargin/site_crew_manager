import 'package:flutter/material.dart';
import 'package:site_crew_manager/services/personel_services.dart';
import '../model/personel_model.dart';
import '../model/site_model.dart';
import '../services/site_services.dart';

class SiteDetailScreen extends StatefulWidget {
  final int siteId;

  const SiteDetailScreen({super.key, required this.siteId});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  late Future<SiteModel> siteFuture;

  @override
  void initState() {
    super.initState();
    siteFuture = SiteService.fetchSiteById(widget.siteId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Site Detail')),
      body: FutureBuilder<SiteModel>(
        future: siteFuture,
        builder: (context, siteSnapshot) {
          if (siteSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (siteSnapshot.hasError) {
            return Center(child: Text('Error: ${siteSnapshot.error}'));
          } else if (!siteSnapshot.hasData) {
            return const Center(child: Text('No data found'));
          }

          final currentSite = siteSnapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏗 ${currentSite.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('📍 ${currentSite.location}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),

                Expanded(
                  child: FutureBuilder<List<PersonnelModel>>(
                    future: PersonnelService.fetchPersonnelBySite(currentSite.id),
                    builder: (context, personnelSnapshot) {
                      if (personnelSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (personnelSnapshot.hasError) {
                        return const Text("Error loading personnel");
                      } else if (!personnelSnapshot.hasData || personnelSnapshot.data!.isEmpty) {
                        return const Text("No personnel assigned.");
                      }

                      final personnel = personnelSnapshot.data!;
                      final roleCounts = PersonnelService.countByRole(personnel);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...roleCounts.entries.map((e) => Text(
                            '${e.key}: ${e.value}',
                            style: const TextStyle(fontSize: 16),
                          )),
                          const SizedBox(height: 16),

                          Expanded(
                            child: FutureBuilder<List<SiteModel>>(
                              future: SiteService.fetchSites(),
                              builder: (context, allSitesSnapshot) {
                                if (allSitesSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (allSitesSnapshot.hasError || !allSitesSnapshot.hasData) {
                                  return const Text("Error loading sites");
                                }

                                final otherSites = allSitesSnapshot.data!
                                    .where((s) => s.id != currentSite.id)
                                    .toList();

                                return ListView.builder(
                                  itemCount: personnel.length,
                                  itemBuilder: (context, index) {
                                    final p = personnel[index];

                                    return ListTile(
                                      leading: Text(p.role == 'Worker' ? '👷' : '🧑‍💼'),
                                      title: Text(p.name),
                                      subtitle: Text(p.role),
                                      trailing: SizedBox(
                                        width: 130,
                                        child: DropdownButton<SiteModel>(
                                          isExpanded: true,
                                          hint: const Text("Move"),
                                          value: null,
                                          items: otherSites.map((s) {
                                            return DropdownMenuItem(
                                              value: s,
                                              child: Text(s.name),
                                            );
                                          }).toList(),
                                          onChanged: (newSite) async {
                                            final success = await PersonnelService.updatePersonnelSite(p.id, newSite!.id);
                                            if (success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('${p.name} moved to ${newSite.name}')),
                                              );
                                              setState(() {
                                                siteFuture = SiteService.fetchSiteById(widget.siteId);
                                              });
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Update failed')),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
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
