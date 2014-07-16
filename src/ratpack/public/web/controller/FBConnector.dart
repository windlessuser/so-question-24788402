import 'package:angular/angular.dart';
import '../model/user/User.dart';
import 'dart:js';
import 'dart:html';

@Controller(selector: '[fb-control]', publishAs: 'stfb')
class FBConnector {

  final Http _http;
  final Router _router;

  var accessToken;
  var userId;
  User user;

  final String BASE = "https://graph.facebook.com";


  FBConnector(this._http, this._router) {
    querySelector("title").text = "Login";
    handleLogin();
  }


  handleLogin() {
    context["statusChangeCallback"] = (response) {
      var status = response['status'];
      if (status == "connected") {
        accessToken = response['authResponse']["accessToken"];
        userId = response['authResponse']["userID"];
        getUser();
      }
    };
  }

  getUser() {
    _http.get("$BASE/$userId?access_token=$accessToken").then((HttpResponse resp) {
      user = new User.fromJson(resp.data);
      user.data = {
          "userId" : userId, "accessToken":accessToken
      };
      this._router.go("commute", {
          "user":user
      });
    }).catchError((e) {
      print(e);
    });
  }


}
