<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RewardRedemption extends Model
{
    protected $fillable = [
        'child_id',
        'points_spent',
        'subscription_plan_id',
        'child_subscription_id',
    ];

    public function child()
    {
        return $this->belongsTo(User::class, 'child_id');
    }

    public function subscriptionPlan()
    {
        return $this->belongsTo(SubscriptionPlan::class, 'subscription_plan_id');
    }

    public function childSubscription()
    {
        return $this->belongsTo(ChildSubscription::class, 'child_subscription_id');
    }
}
