# TrueLern Parent App — Flutter API Integration Contract

This document provides the definitive guide for Flutter Android developers integrating the TrueLern Parent Application with the existing TrueLern backend.

The backend acts as the single source of truth. The mobile app interacts directly with TrueLern's canonical business logic, services, database models, and role permissions via REST APIs without relying on browser cookies, browser sessions, Next.js HTML pages, or manual logins inside a WebView.

---

## 1. Core Architecture Principles

1. **Authenticated Entity is the Parent**:
   - The authenticated TrueLern account is always the **Parent** user (`role: "Parent"`).
   - Children are `Student` entities linked to the authenticated Parent via `ParentStudentLink`.
   - **No separate child email/password authentication** exists or should be created.
2. **Server-Enforced Child Ownership**:
   - Every child-scoped endpoint (`/api/parent/children/:childId/...`) validates on the server that the child belongs to the authenticated parent (`canAccessPortal === true`, active status).
   - A valid session for Parent A can **never** access Parent B's children, dashboard, timetable, invoices, assessments, messages, or recordings.
3. **Session Credentials**:
   - Web users authenticate via HTTP-only cookies.
   - Mobile Flutter users authenticate via standard HTTP header:
     ```http
     Authorization: Bearer <truelern-access-token>
     Content-Type: application/json
     Accept: application/json
     ```
4. **Security & Secrets**:
   - **Never** place Google Client Secrets, backend JWT signing secrets, or Stripe secret keys inside the Flutter app.
   - Mobile apps only hold public client configuration (`GOOGLE_CLIENT_ID`, `GOOGLE_ANDROID_CLIENT_ID`).

---

## 2. Environments & Connectivity

### Base URLs

| Environment | Base URL | Notes |
| :--- | :--- | :--- |
| **Android Emulator** | `http://10.0.2.2:3000` | Inside the Android emulator, `localhost` refers to the emulator itself. `10.0.2.2` aliases the workstation host. |
| **Physical Android Device (LAN)** | `http://<HOST_LAN_IP>:3000` | Both computer and phone must be on the same Wi-Fi network, or use ADB reverse: `adb reverse tcp:3000 tcp:3000` then `http://localhost:3000`. |
| **Production Server** | `https://truelern.visital.in` | Verified deployed TrueLern domain. aaPanel reverse proxy routes directly to the Next.js process; all `/api/...` endpoints live under this exact origin. |

> [!IMPORTANT]
> - The verified production HTTPS hostname is `https://truelern.visital.in`. Do not use hypothetical hostnames like `api.truelern.com`.
> - Always configure the base URL dynamically in Flutter via `--dart-define=API_BASE_URL=...` or an environment config class. Never hardcode a developer's private LAN IP address in production code.

---

## 3. Google Cloud Console & Android Setup

### Required OAuth Client Types in Google Cloud Console

You must configure two distinct OAuth 2.0 Client IDs in the same Google Cloud Console Project:

1. **Web Application Client ID (`serverClientId`)**:
   - **Type**: Web application.
   - **Backend Environment Variable**: Configured in `.env` as `GOOGLE_CLIENT_ID` (e.g. `765360296728-9djdevn7k3vle3k4hjc0naq5k6el4s9e.apps.googleusercontent.com`).
   - **Client App Usage**: Passed to Flutter's `GoogleSignIn(serverClientId: '...')`.
   - **Token Audience**: When `serverClientId` is set, Google Play Services mints an ID token whose `aud` claim matches this Web Client ID. TrueLern server cryptographically validates this audience.
   - **Client Secrets**: `GOOGLE_CLIENT_SECRET` stays strictly on the server; **never** bundle client secrets in the Flutter app.

