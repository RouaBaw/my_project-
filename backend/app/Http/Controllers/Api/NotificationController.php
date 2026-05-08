<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * GET /api/notifications
     * Returns the authenticated user's notifications (latest first, paginated).
     * Optional filter: ?unread=1
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $query = $user->notifications()->latest();
        // إذا أرسل unread=1 تجلب غير المقروء فقط.
        if ($request->boolean('unread')) {
            $query->whereNull('read_at');
        }

        $perPage = min((int) $request->query('per_page', 20), 100);
        $paginator = $query->paginate($perPage);
        // ترجع الإشعارات + عدد غير المقروء + معلومات الصفحات.
        return response()->json([
            'status'       => 'success',
            'data'         => $paginator->items(),
            'unread_count' => (int) $user->unreadNotifications()->count(),
            'meta'         => [
                'current_page' => $paginator->currentPage(),
                'last_page'    => $paginator->lastPage(),
                'per_page'     => $paginator->perPage(),
                'total'        => $paginator->total(),
            ],
        ]);
    }

    /**
     * GET /api/notifications/unread-count
     */
    public function unreadCount(Request $request)
    {
        return response()->json([
            'status'       => 'success',
            'unread_count' => (int) $request->user()->unreadNotifications()->count(),
        ]);
    }

    /**
     * PATCH /api/notifications/{id}/read
     */
    public function markRead(Request $request, string $id)
    {
        $notification = $request->user()->notifications()->where('id', $id)->first();
        if (!$notification) {
            return response()->json(['message' => 'الإشعار غير موجود'], 404);
        }
        if (!$notification->read_at) {
            $notification->markAsRead();
        }
        return response()->json([
            'status'       => 'success',
            'data'         => $notification->fresh(),
            'unread_count' => (int) $request->user()->unreadNotifications()->count(),
        ]);
    }

    /**
     * POST /api/notifications/read-all
     */
    public function markAllRead(Request $request)
    {
        $request->user()->unreadNotifications->markAsRead();
        return response()->json([
            'status'       => 'success',
            'message'      => 'تم تعليم جميع الإشعارات كمقروءة',
            'unread_count' => 0,
        ]);
    }

    /**
     * DELETE /api/notifications/{id}
     */
    public function destroy(Request $request, string $id)
    {
        $notification = $request->user()->notifications()->where('id', $id)->first();
        if (!$notification) {
            return response()->json(['message' => 'الإشعار غير موجود'], 404);
        }
        $notification->delete();
        return response()->json([
            'status'       => 'success',
            'message'      => 'تم حذف الإشعار',
            'unread_count' => (int) $request->user()->unreadNotifications()->count(),
        ]);
    }
}
