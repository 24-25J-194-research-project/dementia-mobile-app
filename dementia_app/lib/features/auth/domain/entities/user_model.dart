class UserModel {
  String uid;
  String email;
  String firstName;
  String lastName;
  String dateOfBirth;
  String gender;

  UserModel(
      {required this.uid,
      required this.email,
      required this.firstName,
      required this.lastName,
      required this.dateOfBirth,
      required this.gender});

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      dateOfBirth: map['dateOfBirth'],
      gender: map['gender'],
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, dateOfBirth: $dateOfBirth, gender: $gender)';
  }
}
