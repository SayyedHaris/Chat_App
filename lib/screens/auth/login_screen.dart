import 'dart:developer';
import 'dart:io';

import 'package:chat_app/api/apis.dart';
import 'package:chat_app/helper/dialog.dart';
import 'package:chat_app/home_page.dart';
import 'package:chat_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late bool _isAnimate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        setState(() {
          _isAnimate = true;
        });
      },
    );
  }

  _handleGoogleBtnClick() {
    //for shwoing progress indicator.
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {
      //for hiding progress indicator
      Navigator.pop(context);
      if (user != null) {
        log("\nUser: ${user.user}");
        log("\nUserAdditionalInfo: ${user.additionalUserInfo}");

        if ((await Apis.userExists())) {
          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Homepage(),
              ));
        } else {
          await Apis.createUser().then((value) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const Homepage(),
                ));
          });
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup("google.com");
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await Apis.auth.signInWithCredential(credential);
    } catch (e) {
      log("\n_signInWithGoogle : $e");
      Dialogs.showSnackBar(context, "Something went wrong (Check Internet!)");
      return null;
    }
  }

  // ignore: unused_element
  _signOut() async {
    await Apis.auth.signOut();
    await GoogleSignIn().signOut();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   centerTitle: true,
      //   title: const Text(
      //     "Welcome to AppChat",
      //   ),
      // ),
      body: Stack(
        children: [
          AnimatedPositioned(
            top: mq.height * .08,
            right: _isAnimate ? mq.width * .21 : mq.width,
            duration: const Duration(seconds: 1),
            child: const Text(
              "Welcome to AppCHAT",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(seconds: 1),
            top: mq.height * .20,
            width: mq.width * .5,
            right: _isAnimate ? mq.width * .25 : -mq.width * .5,
            child: Image.asset("assets/images/chatlogo.png"),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1300),
            bottom: _isAnimate ? mq.height * .13 : -mq.height * .6,
            left: mq.width * .05,
            width: mq.width * .9,
            height: mq.height * .06,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  elevation: 1.0,
                  shape: const StadiumBorder(),
                  backgroundColor: const Color.fromARGB(255, 223, 255, 187)),
              onPressed: () {
                _handleGoogleBtnClick();
              },
              icon: Image.asset("assets/images/googlepic.png",
                  height: mq.height * .03),
              label: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(text: 'Sign in with'),
                    TextSpan(
                      text: ' Google',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
