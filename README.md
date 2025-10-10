## ⚙️ 변경된 사항 요약 (구버전 수정 내역)

이 저장소는 공개 가능한 수준으로 일부 민감한 정보 및 설정을 제거하거나 수정한 버전입니다. 아래는 주요 수정 내역입니다:

---

### 1. Android `build.gradle` 수정

```diff
- minSdk = flutter.minSdkVersion
+ minSdk = 23
```

🛠️ **build(android):** 호환성 확보를 위해 `minSdkVersion`을 23으로 고정

---

### 2. Gradle Wrapper 설정 업데이트

`gradle-wrapper.properties` 내 수정 사항:

```diff
+ distributionUrl=https\://services.gradle.org/distributions/gradle-8.10-bin.zip
+ networkTimeout=10000
+ validateDistributionUrl=true
- distributionUrl=https\://services.gradle.org/distributions/gradle-8.10.2-all.zip
```

🧱 **chore:** Gradle 버전을 `8.10-bin`으로 변경하고 네트워크 설정 추가

---

### 3. MainActivity 정의

```kotlin
package com.pard.pard_app

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() { }
```

📱 **feat:** 기본 `MainActivity.kt` 클래스 정의 (`FlutterActivity` 상속)

Here's an additional section you can add to your `README.md` to document the QR 코드 기능 변경:

---

### 4. QR 코드 기능 라이브러리 교체

```diff
- qr_code_scanner
+ mobile_scanner
```

📷 **refactor:** QR 코드 스캔 기능을 위해 기존 `qr_code_scanner` 패키지 대신 `mobile_scanner`로 교체

---

멋져요. 아래 섹션을 **README.md**에 그대로 붙여넣으면, 이번에 우리가 함께 디버깅·정렬한 내용이 한눈에 정리됩니다.

---

## 🛠 신규 디버깅/정렬 내역 (2025-10)

### 5. Android 15(API 35) / 16KB 메모리 페이지 대응

- `compileSdk`/`targetSdk` 정렬로 Android 15 및 16KB 페이지 사이즈 기기 지원.
- 플러터 3.35.x + 최신 NDK(r27) 조합으로 16KB 지원 번들 생성 확인.

```diff
// android/app/build.gradle.kts
- compileSdk = 35
+ compileSdk = 36

- targetSdk = flutter.targetSdkVersion
+ targetSdk = 35
```

---

### 6. Gradle / Kotlin / Java 정렬

- Gradle Wrapper 8.10, AGP 8.7.0, Kotlin 2.1.0, JVM 17로 업그레이드.

```diff
# android/gradle/wrapper/gradle-wrapper.properties
+ distributionUrl=https\://services.gradle.org/distributions/gradle-8.10-bin.zip
```

```diff
// android/settings.gradle.kts
 plugins {
   id("dev.flutter.flutter-plugin-loader") version "1.0.0"
   id("com.android.application") version "8.7.0" apply false
-  id("org.jetbrains.kotlin.android") version "1.9.25" apply false
+  id("org.jetbrains.kotlin.android") version "2.1.0" apply false
+  id("com.google.gms.google-services") version "4.4.3" apply false
 }
```

```diff
// android/app/build.gradle.kts
  compileOptions {
-   sourceCompatibility = JavaVersion.VERSION_11
-   targetCompatibility = JavaVersion.VERSION_11
+   sourceCompatibility = JavaVersion.VERSION_17
+   targetCompatibility = JavaVersion.VERSION_17
  }
- kotlinOptions { jvmTarget = "11" }
+ kotlinOptions { jvmTarget = "17" }
```

---

### 7. Google Services 플러그인 오류 해결

- 에러: `Plugin 'com.google.gms.google-services' was not found…`
- 조치: `settings.gradle.kts`에 **버전 명시** 추가(위 6번 참조) 후, 앱 모듈에 적용.

```diff
// android/app/build.gradle.kts
 plugins {
   id("com.android.application")
   id("org.jetbrains.kotlin.android")
+  id("com.google.gms.google-services")
   id("dev.flutter.flutter-gradle-plugin")
 }
```

- `google-services.json` 위치: `android/app/google-services.json`

---

### 8. 앱 서명(Upload Key) 미설정 오류 해결

- 에러: **“업로드된 모든 번들에 서명해야 합니다.”**
- 조치: `key.properties` 읽어서 `release` 서명 구성.

