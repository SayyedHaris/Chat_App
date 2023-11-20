import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/helper/my_date_util.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/widgets/dialogs/profile_dialogs.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  Messages? _messages;
  @override
  Widget build(BuildContext context) {
    return Card(
      // color: Colors.blue.shade200,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.symmetric(horizontal: mq.width * .03, vertical: 5),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(user: widget.user),
              ));
        },
        child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: StreamBuilder(
              stream: Apis.getLastMessage(widget.user),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data!.docs;
                  final list =
                      data.map((e) => Messages.fromJson(e.data())).toList();
                  if (list.isNotEmpty) {
                    _messages = list[0];
                  }
                }
                // final data = snapshot.data!.docs;
                // final list =
                //     data.map((e) => Messages.fromJson(e.data())).toList();

                // if (list.isNotEmpty) _messages = list[0];

                return ListTile(
                    title: Text(widget.user.name),
                    leading: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              ProfileDialog(user: widget.user),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(mq.height * .5),
                        child: CachedNetworkImage(
                          width: mq.width * .16,
                          height: mq.height * .8,
                          imageUrl: widget.user.image,
                          // placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(CupertinoIcons.person),
                        ),
                      ),
                    ),
                    subtitle: Text(
                      _messages != null
                          ? _messages!.type == Type.image
                              ? 'image'
                              : _messages!.msg
                          : widget.user.about,
                      maxLines: 1,
                    ),
                    trailing: _messages == null
                        ? null
                        : _messages!.read.isEmpty &&
                                _messages!.fromId != Apis.user.uid
                            ? Container(
                                height: 13,
                                width: 13,
                                decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10)),
                              )
                            : Text(
                                MyDateUtil.getLastMessageTime(
                                    context: context, time: _messages!.sent),
                                style: const TextStyle(color: Colors.black54),
                              ));
              },
            )),
      ),
    );
  }
}
