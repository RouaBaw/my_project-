<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChildSubscription;
use App\Models\SubscriptionPlan;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

class SubscriptionController extends Controller
{
    public function plans()
    {
        $plans = SubscriptionPlan::where('is_active', true)->orderBy('price')->get();

        return response()->json([
            'status' => 'success',
            'data' => $plans,
        ]);
    }

    public function myChildrenSubscriptions(Request $request)
    {
        $children = $request->user()->children()
            ->with([
                'latestChildSubscription.plan',
                'latestChildSubscription.reviewer:id,first_name,last_name',
            ])
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $children,
        ]);
    }

    public function childSubscriptions(Request $request, $childId)
    {
        $user = $request->user();
        $child = User::where('user_type', 'child')->findOrFail($childId);

        if ($user->isParent() && $child->parent_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $subscriptions = ChildSubscription::with([
            'plan',
            'child:id,first_name,last_name,parent_id',
            'parent:id,first_name,last_name',
            'reviewer:id,first_name,last_name',
        ])->where('child_id', $childId)->latest()->get();

        return response()->json([
            'status' => 'success',
            'data' => $subscriptions,
        ]);
    }

    public function store(Request $request)
    {
        $user = $request->user();
        if (!$user->isParent()) {
            return response()->json(['message' => 'Only parents can request subscriptions'], 403);
        }

        $validated = $request->validate([
            'child_id' => 'required|exists:users,id',
            'subscription_plan_id' => 'required|exists:subscription_plans,id',
            'payment_receipt' => 'required|image|mimes:jpeg,png,jpg,webp|max:4096',
            'notes' => 'nullable|string|max:1000',
        ]);

        $child = $user->children()->find($validated['child_id']);
        if (!$child) {
            return response()->json(['message' => 'الطفل غير موجود أو لا تملك صلاحية الوصول إليه'], 404);
        }

        $existing = ChildSubscription::where('child_id', $child->id)
            ->whereIn('status', ['pending', 'active'])
            ->where(function ($query) {
                $query->whereNull('ends_at')
                    ->orWhere('ends_at', '>=', now());
            })
            ->exists();

        if ($existing) {
            return response()->json([
                'message' => 'يوجد اشتراك فعّال أو طلب قيد المراجعة لهذا الطفل'
            ], 422);
        }

        $file = $request->file('payment_receipt');
        $fileName = time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
        $destination = public_path('uploads/subscriptions');
        if (!File::isDirectory($destination)) {
            File::makeDirectory($destination, 0777, true, true);
        }
        $file->move($destination, $fileName);

        $subscription = ChildSubscription::create([
            'child_id' => $child->id,
            'parent_id' => $user->id,
            'subscription_plan_id' => $validated['subscription_plan_id'],
            'status' => 'pending',
            'payment_receipt' => 'uploads/subscriptions/' . $fileName,
            'notes' => $validated['notes'] ?? null,
        ]);

        NotificationService::subscriptionRequested($subscription, $user->id);

        return response()->json([
            'message' => 'تم إرسال طلب الاشتراك بنجاح وبانتظار المراجعة',
            'data' => $subscription->load('plan'),
        ], 201);
    }

    public function cancel(Request $request, $id)
    {
        $user = $request->user();
        $subscription = ChildSubscription::with('child')->findOrFail($id);

        if ($user->isParent() && $subscription->parent_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if (!in_array($subscription->status, ['pending', 'active'], true)) {
            return response()->json(['message' => 'لا يمكن إلغاء هذا الاشتراك في حالته الحالية'], 422);
        }

        $subscription->update([
            'status' => 'cancelled',
            'ends_at' => now(),
        ]);

        return response()->json([
            'message' => 'تم إلغاء الاشتراك بنجاح',
            'data' => $subscription,
        ]);
    }

    public function reviewQueue()
    {
        $subscriptions = ChildSubscription::with([
            'plan',
            'child:id,first_name,last_name,parent_id',
            'parent:id,first_name,last_name',
            // ])->where('status', 'pending')->latest()->get();
        ])->latest()->get();

        return response()->json([
            'status' => 'success',
            'data' => $subscriptions->map(function ($subscription) {
                return array_merge($subscription->toArray(), [
                    'receipt_url' => $subscription->payment_receipt
                        ? asset($subscription->payment_receipt)
                        : null,
                ]);
            }),
        ]);
    }

    public function review(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->isContentAuditor() && !$user->isSystemAdministrator()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:active,rejected',
            'notes' => 'nullable|string|max:1000',
        ]);

        $subscription = ChildSubscription::with('plan')->findOrFail($id);

        $payload = [
            'status' => $validated['status'],
            'notes' => $validated['notes'] ?? $subscription->notes,
            'reviewed_by' => $user->id,
            'reviewed_at' => now(),
        ];

        if ($validated['status'] === 'active') {
            $payload['starts_at'] = now();
            $payload['ends_at'] = now()->addDays($subscription->plan->duration_days);
        }

        $subscription->update($payload);

        NotificationService::subscriptionReviewed($subscription, $validated['status'], $user->id);

        return response()->json([
            'message' => 'تم تحديث حالة الاشتراك بنجاح',
            'data' => $subscription->fresh(['plan', 'child', 'parent', 'reviewer']),
        ]);
    }

    public function childStatus(Request $request)
    {
        $user = $request->user();
        if (!$user->isChild()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $subscription = ChildSubscription::with('plan')
            ->where('child_id', $user->id)
            ->latest()
            ->first();

        $hasActive = $user->hasActiveSubscription();

        return response()->json([
            'status' => 'success',
            'has_active_subscription' => $hasActive,
            'data' => $subscription ? array_merge($subscription->toArray(), [
                'receipt_url' => $subscription->payment_receipt ? asset($subscription->payment_receipt) : null,
            ]) : null,
        ]);
    }
}
