const Task = require('../models/Task');

// 1. Tạo công việc
const createTask = async (req, res) => {
    try {
        const { title, description } = req.body;

        if (!title) {
            return res.status(400).json({ message: 'Vui lòng nhập tiêu đề công việc' });
        }

        const task = await Task.create({
            title,
            description,
            createdBy: req.user.id
        });

        res.status(201).json({
            message: 'Tạo công việc thành công',
            task
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// 2. Xem danh sách công việc
const getTasks = async (req, res) => {
    try {
        const tasks = await Task.find({ createdBy: req.user.id }).sort({ createdAt: -1 });
        res.json(tasks);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// 3. Cập nhật công việc
const updateTask = async (req, res) => {
    try {
        const task = await Task.findOneAndUpdate(
            { _id: req.params.id, createdBy: req.user.id },
            req.body,
            { new: true, runValidators: true }
        );

        if (!task) {
            return res.status(404).json({ message: 'Không tìm thấy công việc' });
        }

        res.json({
            message: 'Cập nhật công việc thành công',
            task
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// 4. Xóa công việc
const deleteTask = async (req, res) => {
    try {
        const task = await Task.findOneAndDelete({
            _id: req.params.id,
            createdBy: req.user.id
        });

        if (!task) {
            return res.status(404).json({ message: 'Không tìm thấy công việc' });
        }

        res.json({ message: 'Xóa công việc thành công' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = { createTask, getTasks, updateTask, deleteTask };