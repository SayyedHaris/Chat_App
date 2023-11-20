// ignore_for_file: file_names

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/helper/dialog.dart';
import 'package:chat_app/helper/my_date_util.dart';
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

import '../models/message.dart';

class ViewProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ViewProfileScreen({super.key, required this.user});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  List<Messages> _list = [];

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
              builder: (context) => const LoginPage(),
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
        title: Text(
          widget.user.name,
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("         Joined On: ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
                MyDateUtil.getLastMessageTime(
                    context: context,
                    time: widget.user.createdAt,
                    showYear: true),
                style: const TextStyle(color: Colors.black54, fontSize: 16)),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // for adding some space
              SizedBox(width: mq.width, height: mq.height * .03),

              //user profile picture
              ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * .1),
                child: CachedNetworkImage(
                  width: mq.height * .2,
                  height: mq.height * .2,
                  fit: BoxFit.cover,
                  imageUrl: widget.user.image,
                  errorWidget: (context, url, error) =>
                      const CircleAvatar(child: Icon(CupertinoIcons.person)),
                ),
              ),

              // for adding some space
              SizedBox(height: mq.height * .03),

              // user email label
              Text(widget.user.email,
                  style: const TextStyle(color: Colors.black, fontSize: 16)),

              // Text(
              //         list.isNotEmpty
              //             ? list[0].isOnline
              //                 ? 'Online'
              //                 : MyDateUtil.getLastActiveTime(
              //                     context: context,
              //                     lastActive: list[0].lastActive)
              //             : MyDateUtil.getLastActiveTime(
              //                 context: context,
              //                 lastActive: widget.user.lastActive),
              //         style: const TextStyle(
              //           fontSize: 13,
              //           color: Colors.black54,
              //         ),
              //       ),

              StreamBuilder(
                stream: Apis.getUserInfo(widget.user),
                builder: (context, snapshot) {
                  final data = snapshot.data?.docs ?? [];
                  final list =
                      data.map((e) => ChatUser.fromJson(e.data())).toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      list.isNotEmpty
                          ? list[0].isOnline
                              ? 'Online 🟢'
                              : MyDateUtil.getLastActiveTime(
                                  context: context,
                                  lastActive: list[0].lastActive)
                          : MyDateUtil.getLastActiveTime(
                              context: context,
                              lastActive: widget.user.lastActive),
                      style: TextStyle(
                        backgroundColor: Colors.grey.shade200,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),

              Divider(),

              // for adding some space
              SizedBox(height: mq.height * .02),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("About: ",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(widget.user.about,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
