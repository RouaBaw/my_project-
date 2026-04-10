<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GameResult;
use Illuminate\Http\Request;

class ParentReportController extends Controller
{
    public function getChildResults($childId)
    {
        // ملاحظة: يفضل هنا التأكد أن الـ childId يخص هذا الأب فعلياً
        $results = GameResult::with('game:id,title,type')
            ->where('user_id', $childId)
            ->latest()
            ->get();

        return response()->json($results);
    }
}