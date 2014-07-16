import 'package:polymer/polymer.dart';
import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:angular/routing/module.dart';
import 'package:angular_node_bind/angular_node_bind.dart';
import "controller/FBConnector.dart";
import "controller/Commute.dart";

// HACK until we fix code gen size. This doesn't really fix it,
// just makes it better.
@MirrorsUsed(override: '*')
import 'dart:mirrors';

class BackendAppModule extends Module {
  BackendAppModule() {
    type(FBConnector);
    type(Commute);
    value(RouteInitializerFn, backendAppRouteInit);
  }
}

void backendAppRouteInit(Router router, ViewFactory view) {
  router.root
    ..addRoute(defaultRoute: true, name: 'login', path: '/login/', enter: view('view/login.html'))
    ..addRoute(name: 'commute', path: '/commute/:user', enter: view('view/commute.html'));
}


main() {
  initPolymer().run(() {
    Polymer.onReady.then((_) {
      applicationFactory()
        ..addModule(new BackendAppModule())
        ..addModule(new NodeBindModule())
        ..run();
    });
  });
}