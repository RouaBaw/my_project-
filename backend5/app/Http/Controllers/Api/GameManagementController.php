<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Game;
use Illuminate\Http\Request;

class GameManagementController extends Controller
{
    // 1. صانع المحتوى: إنشاء لعبة جديدة
    public function store(Request $request)
    {
        $validated = $request->validate([
            'learning_content_id' => 'required|exists:learning_contents,id',
            'title' => 'required|string|max:255',
            'type' => 'required|in:reorder,select_image,fill_gap,match',
            'content' => 'required|array', // لارافل سيحولها لـ JSON تلقائياً
            'settings' => 'nullable|array',
        ]);

        $game = Game::create($validated + [
            'creator_id' => auth()->id(),
            'status' => 'draft'
        ]);

        return response()->json(['message' => 'تم إنشاء اللعبة بنجاح', 'game' => $game], 201);
    }

    // 2. المدقق: مراجعة اللعبة (تحديث الحالة)
    public function updateStatus(Request $request, Game $game)
    {
        $request->validate(['status' => 'required|in:reviewed,published,draft']);

        $game->update(['status' => $request->status]);

        return response()->json(['message' => 'تم تحديث حالة اللعبة']);
    }

    // 3. الإدارة: عرض الألعاب حسب الحالة (للمدقق أو الأدمن)
    public function index(Request $request)
    {
        // إن لم يُرسل المستخدم status، اعتبره published
        $status = $request->query('status', 'published');
        $games = Game::where('status', $status)->get();
        return response()->json($games);
    }
}