<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('subscription_plans', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('billing_cycle', ['monthly', 'yearly']);
            $table->decimal('price', 10, 2);
            $table->unsignedInteger('duration_days');
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        DB::table('subscription_plans')->insert([
            [
                'name' => 'الاشتراك الشهري',
                'billing_cycle' => 'monthly',
                'price' => 15.00,
                'duration_days' => 30,
                'description' => 'اشتراك شهري لطفل واحد مع وصول كامل إلى محتوى التطبيق.',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'الاشتراك السنوي',
                'billing_cycle' => 'yearly',
                'price' => 120.00,
                'duration_days' => 365,
                'description' => 'اشتراك سنوي لطفل واحد بسعر أوفر مع وصول كامل إلى المحتوى.',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_plans');
    }
};
