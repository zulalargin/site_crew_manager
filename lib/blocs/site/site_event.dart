import 'package:equatable/equatable.dart';

abstract class SiteEvent extends Equatable {
  const SiteEvent();

  @override
  List<Object?> get props => [];
}

class LoadSites extends SiteEvent {}
