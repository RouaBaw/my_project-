<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StoryQuestion extends Model
{
    protected $fillable = ['story_id', 'question'];

    public function story()
    {
        return $this->belongsTo(Story::class);
    }

    public function answers()
    {
        return $this->hasMany(StoryAnswer::class, 'question_id');
    }
    public function userAnswers()
    {
        return $this->hasMany(StoryUserAnswer::class, 'story_question_id');
    }
}
