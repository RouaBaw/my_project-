<?php


namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Story;
use App\Models\StoryAnswer;
use App\Models\StoryContent;
use App\Models\StoryQuestion;
use DB;
use Illuminate\Http\Request;

class StoryController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'learning_path_id' => 'required|exists:learning_paths,id',
            'title' => 'required|string',
            'description' => 'nullable|string',
        ]);

        $data['creator_id'] = auth()->id(); // صانع المحتوى

        $story = Story::create($data);

        return response()->json([
            'message' => 'Story created successfully',
            'data' => $story
        ]);
    }
    public function index()
    {
        $stories = Story::with(['contents', 'questions.answers'])->get();

        return response()->json($stories);
    }

    public function show($id)
    {
        $story = Story::with(['contents', 'questions.answers'])
            ->findOrFail($id);

        return response()->json($story);
    }

    public function published()
    {
        $stories = Story::where('status', 'published')->get();

        return response()->json($stories);
    }
    public function update(Request $request, $id)
    {
        $story = Story::findOrFail($id);

        // ممكن تضيف شرط: فقط صاحب القصة يعدلها
        if ($story->creator_id !== auth()->id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $data = $request->validate([
            'title' => 'sometimes|string',
            'description' => 'nullable|string',
        ]);

        $story->update($data);

        return response()->json([
            'message' => 'Story updated',
            'data' => $story
        ]);
    }
    public function destroy($id)
    {
        $story = Story::findOrFail($id);

        // فقط صاحب القصة
        if ($story->creator_id !== auth()->id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $story->delete();

        return response()->json([
            'message' => 'Story deleted'
        ]);
    }
    public function approve($id)
    {
        $story = Story::findOrFail($id);

        $story->update([
            'status' => 'published'
        ]);

        return response()->json([
            'message' => 'Story approved and published'
        ]);
    }
    public function reject($id)
    {
        $story = Story::findOrFail($id);

        $story->update([
            'status' => 'draft'
        ]);

        return response()->json([
            'message' => 'Story rejected'
        ]);
    }
    public function pending()
    {
        $stories = Story::where('status', 'reviewed')->get();

        return response()->json($stories);
    }

    public function courseStories($id)
    {
        $stories = Story::with(['contents', 'questions.answers'])
            ->where('learning_content_id', $id)
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'message' => 'Stories fetched successfully',
            'data' => $stories
        ]);
    }

    public function storeFull(Request $request)
    {
        $request->validate([
            'learning_content_id' => 'required|exists:learning_contents,id',
            'title' => 'required|string',

            'contents' => 'required|array',
            'contents.*.type' => 'required|in:text,image,audio',

            'questions' => 'nullable|array',
            'questions.*.question' => 'required|string',
            'questions.*.answers' => 'required|array'
        ]);
        DB::beginTransaction();

        try {

            // 1. إنشاء القصة
            $story = Story::create([
                'learning_content_id' => $request->learning_content_id,
                'title' => $request->title,
                'description' => $request->description,
                'creator_id' => auth()->id(),
                'status' => 'draft'
            ]);

            // 2. إضافة المحتوى
            if ($request->has('contents')) {
                foreach ($request->contents as $index => $content) {

                    $filePath = null;

                    if (isset($content['file'])) {
                        $filePath = $content['file']->store('stories', 'public');
                    }

                    StoryContent::create([
                        'story_id' => $story->id,
                        'type' => $content['type'],
                        'content' => $content['content'] ?? null,
                        'file_path' => $filePath,
                        'order' => $index
                    ]);
                }
            }

            // 3. إضافة الأسئلة
            if ($request->has('questions')) {
                foreach ($request->questions as $q) {

                    $question = StoryQuestion::create([
                        'story_id' => $story->id,
                        'question' => $q['question']
                    ]);

                    // 4. إضافة الأجوبة
                    foreach ($q['answers'] as $a) {
                        StoryAnswer::create([
                            'question_id' => $question->id,
                            'answer' => $a['answer'],
                            'is_correct' => $a['is_correct'] ?? false
                        ]);
                    }
                }
            }

            DB::commit();

            return response()->json([
                'message' => 'Story with full content created successfully',
                'story_id' => $story->id
            ]);

        } catch (\Exception $e) {

            DB::rollBack();

            return response()->json([
                'message' => 'Error',
                'error' => $e->getMessage()
            ], 500);
        }
    }


    public function updateFull(Request $request, $id)
    {
        DB::beginTransaction();

        try {

            $story = Story::findOrFail($id);

            // 🔐 تحقق الصلاحيات
            if ($story->creator_id !== auth()->id()) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }

            // 1. تحديث القصة
            $story->update([
                'title' => $request->title ?? $story->title,
                'description' => $request->description ?? $story->description,
                'status' => 'draft' // يرجع draft بعد التعديل
            ]);

            // ==================================================
            // 2. تحديث المحتوى (نحذف القديم ونضيف الجديد)
            // ==================================================

            // حذف القديم
            $story->contents()->delete();

            if ($request->has('contents')) {
                foreach ($request->contents as $index => $content) {

                    $filePath = null;

                    if (isset($content['file'])) {
                        $filePath = $content['file']->store('stories', 'public');
                    }

                    StoryContent::create([
                        'story_id' => $story->id,
                        'type' => $content['type'],
                        'content' => $content['content'] ?? null,
                        'file_path' => $filePath,
                        'order' => $index
                    ]);
                }
            }

            // ==================================================
            // 3. تحديث الأسئلة (حذف وإعادة إنشاء)
            // ==================================================

            $story->questions()->delete();

            if ($request->has('questions')) {
                foreach ($request->questions as $q) {

                    $question = StoryQuestion::create([
                        'story_id' => $story->id,
                        'question' => $q['question']
                    ]);

                    foreach ($q['answers'] as $a) {
                        StoryAnswer::create([
                            'question_id' => $question->id,
                            'answer' => $a['answer'],
                            'is_correct' => $a['is_correct'] ?? false
                        ]);
                    }
                }
            }

            DB::commit();

            return response()->json([
                'message' => 'Story updated successfully'
            ]);

        } catch (\Exception $e) {

            DB::rollBack();

            return response()->json([
                'message' => 'Error',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
// "error": 
// "SQLSTATE[23000]: Integrity constraint violation: 19 NOT NULL constraint failed: 
// stories.learning_content_id (Connection: sqlite, SQL: insert into \"stories\" 
// (\"title\", \"description\", \"creator_id\", \"status\", \"updated_at\", \"created_at\") values
//  (123, 123, 2, draft, 2026-04-04 08:49:34, 2026-04-04 08:49:34))"