```kotlin
// android/app/build.gradle.kts 상단
import java.util.Properties

val keystoreProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(f.inputStream())
}
fun prop(name: String) = keystoreProps.getProperty(name)
    ?: throw GradleException("Missing '$name' in key.properties")
```

```kotlin
// android/app/build.gradle.kts
signingConfigs {
    create("release") {
        storeFile = file(prop("storeFile"))
        storePassword = prop("storePassword")
        keyAlias = prop("keyAlias")
        keyPassword = prop("keyPassword")
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

- `android/key.properties` 예시:

```
storeFile=../keystore/upload-keystore.jks
storePassword=*******
keyAlias=upload
keyPassword=*******
```

---

### 9. 패키지명 불일치 수정

- 에러: **“패키지 이름에는 `com.pard.pard_app`이 있어야 합니다.”**
- 조치: `applicationId`/`namespace`를 스토어와 동일하게 변경(+ Firebase 파일도 동일 패키지로 교체).

```diff
// android/app/build.gradle.kts
- namespace = "com.example.pard_app"
+ namespace = "com.pard.pard_app"

 defaultConfig {
-   applicationId = "com.example.pard_app"
+   applicationId = "com.pard.pard_app"
 }
```

- `android/app/google-services.json`도 동일 패키지의 파일로 교체.

---

### 10. 이미 사용된 버전 코드(36) 문제 해결

- 에러: **“36 버전 코드는 이미 사용되었습니다.”**
- 조치: `pubspec.yaml`의 `version`에서 **build number 증가**.

```diff
# pubspec.yaml
- version: 2.0.1+36
+ version: 2.0.1+37
```

또는 빌드 시:

```
flutter build appbundle --release --build-name=2.0.1 --build-number=37
```

---

### 11. 빌드 & 배포 절차 고도화

- 빌드:

```
flutter clean
flutter pub get
flutter build appbundle --release
```

- 업로드 후 **App Bundle Explorer**에서 16KB 지원 표시 확인.
- 트랙 배포:

  - 내부 테스트: 테스터 추가 → 참여 링크로 설치.
  - 프로덕션: 새 릴리스 생성 → `2.0.1 (37)` 선택 → 단계적 출시 권장(10~20%).

---

### 12. 이스터에그 추가 (마이페이지 10회 탭)

- `RootView`를 `StatefulWidget`으로 전환, 마이페이지 AppBar 타이틀 10회 탭 시 이미지 표시.

```dart
int _myPageTapCount = 0;

void _handleMyPageTap() {
  setState(() {
    _myPageTapCount++;
    if (_myPageTapCount >= 10) {
      _myPageTapCount = 0;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: Image.asset('assets/images/complete.png', width: 200),
          ),
        ),
      );
    }
  });
}
```

```dart
// AppBar title
title: GestureDetector(
  onTap: _handleMyPageTap,
  child: Text('마이 페이지', style: headlineLarge),
),
```

---

### 13. 로컬 개발환경(local.properties) 확인 지침

- 예시(Windows):

```
sdk.dir=C:/Users/User/AppData/Local/Android/Sdk
flutter.sdk=C:/Users/User/dev/flutter
```

- 머신 경로에 맞게만 설정(커밋 금지).

---

### 14. 보안 파일 & .gitignore

- 커밋 금지: `android/key.properties`, `android/keystore/*.jks`, `android/local.properties`
- 커밋 가능: `android/app/google-services.json`(일반적으로 OK), `upload_certificate.pem`(공개 인증서)
- 예시:

```
android/key.properties
android/keystore/
android/local.properties
*.jks
*.keystore
```

---

### 15. 빌드 로그 경고에 대한 메모

- **플러그인 SDK 36 경고**: `compileSdk = 36`으로 정렬하여 해소, `targetSdk = 35`로 Play 요구 충족.
- **패키지 최신 버전 안내(“67 packages …”)**: 이번 릴리스에는 영향 없음. 이후 별도 브랜치에서 정리 권장.
- **Windows에서 `flutter clean` 삭제 실패 경고**: 파일 핸들 잠김 현상으로, 에디터/Gradle 프로세스 종료 후 재실행하면 해소.

---

## 🧾 요약

- compileSdk 36 / targetSdk 35
- AGP 8.7.0, Kotlin 2.1.0, Gradle 8.10, NDK r27
- Google Services plugin 등록 및 Firebase 설정
- release 서명 구성 및 패키지명 정정(com.pard.pard_app)
- versionCode 37로 증가, signed AAB 빌드
