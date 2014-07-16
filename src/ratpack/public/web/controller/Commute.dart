import 'package:angular/angular.dart';
import '../model/user/User.dart';
import '../model/map/CommuteMap.dart';
import 'dart:js';
import 'dart:html';
import 'dart:convert';
import 'dart:js';
import 'package:paper_elements/paper_input.dart';

@Controller(selector: '[commute-control]', publishAs: 'commute')
class Commute implements ShadowRootAware {
  final Http _http;
  var user;
  var userId;
  var accessToken;
  var img;
  CommuteMap map;

  Commute(RouteProvider routeProvider, this._http) {
    this.user = JSON.decode(routeProvider.parameters["user"]);
    userId = user['data']['userId'];
    accessToken = user['data']['accessToken'];
    img = "https://graph.facebook.com/$userId/picture?type=large&access_token=$accessToken";
    querySelector("title").text = "Call a taxi!";
    print(querySelector("#pickUp"));
    //map = new CommuteMap();
  }

  onShadowRoot(ShadowRoot shadowRoot) {
    print(shadowRoot.querySelector("pickUp"));
  }
}
