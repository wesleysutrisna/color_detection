//////////////////////////////
//
//camera page resource
//https://www.youtube.com/watch?v=YmQDQZSh1JA&ab_channel=EricoDarmawanHandoyo
//
//////////////////////////////
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController controller;

  Future<void> initializeCamera() async {
    var cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    await controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<String?> takePicture() async {
    Directory root = await getTemporaryDirectory();
    String directoryPath = '${root.path}/flutter_application_1';
    await Directory(directoryPath).create(recursive: true);
    String filePath = '$directoryPath/${DateTime.now()}.jpg';

    try {
      XFile picture = await controller.takePicture();
      picture.saveTo(filePath);
    } catch (e) {
      return null;
    }

    return filePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder(
            future: initializeCamera(),
            builder: (_, snapshot) => (snapshot.connectionState ==
                    ConnectionState.done)
                ? Stack(
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width *
                                controller.value.aspectRatio,
                            child: CameraPreview(controller),
                          ),
                          Container(
                            width: 70,
                            height: 70,
                            margin: const EdgeInsets.only(
                              top: 50,
                            ),
                            child: FloatingActionButton(onPressed: () async {
                              if (!controller.value.isTakingPicture) {
                                String? result = await takePicture();
                                Navigator.pop(context, result);
                              }
                            }),
                          ),
                        ],
                      ),
                    ],
                  )
                : const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(),
                    ),
                  )));
  }
}
