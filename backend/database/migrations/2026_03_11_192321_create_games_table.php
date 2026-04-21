<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('games', function (Blueprint $table) {
            $table->id();
            $table->foreignId('learning_content_id')->constrained(); // ربط اللعبة بالكورس
            $table->string('title'); // اسم اللعبة (مثلاً: لعبة الفواكه)
            $table->enum('type', ['reorder', 'select_image', 'fill_gap', 'match']); // نوع القالب

            // هنا نضع المحتوى (الكلمات، الصور، الإجابات الصحيحة)
            $table->json('content');

            // إعدادات اللعبة (النقاط، الوقت بالثواني)
            $table->json('settings')->nullable();

            $table->enum('status', ['draft', 'reviewed', 'published'])->default('draft');
            $table->foreignId('creator_id')->references('id')->on('users'); // صانع المحتوى
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('games');
    }
};
