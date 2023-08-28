import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  CameraController? controller;
  String imagePath = "";
  int selectedCamera = 0;

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras![selectedCamera], ResolutionPreset.max);

    controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: 50,
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(hintText: "Server URL"),
                  onChanged: (text) {},
                ),
              ),
              TextButton(
                  onPressed: () async {
                    try {
                      selectedCamera = selectedCamera == 0 ? 1 : 0;
                      controller = CameraController(cameras![selectedCamera], ResolutionPreset.max);
                      controller?.initialize().then((_) {
                        if (!mounted) {
                          return;
                        }
                        setState(() {});
                      });
                    } catch (e) {
                      print(e);
                    }
                  },
                  child: const Text("Change Camera")),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 90,
                        height: 160,
                        child: AspectRatio(
                          aspectRatio: controller!.value.aspectRatio,
                          child: CameraPreview(controller!),
                        ),
                      ),
                      TextButton(
                          onPressed: () async {
                            try {
                              // print("click.......");
                              final image = await controller!.takePicture();
                              setState(() {
                                imagePath = image.path;
                              });
                              print(imagePath);
                            } catch (e) {
                              print(e);
                            }
                          },
                          child: Text("Take Photo")),
                    ],
                  ),
                  Column(
                    children: [
                      if (imagePath != "")
                        Container(
                            width: 200,
                            height: 160,
                            child: Image.file(
                              File(imagePath),
                            )),
                      if (imagePath != "")
                        TextButton(
                            onPressed: () async {
                              _uploadImage();
                            },
                            child: Text("Upload Photo"))
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadImage() async {
    if (imagePath == null) {
      return;
    }

    final url = Uri.parse(
        'http://192.168.0.230:1234/upload'); // Replace with your server URL
    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    final response = await request.send();

    print(response.statusCode);

    if (response.statusCode == 200) {
      // Image uploaded successfully
      print('Image uploaded!');
    } else {
      print('Image upload failed');
    }
  }
}