2. **Android OAuth Client ID**:
   - **Type**: Android.
   - **Package Name**: Must match the actual `applicationId` or `namespace` declared in your Flutter project's `android/app/build.gradle` (e.g. `com.truelern.parent` or your organization's custom ID). **Do not guess or assume this value; inspect your Flutter Android configuration.**
   - **Debug SHA-1 Certificate Fingerprint**: Required for local testing on emulators and debug APKs:
     ```bash
     # Windows (cmd/PowerShell)
     keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
     # macOS/Linux
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - **Release SHA-1 Certificate Fingerprint**: Required for production release builds. Generated from your release upload keystore or copied from Google Play Console under **Release > Setup > App Integrity > App signing key certificate**.

### Native Android Sign-In (Credential Manager)

Do **not** use an embedded WebView for Google Sign-In. Google strictly blocks OAuth inside embedded WebViews.

Use the official `google_sign_in` Flutter plugin (`^6.2.1` or higher) configured with Credential Manager:

```dart
final GoogleSignIn googleSignIn = GoogleSignIn(
  serverClientId: '765360296728-9djdevn7k3vle3k4hjc0naq5k6el4s9e.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);
```

When the user selects their Google account, Google Play Services verifies the Android app package name and signing SHA-1 with Google Cloud, and mints an RS256-signed ID token whose `aud` claim matches `serverClientId`. Flutter then sends this token to `POST /api/auth/mobile/google` for server verification.

---

## 4. Mobile Authentication Flow & API Contracts

```
[Flutter App]                          [Google Play Services]               [TrueLern Backend]
      |                                           |                                  |
      | 1. Trigger Google Sign-In                 |                                  |
      |------------------------------------------>|                                  |
      | 2. Returns Google ID Token                |                                  |
      |<------------------------------------------|                                  |
      |                                                                              |
      | 3. POST /api/auth/mobile/google { idToken, platform: "android" }             |
      |----------------------------------------------------------------------------->|
      |                                           | 4. Cryptographically verifies    |
      |                                           |    signature against Google JWKS |
      |                                           | 5. Verifies iss, aud, exp, nonce |
      |                                           | 6. Links/Resolves Parent User    |
      |                                           | 7. Generates TrueLern Session    |
      | 8. Returns { accessToken, refreshToken, expiresIn, user, parent, children }  |
      |<-----------------------------------------------------------------------------|
      |                                                                              |
      | 9. Store tokens in FlutterSecureStorage                                      |
      | 10. Use 'Authorization: Bearer <accessToken>' for all subsequent API calls  |
```

---

### Endpoint 1: Google Native Sign-In Exchange

**`POST /api/auth/mobile/google`**

Exchanges a cryptographically verified Google ID Token for TrueLern session credentials.

#### Request Headers
```http
Content-Type: application/json
Accept: application/json
```

#### Request Body
```json
{
  "idToken": "<google-id-token-jwt-from-credential-manager>",
  "platform": "android",
  "nonce": "<optional-cryptographic-nonce>"
}
```

#### Successful Response (`200 OK`)
```json
{
  "success": true,
  "message": "Google authentication successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 86400,
    "tokenType": "Bearer",
    "user": {
      "id": "67b819f0...",
      "email": "sarah.parent@example.com",
      "firstName": "Sarah",
      "lastName": "Smith",
      "role": "Parent"
    },
    "parent": {
      "id": "67b819f1...",
      "parentId": "PAR-0001",
      "firstName": "Sarah",
      "lastName": "Smith",
      "email": "sarah.parent@example.com",
      "phone": "+1-555-0199",
      "status": "active"
    },
    "children": [
      {
        "linkId": "67b819f2...",
        "studentId": "67b819f3...",
        "studentCode": "STU-0001",
        "firstName": "Tommy",
        "lastName": "Smith",
        "name": "Tommy Smith",
        "relationshipType": "mother",
        "isCustodial": true,
        "isEmergencyContact": true,
        "canAccessPortal": true,
        "status": "active"
      }
    ]
  }
}
```

#### Error Codes
| HTTP Status | Error Code | Meaning |
| :--- | :--- | :--- |
| `400 Bad Request` | `VALIDATION_ERROR` | `idToken` missing or invalid format |
| `401 Unauthorized` | `AUTH_TOKEN_INVALID` | Invalid Google signature, wrong audience, or wrong issuer |
| `401 Unauthorized` | `AUTH_TOKEN_EXPIRED` | Google ID token has expired |
| `403 Forbidden` | `FORBIDDEN` | Account is disabled or has a non-Parent role (e.g. Student/Teacher) |
| `404 Not Found` | `NOT_FOUND` | Google email is not registered in TrueLern |
| `409 Conflict` | `CONFLICT` | TrueLern account is already linked to a different Google account |

---

### Endpoint 2: Mobile Token Refresh

**`POST /api/auth/mobile/refresh`**

Refreshes an expiring TrueLern access token. Implements **Refresh Token Rotation**: each refresh issues a brand new access token and a brand new refresh token, immediately invalidating the previous refresh token. Replaying an already-rotated token triggers automatic session revocation.

#### Request Headers
```http
Content-Type: application/json
Accept: application/json
```

#### Request Body
```json
{
  "refreshToken": "<truelern-refresh-token>"
}
```

#### Successful Response (`200 OK`)
```json
{
  "success": true,
  "message": "Session refreshed successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 86400,
    "tokenType": "Bearer"
  }
}
```

#### Error Codes
| HTTP Status | Error Code | Meaning |
| :--- | :--- | :--- |
| `401 Unauthorized` | `AUTH_TOKEN_INVALID` | Refresh token is invalid, expired, revoked, or already rotated (replay detected) |
| `403 Forbidden` | `FORBIDDEN` | Parent user account has been disabled |

---

### Endpoint 3: Mobile Logout

**`POST /api/auth/mobile/logout`**

Revokes the mobile session and marks the refresh token hash as revoked in MongoDB.

#### Request Headers
```http
Authorization: Bearer <truelern-access-token>
Content-Type: application/json
Accept: application/json
```

#### Request Body (Optional)
```json
{
  "refreshToken": "<current-refresh-token>"
}
```

#### Successful Response (`200 OK`)
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

### Endpoint 4: Get Current Authenticated Profile

**`GET /api/auth/mobile/me`**

Retrieves the currently authenticated Parent profile, user identity, and list of linked children.

#### Request Headers
```http
Authorization: Bearer <truelern-access-token>
Accept: application/json
```

#### Successful Response (`200 OK`)
```json
{
  "success": true,
  "message": "Authenticated parent profile retrieved successfully",
  "data": {
    "user": {
      "id": "67b819f0...",
      "email": "sarah.parent@example.com",
      "firstName": "Sarah",
      "lastName": "Smith",
      "role": "Parent"
    },
    "parent": {
      "id": "67b819f1...",
      "parentId": "PAR-0001",
      "firstName": "Sarah",
      "lastName": "Smith",
      "email": "sarah.parent@example.com",
      "phone": "+1-555-0199",
      "status": "active"
    },
    "children": [
      {
        "linkId": "67b819f2...",
        "studentId": "67b819f3...",
        "studentCode": "STU-0001",
        "firstName": "Tommy",
        "lastName": "Smith",
        "relationshipType": "mother",
        "isCustodial": true,
        "isEmergencyContact": true,
        "canAccessPortal": true,
        "status": "active"
      }
    ]
  }
}
```

---

## 5. Complete Parent Portal API Inventory

Every screen in the Flutter Parent App maps directly to the existing TrueLern backend routes. The Flutter client passes `Authorization: Bearer <accessToken>` on all requests.

### A. Parent Identity & Child Management

| Screen / Action | HTTP Method & Route | Request Body | Response Details |
| :--- | :--- | :--- | :--- |
| **Get Parent Profile** | `GET /api/parent/profile` | None | Returns parent record, contact info, and address. |
| **Update Parent Profile** | `PUT /api/parent/profile` | `{ phone, address, city, state, country, postalCode }` | Updates parent contact details. |
| **Get Preferences** | `GET /api/parent/preferences` | None | Returns notification and display preferences. |
| **Update Preferences** | `PUT /api/parent/preferences` | `{ emailNotifications, smsNotifications, timezone }` | Saves notification preferences. |
| **List Linked Children** | `GET /api/parent/children` | None | Returns all verified linked children for selector. |
| **Add New Child** | `POST /api/parent/children` | `{ firstName, lastName, relationshipType, gender, dob, phone }` | Creates Student and links with `canAccessPortal: true`. |
| **Get Child Details** | `GET /api/parent/children/:studentId` | None | Returns child profile, emergency contacts. |
| **Update Child Profile**| `PUT /api/parent/children/:studentId` | `{ firstName, lastName, phone, city, state }` | Updates linked child details. |
| **Remove Child Link** | `DELETE /api/parent/children/:studentId` | None | Soft-deletes child access link. |

---

### B. Dashboard, Academics & Schedules

| Screen / Action | HTTP Method & Route | Request Body / Query | Response Details |
| :--- | :--- | :--- | :--- |
| **Child Dashboard** | `GET /api/parent/children/:studentId/dashboard` | None | Enrolled courses count, overall attendance %, upcoming live classes, recent assignments, metrics. |
| **Child Program Info** | `GET /api/parent/children/:studentId/program` | None | Active cohort, enrolled courses, batch schedules. |
| **Child Academics** | `GET /api/parent/children/:studentId/academics` | None | Course list, syllabus progress, modules completed. |
| **Child Progress** | `GET /api/parent/children/:studentId/progress` | None | Skill mastery, chapter completion milestones. |
| **Child Skills** | `GET /api/parent/children/:studentId/skills` | None | Detailed competencies and mastery badges. |
| **Topic Details** | `GET /api/parent/children/:studentId/topics/:topicId` | None | Topic overview, resources, lesson status. |
| **Timetable & Schedule**| `GET /api/parent/children/:studentId/schedule` | Query: `?fromDate=...&toDate=...` | Calendar entries, class dates, teacher names, zoom/jitsi links. |
| **Attendance History** | `GET /api/parent/children/:studentId/attendance` | None | Present, absent, late records, percentage breakdown. |
| **Certificates** | `GET /api/parent/children/:studentId/certificates` | None | Issued completion certificates, download links. |

---

### C. Assignments, Submissions & Attachments

| Screen / Action | HTTP Method & Route | Request Body / Query | Response Details |
| :--- | :--- | :--- | :--- |
| **List Assignments** | `GET /api/parent/children/:studentId/assignments` | None | Pending, submitted, graded assignments with due dates. |
| **Assignment Detail** | `GET /api/parent/children/:studentId/assignments/:assignmentId` | None | Instructions, maximum marks, attached worksheet files. |
| **Upload Attachment** | `POST /api/upload` | Multipart form: `file` or `files` | Returns `{ url, fileUrl, fileName, fileSize, fileType }`. |
| **Save Draft** | `POST /api/parent/children/:studentId/assignments/:assignmentId/draft` | `{ content, attachments: [...] }` | Saves submission draft without grading lock. |
| **Submit Assignment** | `POST /api/parent/children/:studentId/assignments/:assignmentId/submit` | `{ content, attachments: [...] }` | Finalizes submission for teacher evaluation. |
| **Preview Attachment** | `GET /api/attachments/preview?fileUrl=:fileUrl` | None | Streams PDF or image preview safely. |

---

### D. Assessments & Results

| Screen / Action | HTTP Method & Route | Request Body / Query | Response Details |
| :--- | :--- | :--- | :--- |
| **List Assessments** | `GET /api/parent/children/:studentId/assessments` | None | Available quizzes, scheduled tests, completed results with scores. |
| **Launch Assessment** | `POST /api/parent/children/:studentId/assessments/:assessmentId/launch` | None | Verifies eligibility, returns `{ redirectUrl, proxyToken }`. |
| **Verify Exam Session** | `GET /api/parent/children/:studentId/assessments/:assessmentId/session` | Header: `x-assessment-proxy-token: <proxyToken>` | Verifies student and assessment; returns questions context and proxy token. |
| **Get Questions** | `GET /api/assessments/:assessmentId?childId=:studentId` | Header: `x-assessment-proxy-token: <proxyToken>` | Returns questions, options, timer duration. |
| **Start Attempt** | `POST /api/assessments/:assessmentId/start` | Header: `x-assessment-proxy-token: <proxyToken>` | Creates attempt timer, returns `attemptId`. |
| **Save Answer Draft** | `POST /api/assessments/:attemptId/save` | `{ answers: [...] }` | Autosaves question responses during test. |
| **Submit Attempt** | `POST /api/assessments/:attemptId/submit` | `{ answers: [...], autoSubmitted: false }` | Submits answers, calculates score, returns result. |

---

### E. Messages & Communication

| Screen / Action | HTTP Method & Route | Request Body / Query | Response Details |
| :--- | :--- | :--- | :--- |
| **Get Notifications** | `GET /api/parent/notifications` | None | Notification cards, unread badges, timestamps. |
| **List Conversations** | `GET /api/parent/children/:studentId/messages` | Query: `?teacherId=...` | Message threads between Parent and Child's assigned teachers. |
| **Send Message** | `POST /api/parent/children/:studentId/messages` | `{ teacherId, content, attachments: [...] }` | Dispatches communication message to teacher. |
| **Mark Message Read** | `POST /api/parent/children/:studentId/messages/:messageId/read` | None | Updates read status. |

---

### F. Live Classes & Recordings

| Screen / Action | HTTP Method & Route | Request Body / Query | Response Details |
| :--- | :--- | :--- | :--- |
| **List Live Classes** | `GET /api/parent/children/:studentId/live-classes` | None | Scheduled, live, and past classes. |
| **Class Summary** | `GET /api/parent/children/:studentId/classes/:classId/summary` | None | Teacher notes, topic covered, attendance record. |
| **Join Live Class Token**| `POST /api/live-classes/:classId/token` | `{ childId: studentId }` | Returns authorized Jitsi JWT. **Parents enter in observer mode (`isModerator: false`) with no recording control.** Enforces join window. |
| **List Recordings** | `GET /api/parent/children/:studentId/recordings` | None | Published classroom recordings for revision. |
| **Stream Recording** | `GET /api/recordings/:recordingId/stream` | None | Authorized video streaming (HTTP 206 Partial Content). |

---

### G. Demos & Enrollment

| Screen / Action | HTTP Method & Route | Request Body / Query | Response Details |
| :--- | :--- | :--- | :--- |
| **Get Demo Status** | `GET /api/parent/demo` | Query: `?studentId=:studentId` | Current scheduled demo sessions and status. |
| **Demo Courses** | `GET /api/parent/demo/courses` | None | Available courses for booking a free trial. |
| **Demo Availability** | `GET /api/parent/demo/availability?courseId=:id` | None | Available teacher calendar slots for demo. |
| **Schedule Demo** | `POST /api/parent/demo` | `{ studentId, courseId, availabilityId, startDateTime }` | Schedules live 1-on-1 demo class. |
| **Join Demo Token** | `POST /api/parent/demo/:demoId/token` | None | Returns Jitsi token for parent to join demo. |
| **Get Enrollment Offer**| `GET /api/parent/children/:studentId/enroll` | None | Post-demo course recommendation and fee plan. |
| **Initiate Enrollment**| `POST /api/parent/children/:studentId/enroll` | `{ courseId, feePlanId }` | Creates invoice and initiates checkout. |

---

### H. Finance & Stripe Payments

| Screen / Action | HTTP Method & Route | Request Body / Query | Response Details |
| :--- | :--- | :--- | :--- |
| **Finance Summary** | `GET /api/parent/children/:studentId/finance` | None | Outstanding balance, paid amounts, invoice list. |
| **List Invoices** | `GET /api/parent/children/:studentId/invoices` | None | Pending, paid, and overdue invoices. |
| **Invoice Detail** | `GET /api/parent/children/:studentId/finance/invoices/:invoiceId` | None | Line items, fee breakdown, taxes, balance due. |
| **Download Invoice** | `GET /api/parent/children/:studentId/finance/invoices/:invoiceId/download` | None | Binary PDF stream of invoice document. |
| **Receipt Detail** | `GET /api/parent/children/:studentId/finance/receipts/:receiptId` | None | Payment reference, transaction timestamp, receipt data. |
| **Download Receipt** | `GET /api/parent/children/:studentId/finance/receipts/:receiptId/download` | None | Binary PDF stream of official receipt. |
| **Stripe Checkout** | `POST /api/finance/stripe/create-checkout` | `{ invoiceId, studentId, successUrl, cancelUrl }` | Generates official server-calculated Stripe Checkout Session URL. |

> [!CAUTION]
> **Stripe Payment Verification Rule**:
> - Never trust client-reported amounts or mark an invoice as paid merely because the app returned from the Stripe checkout screen.
> - The mobile app opens the `session.url` in Chrome Custom Tabs or an external browser.
> - When payment succeeds, Stripe's cryptographically signed webhook notifies `/api/finance/stripe/webhook` on the TrueLern server.
> - Only the backend webhook marks invoices as paid and activates course enrollment.
> - After returning to the app, call `GET /api/parent/children/:studentId/finance/invoices/:invoiceId` to poll verified status.

---

## 6. Child Selection & Multi-Child Switching Rules

1. **Active Child State**:
   - The Flutter app should store the currently selected `studentId` in a centralized state manager (e.g., `Riverpod`, `Bloc`, or `Provider`).
   - If the parent has only one child, auto-select that child.
   - If the parent has multiple children, present a child switcher (avatar dropdown) in the app bar.
2. **Scoping Requests**:
   - Pass the active child's `studentId` as the path parameter in child-scoped routes:
     ```dart
     final response = await dio.get('/api/parent/children/$activeStudentId/dashboard');
     ```
3. **Switching Children**:
   - When the user switches child in the UI:
     1. Update `activeStudentId` in app state.
     2. Invalidate/refresh cached dashboard, academic, and finance queries.
     3. The server immediately enforces data isolation for the newly selected child.

---

## 7. Production Flutter Integration Blueprint

### Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.2
  google_sign_in: ^6.2.1
  url_launcher: ^6.3.1
```

