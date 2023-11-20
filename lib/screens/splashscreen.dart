import 'dart:developer';

import 'package:chat_app/home_page.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/screens/auth/login_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/apis.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(seconds: 2),
      () {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.white,
            statusBarColor: Colors.white));

        if (Apis.auth.currentUser != null) {
          log("\nUser: ${Apis.auth.currentUser}");

          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Homepage(),
              ));
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: mq.height * .35,
            width: mq.width * .5,
            right: mq.width * .25,
            child: Image.asset("assets/images/chatlogo.png"),
          ),
          Positioned(
            bottom: mq.height * .15,
            width: mq.width,
            child: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(),
                children: [
                  TextSpan(
                      text: "Developer ",
                      style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  TextSpan(
                      text: " :-",
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  TextSpan(
                      text: "  Harry ❤️",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
