# 📑 الدليل الفني الكامل والمواصفات الشاملة لربط الروشتات والعروض
## Prescriptions & Offers Full API Documentation & Technical Specifications

يحتوي هذا الملف الموحد على التوثيق الشامل والمواصفات الفنية النهائية لجميع الـ Endpoints الخاصة بنظام الروشتات والعروض (Replies) في مشروع **Elaaj**، بناءً على تجارب الاختبار الفعلية وتصميم واجهة المستخدم التفاعلية في تطبيق Flutter.

---

## 🔐 أولاً: ملاحظة أمنية عامة والتحقق (Authentication & Casing)

* **الـ JWT Token:** تعتمد **جميع الـ Endpoints** (سواء للمريض أو الصيدلية) على تمرير الـ JWT Token في الـ Headers كـ `Bearer Token` للتعرف على المستخدم وصلاحياته.
* **معيار أسماء المتغيرات (JSON Casing Standard):**
  > [!IMPORTANT]
  > يجب أن تكون جميع مفاتيح الـ JSON المرسلة والمستقبلة بصيغة **camelCase** (تبدأ بحرف صغير) لضمان التوافق المطلق وتجنب أي مشاكل مطابقة في تطبيق الـ Flutter.

```http
Authorization: Bearer <YOUR_JWT_TOKEN_HERE>
Content-Type: application/json
Accept: application/json
```

---

## 🔄 ثانياً: دورة حياة الطلب الكاملة (Prescription Workflow)

```
المريض يرفع روشتة  ──►  الصيدليات القريبة تراها  ──►  صيدلية تقدم عرض  ──►  المريض يقبل العرض  ──►  بدء التجهيز والمحادثة
     [POST]                      [GET]                      [POST]                  [PUT]                      [CHAT]
```

---

## 📋 ثالثاً: جدول الـ Endpoints والعمليات المشتركة

| # | Method | Endpoint | الجهة (Role) | حالة الاستخدام (Use Case) |
|---|---|---|---|---|
| 1 | `POST` | `/api/Prescriptions` | المريض (Patient) | رفع صورة روشتة جديدة مع الموقع الجغرافي والملاحظات |
| 2 | `GET` | `/api/Prescriptions/{id}` | المريض (Patient) | **[جديد ومهم]** جلب تفاصيل روشتة فردية مع عروضها لحظياً |
| 3 | `GET` | `/api/Prescriptions/my-prescriptions` | المريض (Patient) | جلب قائمة الروشتات التاريخية الخاصة بالمريض الحالي |
| 4 | `GET` | `/api/Prescriptions/nearby/{pharmacyId}` | الصيدلية (Pharmacy) | جلب الروشتات القريبة من موقع الصيدلية جغرافياً |
| 5 | `POST` | `/api/Prescriptions/{id}/replies` | الصيدلية (Pharmacy) | إرسال عرض سعر وتوافر ورسالة للروشتة المستهدفة |
| 6 | `PUT` | `/api/Prescriptions/{prescriptionId}/replies/{replyId}/accept` | المريض (Patient) | قبول عرض سعر معين وإغلاق الطلب لبدء التجهيز |
| 7 | `PATCH` | `/api/Prescriptions/{id}/status` | الصيدلية/المريض | تحديث حالة الروشتة جزئياً (مثال: الرفض بالكود `4` أو الإلغاء) |
| 8 | `PUT` | `/api/Prescriptions/{id}` | المريض (Patient) | تعديل بيانات روشتة قائمة بالكامل |
| 9 | `DELETE` | `/api/Prescriptions/{id}` | المريض (Patient) | حذف أو إلغاء روشتة نهائياً من النظام |

---

## 🔍 رابعاً: تفاصيل الـ Endpoints ومواصفات الدخل والخرج

### 1️⃣ رفع روشتة جديدة — Patient Side
* **Method:** `POST`
* **Endpoint:** `/api/Prescriptions`
* **Content-Type:** `multipart/form-data`

