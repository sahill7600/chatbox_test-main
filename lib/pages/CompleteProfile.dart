import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../models/UIHelper.dart';
import '../models/UserModel.dart';
import 'HomePage.dart';
import 'package:uuid/uuid.dart';


class CompleteProfile extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const CompleteProfile({Key? key, required this.userModel, required this.firebaseUser}) : super(key: key);

  @override
  _CompleteProfileState createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<CompleteProfile> {

  String? chatRoomId;
  File? imageFile;
  TextEditingController fullNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void selectImage(ImageSource source) async {
    XFile? pickedFile = await ImagePicker().pickImage(source: source);

    if(pickedFile != null) {
      cropImage(pickedFile);
    }
  }

  // void cropImage(XFile file) async {
  //   File? croppedImage = await ImageCropper.cropImage(
  //     sourcePath: file.path,
  //     aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
  //     compressQuality: 20
  //   );
  //
  //   if(croppedImage != null) {
  //     setState(() {
  //       imageFile = croppedImage;
  //     });
  //   }
  // }

  Future cropImage(XFile file) async {
    CroppedFile? cropped = await ImageCropper().cropImage(
        //sourcePath: imageFile!.path,
            sourcePath: file.path,
            aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
            compressQuality: 20
    );
  if (cropped != null) {
  setState(() {
  imageFile = File(cropped.path);
 // imageFile = cropped as File?;
  });
  }
  }


  void showPhotoOptions() {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text("Upload Profile Picture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ListTile(
              onTap: () {
                Navigator.pop(context);
                selectImage(ImageSource.gallery);
              },
              leading: Icon(Icons.photo_album),
              title: Text("Select from Gallery"),
            ),

            ListTile(
              onTap: () {
                Navigator.pop(context);
                selectImage(ImageSource.camera);
              },
              leading: Icon(Icons.camera_alt),
              title: Text("Take a photo"),
            ),

          ],
        ),
      );
    });
  }

  void checkValues() {
    String fullname = fullNameController.text.trim();

    if(fullname == "" || imageFile == null) {
      print("Please fill all the fields");
      UIHelper.showAlertDialog(context, "Incomplete Data", "Please fill all the fields and upload a profile picture");
    }
    else {
      log("Uploading data..");
      uploadData();
      print("checking_test ");

    }
  }


  void uploadData() async {

    UIHelper.showLoadingDialog(context, "Uploading image..");
    print("checking1 ");
    UploadTask uploadTask = FirebaseStorage.instance.ref("profilepictures").child(widget.userModel.uid.toString()).putFile(imageFile!);
    print("checking33 ");
    print("checkingcheck$uploadTask");
    TaskSnapshot snapshot = await uploadTask;
    print("checking2 ");
    print("checkingcheck_snapshot$snapshot");

    String? imageUrl = await snapshot.ref.getDownloadURL();
    String? fullname = fullNameController.text.trim();
    print("checking3 ");
    widget.userModel.fullname = fullname;
    widget.userModel.profilepic = imageUrl;
    print("checking11 ");
    print("checkinggg$imageUrl ");
    print("checkinggggg$fullname ");
    await FirebaseFirestore.instance.collection("users").doc(widget.userModel.uid).set(widget.userModel.toMap()).then((value) {
      log("Data uploaded!");
      print("checkingcheck_snapshot>>$snapshot");
      print("checkingggurll$imageUrl ");
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) {
          return HomePage(userModel: widget.userModel, firebaseUser: widget.firebaseUser, targetUser: widget.userModel,);
        }),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("Complete Profile"),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 40
          ),
          child: ListView(
            children: [

              SizedBox(height: 20,),

              CupertinoButton(
                onPressed: () {
                  showPhotoOptions();
                },
                padding: EdgeInsets.all(0),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: (imageFile != null) ? FileImage(imageFile!) : null,
                  child: (imageFile == null) ? Icon(Icons.person, size: 60,) : null,
                ),
              ),

              SizedBox(height: 20,),

              TextField(
                controller: fullNameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                ),
              ),

              SizedBox(height: 20,),

              CupertinoButton(
                onPressed: () {
                  checkValues();
                },
                color: Theme.of(context).colorScheme.secondary,
                child: Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}