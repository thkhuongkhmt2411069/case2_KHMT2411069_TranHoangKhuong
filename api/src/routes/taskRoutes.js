const express = require('express');
const router = express.Router();

const protect = require('../middleware/authMiddleware');

const {
    createTask,
    getTasks,
    updateTask,
    deleteTask
} = require('../controllers/taskController');

// Tạo công việc
router.post('/', protect, createTask);

// Xem danh sách công việc
router.get('/', protect, getTasks);

// Cập nhật công việc
router.put('/:id', protect, updateTask);

// Xóa công việc
router.delete('/:id', protect, deleteTask);

module.exports = router;