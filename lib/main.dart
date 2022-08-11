import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skr_verify_app/model/provider_model.dart';
import 'package:skr_verify_app/model/user_model.dart';
import 'package:skr_verify_app/others/style.dart';
import 'package:skr_verify_app/screen/splash_screen/splash_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Add this
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserModel>(
          create: (_) => UserModel(),
        ),
        ChangeNotifierProvider<ProviderModel>(
          create: (_) => ProviderModel(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          appBarTheme: AppBarTheme(
            color: themeColor1
          )
        ),
        home: SplashScreen(),
      ),
    );
  }
}



