import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  HomeView({Key? key}) : super(key: key);

  final controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('BarCode scanner app'),
          centerTitle: true,
        ),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /*QRImageContainer*/
              Container(
                  height: 220,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: Obx(
                      () => controller.selectedImagePath.value == ''
                          ? const Padding(
                              padding: EdgeInsets.only(top: 20.0),
                              child: Center(
                                  child: Text("Select an image from Gallery ")),
                            )
                          : Image.file(
                              File(controller.selectedImagePath.value),
                              width: Get.width,
                              height: 300,
                            ),
                    ),
                  )),
              /*Pick QRImage from gallery*/
              Center(
                child: ElevatedButton(
                    onPressed: () {
                      controller.getImage(ImageSource.gallery);
                    },
                    child: const Text("Pick Image")),
              ),
              /* Response of QRCode*/
              SingleChildScrollView(
                child: Container(
                  height: 190,
                  margin: const EdgeInsets.all(12),
                  child: Obx(() => controller.extractedBarcode.value.isEmpty
                      ? Container()
                      : GestureDetector(
                          onTap: () async {
                            if(controller.extractedBarcode.value.isNotEmpty && controller.extractedBarcode.value!=''){
                              await Clipboard.setData(ClipboardData(text: controller.extractedBarcode.value));
                              Fluttertoast.showToast(
                                  msg: "Text Copied...",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 2,
                                  backgroundColor: Colors.blue,
                                  textColor: Colors.white,
                                  fontSize: 14.0
                              );
                            }
                          },
                          child: Center(
                              child: Text(controller.extractedBarcode.value)),
                        )),
                ),
              )
            ],
          ),
        )),
      ),
    );
  }
}

class HomeController extends GetxController {
  var selectedImagePath = ''.obs;
  var extractedBarcode = ''.obs;

  /* get image method*/
  getImage(ImageSource imageSource) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    extractedBarcode.value = '';
    selectedImagePath.value = '';
    if (pickedFile != null) {
      selectedImagePath.value = pickedFile.path;
      recognizedText(selectedImagePath.value);
    }
  }

  /*recognise image text method*/
  Future<void> recognizedText(String pickedImage) async {
    extractedBarcode.value = '';
    var barCodeScanner = GoogleMlKit.vision.barcodeScanner();
    final visionImage = InputImage.fromFilePath(pickedImage);
    try {
      var barcodeText = await barCodeScanner.processImage(visionImage);
      for (Barcode barcode in barcodeText) {
        extractedBarcode.value = barcode.displayValue!;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red);
    }
  }
}
