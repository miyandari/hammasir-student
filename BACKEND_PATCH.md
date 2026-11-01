# وصله‌ی بک‌اند (اختیاری ولی توصیه‌شده)

۱. فایل `backend/app/api/student_self.py` را در پروژه‌ی بک‌اند به `app/api/student_self.py` کپی کنید.

۲. در `app/main.py` دو خط اضافه کنید. **مهم:** include آن باید **قبل از** `students_router` باشد
(وگرنه `/students/me` را مسیر `/students/{student_id}` می‌بلعد):

```python
from app.api.student_self import router as student_self_router
...
app.include_router(student_self_router)   # قبل از students_router
app.include_router(students_router)
```

۳. سرور را دوباره اجرا کنید. مسیرهای جدید (همه فقط خواندنی):
- `GET /students/me` — وضعیت دانشجو (تخلف، مسدودی، جنسیت)
- `GET /students/me/qr` — توکن QR
- `GET /trips/{trip_id}/availability` — ظرفیت باقی‌مانده

این مسیرها فقط با import و openapi بررسی شده‌اند، نه با دیتابیس واقعی؛ لطفاً در `/docs` امتحان کنید.
