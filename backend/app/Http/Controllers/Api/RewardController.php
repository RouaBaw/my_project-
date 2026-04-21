<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PointTransaction;
use App\Models\RewardRedemption;
use App\Models\User;
use App\Services\PointsService;
use Illuminate\Http\Request;

class RewardController extends Controller
{
    /**
     * GET /api/my-points
     * Returns current balance + latest 20 point transactions for the child.
     */
    public function myPoints(Request $request)
    {
        $user = $request->user();
        if (!$user->isChild()) {
            return response()->json(['message' => 'هذه الخدمة للأطفال فقط'], 403);
        }

        $transactions = PointTransaction::where('user_id', $user->id)
            ->latest()
            ->limit(20)
            ->get();

        return response()->json([
            'status'       => 'success',
            'balance'      => (int) $user->points_balance,
            'goal'         => PointsService::REDEMPTION_COST,
            'can_redeem'   => (int) $user->points_balance >= PointsService::REDEMPTION_COST,
            'transactions' => $transactions,
        ]);
    }

    /**
     * GET /api/children/{id}/points
     * For parents / admins / auditors to view a child's balance.
     */
    public function childPoints(Request $request, int $id)
    {
        $user = $request->user();
        $child = User::where('user_type', 'child')->findOrFail($id);

        if ($user->isParent() && $child->parent_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        if ($user->isChild() && $user->id !== $child->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $transactions = PointTransaction::where('user_id', $child->id)
            ->latest()
            ->limit(50)
            ->get();

        return response()->json([
            'status'       => 'success',
            'child'        => $child->only(['id', 'first_name', 'last_name', 'points_balance']),
            'balance'      => (int) $child->points_balance,
            'goal'         => PointsService::REDEMPTION_COST,
            'transactions' => $transactions,
        ]);
    }

    /**
     * POST /api/rewards/redeem
     * Redeem REDEMPTION_COST points against a one-month free subscription.
     */
    public function redeem(Request $request)
    {
        $user = $request->user();
        if (!$user->isChild()) {
            return response()->json(['message' => 'الاستبدال متاح للأطفال فقط'], 403);
        }

        $result = PointsService::redeemMonthlyPlan($user);

        if (!($result['ok'] ?? false)) {
            return response()->json([
                'status'  => 'error',
                'message' => $result['message'] ?? 'تعذر إجراء الاستبدال',
            ], $result['code'] ?? 422);
        }

        return response()->json([
            'status'      => 'success',
            'message'     => $result['message'],
            'data'        => $result['redemption'],
            'new_balance' => $result['new_balance'],
        ]);
    }

    /**
     * GET /api/rewards/history
     * Authenticated child's redemption history.
     */
    public function history(Request $request)
    {
        $user = $request->user();
        if (!$user->isChild()) {
            return response()->json(['message' => 'الخدمة للأطفال فقط'], 403);
        }
        $history = RewardRedemption::with(['subscriptionPlan', 'childSubscription'])
            ->where('child_id', $user->id)
            ->latest()
            ->get();

        return response()->json([
            'status' => 'success',
            'data'   => $history,
        ]);
    }
}
