<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GameResult extends Model
{
    protected $fillable = [
        'game_id',
        'user_id',
        'score',
        'time_taken',
        'is_completed'
    ];

    // الوصول لبيانات اللعبة (اسمها، نوعها) من خلال النتيجة
    public function game(): BelongsTo
    {
        return $this->belongsTo(Game::class);
    }

    // الطفل الذي لعب
    public function student(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}