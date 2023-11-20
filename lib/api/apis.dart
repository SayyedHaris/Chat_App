import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:chat_app/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';

import '../models/chat_user.dart';

class Apis {
  //for self info
  static late ChatUser me;
  //for firebase
  static FirebaseAuth auth = FirebaseAuth.instance;
  //for firestore
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  //for accessing firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;
  // making shortcut of authentication
  static User get user => auth.currentUser!;
  // for push notifications
  static FirebaseMessaging fmessaging = FirebaseMessaging.instance;
  static Future<void> getFirebaseMessagingToken() async {
    await fmessaging.requestPermission();

    await fmessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Push Token : $t');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
    });
  }
  //for push notification purpose

  static Future<void> sendPushNotification(ChatUser user, String msg) async {
    try {
      final body = {
        "to": user.pushToken,
        "notification": {
          "title": me.name,
          "body": msg,
          "android_channel_id": "chats"
        },
        "data": {
          "some_data": "User ID: ${me.id}",
        },
      };
      var res = await post(Uri.parse("https://fcm.googleapis.com/fcm/send"),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader:
                'key=AAAA60V6O7w:APA91bHjcwDmlOooX8bFUancAINGE3qzDHuMJl0DvFtZmzYZP2RlyPOb8tWpVfNgNBIkeNVlTDFF007DNZXocr9xswFSIOgR_GMoKM4xgedxWQQCH1n5hj8wicZSTG7ageW4dfNBPKqI'
          },
          body: jsonEncode(body));
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }

  //for checking if user exists or not
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  // for adding an chat user for our conversation
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    log('data: ${data.docs}');

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exists

      log('user exists: ${data.docs.first.data()}');

      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      //user doesn't exists

      return false;
    }
  }

  //for self info
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        Apis.updateActiveStatus(true);
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

//create new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      about: "Hey i am creating AppCHAT",
      createdAt: time,
      email: user.email.toString(),
      image: user.photoURL.toString(),
      isOnline: false,
      lastActive: time,
      pushToken: '',
    );

    return await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .set(chatUser.toJson());
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection("users")
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    log('\nUserIds: $userIds');
    return firestore
        .collection("users")
        .where('id', whereIn: userIds.isEmpty ? [''] : userIds)
        // .where("id", isNotEqualTo: user.uid)
        .snapshots();
  }

  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection("users")
        .where("id", isEqualTo: chatUser.id)
        .snapshots();
  }

  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection("users").doc(user.uid).update({
      'is_online': isOnline,
      'last_acive': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken
    });
  }

  static Future<void> updateUserInfo() async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'name': me.name, 'about': me.about});
  }

  //update profile pic of user
  static Future<void> updateProfilePicture(File file) async {
    final ext = file.path.split('.').last;
    log("Extension : $ext");
    //storage file ref
    final ref = storage.ref().child('profile picture/${user.uid}.$ext');

    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext')).then(
        (p0) => log("Data Transfered : ${p0.bytesTransferred / 1000} kb"));

    //updating image
    me.image = await ref.getDownloadURL();

    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': me.image});
  }

  /// ********** Chat screen related APis************

//usefull for getting conversation id

  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  // get all messages of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection("chat/${getConversationID(user.id)}/messages/")
        .orderBy('sent', descending: true)
        .snapshots();
  }

  // for sending messages
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final Messages messages = Messages(
        msg: msg,
        read: '',
        told: chatUser.id,
        type: type,
        sent: time,
        fromId: user.uid);
    final ref = firestore
        .collection("chat/${getConversationID(chatUser.id)}/messages/");
    await ref.doc(time).set(messages.toJson()).then((value) =>
        sendPushNotification(chatUser, type == Type.text ? msg : 'image'));
  }

  //for update read messages(bluetick),,
  static Future<void> updateMessageReadStatus(Messages messages) async {
    firestore
        .collection("chat/${getConversationID(messages.fromId)}/messages/")
        .doc(messages.sent)
        .update({"read": DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection("chat/${getConversationID(user.id)}/messages/")
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    final ext = file.path.split('.').last;
    log("Extension : $ext");
    //storage file ref
    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext')).then(
        (p0) => log("Data Transfered : ${p0.bytesTransferred / 1000} kb"));

    //updating image
    final imageUrl = await ref.getDownloadURL();

    await sendMessage(chatUser, imageUrl, Type.image);
  }

  static Future<void> deleteMessage(Messages message) async {
    await firestore
        .collection("chat/${getConversationID(message.told)}/messages/")
        .doc(message.sent)
        .delete();
    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  //update message
  static Future<void> updateMessage(Messages message, String updatedMsg) async {
    await firestore
        .collection('chat/${getConversationID(message.told)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }
}
