import 'dart:io';
import 'package:flutter/widgets.dart';

bool fileExists(String? path) => path != null && File(path).existsSync();

ImageProvider? imageProviderForPath(String path) => FileImage(File(path));
