<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('point_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->integer('points');
            $table->enum('type', [
                'quiz_correct',
                'story_correct',
                'game_completed',
                'redemption',
                'bonus',
            ]);
            $table->string('reference_type')->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->string('note')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->unique(['type', 'reference_type', 'reference_id'], 'point_tx_unique_ref');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('point_transactions');
    }
};
