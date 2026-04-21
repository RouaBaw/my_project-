<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StoryUserAnswer extends Model
{
    protected $fillable = [
        'story_attempt_id',
        'story_question_id',
        'story_answer_id',
        'is_correct',
    ];

    public function attempt()
    {
        return $this->belongsTo(StoryAttempt::class, 'story_attempt_id');
    }

    public function question()
    {
        return $this->belongsTo(StoryQuestion::class, 'story_question_id');
    }

    public function answer()
    {
        return $this->belongsTo(StoryAnswer::class, 'story_answer_id');
    }
}
