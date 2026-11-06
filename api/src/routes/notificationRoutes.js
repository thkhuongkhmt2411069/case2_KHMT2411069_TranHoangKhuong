
const express = require('express');
const router = express.Router();

const protect = require('../middleware/authMiddleware');

const {
    getNotifications,
    markAsRead,
    markAllAsRead
} = require('../controllers/notificationController');

// Xem danh sách thông báo
router.get('/', protect, getNotifications);

// Đánh dấu tất cả thông báo đã đọc
router.put('/read-all', protect, markAllAsRead);

// Đánh dấu một thông báo đã đọc
router.put('/:id/read', protect, markAsRead);

module.exports = router;
