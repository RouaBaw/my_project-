<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Story extends Model
{
    protected $fillable = [
        'learning_content_id',
        'title',
        'description',
        'status',
        'creator_id'
    ];

    public function contents()
    {
        return $this->hasMany(StoryContent::class)->orderBy('order');
    }

    public function questions()
    {
        return $this->hasMany(StoryQuestion::class);
    }
    // العلاقة مع صانع المحتوى
    public function creator()
    {
        return $this->belongsTo(User::class, 'creator_id');
    }
    public function course()
    {
        return $this->belongsTo(LearningContent::class);
    }
    public function learningContent()
    {
        return $this->belongsTo(LearningContent::class, 'learning_content_id');
    }
    public function attempts()
    {
        return $this->hasMany(StoryAttempt::class);
    }
}