#### البيانات المرسلة (Form Fields):
| Field | النوع | الوصف | مثال |
|---|---|---|---|
| `File` | File | ملف صورة الروشتة المرفوعة | `prescription.jpeg` |
| `Notes` | String | ملاحظات المريض الإضافية | `"أريد البديل المحلي إذا أمكن"` |
| `Latitude` | Double | خط العرض لموقع المريض | `30.0444` |
| `Longitude` | Double | خط الطول لموقع المريض | `31.2357` |

#### Response ناجح `200 OK`:
```json
{
  "prescriptionId": "d2b757b6-69e8-466a-aec7-9efc553b3d7f",
  "message": "تم إرسال روشتتك للصيدليات القريبة بنجاح، في انتظار الردود."
}
```

---

### 2️⃣ تفاصيل روشتة فردية وعروضها لحظياً (المريض) — [هام جداً للتحديث اللحظي]
يتم استدعاء هذا المسار دورياً من تطبيق المريض (كل 5 ثوانٍ مثلاً) أثناء شاشة الانتظار للحصول على تحديثات الروشتة الحالية والعروض المقدمة عليها فوراً وبثها للواجهة.

* **Method:** `GET`
* **Endpoint Path:** `/api/Prescriptions/{id}`
* **Parameters:** `{id}`: معرف الروشتة الفريد (GUID String) في الـ Path.

#### Response ناجح `200 OK`:
```json
{
  "id": "9f1b575a-a75c-4f6d-b7da-4c68ef936c98",
  "imageUrl": "/images/prescriptions/ddf950e2-802a-401d-b70f-2905148c02a1.jpg",
  "notes": "ملاحظات المريض المكتوبة هنا",
  "createdAt": "2026-05-31T18:42:32Z",
  "isResolved": false,
  "status": 0, 
  "replies": [
    {
      "id": "98b51b0d-f599-47ee-9709-a3131d5f01b4",
      "pharmacyId": "cc29f0a9-9676-4949-5e44-08debf09c68b",
      "pharmacyName": "صيدلية الشفاء الحديثة",
      "message": "العلاج متوفر بالكامل وجاهز للشحن فوراً",
      "totalPrice": 150.0,
      "isAvailable": true,
      "createdAt": "2026-05-31T18:45:00Z"
    }
  ]
}
```

---

### 3️⃣ جلب الروشتات الكلية للمريض (Patient Side)
جلب قائمة بجميع طلبات الروشتات الخاصة بالمريض الحالي.

* **Method:** `GET`
* **Endpoint Path:** `/api/Prescriptions/my-prescriptions`
* **Query Parameters:**
  * `pageNumber` = `1`
  * `pageSize` = `100` (لضمان تحميل كافة العناصر النشطة)

#### Response ناجح `200 OK`:
```json
[
  {
    "id": "9f1b575a-a75c-4f6d-b7da-4c68ef936c98",
    "imageUrl": "/images/prescriptions/ddf950e2-802a-401d-b70f-2905148c02a1.jpg",
    "notes": "روشتة فحص أذن",
    "createdAt": "2026-05-31T18:42:32Z",
    "isResolved": false,
    "status": 1,
    "replies": [] // يجب تحميل العروض المتاحة هنا أيضاً في الاستعلام
  }
]
```

---

### 4️⃣ جلب الروشتات القريبة — Pharmacy Side
تستدعيه الصيدلية لعرض الطلبات القريبة منها جغرافياً لتقديم عروض أسعار عليها.

* **Method:** `GET`
* **Endpoint Path:** `/api/Prescriptions/nearby/{pharmacyId}`
* **Parameters:**
  * `pharmacyId` (Path): معرف الصيدلية الفريد.
  * `radius` (Query): قطر البحث بالكيلومترات (مثال: `/api/Prescriptions/nearby/cc29?radius=5`).

#### Response ناجح `200 OK`:
```json
[
  {
    "id": "d2b757b6-69e8-466a-aec7-9efc553b3d7f",
    "imageUrl": "/images/prescriptions/8fb0057e-1654-40f6-a632-77a25bb64fe1.jpeg",
    "notes": "صداع مستمر وسخونة",
    "createdAt": "2026-05-31T14:55:08Z",
    "distance": 1.62
  }
]
```

