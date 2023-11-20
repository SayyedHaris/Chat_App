import 'dart:developer';

import 'package:chat_app/api/apis.dart';
import 'package:chat_app/helper/dialog.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/widgets/chat_user_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<ChatUser> _list = [];

  // for searching users..
  final List<ChatUser> _searchList = [];

  bool _seaching = false;

  @override
  void initState() {
    super.initState();
    Apis.getSelfInfo();
    Apis.updateActiveStatus(true);
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message  $message');

      if (Apis.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          Apis.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          Apis.updateActiveStatus(false);
        }
      }

      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        //if seacing is on and back button is pressed then it should close search..
        onWillPop: () {
          if (_seaching) {
            setState(() {
              _seaching = !_seaching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
            appBar: AppBar(
              leading: const Icon(CupertinoIcons.home, color: Colors.black),
              title: _seaching
                  ? TextField(
                      decoration: const InputDecoration(
                          hintText: "Name,Email,...", border: InputBorder.none),
                      autofocus: true,
                      style: const TextStyle(fontSize: 16, letterSpacing: 0.5),
                      //when we search, it shows only those things which we searched..
                      onChanged: (val) {
                        //search logic
                        _searchList.clear();

                        for (var i in _list) {
                          if (i.name.toLowerCase().contains(val) ||
                              i.email.toLowerCase().contains(val)) {
                            _searchList.add(i);
                          }
                          setState(() {
                            _searchList;
                          });
                        }
                      },
                    )
                  : const Text(
                      "AppCHAT",
                    ),
              actions: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _seaching = !_seaching;
                    });
                  },
                  icon: Icon(
                    _seaching
                        ? CupertinoIcons.clear_circled_solid
                        : Icons.search,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(user: Apis.me),
                        ));
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 10),
              child: FloatingActionButton(
                onPressed: () {
                  _addChatUserDialog();
                },
                child: const Icon(CupertinoIcons.person_add_solid, size: 35),
              ),
            ),
            body: StreamBuilder(
              stream: Apis.getMyUsersId(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  //if data is loading
                  case ConnectionState.waiting:
                  case ConnectionState.none:
                    return const Center(child: CircularProgressIndicator());

                  //if some or all data is loaded then show it
                  case ConnectionState.active:
                  case ConnectionState.done:
                    return StreamBuilder(
                      stream: Apis.getAllUsers(
                          snapshot.data?.docs.map((e) => e.id).toList() ?? []),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          //if data is loading
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                            return const Center(
                                child: CircularProgressIndicator());

                          //if some or all data is loaded then show it
                          case ConnectionState.active:
                          case ConnectionState.done:
                            final data = snapshot.data!.docs;
                            _list = data
                                .map((e) => ChatUser.fromJson(e.data()))
                                .toList();

                            if (_list?.isNotEmpty == true) {
                              return ListView.builder(
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _seaching
                                    ? _searchList.length
                                    : _list.length,
                                itemBuilder: (context, index) {
                                  return ChatUserCard(
                                    user: _seaching
                                        ? _searchList[index]
                                        : _list[index],
                                  );
                                  // return Text("Name : ${list[index]}");
                                },
                              );
                            } else {
                              return const Center(
                                child: Text(
                                  "No Connections Found!",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                        }
                      },
                    );
                }
              },
            )),
      ),
    );
  }

// for adding new chat user
  void _addChatUserDialog() {
    String email = "";

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),

              //title
              title: const Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Colors.blue,
                    size: 28,
                  ),
                  Text('  Add Users')
                ],
              ),

              //content
              content: TextFormField(
                maxLines: null,
                onChanged: (value) => email = value,
                decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.email,
                      color: Colors.blue,
                    ),
                    hintText: "Email",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),

              //actions
              actions: [
                //cancel button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    )),

                //add button
                MaterialButton(
                    onPressed: () async {
                      //hide alert dialog
                      Navigator.pop(context);
                      if (email.isNotEmpty) {
                        await Apis.addChatUser(email).then((value) {
                          if (!value) {
                            Dialogs.showSnackBar(
                                context, "User does not Exists!");
                          }
                        });
                      }
                    },
                    child: const Text(
                      'Add',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ))
              ],
            ));
  }
}
