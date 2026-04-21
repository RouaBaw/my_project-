<?php

namespace App\Services;

use App\Models\User;
use App\Notifications\GenericNotification;
use Illuminate\Support\Facades\Notification as NotificationFacade;

/**
 * Central orchestrator for system notifications.
 *
 * Every public method builds a uniform payload and dispatches
 * GenericNotification via Laravel Notifications (database channel).
 */
class NotificationService
{
    /* ======================================================================
     *  Recipients helpers
     * ====================================================================== */

    protected static function admins(): \Illuminate\Support\Collection
    {
        return User::where('user_type', 'system_administrator')->get();
    }

    protected static function auditors(): \Illuminate\Support\Collection
    {
        return User::where('user_type', 'content_auditor')->get();
    }

    protected static function adminsAndAuditors(): \Illuminate\Support\Collection
    {
        return User::whereIn('user_type', ['system_administrator', 'content_auditor'])->get();
    }

    /* ======================================================================
     *  Low level senders
     * ====================================================================== */

    protected static function send($recipients, array $payload, ?int $actorId = null): void
    {
        if (empty($payload['actor_id']) && $actorId) {
            $payload['actor_id'] = $actorId;
        }

        if ($recipients instanceof \Illuminate\Support\Collection) {
            if ($actorId) {
                $recipients = $recipients->filter(fn ($u) => $u->id !== $actorId);
            }
            if ($recipients->isEmpty()) {
                return;
            }
        } elseif ($recipients instanceof User) {
            if ($actorId && $recipients->id === $actorId) {
                return;
            }
        } elseif (!$recipients) {
            return;
        }

        NotificationFacade::send($recipients, new GenericNotification($payload));
    }

    /* ======================================================================
     *  High level events – System / Admin & Auditor
     * ====================================================================== */

    public static function newUserRegistered(User $user): void
    {
        self::send(self::admins(), [
            'type'        => 'user.registered',
            'title_ar'    => 'تسجيل مستخدم جديد',
            'body_ar'     => "قام {$user->first_name} {$user->last_name} بإنشاء حساب جديد كـ {$user->user_type} وبانتظار المراجعة.",
            'entity_type' => 'user',
            'entity_id'   => $user->id,
            'actor_id'    => $user->id,
            'extra'       => [
                'user_type'      => $user->user_type,
                'account_status' => $user->account_status,
            ],
        ], $user->id);
    }

    public static function pathSubmittedForReview($path, ?int $creatorId): void
    {
        self::send(self::adminsAndAuditors(), [
            'type'        => 'path.submitted',
            'title_ar'    => 'مسار تعليمي جديد للمراجعة',
            'body_ar'     => "تمت إضافة مسار تعليمي جديد «{$path->title}» وينتظر المراجعة.",
            'entity_type' => 'path',
            'entity_id'   => $path->id,
            'actor_id'    => $creatorId,
        ], $creatorId);
    }

    public static function courseSubmittedForReview($course, ?int $creatorId): void
    {
        self::send(self::adminsAndAuditors(), [
            'type'        => 'course.submitted',
            'title_ar'    => 'كورس جديد للمراجعة',
            'body_ar'     => "تمت إضافة كورس جديد «" . ($course->course_name ?? $course->title ?? '—') . "» وينتظر المراجعة.",
            'entity_type' => 'course',
            'entity_id'   => $course->id,
            'actor_id'    => $creatorId,
            'extra'       => [
                'learning_path_id' => $course->learning_path_id ?? null,
            ],
        ], $creatorId);
    }

    public static function gameSubmittedForReview($game, ?int $creatorId): void
    {
        self::send(self::adminsAndAuditors(), [
            'type'        => 'game.submitted',
            'title_ar'    => 'لعبة جديدة للمراجعة',
            'body_ar'     => "تمت إضافة لعبة جديدة «{$game->title}» وتنتظر الموافقة.",
            'entity_type' => 'game',
            'entity_id'   => $game->id,
            'actor_id'    => $creatorId,
            'extra'       => [
                'learning_content_id' => $game->learning_content_id ?? null,
            ],
        ], $creatorId);
    }

    public static function storySubmittedForReview($story, ?int $creatorId): void
    {
        self::send(self::adminsAndAuditors(), [
            'type'        => 'story.submitted',
            'title_ar'    => 'قصة جديدة للمراجعة',
            'body_ar'     => "تمت إضافة قصة جديدة «{$story->title}» وتنتظر المراجعة.",
            'entity_type' => 'story',
            'entity_id'   => $story->id,
            'actor_id'    => $creatorId,
        ], $creatorId);
    }

    public static function subscriptionRequested($subscription, ?int $actorId): void
    {
        self::send(self::adminsAndAuditors(), [
            'type'        => 'subscription.requested',
            'title_ar'    => 'طلب اشتراك جديد',
            'body_ar'     => 'تم استلام طلب اشتراك جديد وينتظر المراجعة.',
            'entity_type' => 'subscription',
            'entity_id'   => $subscription->id,
            'actor_id'    => $actorId,
            'extra'       => [
                'child_id'             => $subscription->child_id,
                'parent_id'            => $subscription->parent_id,
                'subscription_plan_id' => $subscription->subscription_plan_id,
            ],
        ], $actorId);
    }

    /* ======================================================================
     *  High level events – Content Creator
     * ====================================================================== */

