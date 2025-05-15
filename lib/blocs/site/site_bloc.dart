import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../model/site_model.dart';
import 'site_event.dart';
import 'site_state.dart';

class SiteBloc extends Bloc<SiteEvent, SiteState> {
  SiteBloc() : super(SiteInitial()) {
    on<LoadSites>(_onLoadSites);
  }

  Future<void> _onLoadSites(LoadSites event, Emitter<SiteState> emit) async {
    emit(SiteLoading());

    try {
      final response = await http.get(Uri.parse('http://localhost:8080/api/sites'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final sites = data.map((json) => SiteModel.fromJson(json)).toList();
        emit(SiteLoaded(sites));
      } else {
        emit(SiteError('Failed to load sites: ${response.statusCode}'));
      }
    } catch (e) {
      emit(SiteError('Error: $e'));
    }
  }
}
