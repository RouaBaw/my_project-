<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Game;
use App\Models\GameResult;
use Illuminate\Http\Request;

class GamePlayController extends Controller
{
    // الطفل: جلب بيانات لعبة معينة للبدء باللعب
    public function show(Game $game)
    {
        if ($game->status !== 'published') {
            return response()->json(['message' => 'اللعبة غير متاحة حالياً'], 403);
        }
        return response()->json($game);
    }

    // الطفل: إرسال النتيجة بعد انتهاء اللعبة
    public function submitResult(Request $request, Game $game)
    {
        $validated = $request->validate([
            'score' => 'required|integer',
            'time_taken' => 'required|integer', // بالثواني
        ]);

        $result = GameResult::create([
            'game_id' => $game->id,
            'user_id' => auth()->id(), // الطفل المسجل دخوله
            'score' => $validated['score'],
            'time_taken' => $validated['time_taken'],
            'is_completed' => true
        ]);

        return response()->json(['message' => 'تم حفظ النتيجة بنجاح', 'result' => $result]);
    }
}