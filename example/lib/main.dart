import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' hide TileLayer;

// ignore: uri_does_not_exist
import 'local_keys.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'vector_map_tiles Example',
      theme: ThemeData.light(),
      home: const MyHomePage(title: 'vector_map_tiles Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MapController _controller = MapController();
  Style? _style;
  Object? _error;

  var progress = ValueNotifier<double>(0.0);
  var zoomLevel = ValueNotifier<double>(15.0);

  @override
  void initState() {
    super.initState();
    _initStyle();
  }

  void _initStyle() async {
    try {
      _style = await _readStyle();
    } catch (e, stack) {
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print(stack);
      _error = e;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (_error != null) {
      children.add(Expanded(child: Text(_error!.toString())));
    } else if (_style == null) {
      children.add(const Center(child: CircularProgressIndicator()));
    } else {
      children.add(Flexible(child: _map(_style!)));
      children.add(SizedBox(height: 20, child: Flexible(child: slider())));
      children.add(const SizedBox(height: 20));
      children
          .add(SizedBox(height: 40, child: Flexible(child: zoomLevelSlider())));
      children.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_statusText()]));
    }
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SafeArea(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children)));
  }

// alternates:
//   Mapbox - mapbox://styles/mapbox/streets-v12?access_token={key}
//   Maptiler - https://api.maptiler.com/maps/outdoor/style.json?key={key}
//   Stadia Maps - https://tiles.stadiamaps.com/styles/outdoors.json?api_key={key}
  Future<Style> _readStyle() => StyleReader(
          uri: mapUri,
          // ignore: undefined_identifier
          // apiKey: stadiaMapsApiKey,
          logger: const Logger.console())
      .read();

  Widget slider() => ValueListenableBuilder<double>(
        builder: (BuildContext context, double value, Widget? child) => Slider(
          value: progress.value,
          onChanged: (value) {
            progress.value = value;
            _controller.rotate(value);
          },
          min: 0,
          max: 360,
        ),
        valueListenable: progress,
      );

  Widget zoomLevelSlider() => ValueListenableBuilder<double>(
        builder: (BuildContext context, double value, Widget? child) => Slider(
          value: zoomLevel.value,
          onChanged: (value) {
            zoomLevel.value = value;
            _controller.move(_controller.center, value);
          },
          min: 15,
          max: 22,
          divisions: 14,
        ),
        valueListenable: zoomLevel,
      );

  Widget _map(Style style) => FlutterMap(
        mapController: _controller,
        options: MapOptions(
            center: LatLng(59.438803, 24.775786),
            zoom: zoomLevel.value,
            // zoom: 18.76, // problematic zoom level background color and text not stacked together
            maxZoom: 22,
            interactiveFlags: InteractiveFlag.drag |
                InteractiveFlag.flingAnimation |
                InteractiveFlag.pinchMove |
                InteractiveFlag.pinchZoom |
                InteractiveFlag.doubleTapZoom),
        children: [
          VectorTileLayer(
              tileProviders: style.providers,
              theme: style.theme,
              maximumZoom: 22,
              // tileOffset: TileOffset.mapbox,
              layerMode: VectorTileLayerMode.vector)
        ],
      );

  Widget _statusText() => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: StreamBuilder(
          stream: _controller.mapEventStream,
          builder: (context, snapshot) {
            return Text(
                'Zoom: ${_controller.zoom.toStringAsFixed(2)} Center: ${_controller.center.latitude.toStringAsFixed(4)},${_controller.center.longitude.toStringAsFixed(4)}, Rotation: ${progress.value}');
          }));
}
