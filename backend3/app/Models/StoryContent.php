<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StoryContent extends Model
{
    protected $fillable = [
        'story_id',
        'type',
        'content',
        'file_path',
        'order'
    ];

    public function story()
    {
        return $this->belongsTo(Story::class);
    }
}