---

### 5️⃣ تقديم عرض سعر للروشتة — Pharmacy Side
تستدعيه الصيدلية لتقديم السعر، التوافر، والرسالة التوضيحية للمريض.

* **Method:** `POST`
* **Endpoint Path:** `/api/Prescriptions/{id}/replies`
* **Parameters:** `{id}` (Path): معرف الروشتة المستهدفة.

#### Request Body (JSON):
```json
{
  "prescriptionId": "d2b757b6-69e8-466a-aec7-9efc553b3d7f",
  "pharmacyId": "cc29f0a9-9676-4949-5e44-08debf09c68b",
  "message": "العلاج متوفر بالكامل وجاهز للتوصيل الفوري مع شرح الجرعات",
  "totalPrice": 120.0,
  "isAvailable": true
}
```

#### Response ناجح `200 OK`:
```json
{
  "replyId": "98b51b0d-f599-47ee-9709-a3131d5f01b4",
  "message": "تم إرسال عرضك للمريض بنجاح."
}
```

---

### 6️⃣ قبول العرض وإغلاق الطلب — Patient Side
تستدعيه واجهة المريض عند الضغط على "قبول العرض" للانتقال لمرحلة التجهيز وبدء المحادثة الفورية.

* **Method:** `PUT`
* **Endpoint Path:** `/api/Prescriptions/{prescriptionId}/replies/{replyId}/accept`
* **Request Body:** فارغ تماماً (Empty Body)

#### Response ناجح `200 OK`:
```json
{
  "message": "تم قبول العرض بنجاح وإغلاق الطلب. سيتم تجهيز طلبك من قبل الصيدلية."
}
```

---

### 7️⃣ تعديل حالة الروشتة جزئياً (تحديث الحالة) — Common Side
تغيير حالة الطلب بشكل منفصل، مثل قيام الصيدلية برفض الطلب، أو قيام المريض بإلغاء البحث.

* **Method:** `PATCH`
* **Endpoint Path:** `/api/Prescriptions/{id}/status`
* **Request Body:** رقم صحيح صريح (Integer) يمثل كود الحالة مباشرة **بدون أي أقواس أو JSON**:
  ```
  4
  ```

#### Response ناجح `200 OK`:
```json
{
  "message": "تم تحديث حالة الطلب بنجاح."
}
```

---

### 8️⃣ تعديل بيانات الروشتة بالكامل — Patient Side
* **Method:** `PUT`
* **Endpoint Path:** `/api/Prescriptions/{id}`
* **Request Body:** كائن البيانات المحدث (Notes, ImageUrl وغيرها)
* **Response ناجح `200 OK`:**
  ```json
  {
    "message": "تم تعديل الروشتة بنجاح."
  }
  ```

---

### 9️⃣ حذف الروشتة نهائياً — Patient Side
* **Method:** `DELETE`
* **Endpoint Path:** `/api/Prescriptions/{id}`
* **Request Body:** فارغ تماماً
* **Response ناجح `200 OK`:**
  ```json
  {
    "message": "تم حذف الروشتة بنجاح."
  }
  ```
> ⚠️ **تنبيه هام للـ Flutter:** بمجرد نجاح هذا الطلب، يجب فوراً إزالة الـ ID من الـ State المحلية (Cubit / Riverpod) وعمل `pop` للشاشة الحالية.

---

## 📊 خامساً: دليل أكواد الحالات (Prescription Status Enum Guide)

تم اعتماد الأرقام التالية في حقل الـ `status` لتمثيل حالات الطلب بشكل دقيق:

