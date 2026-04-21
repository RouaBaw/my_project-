<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChildSubscription extends Model
{
    protected $fillable = [
        'child_id',
        'parent_id',
        'subscription_plan_id',
        'status',
        'payment_receipt',
        'notes',
        'starts_at',
        'ends_at',
        'reviewed_by',
        'reviewed_at',
    ];

    protected $casts = [
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'reviewed_at' => 'datetime',
    ];

    public function child()
    {
        return $this->belongsTo(User::class, 'child_id');
    }

    public function parent()
    {
        return $this->belongsTo(User::class, 'parent_id');
    }

    public function plan()
    {
        return $this->belongsTo(SubscriptionPlan::class, 'subscription_plan_id');
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
