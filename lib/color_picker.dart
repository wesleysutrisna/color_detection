//////////////////////////////
//
// 2019, roipeker.com
// screencast - demo simple image:
// https://youtu.be/EJyRH4_pY8I
//
// screencast - demo snapshot:
// https://youtu.be/-LxPcL7T61E
//
// color detection resource
// https://gist.github.com/roipeker/9315aa25301f5c0362caaebd15876c2f
//
//////////////////////////////
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colornames/colornames.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'camera_page.dart';

class ColorPickerWidget extends StatefulWidget {
  @override
  _ColorPickerWidgetState createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  String? imagePath;
  GlobalKey imageKey = GlobalKey();
  GlobalKey paintKey = GlobalKey();

  bool useSnapshot = false;

  late GlobalKey currentKey;

  final StreamController<Color> _stateController = StreamController<Color>();
  late img.Image photo;

  List<Color> colorOption = [
    Colors.green,
    Colors.red,
    Colors.blue,
    Colors.yellow
  ];

  @override
  void initState() {
    currentKey = useSnapshot ? paintKey : imageKey;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Color Blind Application")),
        body: Column(
          children: [
            StreamBuilder(
                initialData: Colors.white,
                stream: _stateController.stream,
                builder: (buildContext, snapshot) {
                  Color selectedColor = snapshot.data ?? Colors.white;
                  return Stack(children: <Widget>[
                    RepaintBoundary(
                        key: paintKey,
                        child: GestureDetector(
                            onPanDown: (details) {
                              searchPixel(details.globalPosition);
                            },
                            onPanUpdate: (details) {
                              searchPixel(details.globalPosition);
                            },
                            child: Center(
                              child: Container(
                                  margin: const EdgeInsets.only(
                                      top: 140, bottom: 10),
                                  width: 300,
                                  height: 450,
                                  color: Colors.grey[200],
                                  child: (imagePath != null)
                                      ? Image.file(File(imagePath!),
                                          key: imageKey)
                                      : const SizedBox()),
                            ))),
                    Container(
                      width: 65,
                      height: 75,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedColor,
                          border: Border.all(width: 2.0, color: Colors.white),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2))
                          ]),
                    ),
                    Positioned(
                        left: 80,
                        top: 48,
                        child: Text(selectedColor.colorName,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                backgroundColor: Colors.black54))),
                    Container(
                      margin: const EdgeInsets.fromLTRB(28, 10, 0, 0),
                      child: Row(
                        children: [
                          for (Color color in colorOption)
                            Container(
                              margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(
                                      width: 2.0, color: Colors.white),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2))
                                  ]),
                            )
                        ],
                      ),
                    )
                  ]);
                }),
            ElevatedButton(
                onPressed: () async {
                  imagePath = await Navigator.push<String>(context,
                      MaterialPageRoute(builder: (_) => const CameraPage()));
                  await loadImageBundleBytes();
                  setState(() {});
                },
                child: const Text("Take Picture"))
          ],
        ));
  }

  void searchPixel(Offset globalPosition) async {
    if (photo == null) {
      await (loadImageBundleBytes());
    }
    _calculatePixel(globalPosition);
  }

  void _calculatePixel(Offset globalPosition) {
    RenderBox box = currentKey.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(globalPosition);

    double px;
    double py;
    try {
      px = localPosition.dx;
      py = localPosition.dy;
    } catch (e) {
      px = 0;
      py = 0;
    }

    if (!useSnapshot) {
      double? widgetScale = box.size.width / photo.width;
      px = (px / widgetScale);
      py = (py / widgetScale);
    }

    img.Pixel pixel32 = photo.getPixel(px.toInt(), py.toInt());
    print(pixel32);
    Color hex = abgrToArgb(pixel32);

    _stateController.add(hex);
  }

  Future<void> loadImageBundleBytes() async {
    File file = File(imagePath!);
    Uint8List bytes = file.readAsBytesSync();
    ByteData imageBytes = ByteData.view(bytes.buffer);
    setImageBytes(imageBytes);
  }

  void setImageBytes(ByteData imageBytes) {
    var values = imageBytes.buffer.asUint8List();
    img.Image? original = img.decodeImage(values)!;
    photo = img.copyResize(original, width: 300, height: 450);
    print(photo);
  }
}

Color abgrToArgb(img.Pixel pixel32) {
  var pixelList = (pixel32.toList());
  int r = pixelList[0] as int;
  int g = pixelList[1] as int;
  int b = pixelList[2] as int;
  return ui.Color.fromARGB(255, r, g, b);
}
