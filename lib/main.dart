import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/site/site_bloc.dart';
import 'blocs/site/site_event.dart';
import 'screens/site_list_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Site Crew Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        canvasColor: Colors.white, // dropdown arka planı için (isteğe bağlı)
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
      home: BlocProvider(
        create: (_) => SiteBloc()..add(LoadSites()),
        child: SiteListScreen(),
      ),
    );
  }
}
