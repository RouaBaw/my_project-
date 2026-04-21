<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MediaController extends Controller
{
    public function upload(Request $request)
    {
        // 1. التحقق من الملف (الحجم والنوع)
        $request->validate([
            'file' => 'required|image|mimes:jpeg,png,jpg,webp|max:2048', // حد أقصى 2 ميجا
        ]);

        if ($request->hasFile('file')) {
            // 2. تخزين الملف في مجلد storage/app/public/games
            $path = $request->file('file')->store('games', 'public');

            // 3. توليد الرابط الكامل للصورة
            $url = asset('storage/' . $path);

            return response()->json([
                'success' => true,
                'url' => $url,
                'path' => $path // نحتفظ بالمسار النسبي للاحتياط
            ], 201);
        }

        return response()->json(['error' => 'لم يتم رفع أي ملف'], 400);
    }
}