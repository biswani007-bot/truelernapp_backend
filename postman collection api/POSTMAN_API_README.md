# TrueLern LMS — Complete Postman Collection & Developer API Handoff Guide

## 1. Executive Summary & Collection Overview

This directory contains the production-synchronized Postman collections and environments for **TrueLern LMS** (also known as LMSCA). Every endpoint documented in this suite corresponds to actual, implemented Next.js route handlers (`app/api/**/route.ts`).

- **Total Implemented Backend API Endpoints:** 458 action endpoints (across 314 route files)
- **Total Postman Requests Documented:** 474 requests (including dedicated multi-child isolation, negative security, and RBAC test suites)
- **Collection Format:** Postman Collection Schema v2.1.0 (`https://schema.getpostman.com/json/collection/v2.1.0/collection.json`)
- **API Coverage:** **100% of implemented endpoints covered**

---

## 2. Discovered & Maintained Postman Files

| File Path | Description | Requests / Variables |
| :--- | :--- | :--- |
| [`TrueLern_Postman_Collection.json`](file:///c:/Users/PABANI/Downloads/truelms-main/TrueLern_Postman_Collection.json) | Root master collection covering all 21 core functional modules + test suites | 474 Requests |
| [`docs/postman/TrueLern-Complete-API.postman_collection.json`](file:///c:/Users/PABANI/Downloads/truelms-main/docs/postman/TrueLern-Complete-API.postman_collection.json) | Complete API collection in documentation directory | 474 Requests |
| [`docs/postman/TrueLern-Mobile-API.postman_collection.json`](file:///c:/Users/PABANI/Downloads/truelms-main/docs/postman/TrueLern-Mobile-API.postman_collection.json) | Scoped mobile collection for Flutter / React Native / Android client integration | 82 Requests |
| [`docs/api/TrueLern-API.postman_collection.json`](file:///c:/Users/PABANI/Downloads/truelms-main/docs/api/TrueLern-API.postman_collection.json) | Mobile/API scoped reference collection | 82 Requests |
| [`TrueLern_Local.postman_environment.json`](file:///c:/Users/PABANI/Downloads/truelms-main/TrueLern_Local.postman_environment.json) | Local development environment (`http://localhost:3000`) | 56 Variables |
| [`TrueLern_Production.postman_environment.json`](file:///c:/Users/PABANI/Downloads/truelms-main/TrueLern_Production.postman_environment.json) | Production environment (`https://truelern.visital.in`) with sanitized credentials | 56 Variables |
| [`docs/postman/TrueLern-Postman-Environment.json`](file:///c:/Users/PABANI/Downloads/truelms-main/docs/postman/TrueLern-Postman-Environment.json) | Local development environment mirror | 56 Variables |
| [`docs/postman/TrueLern-Mobile-Local.postman_environment.json`](file:///c:/Users/PABANI/Downloads/truelms-main/docs/postman/TrueLern-Mobile-Local.postman_environment.json) | Mobile local development environment | 38 Variables |
| [`docs/postman/TrueLern-Mobile-Production.postman_environment.json`](file:///c:/Users/PABANI/Downloads/truelms-main/docs/postman/TrueLern-Mobile-Production.postman_environment.json) | Mobile production environment | 38 Variables |
| [`docs/api/TrueLern-API.postman_environment.json`](file:///c:/Users/PABANI/Downloads/truelms-main/docs/api/TrueLern-API.postman_environment.json) | Mobile/API reference environment | 38 Variables |
| [`docs/postman/TrueLern-API-Endpoint-Inventory.md`](file:///c:/Users/PABANI/Downloads/truelms-main/docs/postman/TrueLern-API-Endpoint-Inventory.md) | Exhaustive tabular inventory of all 458 action endpoints | 458 Endpoints |
| [`docs/postman/TrueLern-Complete-URL-Inventory.md`](file:///c:/Users/PABANI/Downloads/truelms-main/docs/postman/TrueLern-Complete-URL-Inventory.md) | Numbered URL inventory mapping to source files | 458 Endpoints |

---

## 3. Quickstart & Import Instructions

### Step 1: Import Files into Postman
1. Launch **Postman** (Desktop App recommended).
2. Click **Import** in the upper-left navigation bar.
3. Select and import:
   - `TrueLern_Postman_Collection.json` (or `docs/postman/TrueLern-Complete-API.postman_collection.json`)
   - `TrueLern_Local.postman_environment.json` (for local development)
   - `TrueLern_Production.postman_environment.json` (for staging/production)

### Step 2: Select the Environment
In the upper-right corner of Postman, switch the active environment from **No Environment** to:
- **`TrueLern - Local (Dev)`** when testing against `http://localhost:3000`
- **`TrueLern - Production`** when testing against `https://truelern.visital.in`

### Step 3: Run Local Backend
Ensure your local Next.js server is running:
```bash
npm run dev
```
Default URL: `http://localhost:3000`

---

## 4. Authentication Architecture & Workflows

TrueLern utilizes a robust dual-mode authentication layer enforced by edge middleware (`proxy.ts` / `middleware.ts`) and API route helpers:
- `getAuthenticatedUser(req)`: Base token verification for all users.
- `getAuthenticatedParent(req)`: Resolves Parent session and linked wards.
- `getAuthenticatedStudent(req)`: Resolves Student profile and batch context.
- `getAuthenticatedTeacher(req)`: Resolves Faculty instructor profile.
- `requireRole(...)` / `withRoles([...])`: Strict RBAC validation.

### Authentication Mechanisms
1. **HTTP Bearer Authorization Header:**
   ```http
   Authorization: Bearer {{accessToken}}
   ```
2. **HttpOnly Cookie Fallback:**
   ```http
   Cookie: accessToken={{accessToken}}; refreshToken={{refreshToken}}
   ```

### Role-Specific Authentication Flows

#### A. Standard / Parent / Admin / Teacher Email & Password Login
- **Endpoint:** `POST {{baseUrl}}/api/auth/login`
- **Request Body:**
  ```json
  {
    "email": "admin@truelern.com",
    "password": "{{adminPassword}}",
    "role": "ADMIN"
  }
  ```
- **Automated Extraction:**
  The collection's post-response test script automatically parses the JSON response and sets:
  - `pm.environment.set("accessToken", jsonData.data.token)`
  - `pm.environment.set("refreshToken", jsonData.data.refreshToken)`
  - `pm.environment.set("userId", jsonData.data.user.id)`
  - `pm.environment.set("userRole", jsonData.data.user.role)`

#### B. Mobile App Authentication (Google OAuth / Mobile OTP)
- **Google Mobile OAuth:** `POST {{baseUrl}}/api/auth/mobile/google`
  - Body: `{ "idToken": "GOOGLE_ID_TOKEN" }`
- **Mobile Refresh:** `POST {{baseUrl}}/api/auth/mobile/refresh`
  - Body: `{ "refreshToken": "{{refreshToken}}" }`
- **Mobile Logout:** `POST {{baseUrl}}/api/auth/mobile/logout`

#### C. Video Conferencing / Jitsi Meet Tokens
- **Live Class Token:** `POST {{baseUrl}}/api/live-classes/:id/token`
  - Generates signed Jitsi JWT with participant display name, avatar, and moderator flags.
  - Returns: `{ "token": "...", "roomName": "...", "jitsiDomain": "livetl.visital.in", "xmppDomain": "meet.jitsi" }`
- **Counselling Session Token:** `POST {{baseUrl}}/api/counselling/:requestId/token`
  - Time-gated access (15 minutes prior to scheduled start until scheduled end).
  - Explicitly disables recording for privacy.
- **Child Counselling Token:** `POST {{baseUrl}}/api/counselling/:requestId/child-token`
  - Scoped token for student participant under parent supervision.
- **Demo Class Token:** `POST {{baseUrl}}/api/parent/demo/:id/token` and `POST {{baseUrl}}/api/parent/demo/:id/child-token`

---

## 5. Module Hierarchy & Structure

The collection is organized into 21 functional domain modules, followed by dedicated isolation and security suites:

```text
├── 01 Authentication               (30 requests) — Login, refresh, OTP, reset password, devices, OAuth
├── 02 Parent                       (26 requests) — Dashboard, wards, progress, demo booking, account deletion
├── 03 Student                      (11 requests) — Student directory, timeline, profiles, documents
├── 04 Teacher                      (13 requests) — Faculty batches, messages, teacher directory, account deletion
├── 05 Admin                        (32 requests) — Roles, CMS, governance, portal settings, user management
├── 06 Courses                      (12 requests) — Catalog, course curriculum, categories, publishing
├── 07 Batches / Cohorts            (20 requests) — Cohort batches, student allocation, faculty assignment
├── 08 Enrollments                  (7 requests)  — Student admissions, checkout, application pipeline
├── 09 Demo / CRM                   (24 requests) — Demos, slot availability, leads, follow-ups, tasks
├── 10 Live Classes                 (31 requests) — Class scheduling, Jitsi tokens, heartbeats, recordings
├── 11 Attendance                   (11 requests) — Attendance logs, session freeze, bulk marking
├── 12 Assignments                  (15 requests) — Homework creation, submissions, grading, attachments
├── 13 Assessments                  (16 requests) — Quizzes, tests, evaluations, rubrics, question bank
├── 14 Academic Progress            (6 requests)  — Schedule-based completion metrics for students and wards
├── 15 Messaging / Communication    (7 requests)  — Parent-teacher conversation threads, unread counters
├── 16 Notifications                (12 requests) — Notification queue, push templates, delivery logs
├── 17 Finance / Invoices / Receipts(28 requests) — Invoices, fee plans, Stripe checkout, webhooks, refunds
├── 18 Certificates                 (15 requests) — Issuance, verification, PDF generation, eligibility
├── 19 Media / Uploads              (6 requests)  — Secure asset upload, preview, avatar processing
├── 20 Profile / Settings           (9 requests)  — User settings, profile updates, theme preferences
├── 21 Health / Utility / Other     (13 requests) — System health, docs-json, workflows, counselling tokens
├── Parent → Child Isolation Tests  (8 requests)  — Verifies zero multi-child data bleed across wards
├── Critical Security & Negative    (9 requests)  — 401 unauthenticated, 403 forbidden, IDOR tests
└── _DEPRECATED                     (3 requests)  — Deprecated endpoints kept for backwards compatibility
```

---

## 6. End-to-End Developer Workflows

### Workflow 1: Parent Registration, Student Onboarding & Dashboard
1. `[POST] /api/auth/login` (Login as Parent)
2. `[GET] /api/parent/children` (Retrieve list of linked wards)
3. `[POST] /api/parent/children` (Link a new child)
4. `[GET] /api/parent/children/:id/dashboard` (Inspect child dashboard, enrolled courses, and upcoming classes)
5. `[GET] /api/parent/children/:id/progress` (Fetch schedule-based progress for the child)

### Workflow 2: Course Creation, Batch Scheduling & Enrollment
1. `[POST] /api/auth/login` (Login as Admin or Academic Manager)
2. `[POST] /api/courses` (Create new course)
3. `[POST] /api/courses/:id/curriculum` (Define course syllabus and modules)
4. `[POST] /api/batches` (Create batch under course)
5. `[POST] /api/batches/:id/students` (Enroll students into batch)
6. `[POST] /api/batches/:id/teachers` (Assign faculty to batch)

### Workflow 3: Live Class Session & Video Token Lifecycle
1. `[POST] /api/live-classes` (Schedule live class with start/end time and batch ID)
2. `[POST] /api/live-classes/:id/token` (Participant requests Jitsi token 15 min before class)
3. `[POST] /api/live-classes/:id/participation` (Send participant heartbeat)
4. `[POST] /api/live-classes/recordings/finalize` (Jibri recording callback webhook)
5. `[POST] /api/live-classes/:id/complete` (Conclude live class)

### Workflow 4: Assessment & Certificate Issuance
1. `[POST] /api/assessments` (Create assessment)
2. `[POST] /api/assessments/:id/questions` (Attach questions from bank)
3. `[POST] /api/assessments/:id/start` (Student initiates test attempt)
4. `[POST] /api/assessments/:id/submit` (Student submits responses)
5. `[POST] /api/assessments/:id/evaluate` (Teacher or system evaluates score)
6. `[GET] /api/admin/certificates/eligible` (Check certificate eligibility)
7. `[POST] /api/certificates/:id/issue` (Issue signed digital certificate)

---

## 7. Automated Testing with Newman & Collection Runner

You can execute the entire collection or specific folders via Newman CLI or Postman Collection Runner.

### Running via Newman CLI
Install newman if not already present:
```bash
npm install -g newman
```

#### Run Entire Local Suite:
```bash
newman run TrueLern_Postman_Collection.json \
  -e TrueLern_Local.postman_environment.json \
  --folder "01 Authentication" \
  --reporters cli
```

#### Run Multi-Child Isolation Suite:
```bash
newman run TrueLern_Postman_Collection.json \
  -e TrueLern_Local.postman_environment.json \
  --folder "Parent → Child Isolation Tests"
```

#### Run Critical Security Suite:
```bash
newman run TrueLern_Postman_Collection.json \
  -e TrueLern_Local.postman_environment.json \
  --folder "Critical Security & Negative Tests"
```

---

## 8. Safe Execution & Production Safeguards

To prevent inadvertent data modification or accidental resource deletion in staging or production:
1. **Never run destructive endpoints in bulk:** Endpoints with `DELETE` method or `POST /api/*/delete` require explicit `confirmPhrase: "DELETE"` and password confirmation.
2. **Sanitized Production Secret:** The production environment `TrueLern_Production.postman_environment.json` has `jitsiAppSecret` sanitized to `"YOUR_PRODUCTION_JITSI_APP_SECRET"`. Replace with your real secret only in your private local Postman session.
3. **Dedicated Test Folders:** Always use the read-only inspection folders (`GET /api/public/*`, `GET /api/health`, `GET /api/courses`) when validating live connectivity.

---

## 9. Troubleshooting & Common Status Codes

| Status Code | Cause | Resolution |
| :--- | :--- | :--- |
| **401 Unauthorized** | Missing or expired `accessToken` | Execute `[POST] /api/auth/login` or `[POST] /api/auth/refresh`. Verify `{{accessToken}}` is populated in the environment. |
| **403 Forbidden** | Role mismatch (e.g. Student accessing Admin route) | Login with an account possessing the required role (`ADMIN`, `TEACHER`, `PARENT`). |
| **400 Bad Request** | Missing required fields or schema validation failure | Check the response `details` array. Verify that path variables (e.g. `:id`) contain valid 24-character MongoDB ObjectIDs. |
| **404 Not Found** | Record does not exist or invalid route URL | Verify the resource ID exists in your database. Check [`TrueLern-API-Endpoint-Inventory.md`](file:///c:/Users/PABANI/Downloads/truelms-main/docs/postman/TrueLern-API-Endpoint-Inventory.md). |
| **500 Server Error** | Unhandled exception or database connection error | Ensure MongoDB is running and `DATABASE_URL` / `MONGODB_URI` is correctly configured in `.env`. |

---

## 10. Collection Maintenance & Synchronization

When backend routes are added, modified, or deleted in `app/api/**`:
1. Run the inventory generator script to update documentation:
   ```bash
   python scripts/generate_complete_api_inventories.py
   ```
2. Run the synchronization script to propagate changes across all collection and environment files:
   ```bash
   python scripts/sync_all_postman_assets.py
   ```
3. Commit the updated JSON collections and markdown inventory files together.