    public static function contentReviewed(?int $creatorId, string $entityType, $entity, string $decision, ?int $actorId = null): void
    {
        if (!$creatorId) {
            return;
        }
        $creator = User::find($creatorId);
        if (!$creator) {
            return;
        }

        $titles = [
            'path'    => 'مسار تعليمي',
            'course'  => 'كورس',
            'game'    => 'لعبة',
            'story'   => 'قصة',
        ];
        $label = $titles[$entityType] ?? 'محتوى';
        $name  = $entity->title ?? $entity->course_name ?? '—';
        $decisionAr = match ($decision) {
            'published' => 'تمت الموافقة',
            'rejected'  => 'تم الرفض',
            'draft'     => 'تم إرجاعه كمسودة',
            default     => $decision,
        };

        self::send($creator, [
            'type'        => "{$entityType}.reviewed",
            'title_ar'    => "نتيجة مراجعة {$label}",
            'body_ar'     => "{$decisionAr} على {$label} «{$name}».",
            'entity_type' => $entityType,
            'entity_id'   => $entity->id,
            'actor_id'    => $actorId,
            'extra'       => [
                'decision' => $decision,
            ],
        ], $actorId);
    }

    /* ======================================================================
     *  High level events – Parent
     * ====================================================================== */

    public static function childFinishedActivity(User $child, string $activityType, $entity, array $extra = []): void
    {
        if (!$child->parent_id) {
            return;
        }
        $parent = User::find($child->parent_id);
        if (!$parent) {
            return;
        }

        $typesAr = [
            'quiz'  => 'اختبار الكورس',
            'story' => 'أسئلة القصة',
            'game'  => 'اللعبة',
        ];
        $label = $typesAr[$activityType] ?? $activityType;
        $name  = $entity->title ?? $entity->course_name ?? '';
        $childFull = trim("{$child->first_name} {$child->last_name}");

        self::send($parent, [
            'type'        => "child.finished_{$activityType}",
            'title_ar'    => 'نشاط جديد لطفلك',
            'body_ar'     => trim("أنهى {$childFull} {$label} " . ($name ? "«{$name}»" : '') . '.'),
            'entity_type' => $activityType,
            'entity_id'   => $entity->id ?? null,
            'actor_id'    => $child->id,
            'extra'       => array_merge([
                'child_id'   => $child->id,
                'child_name' => $childFull,
            ], $extra),
        ], $child->id);
    }

    public static function subscriptionReviewed($subscription, string $decision, ?int $actorId = null): void
    {
        $parent = User::find($subscription->parent_id);
        if (!$parent) {
            return;
        }
        $decisionAr = $decision === 'active' ? 'تمت الموافقة على اشتراك طفلك' : 'تم رفض طلب اشتراك طفلك';
        self::send($parent, [
            'type'        => 'subscription.reviewed',
            'title_ar'    => 'نتيجة مراجعة الاشتراك',
            'body_ar'     => $decisionAr,
            'entity_type' => 'subscription',
            'entity_id'   => $subscription->id,
            'actor_id'    => $actorId,
            'extra'       => [
                'decision' => $decision,
                'child_id' => $subscription->child_id,
            ],
        ], $actorId);
    }

    /* ======================================================================
     *  High level events – Child (points / rewards)
     * ====================================================================== */

    public static function pointsAwarded(User $child, int $points, string $reason, int $newBalance): void
    {
        self::send($child, [
            'type'        => 'points.awarded',
            'title_ar'    => 'لقد ربحت نقاطاً جديدة!',
            'body_ar'     => "حصلت على {$points} نقطة. رصيدك الحالي: {$newBalance}.",
            'entity_type' => 'reward',
            'entity_id'   => $child->id,
            'actor_id'    => null,
            'extra'       => [
                'points'      => $points,
                'reason'      => $reason,
                'new_balance' => $newBalance,
            ],
        ]);
    }

    public static function rewardRedeemed(User $child, $redemption): void
    {
        self::send($child, [
            'type'        => 'reward.redeemed',
            'title_ar'    => 'تم استبدال النقاط',
            'body_ar'     => 'لقد حصلت على اشتراك مجاني لمدة شهر كامل!',
            'entity_type' => 'reward',
            'entity_id'   => $redemption->id,
            'actor_id'    => $child->id,
            'extra'       => [
                'points_spent'          => $redemption->points_spent,
                'subscription_plan_id'  => $redemption->subscription_plan_id,
                'child_subscription_id' => $redemption->child_subscription_id,
            ],
        ]);

        if ($child->parent_id) {
            $parent = User::find($child->parent_id);
            if ($parent) {
                $childFull = trim("{$child->first_name} {$child->last_name}");
                self::send($parent, [
                    'type'        => 'reward.redeemed',
                    'title_ar'    => 'استبدال مكافأة',
                    'body_ar'     => "استبدل {$childFull} نقاطه بشهر اشتراك مجاني.",
                    'entity_type' => 'reward',
                    'entity_id'   => $redemption->id,
                    'actor_id'    => $child->id,
                    'extra'       => [
                        'child_id' => $child->id,
                    ],
                ]);
            }
        }

        self::send(self::admins(), [
            'type'        => 'reward.redeemed',
            'title_ar'    => 'استبدال نقاط جديدة',
            'body_ar'     => 'قام أحد الأطفال باستبدال نقاطه باشتراك مجاني.',
            'entity_type' => 'reward',
            'entity_id'   => $redemption->id,
            'actor_id'    => $child->id,
            'extra'       => [
                'child_id' => $child->id,
            ],
        ], $child->id);
    }
}
