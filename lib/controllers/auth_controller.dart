import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pard_app/controllers/error_controller.dart';
import 'package:pard_app/controllers/spring_user_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pard_app/models/user_model/user_info_model.dart' as pard_user;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;

class AuthController extends GetxController {
  final SpringUserController _springUserController = Get.put(
    SpringUserController(),
  );
  final ErrorController _errorController = Get.put(ErrorController());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Rx<FlutterSecureStorage> sStorage = const FlutterSecureStorage().obs;
  Rx<String?> userEmail = Rx<String?>(null); // 1차적으로 이메일 저장(휴대폰 인증 전 필요)
  Rx<User?> user = Rx<User?>(null);
  RxBool isAgree = false.obs;
  RxBool isLogin = false.obs;
  var obxToken = ''.obs;
  Rx<pard_user.UserInfo?> userInfo = Rx<pard_user.UserInfo?>(null);

  @override
  void onInit() {
    super.onInit();
    checkPreviousLogin();
  }

  checkPreviousLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 첫 앱 실행인지 구분
      if (prefs.getBool('first_run') ?? true) {
        await sStorage.value.deleteAll();
        prefs.setBool('first_run', false);
      }
      String? email = await sStorage.value.read(key: 'email');
      userEmail.value = email;
      if (email != null) {
        String? token = await _springUserController.login(userEmail.value!);
        if (token != null) {
          if (token.startsWith('Authorization=')) {
            token = token.replaceFirst('Authorization=', '');
          }
          obxToken.value = token;
          print('checkPreviousLogin() $token , $email');
          // await sStorage.value.write(key: 'Authorization', value: token); // sStorage에 토큰 저장
          pard_user.UserInfo? userInfo = await _springUserController.fetchUser(
            token,
          );
          String? tosAgreement = await sStorage.value.read(key: 'tos');
          if (userInfo != null && tosAgreement == 'agree') {
            // await sStorage.value.write(key: 'login', value: user.email!);
            await _springUserController.fetchUser(token); // 스프링 서버에서 유저 정보 가져옴
            Get.toNamed('/home');
            isLogin.value = true;
          } else {
            Get.toNamed('/tos');
          }
        }
      } else if (email == null) {
        // await signInWithGoogle();
        print('로그인 이력 없음: 로그인 필요');
        isLogin.value = false;
      } else {
        Get.toNamed('/tos');
      }
    } catch (e) {
      await _errorController.writeErrorLog(
        e.toString(),
        _springUserController.userInfo.value?.name ?? 'none',
        'checkPreviousLogin()',
      );
    }
    isLogin.value = false;
  }

  // 에러로그 db 삭제
  Future<void> deleteAllDocuments() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference collectionRef = firestore.collection('Errorlog');

    // Get all documents in the collection
    QuerySnapshot querySnapshot = await collectionRef.get();

    // Loop through and delete each document
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  //로그인
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final UserCredential authResult = await _auth.signInWithCredential(
          credential,
        );
        final User? user = authResult.user;

        if (user != null) {
          userEmail.value = user.email;
          print(userEmail.value);
          // 구글 로그인 후 서버에서 받아온 토큰을 가져옴
          sStorage.value.write(key: 'email', value: userEmail.value);
          String? token = await _springUserController.login(userEmail.value!);

          if (token != null) {
            if (token.startsWith('Authorization=')) {
              token = token.replaceFirst('Authorization=', '');
            }
            obxToken.value = token;
            // await sStorage.value.write(key: 'Authorization', value: token); // sStorage에 토큰 저장
            pard_user.UserInfo? userInfo = await _springUserController
                .fetchUser(token);
            String? tosAgreement = await sStorage.value.read(key: 'tos');
            if (userInfo != null && tosAgreement == 'agree') {
              // await sStorage.value.write(key: 'login', value: user.email!);
              Get.toNamed('/home');
            } else {
              Get.toNamed('/tos');
            }
          } else {
            Get.toNamed('/tos');
          }
        } else {
          print('로그인 실패');
        }
      }
    } catch (e) {
      print(e.toString());
      await _errorController.writeErrorLog(
        e.toString(),
        _springUserController.userInfo.value?.name ?? 'none',
        'signInWithGoogle()',
      );
    }
  }

  Future<void> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: "com.pard.service",
          // TODO: url 확인
          redirectUri: Uri.parse(
            "https://evergreen-glory-sagittarius.glitch.me/callbacks/sign_in_with_apple",
          ),
        ),
      );

      userEmail.value = appleCredential.email; //애플에서 받아온 email을 Rx email에 넣는다

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      if (appleCredential.email == null) {
        List<String> jwt = appleCredential.identityToken?.split('.') ?? [];
        String payload = jwt[1];
        payload = base64.normalize(payload);

        final List<int> jsonData = base64.decode(payload);
        final userInfo = jsonDecode(utf8.decode(jsonData));
        print('--------------DECODED USERINFO-----------------');
        print(userInfo);
        String email = userInfo['email'];
        print('-----------DECODED Email----------------------');
        print(email);
        userEmail.value = email;
      }

      final UserCredential authResult = await FirebaseAuth.instance
          .signInWithCredential(oauthCredential);
      final User? user = authResult.user;

      if (user != null) {
        userEmail.value = user.email;
        print(userEmail.value);
        // 구글 로그인 후 서버에서 받아온 토큰을 가져옴
        String? token = await _springUserController.login(userEmail.value!);

        if (token != null) {
          if (token.startsWith('Authorization=')) {
            token = token.replaceFirst('Authorization=', '');
          }
          obxToken.value = token;
          // await sStorage.value.write(key: 'Authorization', value: token); // sStorage에 토큰 저장
          pard_user.UserInfo? userInfo = await _springUserController.fetchUser(
            token,
          );
          String? tosAgreement = await sStorage.value.read(key: 'tos');
          if (userInfo != null && tosAgreement == 'agree') {
            // await sStorage.value.write(key: 'login', value: user.email!);
            Get.toNamed('/home');
          } else {
            Get.toNamed('/tos');
          }
        } else {
          Get.toNamed('/tos');
        }
      }
    } catch (e) {
      print(e);
      await _errorController.writeErrorLog(
        e.toString(),
        _springUserController.userInfo.value?.name ?? 'none',
        'signInWithApple()',
      );
    }
  }

  //탈퇴하기
  Future<void> deleteUserFields() async {
    try {
      final response = await http.delete(
        Uri.parse('${dotenv.env['SERVER_URL']}/v1/users'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'Authorization=$obxToken',
        },
      );

      if (response.statusCode == 200) {
        print('User deleted successfully');
        await sStorage.value.deleteAll();
        await _auth.signOut();
        await _googleSignIn.signOut();
        Get.offAllNamed('/', predicate: (route) => Get.currentRoute == '/');
      } else {
        print('Failed to delete user: ${response.statusCode}');
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      await _errorController.writeErrorLog(
        e.toString(),
        _springUserController.userInfo.value?.name ?? 'none',
        'deleteUserFields()',
      );
    }
  }

  //로그아웃
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await sStorage.value.delete(key: 'login');
      await sStorage.value.delete(key: 'tos');
      Get.offAllNamed('/', predicate: (route) => Get.currentRoute == '/');
    } catch (e) {
      await _errorController.writeErrorLog(
        e.toString(),
        _springUserController.userInfo.value?.name ?? 'none',
        'signOut()',
      );
    }
  }
}