---

### Step 1: Secure Token Storage (`token_storage.dart`)

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken = 'truelern_access_token';
  static const _keyRefreshToken = 'truelern_refresh_token';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }
}
```

---

### Step 2: Dio HTTP Client with Serialized Auto-Refresh (`api_client.dart`)

The TrueLern server implements **Refresh Token Rotation (RTR)** with an **atomic 15-second grace window**. To prevent race conditions, the Flutter client must:
1. Use `QueuedInterceptor` (Dio's serialized interceptor) to prevent simultaneous refresh requests.
2. Use a `Completer<String?>` so concurrent 401 errors await the single in-flight refresh call.
3. Mark retried requests with `options.extra['isRetry'] = true` to guarantee at most ONE retry and eliminate infinite retry loops.

```dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiClient {
  static late final Dio dio;
  static Completer<String?>? _refreshCompleter;

  // Base URL: http://10.0.2.2:3000 for Android emulator; https://truelern.visital.in for production
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static void init() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // QueuedInterceptor processes requests and errors sequentially
    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth header on public or login/refresh routes
        if (!options.path.contains('/api/auth/mobile/google') &&
            !options.path.contains('/api/auth/mobile/refresh') &&
            !options.path.contains('/api/public/')) {
          final token = await TokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        final requestPath = error.requestOptions.path;
        final statusCode = error.response?.statusCode;
        final isRetry = error.requestOptions.extra['isRetry'] == true;

        // Only handle 401 for non-auth endpoints, and never retry a request more than once
        if (statusCode == 401 &&
            !requestPath.contains('/api/auth/mobile/refresh') &&
            !requestPath.contains('/api/auth/mobile/google') &&
            !isRetry) {

          // Mark request as retried to eliminate infinite refresh loops
          error.requestOptions.extra['isRetry'] = true;

          // If a refresh is already in progress, await its completion
          if (_refreshCompleter != null) {
            try {
              final newAccessToken = await _refreshCompleter!.future;
              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final retryResponse = await dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              }
            } catch (_) {
              // Refresh failed for waiting request
            }
            await _handleLogout();
            return handler.reject(error);
          }

          // Start a new serialized refresh operation
          _refreshCompleter = Completer<String?>();

          try {
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken == null || refreshToken.isEmpty) {
              _refreshCompleter?.complete(null);
              _refreshCompleter = null;
              await _handleLogout();
              return handler.reject(error);
            }

            // Call canonical mobile refresh endpoint using a standalone Dio instance
            final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
            final refreshResponse = await refreshDio.post(
              '/api/auth/mobile/refresh',
              data: {'refreshToken': refreshToken},
            );

            if (refreshResponse.statusCode == 200 &&
                refreshResponse.data['success'] == true) {
              final data = refreshResponse.data['data'] as Map<String, dynamic>;
              final newAccessToken = data['accessToken'] as String;
              final newRefreshToken = data['refreshToken'] as String;

              await TokenStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              _refreshCompleter?.complete(newAccessToken);
              _refreshCompleter = null;

              // Retry the original request with new access token
              error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            } else {
              _refreshCompleter?.complete(null);
              _refreshCompleter = null;
              await _handleLogout();
              return handler.reject(error);
            }
          } catch (refreshErr) {
            _refreshCompleter?.complete(null);
            _refreshCompleter = null;
            await _handleLogout();
            return handler.reject(error);
          }
        }

        return handler.next(error);
      },
    ));
  }

  static Future<void> _handleLogout() async {
    await TokenStorage.clearTokens();
    // Dispatch navigation event to Login Screen in your app router
  }
}
```

---

### Step 3: Google Sign-In & Session Exchange Service (`auth_service.dart`)

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '765360296728-9djdevn7k3vle3k4hjc0naq5k6el4s9e.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Performs Native Google Sign-In and exchanges verified token with TrueLern
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // 1. Native Android Google Account Picker
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('User cancelled Google sign-in');
      }

      // 2. Obtain Google Authentication tokens
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to retrieve Google ID token');
      }

      // 3. Exchange Google ID Token with TrueLern Backend
      final response = await ApiClient.dio.post(
        '/api/auth/mobile/google',
        data: {
          'idToken': idToken,
          'platform': 'android',
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;

        // 4. Save session securely
        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        return data;
      } else {
        throw Exception(response.data['message'] ?? 'Authentication failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Revokes server session and signs out locally
  static Future<void> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      await ApiClient.dio.post(
        '/api/auth/mobile/logout',
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {
      // Ignore network failures on logout
    } finally {
      await _googleSignIn.signOut();
      await TokenStorage.clearTokens();
    }
  }
}
```

---

## 8. Summary Checklist for the Flutter Developer

- [ ] Run backend on local machine (`npm run dev`) or connect to staging server.
- [ ] For Android emulator, use `http://10.0.2.2:3000` as API base URL.
- [ ] Configure `google_sign_in` with `serverClientId` matching the Web Application Client ID in Google Cloud.
- [ ] Add your debug keystore SHA-1 / SHA-256 fingerprint to the Android OAuth client in Google Cloud Console.
- [ ] Call `POST /api/auth/mobile/google` with `{ idToken: idToken, platform: "android" }`.
- [ ] Save `accessToken` and `refreshToken` in `FlutterSecureStorage`.
- [ ] Attach `Authorization: Bearer <accessToken>` to all subsequent HTTP requests via Dio Interceptor.
- [ ] Automatically rotate tokens via `POST /api/auth/mobile/refresh` upon receiving HTTP `401`.
- [ ] Call `GET /api/auth/mobile/me` to load the parent's profile and linked children.
- [ ] Store active `studentId` in app state and pass it in all `/api/parent/children/:studentId/...` routes.
- [ ] Use `POST /api/finance/stripe/create-checkout` to initiate payment, and poll the invoice status after returning from checkout.
