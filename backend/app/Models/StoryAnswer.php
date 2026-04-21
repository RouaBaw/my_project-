<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StoryAnswer extends Model
{
    protected $fillable = ['question_id', 'answer', 'is_correct'];

    public function question()
    {
        return $this->belongsTo(StoryQuestion::class, 'question_id');
    }
    public function userAnswers()
    {
        return $this->hasMany(StoryUserAnswer::class, 'story_answer_id');
    }
}