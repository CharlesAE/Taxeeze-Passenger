
import 'package:cloud_firestore/cloud_firestore.dart';

class User{
  String? uid;
  String? name;
  String? email;
  String? phone;


  User({
  this.uid,
    this.name,
    this.email,
    this.phone
  });


  User.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    uid = snapshot.id; //data['id'];
    name = data['name'];
    email = data['email'];
    phone = data['phone'];
  }

  static User fromFirestore(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
        name: snapshot["name"],
        uid: snapshot["uid"],
        email: snapshot["email"],
        phone: snapshot["phone"]);
  }

  Map<String, dynamic> toJson() =>
      {'uid': uid, 'name': name, 'email': email, 'phone': phone};
}