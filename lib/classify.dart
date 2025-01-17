import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'package:image/image.dart';
import 'package:tflite/tflite.dart';

final int imgSize = 28;

class MnistClassifier {

  // Model files
  static final String modelFilename = "assets/model/mnist.tflite";
  static final String modelLabels = "assets/model/labels.txt";

  // Model inputs
  static final int imgWidth = 28;
  static final int imgHeight = 28;
  static final int floatSize = 4;
  static final int pixelSize = 4;
  static final int modelInputSize = floatSize * imgWidth * imgHeight * pixelSize;

  // Model outputs
  static final int numClassificationResults = 3;
}

class MnistClassifierResult {
  String fileName;
  String label;
  int index;
  double confidence;
}

Uint8List imageToByteListFloat32(Image image, int width, int height) {
  var convertedBytes = Float32List(width * height);
  var buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (var i = 0; i < width; i++) {
    for (var j = 0; j < height; j++) {
      var pixel = image.getPixel(j, i);
      buffer[pixelIndex++] =
          (getRed(pixel) + getGreen(pixel) + getBlue(pixel)) / 3 / 255.0;
    }
  }
  return convertedBytes.buffer.asUint8List();
}

Future<MnistClassifierResult> classifyImage(String imgFile) async {

  await Tflite.loadModel(
    model: MnistClassifier.modelFilename,
    labels: MnistClassifier.modelLabels,
  );

  var file = File(imgFile);
  var loadedImage = file.readAsBytesSync().buffer.asByteData();
  // var loadedImage = await rootBundle.load(imgFile);
  var imageBytes = loadedImage.buffer;
  Image oriImage = decodeJpg(imageBytes.asUint8List());
  Image resizedImage = copyResize(oriImage, MnistClassifier.imgWidth, MnistClassifier.imgHeight);

  List recognitions = await Tflite.runModelOnBinary(
    binary: imageToByteListFloat32(resizedImage, MnistClassifier.imgWidth, MnistClassifier.imgHeight),
  );

  Tflite.close();

  print(recognitions.toString());

  var res = MnistClassifierResult();
  res.fileName = imgFile;
  res.label = recognitions[0]['label'];
  res.index = recognitions[0]['index'];
  res.confidence = recognitions[0]['confidence'];

  return res;
}
