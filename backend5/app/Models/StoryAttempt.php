<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StoryAttempt extends Model
{
    protected $fillable = [
        'user_id',
        'story_id',
        'score',
        'correct_count',
        'total_questions',
    ];

    public function story()
    {
        return $this->belongsTo(Story::class);
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function answers()
    {
        return $this->hasMany(StoryUserAnswer::class, 'story_attempt_id');
    }
}
