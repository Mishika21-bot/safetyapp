import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'contacts_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  LatLng? currentLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _getUserLocation() async {
    setState(() {
      currentLocation = const LatLng(37.422, -122.084);
    });
  }

  void _addPin(LatLng position, String type) async {
    await firestore.collection('pins').add({
      'lat': position.latitude,
      'lng': position.longitude,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'isSOS': false,
    });
  }

  void _triggerSOS() async {
    const url = 'tel:112';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }

    await firestore.collection('pins').add({
      'lat': currentLocation!.latitude,
      'lng': currentLocation!.longitude,
      'type': 'red',
      'timestamp': FieldValue.serverTimestamp(),
      'isSOS': true,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Emergency services notified!")));
    }
  }

  Set<Marker> _createMarkers() {
    final markers = <Marker>{};

    if (currentLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('current'),
        position: currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentLocation!,
          zoom: 14,
        ),
        markers: _createMarkers(),
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
        },
        onLongPress: (latLng) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Add Pin"),
              actions: [
                TextButton(
                  child: const Text("🟢 Safe"),
                  onPressed: () {
                    _addPin(latLng, "green");
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: const Text("🔴 Danger"),
                  onPressed: () {
                    _addPin(latLng, "red");
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _triggerSOS,
            child: const Icon(Icons.warning, color: Colors.white),
            backgroundColor: Colors.red,
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactsScreen()),
            ),
            child: const Icon(Icons.contacts),
          ),
        ],
      ),
    );
  }
}