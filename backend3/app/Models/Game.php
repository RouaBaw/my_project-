<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Game extends Model
{
    protected $fillable = [
        'learning_content_id',
        'title',
        'type',
        'content',
        'settings',
        'status',
        'creator_id'
    ];

    // تحويل حقول الـ JSON إلى مصفوفات تلقائياً عند استدعائها
    protected $casts = [
        'content' => 'array',
        'settings' => 'array',
    ];

    // العلاقة مع الكورس
    public function course(): BelongsTo
    {
        return $this->belongsTo(LearningContent::class);
    }

    // العلاقة مع صانع المحتوى
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'creator_id');
    }

    // سجلات نتائج الأطفال لهذه اللعبة
    public function results(): HasMany
    {
        return $this->hasMany(GameResult::class);
    }
}