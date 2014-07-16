import 'dart:convert';

class User {

  var id;
  var email;
  var firstName;
  var lastName;
  var data;


  User(this.id, this.email, this.firstName, this.lastName, this.data);

  Map<String, dynamic> toJson() => <String, dynamic>{
      "id": id, "email": email, "first_name": firstName, "last_name": lastName, "data": data
  };

  User.fromJson(Map<String, dynamic> json) : this(json['id'], json['email'], json['first_name'], json['last_name'], json['data']);

  toString() {
    return JSON.encode({
        "id": id, "email": email, "first_name": firstName, "last_name": lastName, "data": data
    });
  }
}
