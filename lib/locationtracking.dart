import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mapsgoogle/googlemapapi.dart';

class LocationTracking extends StatefulWidget {
  const LocationTracking({Key? key}) : super(key: key);

  @override
  _LocationTrackingState createState() => _LocationTrackingState();
}

class _LocationTrackingState extends State<LocationTracking> {

  LatLng sourceLocation = const LatLng(28.432864, 77.002563);
  LatLng destinationLatlng = const LatLng(28.431626, 77.002475);

  bool isLoading = false;
  final Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> _marker = <Marker>{};

  final Set<Polyline> _polyline = <Polyline>{};
  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;

  late StreamSubscription<LocationData> subscription;

  late LocationData currentLocation;
  late LocationData destinationLocation;
  late Location location;

  @override
  void initState() {
    super.initState();

    location = Location();
    polylinePoints = PolylinePoints();

    subscription = location.onLocationChanged.listen((clocation) {
      currentLocation = clocation;
    });

    setInitialLocation();
  }

  void setInitialLocation() async{
    currentLocation = await location.getLocation();

    destinationLocation = LocationData.fromMap({
      "latitude": destinationLatlng.latitude,
      "longitude": destinationLatlng.longitude,
    });
  }

  void showLocationPins() {

    var sourceposition = LatLng(
        currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0);

    var destinationPosition =
        LatLng(destinationLatlng.latitude, destinationLatlng.longitude);

    _marker.add(Marker(
      markerId: const MarkerId('sourcePosition'),
      position: sourceposition,
    ));

    _marker.add(
      Marker(
        markerId: const MarkerId('destinationPosition'),
        position: destinationPosition,
      ),
    );

    setPolylinesInMap();
  }

  void setPolylinesInMap() async {

    var result = await polylinePoints.getRouteBetweenCoordinates(
        GoogleMapApi().url,
        PointLatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
        PointLatLng(destinationLatlng.latitude, destinationLatlng.longitude),
    );

    if(result.points.isNotEmpty) {

      for (var pointLatLng in result.points) {
        polylineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    setState(() {
      _polyline.add(Polyline(
        width: 5,
        polylineId: const PolylineId('polyline'),
        color: Colors.blueAccent,
        points: polylineCoordinates,
      ));
    });
  }

  void updatePinsOnMap() async {

    CameraPosition cameraPosition = CameraPosition(
      zoom: 20,
      tilt: 80,
      bearing: 30,
      target: LatLng(
          currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
    );

    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    var sourcePosition = LatLng(
        currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0);

    setState(() {
      _marker.removeWhere((marker) => marker.mapsId.value == 'sourcePosition');

      _marker.add(Marker(
        markerId: const MarkerId('sourcePosition'),
        position: sourcePosition,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {

    CameraPosition initialCameraPosition = CameraPosition(
      zoom: 20,
      tilt: 80,
      bearing: 30,
      target: LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0),
    );

    return SafeArea(
      child: Scaffold(
        body: GoogleMap(
          markers: _marker,
          polylines: _polyline,
          mapType: MapType.normal,
          initialCameraPosition: initialCameraPosition,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);

            showLocationPins();

          },
        ),
      ),
    );
  }
}
