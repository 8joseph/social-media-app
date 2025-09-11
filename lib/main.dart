import 'package:flutter/material.dart';
import 'ui.dart';
import 'app_brain.dart';
import 'package:firebase_core/firebase_core.dart';

//create the app brain class which will be used to call all of the algorithms
AppBrain appBrain = AppBrain();

Future main() async {
  //initialise firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //run the app
  runApp(const SocialMediaApp());
}
