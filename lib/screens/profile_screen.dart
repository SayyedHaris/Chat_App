// ignore_for_file: prefer_const_constructors

import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/helper/dialog.dart';
import 'package:chat_app/home_page.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
// import 'package:chat_app/main.dart';
// import 'package:chat_app/models/chat_user.dart';
// import 'package:chat_app/widgets/chat_user_card.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _image;
  final _formkey = GlobalKey<FormState>();

  Future<void> logout() async {
    Dialogs.showProgressBar(context);

    await Apis.updateActiveStatus(false);
    await Apis.auth.signOut().then((value) async {
      await GoogleSignIn().signOut().then((value) {
        Navigator.pop(context);

        Navigator.pop(context);

        Apis.auth = FirebaseAuth.instance;

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(),
            ));
      });
    });
  }

  bool isTrue = true;
  void trogglePage() {
    setState(() {
      isTrue = false;
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Homepage(),
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
            onTap: () {
              trogglePage();
              // print("Clicked");
            },
            child: const Icon(
              CupertinoIcons.arrow_left_circle_fill,
              color: Colors.black,
              size: 36,
            )),
        title: const Text(
          "Profile Screen",
        ),
      ),
      body: Form(
        key: _formkey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // for adding some space
                SizedBox(width: mq.width, height: mq.height * .03),

                //user profile picture
                Stack(
                  children: [
                    //profile picture
                    _image != null
                        ?

                        //local image
                        ClipRRect(
                            borderRadius: BorderRadius.circular(mq.height * .1),
                            child: Image.file(File(_image!),
                                width: mq.height * .2,
                                height: mq.height * .2,
                                fit: BoxFit.cover))
                        :

                        //image from server
                        ClipRRect(
                            borderRadius: BorderRadius.circular(mq.height * .1),
                            child: CachedNetworkImage(
                              width: mq.height * .2,
                              height: mq.height * .2,
                              fit: BoxFit.cover,
                              imageUrl: widget.user.image,
                              errorWidget: (context, url, error) =>
                                  const CircleAvatar(
                                      child: Icon(CupertinoIcons.person)),
                            ),
                          ),

                    //edit image button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: MaterialButton(
                        elevation: 1,
                        onPressed: () {
                          _showBottomSheet();
                        },
                        shape: const CircleBorder(),
                        color: Colors.white,
                        child: const Icon(CupertinoIcons.photo_camera_solid,
                            color: Colors.black, size: 23),
                      ),
                    )
                  ],
                ),

                // for adding some space
                SizedBox(height: mq.height * .03),

                // user email label
                Text(widget.user.email,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 16)),

                // for adding some space
                SizedBox(height: mq.height * .05),

                // name input field
                TextFormField(
                  initialValue: widget.user.name,
                  onSaved: (val) => Apis.me.name = val ?? '',
                  validator: (val) =>
                      val != null && val.isNotEmpty ? null : 'Required Field',
                  decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hintText: 'eg. Happy Singh',
                      label: const Text('Name')),
                ),

                // for adding some space
                SizedBox(height: mq.height * .02),

                // about input field
                TextFormField(
                  initialValue: widget.user.about,
                  onSaved: (val) => Apis.me.about = val ?? '',
                  validator: (val) =>
                      val != null && val.isNotEmpty ? null : 'Required Field',
                  decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.info_outline, color: Colors.blue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hintText: 'eg. Feeling Happy',
                      label: const Text('About')),
                ),

                // for adding some space
                SizedBox(height: mq.height * .05),

                // update profile button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      minimumSize: Size(mq.width * .4, mq.height * .054)),
                  onPressed: () {
                    if (_formkey.currentState!.validate()) {
                      _formkey.currentState!.save();
                      Apis.updateUserInfo().then((value) {
                        Dialogs.showSnackBar(
                            context, 'Profile Updated Successfully!');
                      });
                    }
                  },
                  icon: const Icon(Icons.edit, size: 28),
                  label: const Text('UPDATE', style: TextStyle(fontSize: 16)),
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 10),
        child: FloatingActionButton.extended(
          elevation: 2,
          backgroundColor: Colors.redAccent.shade200,
          onPressed: () {
            logout();
          },
          icon: const Icon(Icons.logout_outlined),
          label: const Text("Logout"),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  //bottom sheet for image pick
  void _showBottomSheet() {
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          padding:
              EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
          children: [
            Text(
              "Pick Profile Picture!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        backgroundColor: Colors.white,
                        fixedSize: Size(mq.width * .3, mq.height * .15)),
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      // Pick an image.
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        log('Image Path : ${image.path} --  Mime type : ${image.mimeType}');
                        setState(() {
                          _image = image.path;
                        });

                        Apis.updateProfilePicture(File(_image!));
                        //for hiding bottom sheet
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                      }
                    },
                    child: Image.asset(
                      "assets/images/add_image.png",
                    )),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        backgroundColor: Colors.white,
                        fixedSize: Size(mq.width * .3, mq.height * .15)),
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      // Pick an image.
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.camera);
                      if (image != null) {
                        log('Image Path : ${image.path}');
                        setState(() {
                          _image = image.path;
                        });

                        Apis.updateProfilePicture(File(_image!));
                        //for hiding bottom sheet
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                      }
                    },
                    child: Image.asset(
                      "assets/images/camera.png",
                    )),
              ],
            )
          ],
        );
      },
    );
  }
}
