<?php

namespace App\Services;

use App\Models\ChildSubscription;
use App\Models\PointTransaction;
use App\Models\RewardRedemption;
use App\Models\SubscriptionPlan;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Central service for awarding and redeeming child points.
 *
 * Every award is idempotent – duplicated calls with the same
 * (type, reference_type, reference_id) are ignored via the unique index
 * defined on point_transactions.
 */
class PointsService
{
    public const REDEMPTION_COST = 100;

    /**
     * Award points to a user.
     *
     * @return PointTransaction|null The newly created transaction
     *                               or null if it was a duplicate.
     */
    public static function award(
        User $user,
        int $points,
        string $type,
        ?string $referenceType = null,
        ?int $referenceId = null,
        ?string $note = null
    ): ?PointTransaction {
        if ($points <= 0) {
            return null;
        }

        return DB::transaction(function () use ($user, $points, $type, $referenceType, $referenceId, $note) {
            if ($referenceType !== null && $referenceId !== null) {
                $existing = PointTransaction::where('type', $type)
                    ->where('reference_type', $referenceType)
                    ->where('reference_id', $referenceId)
                    ->first();
                if ($existing) {
                    return null;
                }
            }

            $tx = PointTransaction::create([
                'user_id'        => $user->id,
                'points'         => $points,
                'type'           => $type,
                'reference_type' => $referenceType,
                'reference_id'   => $referenceId,
                'note'           => $note,
            ]);

            $user->increment('points_balance', $points);
            $user->refresh();

            NotificationService::pointsAwarded($user, $points, $type, (int) $user->points_balance);

            return $tx;
        });
    }

    /**
     * Awards points for a completed quiz attempt.
     */
    public static function awardForQuizAttempt(User $user, int $attemptId, int $correctCount): void
    {
        if ($correctCount <= 0) {
            return;
        }
        self::award(
            $user,
            $correctCount,
            'quiz_correct',
            'quiz_attempt',
            $attemptId,
            "نقاط إجابات اختبار كورس (x{$correctCount})"
        );
    }

    /**
     * Awards points for a completed story attempt.
     */
    public static function awardForStoryAttempt(User $user, int $attemptId, int $correctCount): void
    {
        if ($correctCount <= 0) {
            return;
        }
        self::award(
            $user,
            $correctCount,
            'story_correct',
            'story_attempt',
            $attemptId,
            "نقاط إجابات أسئلة قصة (x{$correctCount})"
        );
    }

    /**
     * Awards a single point for a game finished with >= 80%.
     *
     * The game result id is used as reference to stay idempotent.
     */
    public static function awardForGameResult(User $user, int $gameResultId, int $scorePercent): void
    {
        if ($scorePercent < 80) {
            return;
        }
        self::award(
            $user,
            1,
            'game_completed',
            'game_result',
            $gameResultId,
            'نقطة إتمام لعبة بامتياز'
        );
    }

    /**
     * Redeem 100 points against a one-month free subscription.
     */
    public static function redeemMonthlyPlan(User $child): array
    {
        if (!$child->isChild()) {
            return [
                'ok'      => false,
                'message' => 'الاستبدال متاح للأطفال فقط',
                'code'    => 403,
            ];
        }

        if ((int) $child->points_balance < self::REDEMPTION_COST) {
            return [
                'ok'      => false,
                'message' => 'رصيد النقاط غير كافٍ. تحتاج ' . self::REDEMPTION_COST . ' نقطة.',
                'code'    => 422,
            ];
        }

        if ($child->hasActiveSubscription()) {
            return [
                'ok'      => false,
                'message' => 'لديك اشتراك فعّال بالفعل، لا يمكن الاستبدال حالياً.',
                'code'    => 422,
            ];
        }

        $plan = SubscriptionPlan::where('is_active', true)
            ->orderBy('price', 'asc')
            ->first();
        if (!$plan) {
            return [
                'ok'      => false,
                'message' => 'لا توجد خطة اشتراك متاحة حالياً.',
                'code'    => 500,
            ];
        }

        return DB::transaction(function () use ($child, $plan) {
            $subscription = ChildSubscription::create([
                'child_id'             => $child->id,
                'parent_id'            => $child->parent_id ?? $child->id,
                'subscription_plan_id' => $plan->id,
                'status'               => 'active',
                'notes'                => 'تم الحصول عليه عبر استبدال ' . self::REDEMPTION_COST . ' نقطة',
                'starts_at'            => now(),
                'ends_at'              => now()->addDays(30),
            ]);

            $redemption = RewardRedemption::create([
                'child_id'              => $child->id,
                'points_spent'          => self::REDEMPTION_COST,
                'subscription_plan_id'  => $plan->id,
                'child_subscription_id' => $subscription->id,
            ]);

            PointTransaction::create([
                'user_id'        => $child->id,
                'points'         => -self::REDEMPTION_COST,
                'type'           => 'redemption',
                'reference_type' => 'reward_redemption',
                'reference_id'   => $redemption->id,
                'note'           => 'استبدال 100 نقطة بشهر اشتراك مجاني',
            ]);

            $child->decrement('points_balance', self::REDEMPTION_COST);
            $child->refresh();

            NotificationService::rewardRedeemed($child, $redemption);

            return [
                'ok'           => true,
                'message'      => 'تمت عملية الاستبدال بنجاح',
                'redemption'   => $redemption->load('childSubscription.plan'),
                'new_balance'  => (int) $child->points_balance,
            ];
        });
    }
}
