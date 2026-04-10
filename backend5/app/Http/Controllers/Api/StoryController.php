<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Story;
use App\Models\StoryAnswer;
use App\Models\StoryAttempt;
use App\Models\StoryContent;
use App\Models\StoryQuestion;
use App\Models\StoryUserAnswer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StoryController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'learning_content_id' => 'required|exists:learning_contents,id',
            'title' => 'required|string',
            'description' => 'nullable|string',
        ]);

        $data['creator_id'] = auth()->id();
        $data['status'] = 'draft';

        $story = Story::create($data);

        return response()->json([
            'message' => 'Story created successfully',
            'data' => $story
        ], 201);
    }
    // جلب جميع القصص
    public function index()
    {
        $stories = Story::with([
            'contents',
            'questions.answers',
            'learningContent.learningPath',
            'creator:id,first_name,last_name',
        ])->latest()->get();

        return response()->json([
            'message' => 'Stories fetched successfully',
            'data' => $stories,
        ]);
    }

    public function show($id)
    {
        $story = Story::with([
            'contents',
            'questions.answers',
            'learningContent.learningPath',
            'creator:id,first_name,last_name',
        ])->findOrFail($id);

        return response()->json([
            'message' => 'Story fetched successfully',
            'data' => $story,
        ]);
    }

    public function published()
    {
        $stories = Story::with([
            'contents',
            'questions.answers',
            'learningContent.learningPath',
        ])->where('status', 'published')->latest()->get();

        return response()->json([
            'message' => 'Published stories fetched successfully',
            'data' => $stories,
        ]);
    }

    public function pending()
    {
        $stories = Story::with([
            'contents',
            'questions.answers',
            'learningContent.learningPath',
            'creator:id,first_name,last_name',
        ])->where('status', 'reviewed')->latest()->get();

        return response()->json([
            'message' => 'Pending stories fetched successfully',
            'data' => $stories,
        ]);
    }

    public function reviewQueue()
    {
        $stories = Story::with([
            'contents',
            'questions.answers',
            'learningContent.learningPath',
            'creator:id,first_name,last_name',
        ])->get();
        // ])->where('status', 'draft')->latest()->get();

        return response()->json([
            'message' => 'Story review queue fetched successfully',
            'data' => $stories,
        ]);
    }
    // جلب كل القصص التابعة لمحتوى تعليمي معيّن
    public function courseStories(Request $request, $id)
    {
        $query = Story::with([
            'contents',
            'questions.answers',
            'learningContent.learningPath',
            'creator:id,first_name,last_name',
        ])->where('learning_content_id', $id);
    // تتحقق أن القيمة موجودة في الطلب وليست سلسلة فارغة
        if ($request->filled('status')) {
            $request->validate([
                'status' => 'in:draft,reviewed,published',
            ]);
            $query->where('status', $request->status);
        }

        $stories = $query->orderByDesc('created_at')->get();

        return response()->json([
            'message' => 'Stories fetched successfully',
            'data' => $stories
        ]);
    }
    // كل القصص المنشورة التابعة للمحتوى التعليمي رقم $id، احسب لكل قصة عدد المحتويات وعدد الأسئلة
    public function playContentStories($id)
    {
        $stories = Story::withCount(['contents', 'questions'])
            ->where('learning_content_id', $id)
            ->where('status', 'published')
            ->latest()
            ->get()
            ->map(function ($story) {
                return [
                    'id' => $story->id,
                    'title' => $story->title,
                    'description' => $story->description,
                    'status' => $story->status,
                    'contents_count' => $story->contents_count,
                    'questions_count' => $story->questions_count,
                ];
            });

        return response()->json([
            'message' => 'Playable stories fetched successfully',
            'data' => $stories,
        ]);
    }
    // لقصة مع محتوياتها وأسئلتها وإجاباتها والمحتوى التعليمي المرتبط بها
    public function playStory($id)
    {
        $story = Story::with([
            'contents',
            'questions.answers',
            'learningContent:id,learning_path_id,title,course_name',
        ])->findOrFail($id);

        if ($story->status !== 'published') {
            return response()->json([
                'message' => 'القصة غير متاحة حالياً'
            ], 403);
        }
    // بعدها يبدأ بناء البيانات التي ستُرسل للواجهة:
        $payload = [
            'id' => $story->id,
            'title' => $story->title,
            'description' => $story->description,
            'status' => $story->status,
            'base_server_url' => url(''),
            'learning_content_id' => $story->learning_content_id,
            'learning_content' => $story->learningContent,
            'contents' => $story->contents->map(function ($content) {
                return [
                    'id' => $content->id,
                    'type' => $content->type,
                    'content' => $content->content,
                    'file_path' => $content->file_path,
                    'order' => $content->order,
                ];
            })->values(),
            'questions' => $story->questions->map(function ($question) {
                return [
                    'id' => $question->id,
                    'question' => $question->question,
                    'answers' => $question->answers->map(function ($answer) {
                        return [
                            'id' => $answer->id,
                            'answer' => $answer->answer,
                        ];
                    })->values(),
                ];
            })->values(),
        ];

        return response()->json([
            'message' => 'Story fetched successfully',
            'data' => $payload,
        ]);
    }
    // الطفل يرسل أجوبته على أسئلة القصة → النظام يفحصها → يحسب الدرجة → يحفظ النتيجة
    // تستقبل إجابات اللاعب على أسئلة قصة، تتحقق منها، تصححها، ثم تحفظ نتيجة المحاولة والإجابات التفصيلية في قاعدة البيانات
    public function submitStory(Request $request, $id)
    {
        $request->validate([
            'answers' => 'required|array',
            'answers.*.question_id' => 'required|exists:story_questions,id',
            'answers.*.answer_id' => 'required|exists:story_answers,id',
        ]);

        $story = Story::with('questions.answers')->findOrFail($id);

        if ($story->status !== 'published') {
            return response()->json([
                'message' => 'القصة غير متاحة حالياً'
            ], 403);
        }

        $questions = $story->questions;
        $totalQuestions = $questions->count();
        if ($totalQuestions === 0) {
            return response()->json([
                'message' => 'لا توجد أسئلة لهذه القصة'
            ], 404);
        }

        return DB::transaction(function () use ($request, $story, $questions, $totalQuestions) {
            $correctCount = 0;
            $details = [];
            //   هل السؤال الذي أرسلته موجود فعلًا ضمن أسئلة هذه القصة؟
            foreach ($request->answers as $submission) {
                $question = $questions->firstWhere('id', $submission['question_id']);
                if (!$question) {
                    return response()->json([
                        'message' => 'يوجد سؤال لا ينتمي إلى هذه القصة'
                    ], 422);
                }

                $answer = $question->answers->firstWhere('id', $submission['answer_id']);
                if (!$answer) {
                    return response()->json([
                        'message' => 'يوجد جواب لا ينتمي إلى السؤال المحدد'
                    ], 422);
                }

                $isCorrect = (bool) $answer->is_correct;
                if ($isCorrect) {
                    $correctCount++;
                }

                $details[] = [
                    'question_id' => $question->id,
                    'answer_id' => $answer->id,
                    'is_correct' => $isCorrect,
                ];
            }

            $score = ($correctCount / $totalQuestions) * 100;

            $attempt = StoryAttempt::create([
                'user_id' => auth()->id(),
                'story_id' => $story->id,
                'score' => round($score, 2),
                'correct_count' => $correctCount,
                'total_questions' => $totalQuestions,
            ]);

            foreach ($details as $detail) {
                StoryUserAnswer::create([
                    'story_attempt_id' => $attempt->id,
                    'story_question_id' => $detail['question_id'],
                    'story_answer_id' => $detail['answer_id'],
                    'is_correct' => $detail['is_correct'],
                ]);
            }

            return response()->json([
                'status' => 'success',
                'message' => 'تم تصحيح أسئلة القصة وحفظ النتيجة',
                'data' => [
                    'score' => round($score, 2),
                    'correct_count' => $correctCount,
                    'total_questions' => $totalQuestions,
                    'attempt_id' => $attempt->id,
                ],
            ]);
        });
    }

    public function update(Request $request, $id)
    {
        $story = Story::findOrFail($id);

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

    public function submitForReview($id)
    {
        $story = Story::findOrFail($id);

        if ($story->creator_id !== auth()->id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $story->update([
            'status' => 'reviewed',
        ]);

        return response()->json([
            'message' => 'تم إرسال القصة للمراجعة',
            'data' => $story,
        ]);
    }

    public function review(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:published,draft',
        ]);

        $user = auth()->user();
        if (!$user || (!$user->isContentAuditor() && !$user->isSystemAdministrator())) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $story = Story::findOrFail($id);
        $story->update([
            'status' => $request->status,
        ]);

        return response()->json([
            'message' => 'تم تحديث حالة القصة بنجاح',
            'data' => $story,
        ]);
    }

    public function destroy($id)
    {
        $story = Story::findOrFail($id);

        if (
            $story->creator_id !== auth()->id()
            && !auth()->user()?->isSystemAdministrator()
            && !auth()->user()?->isContentAuditor()
        ) {
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
        $story->update(['status' => 'published']);

        return response()->json([
            'message' => 'Story approved and published'
        ]);
    }

    public function reject($id)
    {
        $story = Story::findOrFail($id);
        $story->update(['status' => 'draft']);

        return response()->json([
            'message' => 'Story rejected'
        ]);
    }
    // التحقق من البيانات، إنشاء القصة، حفظ المحتويات والملفات، ثم حفظ الأسئلة والأجوبة داخل transaction واحدة.
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
            $story = Story::create([
                'learning_content_id' => $request->learning_content_id,
                'title' => $request->title,
                'description' => $request->description,
                'creator_id' => auth()->id(),
                'status' => 'draft'
            ]);

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

            if ($story->creator_id !== auth()->id()) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }

            $story->update([
                'title' => $request->title ?? $story->title,
                'description' => $request->description ?? $story->description,
                'status' => 'draft'
            ]);

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
