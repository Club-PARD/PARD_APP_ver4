import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pard_app/controllers/auth_controller.dart';
import 'package:pard_app/controllers/spring_schedule_controller.dart';
import 'package:pard_app/models/qr_model/attendance_admin_request_dto.dart';
import 'package:pard_app/models/qr_model/request_qr_dto.dart';
import 'package:pard_app/models/qr_model/response_qr_dto.dart';
import 'package:pard_app/utilities/color_style.dart';

class QRController extends GetxController {
  Rx<Barcode?> result = Rx<Barcode?>(null);
  bool isScanned = false;
  RxString? obxToken;
  SpringScheduleController springScheduleController = Get.find();
  AuthController authController = Get.find();
  bool _isScanning = false;
  bool _dialogShown = false;

  // TODO: url 확인
  final List<String> validQrCodes = [
    "https://me-qr.com/uoN4lOs1",
    "https://m.site.naver.com/1tv11",
    "https://m.site.naver.com/1tv1w",
    "https://m.site.naver.com/1tv1S",
    "https://m.site.naver.com/1tv29",
    "https://m.site.naver.com/1tv3r",
    "https://m.site.naver.com/1tv3C",
    "https://m.site.naver.com/1tv3L",
    "https://m.site.naver.com/1tv47",
    "https://me-qr.com/9",
    "https://me-qr.com/10",
  ];

  void handleScannedData(
    String qrCode,
    MobileScannerController scannerController,
  ) async {
    if (_isScanning || isScanned) return;
    _isScanning = true;

    print('Scanned: $qrCode');
    result.value = Barcode(rawValue: qrCode, format: BarcodeFormat.qrCode);

    if (!validQrCodes.contains(qrCode) && !_dialogShown) {
      _dialogShown = true;
      _showInvalidQRDialog();
      _isScanning = false;
      return;
    }

    try {
      String? todaySchedule = await getTodaySchedule(qrCode);
      QRAttendanceRequestDTO requestDTO = QRAttendanceRequestDTO(
        qrUrl: qrCode,
        seminar: todaySchedule ?? '',
      );

      AttendanceResponse? response = await _validateQR(requestDTO);
      if (response != null && response.attended) {
        _showAttendanceDialog(
          '출석이 완료되었어요.',
          '출석',
          'check_success.png',
          Colors.green,
        );
      } else {
        _showAttendanceDialog('지각 처리되었어요', '지각', 'warning.png', Colors.red);
      }
    } catch (e) {
      print('Exception in handleScannedData: $e');
    } finally {
      _isScanning = false;
    }
  }

  Future<AttendanceResponse?> _validateQR(
    QRAttendanceRequestDTO requestDTO,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['SERVER_URL']}/v1/validQR'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'Authorization=${authController.obxToken.value}',
        },
        body: jsonEncode(requestDTO.toJson()),
      );

      if (response.statusCode == 200) {
        return AttendanceResponse.fromJson(jsonDecode(response.body));
      } else {
        print('Invalid response: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error validating QR: $e');
      return null;
    }
  }

  void _showInvalidQRDialog() {
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        child: _buildDialogBody(
          title: '출석체크',
          message: '유효하지 않은 QR 코드입니다.\n다시 시도해주세요.',
          image: null,
          color: const Color(0xFF5262F5),
          buttonText: '확인',
          onPressed: () {
            Get.back();
            isScanned = false;
            _dialogShown = false;
          },
        ),
      ),
    );
  }

  void _showAttendanceDialog(
    String message,
    String title,
    String image,
    Color color,
  ) {
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        child: _buildDialogBody(
          title: title,
          message: message,
          image: image,
          color: color,
          buttonText: title == "지각" ? '다음부터 안그럴게요' : '세미나 입장하기',
          onPressed: () {
            isScanned = true;
            _isScanning = false;
            Get.toNamed('/home');
          },
        ),
      ),
    );
  }

  Widget _buildDialogBody({
    required String title,
    required String message,
    String? image,
    required Color color,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 327.w,
      height: 264.h,
      decoration: ShapeDecoration(
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 0.50, color: Color(0xFF5262F5)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(height: 10.h),
          Text(title, style: TextStyle(color: color, fontSize: 20.sp)),
          if (image != null)
            SizedBox(
              width: 56.w,
              height: 58.h,
              child: Image.asset('assets/images/$image', fit: BoxFit.fill),
            ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 16.sp),
          ),
          SizedBox(height: 10.h),
          Container(
            width: 254.w,
            height: 44.h,
            decoration: ShapeDecoration(
              gradient: const LinearGradient(
                begin: Alignment(1.00, -0.03),
                end: Alignment(-1, 0.03),
                colors: [Color(0xFF7B3FEF), Color(0xFF5262F5)],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: TextButton(
              onPressed: onPressed,
              child: Text(
                buttonText,
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  // TODO: url 확인
  Future<String> getTodaySchedule(String qrCode) async {
    switch (qrCode) {
      case "https://m.site.naver.com/1tv2A":
        return "OT";
      case "https://m.site.naver.com/1tv11":
        return "1차 세미나";
      case "https://m.site.naver.com/1tv1w":
        return "2차 세미나";
      case "https://m.site.naver.com/1tv1S":
        return "3차 세미나";
      case "https://m.site.naver.com/1tv29":
        return "4차 세미나";
      case "https://m.site.naver.com/1tv3r":
        return "5차 세미나";
      case "https://m.site.naver.com/1tv3C":
        return "6차 세미나";
      case "https://m.site.naver.com/1tv3L":
        return "연합 세미나";
      case "https://m.site.naver.com/1tv47":
        return "연합 세미나2";
      case "https://me-qr.com/10":
        return "종강총회";
      default:
        throw Exception("잘못된 QR 코드입니다.");
    }
  }

  void onPermissionSet(bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      Get.snackbar('Error', 'No permission');
    }
  }
}
