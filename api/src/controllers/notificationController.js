
const Notification = require('../models/Notification');

// 1. Xem danh sách thông báo
const getNotifications = async (req, res) => {
    try {
        const notifications = await Notification.find({
            recipient: req.user.id
        })
            .populate('sender', 'name email')
            .populate('task', 'title')
            .sort({ createdAt: -1 });

        res.json(notifications);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// 2. Đánh dấu một thông báo đã đọc
const markAsRead = async (req, res) => {
    try {
        const notification = await Notification.findOneAndUpdate(
            {
                _id: req.params.id,
                recipient: req.user.id
            },
            { isRead: true },
            { new: true }
        );

        if (!notification) {
            return res.status(404).json({
                message: 'Không tìm thấy thông báo'
            });
        }

        res.json({
            message: 'Đã đánh dấu thông báo đã đọc',
            notification
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// 3. Đánh dấu tất cả thông báo đã đọc
const markAllAsRead = async (req, res) => {
    try {
        await Notification.updateMany(
            {
                recipient: req.user.id,
                isRead: false
            },
            { isRead: true }
        );

        res.json({
            message: 'Đã đánh dấu tất cả thông báo đã đọc'
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getNotifications,
    markAsRead,
    markAllAsRead
};
