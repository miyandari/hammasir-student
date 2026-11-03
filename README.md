# هم‌مسیر — اپ دانشجو

اپ Flutter دانشجو برای سرویس ایاب‌وذهاب «هم‌مسیر». فقط فارسی (RTL)، حالت روشن/تیره، بدون پکیج مدیریت وضعیت.

## راه‌اندازی (پروژه‌ی جدید)

```powershell
flutter create --org ir.hammasir --project-name hammasir_student --platforms android,ios hammasir_student
cd hammasir_student
```

سپس از این بسته **این‌ها را روی پروژه‌ی تازه کپی کنید (جایگزین شوند)**:
`lib/` ، `test/` ، `assets/` ، `pubspec.yaml` ، `analysis_options.yaml` ، `flutter_launcher_icons.yaml`
و فایل پیش‌فرض `test/widget_test.dart` را **پاک کنید**.

```powershell
flutter pub get
flutter analyze
flutter test
```

## مجوزها

**android/app/src/main/AndroidManifest.xml** (داخل `<manifest>` و بیرون از `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

برای کار با سرور `http://` در توسعه، در تگ `<application>` اضافه کنید:
`android:usesCleartextTraffic="true"` (در نسخه‌ی نهایی با https حذف شود).

**android/app/build.gradle(.kts)**: `minSdk` را حداقل `23` بگذارید (برای ذخیره‌ی امن توکن و اسکنر).

**ios/Runner/Info.plist**:

```xml
<key>NSCameraUsageDescription</key>
<string>برای اسکن QR ایستگاه به دوربین نیاز است.</string>
```

### مجوزهای نسخه‌ی ۲ (اثر انگشت، عکس پروفایل)

- **android/app/src/main/AndroidManifest.xml**: `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`
- **MainActivity.kt**: به‌جای `FlutterActivity` از `FlutterFragmentActivity` ارث‌بری کند (الزام local_auth).
- **android/app/src/main/res/values/styles.xml** (و values-night): والد `LaunchTheme` و `NormalTheme` را یک تم AppCompat/`Theme.AppCompat.DayNight.NoActionBar` بگذارید.
- **ios/Runner/Info.plist**: `NSFaceIDUsageDescription` و `NSPhotoLibraryUsageDescription` را با متن دلخواه اضافه کنید.
- مسیریابی خیابانی از OSRM می‌آید (آدرس پیش‌فرض نمایشی است و ممکن است در دسترس نباشد؛ در این حالت خط مستقیم رسم می‌شود). برای سرور خودتان: `--dart-define=ROUTING_URL=https://...`
- **موقعیت من (geolocator)**: در AndroidManifest دو مجوز `ACCESS_FINE_LOCATION` و `ACCESS_COARSE_LOCATION` را اضافه کنید؛ در iOS کلید `NSLocationWhenInUseUsageDescription` را در Info.plist.
- **اعلان‌ها**: انتخاب «نوتیفیکیشن دستگاه / فقط داخل برنامه» برای هر دسته ذخیره می‌شود، ولی ارسال نوتیفیکیشن وقتی اپ بسته است نیاز به سرویس push (مثل FCM) و ارسال از بک‌اند دارد که هنوز ساخته نشده است.
- عکس پروفایل فعلاً فقط روی همین دستگاه ذخیره می‌شود.

## اجرا

بک‌اند باید روی پورت ۸۰۰۰ اجرا باشد (`uvicorn app.main:app --host 0.0.0.0 --port 8000`).

```powershell
# امولاتور اندروید
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# گوشی واقعی با کابل
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## آیکون

```powershell
dart run flutter_launcher_icons
```

## بک‌اند

اپ با بک‌اند فعلی هم کار می‌کند، ولی سه قابلیت با `backend/app/api/student_self.py` کامل می‌شود
(راهنما: `BACKEND_PATCH.md`): کارت وضعیت و مسدودی دانشجو، ظرفیت باقی‌مانده‌ی سفر، و فیلتر سرویس بر اساس جنسیت.

## ساختار

```
lib/
  app/        ریشه‌ی اپ، وابستگی‌ها (Deps)، ذخیره‌گاه‌های مشترک (Stores)، قاب تب‌ها
  core/       پیکربندی، شبکه (ApiClient)، ذخیره‌سازی، تم، ابزارها، ویجت‌های پایه
  data/       مدل‌ها و ریپازیتوری‌ها (تنها جایی که API صدا زده می‌شود)
  state/      کنترلرهای ChangeNotifier (نشست، تم، رزروها، اعلان‌ها)
  features/   صفحه‌ها به تفکیک قابلیت (auth, home, reserve, trip, qr, ...)
```

قواعد: صفحه‌ها مستقیم `http` صدا نمی‌زنند؛ هر فایل کوچک و تک‌مسئولیتی است؛ همه‌ی خطاها `ApiException` فارسی‌اند.

## نکات شناخته‌شده

- موقعیت زنده از WebSocket می‌آید و توکن در آدرس اتصال است (محدودیت بک‌اند). با قطع اتصال، اپ هر ۱۵ ثانیه polling می‌کند.
- تایل نقشه از سرور عمومی OpenStreetMap است؛ برای انتشار عمومی سرویس تایل مناسب بگیرید (`AppConfig.tileUrl`).
- داده‌ی آفلاین فقط در حافظه است (با بستن اپ پاک می‌شود)؛ در حالت قطعی، آخرین اطلاعات همراه نوار هشدار نمایش داده می‌شود.
