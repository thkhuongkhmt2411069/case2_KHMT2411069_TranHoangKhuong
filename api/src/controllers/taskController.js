
const Task = require('../models/Task');
const User = require('../models/User');

// 1. Tạo công việc
const createTask = async (req, res) => {
    try {
        const { title, description } = req.body;

        if (!title) {
            return res.status(400).json({
                message: 'Vui lòng nhập tiêu đề công việc'
            });
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

// 2. Xem công việc của mình, được giao và được chia sẻ
const getTasks = async (req, res) => {
    try {
        const tasks = await Task.find({
            $or: [
                { createdBy: req.user.id },
                { assignedTo: req.user.id },
                { 'sharedWith.user': req.user.id }
            ]
        }).sort({ createdAt: -1 });

        res.json(tasks);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// 3. Cập nhật công việc
const updateTask = async (req, res) => {
    try {
        const task = await Task.findById(req.params.id);

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc'
            });
        }

        const isOwner = task.createdBy.toString() === req.user.id;

        const sharedMember = task.sharedWith.find(
            item => item.user.toString() === req.user.id
        );

        const isEditor = sharedMember?.role === 'editor';

        if (!isOwner && !isEditor) {
            return res.status(403).json({
                message: 'Bạn không có quyền chỉnh sửa công việc'
            });
        }

        const { title, description, status } = req.body;

        if (title !== undefined) task.title = title;
        if (description !== undefined) task.description = description;
        if (status !== undefined) task.status = status;

        await task.save();

        res.json({
            message: 'Cập nhật công việc thành công',
            task
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// 4. Xóa công việc (chỉ chủ sở hữu)
const deleteTask = async (req, res) => {
    try {
        const task = await Task.findOneAndDelete({
            _id: req.params.id,
            createdBy: req.user.id
        });

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc'
            });
        }

        res.json({ message: 'Xóa công việc thành công' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// 5. Giao công việc
const assignTask = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                message: 'Vui lòng nhập email thành viên'
            });
        }

        const task = await Task.findOne({
            _id: req.params.id,
            createdBy: req.user.id
        });

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc'
            });
        }

        const user = await User.findOne({
            email: email.trim().toLowerCase()
        });

        if (!user) {
            return res.status(404).json({
                message: 'Không tìm thấy thành viên'
            });
        }

        task.assignedTo = user._id;
        await task.save();
        await task.populate('assignedTo', 'name email');

        res.json({
            message: 'Giao công việc thành công',
            task
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// 6. Chia sẻ công việc với Viewer hoặc Editor
const shareTask = async (req, res) => {
    try {
        const { email, role } = req.body;

        if (!email || !role) {
            return res.status(400).json({
                message: 'Vui lòng nhập email và quyền chia sẻ'
            });
        }

        if (!['viewer', 'editor'].includes(role)) {
            return res.status(400).json({
                message: 'Quyền chỉ được là viewer hoặc editor'
            });
        }

        const task = await Task.findOne({
            _id: req.params.id,
            createdBy: req.user.id
        });

        if (!task) {
            return res.status(404).json({
                message: 'Không tìm thấy công việc'
            });
        }

        const user = await User.findOne({
            email: email.trim().toLowerCase()
        });

        if (!user) {
            return res.status(404).json({
                message: 'Không tìm thấy thành viên'
            });
        }

        if (user._id.toString() === req.user.id) {
            return res.status(400).json({
                message: 'Không thể chia sẻ cho chính mình'
            });
        }

        const existingShare = task.sharedWith.find(
            item => item.user.toString() === user._id.toString()
        );

        if (existingShare) {
            existingShare.role = role;
        } else {
            task.sharedWith.push({
                user: user._id,
                role
            });
        }

        await task.save();

        res.json({
            message: 'Chia sẻ công việc thành công',
            task
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    createTask,
    getTasks,
    updateTask,
    deleteTask,
    assignTask,
    shareTask
};
