import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../models/ChatRoomModel.dart';
import '../models/MessageModel.dart';
import '../models/UserModel.dart';

class ChatRoomPage extends StatefulWidget {
  final UserModel targetUser;
  final ChatRoomModel chatroom;
  final UserModel userModel;
  final User firebaseUser;

 // final Map<String, dynamic> userMap;


  const ChatRoomPage({Key? key, required this.targetUser, required this.chatroom, required this.userModel, required this.firebaseUser}) : super(key: key);

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController messageController = TextEditingController();
   String? chatRoomId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? imageFile;

  Future getImage() async {
    ImagePicker _picker = ImagePicker();

    await _picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
        print("helloooo111");
      }
    });

  }

  Future uploadImage() async {
    String fileName = Uuid().v1();
    int status = 1;
    print("helloooo1");
    await _firestore
        .collection('chatroom')
        .doc(chatRoomId)
        .collection('chats')
        .doc(fileName)
        .set({
      "sendby": _auth.currentUser!.displayName,
      "message": "",
      "type": "img",
      "time": FieldValue.serverTimestamp(),
    });
    print("helloooo2");
    var ref =
    FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");
    print("helloooo5$ref");
    var uploadTask = await ref.putFile(imageFile!).catchError((error) async {
      print("helloooo6$uploadImage()");
      await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .doc(fileName)
          .delete();
      print("helloooo7$uploadImage()");
      print("helloooo3");
      status = 0;
    });
    print("helloooo3");
    if (status == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();
      print("helloooo4");
      print("heloo>>>>$imageFile");
      print("helooURl>>>>$imageUrl");

      await _firestore
          .collection('chatroom')
          .doc(chatRoomId)
          .collection('chats')
          .doc(fileName)
          .update({"message": imageUrl});
      print("helloooo444");
      print("hel12ooURl>>>>$imageUrl");
      print(imageUrl);
    }
  }


  Map<String, dynamic>? userMap;
  void sendMessage() async {
    String msg = messageController.text.trim();
    messageController.clear();

    if(msg != "") {
      // Send Message
      MessageModel newMessage = MessageModel(
        messageid: uuid.v1(),
        sender: widget.userModel.uid,
        createdon: DateTime.now(),
        text: msg,
        seen: false
      );

      FirebaseFirestore.instance.collection("chatrooms").doc(widget.chatroom.chatroomid).collection("messages").doc(newMessage.messageid).set(newMessage.toMap());

      widget.chatroom.lastMessage = msg;
      FirebaseFirestore.instance.collection("chatrooms").doc(widget.chatroom.chatroomid).set(widget.chatroom.toMap());

      log("Message Sent!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title:
        StreamBuilder<DocumentSnapshot>(
          stream:
          _firestore.collection("users").doc(userMap?['uid']).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              print("hello>>$snapshot.data!['status']");
              print("hellooo>>$snapshot.data!.id");
              print("helloooooo");
              print("heloooo$widget.targetUser.fullname");
              print("heloooooo$widget.targetUser.status");
             // print(snapshot.data!['status']);
              return
                Container(

                child:
                Row(
                  children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          backgroundImage: NetworkImage(widget.targetUser.profilepic.toString()),
                        ),
                    SizedBox(width: 10,),
                    Column(
                      children: [
                        Text(widget.targetUser.fullname.toString()),
                      //  Text(widget.targetUser.status.toString(),style: TextStyle(fontSize: 14),),


                        // Text(
                        //  // data['status']??"",
                        //   snapshot.data!['status'],
                        //   //snapshot.data?['status']??"",
                        //   style: TextStyle(fontSize: 14),
                        // ),

                      ],
                    ),
                  ],
                ),
              );
            } else {
              return Container();
            }
          },
        ),
        // Row(
        //   children: [
        //
        //     CircleAvatar(
        //       backgroundColor: Colors.grey[300],
        //       backgroundImage: NetworkImage(widget.targetUser.profilepic.toString()),
        //     ),
        //
        //     SizedBox(width: 10,),
        //
        //     Column(
        //       children: [
        //         Text(widget.targetUser.fullname.toString()),
        //         Text(
        //           snapshot.data!['status'],
        //           style: TextStyle(fontSize: 14),
        //         ),
        //       ],
        //     ),
        //
        //   ],
        // ),
      ),

      body: SafeArea(
        child: Container(
          child: Column(
            children: [

              // This is where the chats will go
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10
                  ),
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance.collection("chatrooms").doc(widget.chatroom.chatroomid).collection("messages").orderBy("createdon", descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if(snapshot.connectionState == ConnectionState.active) {
                        if(snapshot.hasData) {
                          QuerySnapshot dataSnapshot = snapshot.data as QuerySnapshot;

                          return ListView.builder(
                            reverse: true,
                            itemCount: dataSnapshot.docs.length,
                            itemBuilder: (context, index) {
                              MessageModel currentMessage = MessageModel.fromMap(dataSnapshot.docs[index].data() as Map<String, dynamic>);

                              return
                                Row(
                                mainAxisAlignment: (currentMessage.sender == widget.userModel.uid) ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (currentMessage.sender == widget.userModel.uid) ? Colors.grey : Theme.of(context).colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child:
                                    Text(
                                      currentMessage.text.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  )

                                ],
                              );

                            },
                          );
                        }
                        else if(snapshot.hasError) {
                          return Center(
                            child: Text("An error occured! Please check your internet connection."),
                          );
                        }
                        else {
                          return Center(
                            child: Text("Say hi to your new friend"),
                          );
                        }
                      }
                      else {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),

              ),

              /// for Sending mesaage : text and send box

              Container(
                height: size.height / 10,
                width: size.width,
                alignment: Alignment.center,
                child: Container(
                  height: size.height / 12,
                  width: size.width / 1.1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: size.height / 17,
                        width: size.width / 1.3,
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                onPressed:
                                    () => getImage(),
                                icon: Icon(Icons.photo),
                              ),
                              hintText: "Send Message",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              )),
                        ),
                      ),
                      IconButton(
                          icon: Icon(Icons.send), onPressed: sendMessage),
                    ],
                  ),
                ),
              ),

              // Container(
              //   color: Colors.grey[200],
              //   padding: EdgeInsets.symmetric(
              //     horizontal: 15,
              //     vertical: 5
              //   ),
              //   child: Row(
              //     children: [
              //
              //       Flexible(
              //         child: TextField(
              //           controller: messageController,
              //           maxLines: null,
              //           decoration: InputDecoration(
              //             border: InputBorder.none,
              //             hintText: "Enter message"
              //           ),
              //         ),
              //       ),
              //
              //       IconButton(
              //         onPressed: () {
              //           sendMessage();
              //         },
              //         icon: Icon(Icons.send, color: Theme.of(context).colorScheme.secondary,),
              //       ),
              //
              //     ],
              //   ),
              // ),

            ],
          ),
        ),
      ),
    );
  }
  /// For displaying message and image in chat
  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
    return map['type'] == "text"
        ? Container(
      width: size.width,
      alignment: map['sendby'] == _auth.currentUser!.displayName
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.blue,
        ),
        child: Text(
          map['message'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    )
        : Container(
      height: size.height / 2.5,
      width: size.width,
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      alignment: map['sendby'] == _auth.currentUser!.displayName
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShowImage(
              imageUrl: map['message'],
            ),
          ),
        ),
        child: Container(
          height: size.height / 2.5,
          width: size.width / 2,
          decoration: BoxDecoration(border: Border.all()),
          alignment: map['message'] != "" ? null : Alignment.center,
          child: map['message'] != ""
              ? Image.network(
            map['message'],
            fit: BoxFit.cover,
          )
              : CircularProgressIndicator(),
        ),
      ),
    );
  }
}
class ShowImage extends StatelessWidget {
  final String imageUrl;

  const ShowImage({required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.black,
        child: Image.network(imageUrl),
      ),
    );
  }
}