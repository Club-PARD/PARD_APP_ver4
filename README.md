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
package com.example.pard_app

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
