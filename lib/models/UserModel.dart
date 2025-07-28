import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? uid;
  String? fullname;
  String? email;
  String? profilepic;
  String? status;

  UserModel({this.uid, this.fullname, this.email, this.profilepic,this.status});

  UserModel.fromMap(Map<String, dynamic> map) {
    uid = map["uid"];
    fullname = map["fullname"];
    email = map["email"];
    profilepic = map["profilepic"];
    status =map["statuss"];
  }

  Map<String, dynamic> toMap() {
    return {

      "uid":  _auth.currentUser?.uid,
      "fullname": fullname,
      "email": email,
      "profilepic": profilepic,
      "status": _auth.currentUser!.uid,
    };
  }

}