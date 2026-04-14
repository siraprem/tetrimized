import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:convert';

void main() {
  print("Todas as importações funcionam!");
  print("Material: ${Material}");
  print("Services: ${SystemChrome}");
  print("InAppWebView: ${InAppWebView}");
  print("SharedPreferences: ${SharedPreferences}");
  print("PointerInterceptor: ${PointerInterceptor}");
  print("dart:convert: jsonDecode funciona");
}
