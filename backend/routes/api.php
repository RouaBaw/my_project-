<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ContentPackageController;
use App\Http\Controllers\Api\EducationalPathController;
use App\Http\Controllers\Api\GameManagementController;
use App\Http\Controllers\Api\GamePlayController;
use App\Http\Controllers\Api\LearningContentController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ParentReportController;
use App\Http\Controllers\MediaController;
use App\Http\Controllers\Api\QuizController;
use App\Http\Controllers\Api\RatingController;
use App\Http\Controllers\Api\RewardController;
use App\Http\Controllers\Api\SubscriptionController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\StoryController;
// مسارات المصادقة العامة (لا تحتاج توكن)
Route::post('register', [AuthController::class, 'register']);
Route::post('login', [AuthController::class, 'login']);
// Route::post('login/child', [AuthController::class, 'loginChild']); // دخول الأطفال بالـ PIN

// المسارات التي تتطلب مصادقة (يجب إرسال التوكن مع الطلب)
Route::middleware('auth:sanctum')->group(function () {

    Route::post('/stories', [StoryController::class, 'store']);
    Route::get('/stories/{id}', [StoryController::class, 'show']);
    Route::put('/stories/{id}', [StoryController::class, 'update']);
    Route::delete('/stories/{id}', [StoryController::class, 'destroy']);
    Route::get('/stories', [StoryController::class, 'published']); // المنشورة
    Route::get('/stories-pending', [StoryController::class, 'pending']); // قيد المراجعة
    Route::post('/stories/{id}/approve', [StoryController::class, 'approve']);
    Route::post('/stories/{id}/reject', [StoryController::class, 'reject']);
    Route::post('/stories/full', [StoryController::class, 'storeFull']);
    Route::post('/stories/{id}/full-update', [StoryController::class, 'updateFull']);
    Route::get('/courses_stories/{id}', [StoryController::class, 'courseStories']);
    Route::get('/stories-review-queue', [StoryController::class, 'reviewQueue']);
    Route::post('/stories/{id}/submit', [StoryController::class, 'submitForReview']);
    Route::post('/stories/{id}/review', [StoryController::class, 'review']);
    Route::get('/play/content/{id}/stories', [StoryController::class, 'playContentStories']);
    Route::get('/play/stories/{id}', [StoryController::class, 'playStory']);
    Route::post('/play/stories/{id}/submit', [StoryController::class, 'submitStory']);
    Route::get('/subscription-plans', [SubscriptionController::class, 'plans']);
    Route::get('/my-children-subscriptions', [SubscriptionController::class, 'myChildrenSubscriptions']);
    Route::get('/children/{id}/subscriptions', [SubscriptionController::class, 'childSubscriptions']);
    Route::post('/child-subscriptions', [SubscriptionController::class, 'store']);
    Route::patch('/child-subscriptions/{id}/cancel', [SubscriptionController::class, 'cancel']);
    Route::get('/child-subscriptions/review-queue', [SubscriptionController::class, 'reviewQueue']);
    Route::post('/child-subscriptions/{id}/review', [SubscriptionController::class, 'review']);
    Route::get('/child-subscription-status', [SubscriptionController::class, 'childStatus']);
    //قبول او رفض المستخدم
    Route::patch('/users/{id}/update-status', [UserController::class, 'updateStatus']);

    Route::post('/rate-content', [RatingController::class, 'store']);

    Route::post('/quiz/submit', [QuizController::class, 'submitQuiz']);


    Route::get('/child/{id}/results', [QuizController::class, 'getChildResults']);
    // تسجيل الخروج
    Route::post('logout', [AuthController::class, 'logout']);

    // إدارة المستخدمين (متحكم UserController)
    Route::prefix('users')->group(function () {

        // جلب قائمة المستخدمين (تختلف حسب الدور: Admin, Parent, Auditor)
        Route::get('/', [UserController::class, 'index']);

        // إنشاء مستخدم (يستخدم لإنشاء الأطفال، أو المراقبين بواسطة المدير)
        Route::post('/', [UserController::class, 'store']);

        // جلب جميع مراقبي المحتوى (لربط صانع محتوى بهم)
        Route::get('auditors', [UserController::class, 'listAuditors']);

        // جلب جميع صناع المحتوى (للمدير)
        Route::get('creators', [UserController::class, 'listCreators']);
        // جلب جميع صناع المحتوى (للمدير)
        Route::get('parents', [UserController::class, 'listParents']);

        // جلب جميع صناع المحتوى (للمدير)
        Route::get('childs', [UserController::class, 'listChilds']);






        // ربط صانع محتوى بمراقب (Admin)
        Route::post('{user}/link-supervisor', [UserController::class, 'linkSupervisor']);

        // تحديث وتفعيل/إلغاء تفعيل المستخدمين (Admin)
        Route::put('{user}', [UserController::class, 'update']);

        // حذف مستخدم (Admin)
        Route::delete('{user}', [UserController::class, 'destroy']);




        // --- مسارات الأب (إدارة الأبناء) ---
        Route::get('/my-children', [UserController::class, 'getMyChildren']);      // عرض أبنائي
        Route::put('/my-children/{id}', [UserController::class, 'updateChild']);    // تعديل بيانات ابن
        Route::delete('/my-children/{id}', [UserController::class, 'destroyChild']); // حذف حساب ابن






    });

    // --- روابط المسارات التعليمية ---
    Route::get('/educational-paths1', [EducationalPathController::class, 'publishedPaths']);

    Route::get('/educational-paths', [EducationalPathController::class, 'index']);
    Route::post('/educational-paths', [EducationalPathController::class, 'store']);

    // ملاحظة: استخدم POST مع _method=PUT في Postman عند تحديث الصور
    Route::post('/educational-paths/{id}', [EducationalPathController::class, 'update']);

    Route::delete('/educational-paths/{id}', [EducationalPathController::class, 'destroy']);

    // يمكنك إضافة رابط خاص لعرض مسار واحد فقط إذا أردت
    // Route::get('/educational-paths/{id}', [EducationalPathController::class, 'show']);




    // إضافة محتوى شامل
    Route::post('/learning-contents', [LearningContentController::class, 'store']);

    // تعديل محتوى (نستخدم POST مع _method=PUT لرفع الفيديوهات)
    Route::post('/learning-contents/{id}', [LearningContentController::class, 'update']);

    // حذف محتوى
    Route::delete('/learning-contents/{id}', [LearningContentController::class, 'destroy']);

    // جلب كافة محتويات مسار معين (دروس، فيديوهات، أسئلة)
    Route::get('/educational-paths/{id}/all-contents', [LearningContentController::class, 'showPathContents']);

    Route::post('/content-packages', [ContentPackageController::class, 'store']);
    Route::delete('/content-packages/{id}', [ContentPackageController::class, 'destroy']);
    Route::put('/content-packages/{id}', [ContentPackageController::class, 'update']);



    Route::get('/courses_videos/{id}', [ContentPackageController::class, 'pathVideos']);
    // جلب جميع المسارات الخاصة بالشخص
    Route::get('/get-my-paths', [EducationalPathController::class, 'getMyPaths']);


    Route::get('/courses_videos/{id}', [ContentPackageController::class, 'pathVideos']);
    // جلب جميع المسارات الخاصة بالشخص
    Route::get('/courses_questions/{id}', [ContentPackageController::class, 'courseQuestions']);

    Route::delete('/courses_questions/{id}', [ContentPackageController::class, 'deleteQuestion']);
    Route::post('/courses_questions', [ContentPackageController::class, 'storeSingleQuestion']);



    // تحديث حالة المسار التعليمي
    Route::post('/educational-paths/{id}/review', [EducationalPathController::class, 'reviewPath']);

    // --- نظام الإشعارات ---
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::patch('/notifications/{id}/read', [NotificationController::class, 'markRead']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllRead']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);

    // --- نظام النقاط والمكافآت ---
    Route::get('/my-points', [RewardController::class, 'myPoints']);
    Route::get('/children/{id}/points', [RewardController::class, 'childPoints']);
    Route::post('/rewards/redeem', [RewardController::class, 'redeem']);
    Route::get('/rewards/history', [RewardController::class, 'history']);

});


// مسارات صانع المحتوى والمدقق
Route::middleware(['auth:sanctum'])->group(function () {
    Route::post('/games', [GameManagementController::class, 'store']);
    Route::patch('/games/{game}/status', [GameManagementController::class, 'updateStatus']);
    Route::get('/courses_games/{id}', [ContentPackageController::class, 'courseGames']);
    Route::delete('/courses_games/{id}', [ContentPackageController::class, 'deleteGame']);




    // مسارات الطفل
    Route::get('/play/game/{game}', [GamePlayController::class, 'show']);
    Route::post('/play/game/{game}/submit', [GamePlayController::class, 'submitResult']);

    // مسارات ولي الأمر
    Route::get('/parent/child/{childId}/results', [ParentReportController::class, 'getChildResults']);

    // 1. رفع الوسائط (صور الألعاب)
    Route::post('/media/upload', [\App\Http\Controllers\Api\MediaController::class, 'upload']);
});