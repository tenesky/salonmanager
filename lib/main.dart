import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:multiplat/core/util/platform_util.dart';
import 'package:multiplat/locator.dart';
import 'package:multiplat/ui/router.dart';

void main() {
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Use the initialRoute defined in router.dart to determine the first page
    // shown to the user. This is typically 'login' for new users.
    if (isCupertino()) {
      return CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'multiplat',
        theme: const CupertinoThemeData(
          primaryColor: Colors.blueGrey,
        ),
        initialRoute: initialRoute,
        onGenerateRoute: MultiPlatRouter.generateRoute,
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'multiplat',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      initialRoute: initialRoute,
      onGenerateRoute: MultiPlatRouter.generateRoute,
    );
  }
}
