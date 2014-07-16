import 'dart:html';
import 'dart:convert';
import 'dart:async';
import 'package:google_maps/google_maps.dart';
import 'package:google_maps/google_maps_places.dart';

const destinationIcon = 'https://chart.googleapis.com/chart?chst=d_map_pin_letter&chld=D|FF0000|000000';
const originIcon = 'https://chart.googleapis.com/chart?chst=d_map_pin_letter&chld=O|FFFF00|000000';

class CommuteMap {
  static final mapOptions = new MapOptions()
    ..zoom = 12
    ..mapTypeId = MapTypeId.ROADMAP;

  var rateBtns = querySelectorAll(".getRate") as List<ButtonElement>;

  final GMap map = new GMap(querySelector("#map-canvas"), mapOptions);
  Geocoder geocoder;
  final markersArray = new List<Marker>();
  var isDest = false;
  DirectionsRenderer directionsDisplay;
  final DirectionsService directionsService = new DirectionsService();
  var pickUp = querySelector('#pickUp').shadowRoot.querySelector("input");
  var dropOff = querySelector('#dropOff::shadow #input');

  LatLng pickUpPos;
  LatLng dropOffPos;


  CommuteMap() {
    init();
  }

  void init() {

    for (ButtonElement submitBtn in rateBtns) {
      submitBtn.onClick.listen(getRates);
    }
    //querySelector('#getTaxi').onClick.listen(sendRequest);

    print(pickUp);

    geocoder = new Geocoder();
    directionsDisplay = new DirectionsRenderer();
    directionsDisplay.map = map;


    // Try HTML5 geolocation
    if (window.navigator.geolocation != null) {
      window.navigator.geolocation.getCurrentPosition().then((position) {
        final pos = new LatLng(position.coords.latitude, position.coords.longitude);

        this.map.center = pos;
        placeMarker(pos);
      }, onError : (error) {
        handleNoGeolocation(true);
      });
    } else {
      // Browser doesn't support Geolocation
      handleNoGeolocation(false);
    }

    final autoPickUp = new Autocomplete(pickUp);
    final autoDropOff = new Autocomplete(dropOff);

    autoPickUp.bindTo('bounds', map);
    autoDropOff.bindTo('bounds', map);

    autoPickUp.onPlaceChanged.listen((_) {
      final place = autoPickUp.place;
      String address = '';
      if (place.addressComponents != null) {
        address = [(place.addressComponents[0] != null && place.addressComponents[0].shortName != null ? place.addressComponents[0].shortName : ''), (place.addressComponents[1] != null && place.addressComponents[1].shortName != null ? place.addressComponents[1].shortName : ''), (place.addressComponents[2] != null && place.addressComponents[2].shortName != null ? place.addressComponents[2].shortName : '')].join(' ');
      }
      setPickUp(address);
    });

    autoDropOff.onPlaceChanged.listen((_) {
      final place = autoDropOff.place;
      String address = '';
      if (place.addressComponents != null) {
        address = [(place.addressComponents[0] != null && place.addressComponents[0].shortName != null ? place.addressComponents[0].shortName : ''), (place.addressComponents[1] != null && place.addressComponents[1].shortName != null ? place.addressComponents[1].shortName : ''), (place.addressComponents[2] != null && place.addressComponents[2].shortName != null ? place.addressComponents[2].shortName : '')].join(' ');
      }
      setDropOff(address);
    });

    pickUp.onChange.listen((e) => calcRoute());
    dropOff.onChange.listen((e) => calcRoute());

    map.onClick.listen((e) {
      placeMarker(e.latLng);
    });
  }

  void getRates(Event e) {
    calcDistance();
  }

  void calcDistance() {
    final service = new DistanceMatrixService();
    service.getDistanceMatrix((new DistanceMatrixRequest()
      ..origins = [pickUpPos]
      ..destinations = [dropOffPos]
      ..travelMode = TravelMode.DRIVING
      ..unitSystem = UnitSystem.METRIC
      ..avoidHighways = false
      ..avoidTolls = false), distCallback);
  }

  void distCallback(DistanceMatrixResponse response, DistanceMatrixStatus status) {
    if (status != DistanceMatrixStatus.OK) {
      window.alert(' Can\'t determine fare. Error was: ${status}');
    } else {
      final origin = response.originAddresses;
      final destination = response.destinationAddresses;
      deleteOverlays();
      var result = response.rows[0];
      var distance = result.elements[0].distance.value / 1000;

      fare = (234.38 + (46.88 * distance));
      final html = new StringBuffer();
      html.write('<p>From <b>${origin[0]}</b> to <b>${destination[0]}</b> is <b>${result.elements[0].distance.text}</b>.</p>' + 'Your fare is therefore <b>\$${fare.toStringAsFixed(2)}</b>');
      querySelector('#rateBody').innerHtml = html.toString();
    }
  }

