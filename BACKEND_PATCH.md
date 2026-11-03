# پچ بک‌اند: اعلان برای رزرو و لغو

اعلان‌ها خالی بودند چون بک‌اند هنگام رزرو/لغو هیچ اعلانی نمی‌سازد.
در `app/services/reservation_service.py`:

```python
from app.services.notification_service import create_notification_for_student
```

داخل `create_reservation` بعد از `db.refresh(reservation)`:

```python
create_notification_for_student(
    db, student_id=student.id, notification_type="reservation",
    title="رزرو ثبت شد" if reservation.status == "active" else "در لیست انتظار",
    message="رزرو شما ثبت شد." if reservation.status == "active"
            else "شما در لیست انتظار قرار گرفتید.",
    data={"trip_id": trip.id, "reservation_id": reservation.id},
)
db.commit()
```

داخل `cancel_reservation` قبل از `db.commit()`:

```python
create_notification_for_student(
    db, student_id=reservation.student_id, notification_type="reservation",
    title="رزرو لغو شد", message="رزرو شما لغو شد.",
    data={"trip_id": trip.id, "reservation_id": reservation.id},
)
```

(تابع فقط flush می‌کند؛ commit بعدش لازم است.) مقدار `notification_type` را با enum/قیدهای مدل Notification چک کنید.
نیاز به `backend/app/api/student_self.py` از زیپ قبلی هم باقی است (جنسیت از `/students/me`).
