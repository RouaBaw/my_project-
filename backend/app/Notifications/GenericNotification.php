<?php

namespace App\Notifications;
// هذا Trait يساعد إذا أردت لاحقًا تشغيل الإشعارات على Queue بدل تنفيذها مباشرة.
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

/**
 * Unified data-driven notification.
 *
 * The shape of the `data` payload is intentionally flat and standard across
 * the whole application so the UI can render any notification generically:
 *
 * {
 *   "type":         "path.submitted" | "game.reviewed" | "child.finished_game" | ...
 *   "title_ar":     "...تمت مراجعة اللعبة",
 *   "body_ar":      "...تم قبول اللعبة الخاصة بك",
 *   "entity_type":  "path" | "course" | "game" | "story" | "subscription" | "quiz" | "user" | "reward",
 *   "entity_id":    123,
 *   "actor_id":     456,      // user who caused the event (nullable)
 *   "extra":        { ... 'status' => 'approved',}   // any additional context (score, status, ...)
 * }
 *
 * Currently delivered via the `database` channel only. Adding `broadcast` or
 * `fcm` later is a one-line change in `via()`; callers do not need to change.
 */
class GenericNotification extends Notification
{
    use Queueable;
// هذا يعني أن الكلاس يستقبل مصفوفة بيانات
    public function __construct(public array $payload)
    {
    }
// أرسل الإشعار عن طريق database فقط.
//  notifications يعني الإشعار سيتم تخزينه في جدول:    
// $notifiable هو الشخص أو الموديل الذي سيتلقى الإشعار.
    public function via(object $notifiable): array
    {
        return ['database'];
    }
// هذه الدالة تحدد ما هي البيانات التي سيتم تخزينها في جدول notifications.
    public function toDatabase(object $notifiable): array
    {
        return $this->payload;
    }
// هذه الدالة ترجع نفس البيانات كمصفوفة.
    public function toArray(object $notifiable): array
    {
        return $this->payload;
    }
}