  void calcRoute() {
    final start = pickUp.value;
    final end = dropOff.value;
    final request = new DirectionsRequest()
      ..origin = start
      ..destination = end
      ..travelMode = TravelMode.DRIVING // TODO bad object in example DirectionsTravelMode
    ;
    directionsService.route(request, (DirectionsResult response, DirectionsStatus status) {
      if (status == DirectionsStatus.OK) {
        directionsDisplay.directions = response;
      }
    });
  }

  void placeMarker(LatLng position) {
    final request = new GeocoderRequest()
      ..location = position;
    geocoder.geocode(request, (List<GeocoderResult> results, GeocoderStatus status) {
      if (status == GeocoderStatus.OK) {
        if (results[0] != null) {
          if (!isDest) {
            dropOff.value = results[0].formattedAddress;
            setDropOff(results[0].formattedAddress);

          } else {
            pickUp.value = results[0].formattedAddress;
            setPickUp(results[0].formattedAddress);
          }
        } else {
          window.alert('No results found');
        }
      } else {
        window.alert('Geocoder failed due to: ${status}');
        reset();
      }
    });
    isDest = !isDest;
  }


  void handleNoGeolocation(bool errorFlag) {
    String content;
    if (errorFlag) {
      content = 'Error: The Geolocation service failed.';
    } else {
      content = 'Error: Your browser doesn\'t support geolocation.';
    }

    print(content);
    map.center = new LatLng(18, 77);
  }


  void setPickUp(String address) {
    addMarker(address, false);
  }

  void setDropOff(String address) {
    addMarker(address, true);
  }

  void addMarker(String location, bool isDestination) {

    if (markersArray.length >= 2) {
      deleteOverlays();
    }

    if (markersArray.length > 0) {
      enableBtn();
    }

    String icon;
    if (isDestination) {
      icon = destinationIcon;
    } else {
      icon = originIcon;
    }
    final request = new GeocoderRequest()
      ..address = location;
    geocoder.geocode(request, (List<GeocoderResult> results, GeocoderStatus status) {
      if (status == GeocoderStatus.OK) {
        if (isDestination) {
          dropOffPos = results[0].geometry.location;
        } else {
          pickUpPos = results[0].geometry.location;
        }
        final marker = new Marker(new MarkerOptions()
          ..map = this.map
          ..animation = Animation.DROP
          ..position = results[0].geometry.location
          ..icon = icon);
        map.panTo(results[0].geometry.location);
        markersArray.add(marker);
      } else {
        window.alert('Geocode was not successful for the following reason: ${status}');
        reset();
      }
    });
  }

  void deleteOverlays() {
    markersArray.forEach((marker) => marker.map = null);
    markersArray.clear();
  }

  void reset() {
    pickUp.value = '';
    dropOff.value = '';
    deleteOverlays();
    disableBtn();
  }

  void enableBtn() {
    for (ButtonElement rateBtn in rateBtns) {
      rateBtn.classes.remove("disabled");
    }
  }

  void disableBtn() {
    for (ButtonElement rateBtn in rateBtns) {
      rateBtn.classes.add("disabled");
    }
  }

  void sendRequest(Event e) {
    Map requestMap = new Map();
    requestMap['commuterId'] = config["commuterId"];
    requestMap['pickUp'] = {
        "geoLoc" : {
            "lat" : pickUpPos.lat, "lon" : pickUpPos.lng
        }, "address" : pickUp.value
    };
    requestMap['dropOff'] = {
        "geoLoc" : {
            "lat" : dropOffPos.lat, "lon" : dropOffPos.lng
        }, "adress" : dropOff.value
    };
    requestMap['partySize'] = 1;

    HttpRequest request = new HttpRequest(); // create a new XHR

    // add an event handler that is called when the request finishes
    request.onReadyStateChange.listen((_) {
      if (request.readyState == HttpRequest.DONE && (request.status == 200 || request.status == 0 || request.status == 202)) {
        // data saved OK.
        print(request.responseText); // output the response from the server
        DivElement progressDiv = querySelector("#progress") as DivElement;
        const scaleRate = 100;
        const finished = 30;
        DateTime startTime = new DateTime.now();
        Timer timer;
        const interval = 1000;
        const progressRate = const Duration(milliseconds:interval);
        var progress = 0;
        progressDiv.style.width = "${progress}%";
        timer = new Timer.periodic(progressRate, (Timer timer) {
          if (progress >= 100) {
            timer.cancel();
            window.location.assign(config['baseUrl'] + '/commute/taxi');
          } else {
            progress += ((progressRate.inSeconds / finished) * 100).round();
            progressDiv.style.width = "${progress}%";
          }
        });
      }
    });

    // POST the data to the server
    var url = "http://private-3133-smarttaxi.apiary-mock.com/api/commute";
    request.open("PUT", url, async: true);
    request.setRequestHeader("Content-Type", "application/json");
    request.send(JSON.encode(requestMap));

  }
}
