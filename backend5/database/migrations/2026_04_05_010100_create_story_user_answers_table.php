<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('story_user_answers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('story_attempt_id')->constrained('story_attempts')->cascadeOnDelete();
            $table->foreignId('story_question_id')->constrained('story_questions')->cascadeOnDelete();
            $table->foreignId('story_answer_id')->constrained('story_answers')->cascadeOnDelete();
            $table->boolean('is_correct')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('story_user_answers');
    }
};
