import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastMsg {
  static void showToastMsg(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: AppColors.green,
      textColor: Colors.white,
      fontSize: 16.0,
      webPosition: "center",
      webBgColor: "linear-gradient(to right, #009B37, #009B37)",
      webShowClose: true,
    );
  }
}
