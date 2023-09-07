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
  String? imagePath = null;
  int selectedCamera = 1;
  String serverUrl = '10.124.71.7:1234';
  String uploadResult = "";

  @override
  void initState() {
    super.initState();
    controller =
        CameraController(cameras![selectedCamera], ResolutionPreset.max);

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
      appBar: AppBar(
        title: const Text('Flutter demo'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 50,
                width: 300,
                child: TextField(
                  controller: TextEditingController()..text = serverUrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Server URL",
                    hintText: "Enter Server URL",
                  ),
                  onChanged: (text) {
                    serverUrl = text;
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Column(
                    children: [
                      SizedBox(
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
                              selectedCamera = selectedCamera == 0 ? 1 : 0;
                              controller = CameraController(
                                  cameras![selectedCamera],
                                  ResolutionPreset.max);
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
                      TextButton(
                          onPressed: () async {
                            try {
                              // print("click.......");
                              final image = await controller?.takePicture();
                              setState(() {
                                imagePath = image?.path != null ? image?.path : '';
                                uploadResult = '';
                              });
                            } catch (e) {
                              print(e);
                            }
                          },
                          child: const Text("Take Photo")),
                    ],
                  ),
                  Column(
                    children: [
                      if (imagePath != "")
                        SizedBox(
                            width: 200,
                            height: 160,
                            child: Image.file(
                              File(imagePath!),
                            )),
                      if (imagePath != "")
                        TextButton(
                            onPressed: () async {
                              _uploadImage();
                            },
                            child: const Text("Upload Photo")),
                      Text(uploadResult),
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

    final url = Uri.parse('http://$serverUrl/upload');
    print(url);
    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', imagePath!));

    try {
      final response = await request.send();
      print(response.statusCode);

      if (response.statusCode == 200) {
        // Image uploaded successfully
        setState(() {
          uploadResult = 'Upload success';
        });
      } else {
        setState(() {
          uploadResult = 'Upload failed';
        });
      }
    } catch (e) {
      setState(() {
        uploadResult = 'Upload failed';
      });
    }
  }
}
