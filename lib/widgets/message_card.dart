import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/helper/dialog.dart';
import 'package:chat_app/helper/my_date_util.dart';
import 'package:chat_app/main.dart';
import 'package:chat_app/models/message.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});
  final Messages message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = Apis.user.uid == widget.message.fromId;
    return InkWell(
        onLongPress: () {
          _showBottomSheet(isMe);
        },
        child: isMe ? _greenMessage() : _blueMessage());
  }

  //sender or another user message
  Widget _blueMessage() {
    if (widget.message.read.isEmpty) {
      Apis.updateMessageReadStatus(widget.message);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: mq.width * .04,
              vertical: mq.height * .01,
            ),
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .03
                : mq.width * .04),
            decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.lightBlue,
                ),
                borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(30),
                    topRight: Radius.circular(30),
                    topLeft: Radius.circular(30)),
                color: const Color.fromARGB(255, 157, 205, 245)),
            child: widget.message.type == Type.text
                ? Text(
                    widget.message.msg,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                      imageUrl: widget.message.msg,
                      // placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image,
                        size: 70,
                      ),
                    ),
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDateUtil.getFormattedTime(
                context: context, time: widget.message.sent),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  //our or user message
  Widget _greenMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: mq.width * .04,
            ),
            //double blue tick
            if (widget.message.read.isNotEmpty)
              const Icon(
                Icons.done_all_rounded,
                color: Colors.blue,
                size: 20,
              ),
            const SizedBox(width: 2),
            Text(
              MyDateUtil.getFormattedTime(
                  context: context, time: widget.message.sent),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        Flexible(
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: mq.width * .04,
              vertical: mq.height * .01,
            ),
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .03
                : mq.width * .04),
            decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.lightGreen,
                ),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    topLeft: Radius.circular(30)),
                color: const Color.fromARGB(255, 218, 255, 176)),
            child: widget.message.type == Type.text
                ? Text(
                    widget.message.msg,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      placeholder: (context, url) => const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      imageUrl: widget.message.msg,
                      // placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image,
                        size: 70,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showBottomSheet(isMe) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            Container(
              margin: EdgeInsets.symmetric(
                  vertical: mq.height * .015, horizontal: mq.width * .4),
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            widget.message.type == Type.text
                ? _OptionItem(
                    icon: const Icon(Icons.copy_outlined, color: Colors.blue),
                    name: 'Copy Text',
                    onTap: () async {
                      await Clipboard.setData(
                              ClipboardData(text: widget.message.msg))
                          .then(
                        (value) {
                          Navigator.pop(context);
                          Dialogs.showSnackBar(context, "Text Copied!");
                        },
                      );
                    })
                : _OptionItem(
                    icon:
                        const Icon(Icons.download_rounded, color: Colors.blue),
                    name: 'Save Imag',
                    onTap: () async {
                      try {
                        log('Image Url: ${widget.message.msg}');
                        await GallerySaver.saveImage(widget.message.msg,
                                albumName: 'App CHAT Images')
                            .then((success) {
                          //for hiding bottom sheet
                          Navigator.pop(context);
                          if (success != null && success) {
                            Dialogs.showSnackBar(
                                context, 'Image Successfully Saved!');
                          }
                        });
                      } catch (e) {
                        log('ErrorWhileSavingImg: $e');
                      }
                    },
                  ),
            if (isMe)
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),
            if (widget.message.type == Type.text && isMe)
              // _OptionItem(
              //   icon: const Icon(Icons.edit, color: Colors.blue),
              //   name: 'Edit Message',
              //   onTap: () {
              //     //for hiding bottom sheet
              //     // Navigator.pop(context);

              //     // _showMessageUpdateDialog();
              //   },
              // ),
              if (isMe)
                _OptionItem(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  name: 'Delete Message',
                  onTap: () async {
                    await Apis.deleteMessage(widget.message).then((value) {
                      Navigator.pop(context);
                    });
                  },
                ),
            Divider(
              color: Colors.black54,
              endIndent: mq.width * .04,
              indent: mq.width * .04,
            ),
            _OptionItem(
              icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
              name:
                  'Sent At: ${MyDateUtil.getMessageTime(context: context, time: widget.message.sent)}',
              onTap: () {},
            ),
            _OptionItem(
              icon: const Icon(Icons.remove_red_eye_outlined,
                  color: Colors.green),
              name: widget.message.read.isEmpty
                  ? "Read At: Not Seen Yet"
                  : 'Read At ${MyDateUtil.getMessageTime(context: context, time: widget.message.read)}',
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  // void _showMessageUpdateDialog() {
  //   String updatedMsg = widget.message.msg;

  //   showDialog(
  //       context: context,
  //       builder: (_) => AlertDialog(
  //             contentPadding: const EdgeInsets.only(
  //                 left: 24, right: 24, top: 20, bottom: 10),

  //             shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(20)),

  //             //title
  //             title: const Row(
  //               children: [
  //                 Icon(
  //                   Icons.message,
  //                   color: Colors.blue,
  //                   size: 28,
  //                 ),
  //                 Text(' Update Message')
  //               ],
  //             ),

  //             //content
  //             content: TextFormField(
  //               initialValue: updatedMsg,
  //               maxLines: null,
  //               onChanged: (value) => updatedMsg = value,
  //               decoration: InputDecoration(
  //                   border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(15))),
  //             ),

  //             //actions
  //             actions: [
  //               //cancel button
  //               MaterialButton(
  //                   onPressed: () {
  //                     //hide alert dialog
  //                     Navigator.pop(context);
  //                   },
  //                   child: const Text(
  //                     'Cancel',
  //                     style: TextStyle(color: Colors.blue, fontSize: 16),
  //                   )),

  //               //update button
  //               MaterialButton(
  //                   onPressed: () {
  //                     //hide alert dialog
  //                     Navigator.pop(context);
  //                     Apis.updateMessage(widget.message, updatedMsg);
  //                   },
  //                   child: const Text(
  //                     'Update',
  //                     style: TextStyle(color: Colors.blue, fontSize: 16),
  //                   ))
  //             ],
  //           ));
  // }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;
  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: EdgeInsets.only(
            left: mq.width * .07,
            top: mq.height * .015,
            bottom: mq.height * .015),
        child: Row(children: [
          icon,
          Flexible(
              child: Text(
            '     $name',
            style: const TextStyle(
                fontSize: 15, color: Colors.black54, letterSpacing: 0.5),
          )),
        ]),
      ),
    );
  }
}