| الكود الرقمي | الحالة البرمجية (Enum) | المعنى والوظيفة في الواجهات |
|:---:|---|---|
| **`0`** | `Active/Searching` | جاري البحث عن صيدليات قريبة (شاشة النبض والعداد التنازلي تعمل) |
| **`1`** | `OffersReceived` | تم استلام عروض أسعار (إيقاف النبض وعرض لوحة العروض للمريض) |
| **`2`** | `Accepted/Preparing` | تم قبول عرض من المريض (بدء التجهيز وتفعيل زر الدردشة مع الصيدلية) |
| **`3`** | `Completed/Ready` | جاهز للتوصيل أو تم التسليم وإغلاق المعاملة بنجاح |
| **`4`** | `Rejected/Declined` | تم رفض أو اعتذار الصيدلية عن الطلب (عرض شاشة الاعتذار للمريض) |
| **`5`** | `Cancelled` | تم إلغاء الطلب بالكامل من قبل المريض |

---

## 🛠️ سادساً: توجيهات هندسية هامة لمطور الباك آند (Backend Developer Guidelines)

1. **تضمين علاقة الردود (Eager Loading in Entity Framework):**
   عند استدعاء طلب تفاصيل الروشتة الفردية `GET /api/Prescriptions/{id}` أو قائمة الروشتات `GET /api/Prescriptions/my-prescriptions`، تأكد تماماً من استخدام `.Include()` لتحميل العروض المرتبطة بها في الـ Database لئلا تعود قائمة العروض `replies` فارغة:
   ```csharp
   var prescription = await _context.Prescriptions
       .Include(p => p.Replies) // 🚨 مهم جداً لتحميل وتضمين قائمة العروض المضافة
       .FirstOrDefaultAsync(p => p.Id == id);
   ```

2. **صلاحيات الصيدلية والتحقق (Pharmacy Claims & Authorization):**
   عند قيام الصيدلية بإرسال عرض سعر `POST /api/Prescriptions/{id}/replies` أو تحديث الحالة، يجب التحقق برمجياً من أن حساب الصيدلي الحالي المسجل في الـ User Claims مرتبط بالفعل بالـ `pharmacyId` الممرر في الطلب لتفادي أخطاء الرفض غير المبررة مثل `400 Bad Request` أو `403 Forbidden` في بيئات الإنتاج والتمكين.

3. **الحفاظ على سلامة الحالات وتعديل الـ Status تلقائياً:**
   * عند إرسال أول عرض سعر `POST /api/Prescriptions/{id}/replies` من أي صيدلية، يجب تحديث حالة الروشتة تلقائياً في قاعدة البيانات إلى `1` (`OffersReceived`).
   * عند قبول المريض للعرض `PUT .../accept`، يجب تحديث حالة الروشتة تلقائياً في قاعدة البيانات إلى `2` (`Accepted/Preparing`).

---

## 📱 سابعاً: القواعد الذهبية للربط وإدارة الأخطاء في Flutter

### إدارة استثناءات الـ HTTP والـ 4xx Errors
يستخدم التطبيق مكتبة **Dio**. تم ضبط الكود لالتقاط أخطاء الـ Validation وتجاوزها أو عرضها بشكل ملائم للمستخدم.

```dart
try {
  final response = await dio.post('/api/Prescriptions/$id/replies', data: { ... });
  // التحقق اليدوي في الـ Client من نجاح كود الحالة لضمان الدقة
  if (response.statusCode != null && response.statusCode! >= 400) {
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: "فشلت العملية بكود: ${response.statusCode}",
    );
  }
} on DioException catch (e) {
  final errorMsg = e.response?.data?['message'] ?? "حدث خطأ أثناء الاتصال بالخادم";
  // عرض تنبيه للمستخدم بالـ errorMsg
}
```

### استخدام الـ Case-Insensitive JSON Lookup
نظراً لاختلاف حالة الأحرف أحياناً بين لغات الباك آند والفرونت آند (مثل `id` مقابل `Id` أو `status` مقابل `Status`)، ننصح باستخدام دالة استرجاع مرنة في موديل البيانات بالـ Flutter لتجنب أخطاء القيم الفارغة (Null Pointer Exceptions):

```dart
dynamic getVal(Map<String, dynamic> map, String key) {
  for (var entry in map.entries) {
    if (entry.key.toLowerCase() == key.toLowerCase()) {
      return entry.value;
    }
  }
  return null;
}
```
