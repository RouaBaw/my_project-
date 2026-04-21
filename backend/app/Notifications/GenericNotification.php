<?php

namespace App\Notifications;

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
 *   "title_ar":     "...",
 *   "body_ar":      "...",
 *   "entity_type":  "path" | "course" | "game" | "story" | "subscription" | "quiz" | "user" | "reward",
 *   "entity_id":    123,
 *   "actor_id":     456,      // user who caused the event (nullable)
 *   "extra":        { ... }   // any additional context (score, status, ...)
 * }
 *
 * Currently delivered via the `database` channel only. Adding `broadcast` or
 * `fcm` later is a one-line change in `via()`; callers do not need to change.
 */
class GenericNotification extends Notification
{
    use Queueable;

    public function __construct(public array $payload)
    {
    }

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        return $this->payload;
    }

    public function toArray(object $notifiable): array
    {
        return $this->payload;
    }
}
