const Task = require('../models/Task');

// Thống kê công việc
const getStatistics = async (req, res) => {
    try {
        const userId = req.user.id;

        const total = await Task.countDocuments({
            $or: [
                { createdBy: userId },
                { assignedTo: userId },
                { 'sharedWith.user': userId }
            ]
        });

        const todo = await Task.countDocuments({
            status: 'todo',
            $or: [
                { createdBy: userId },
                { assignedTo: userId },
                { 'sharedWith.user': userId }
            ]
        });

        const inProgress = await Task.countDocuments({
            status: 'in_progress',
            $or: [
                { createdBy: userId },
                { assignedTo: userId },
                { 'sharedWith.user': userId }
            ]
        });

        const done = await Task.countDocuments({
            status: 'done',
            $or: [
                { createdBy: userId },
                { assignedTo: userId },
                { 'sharedWith.user': userId }
            ]
        });

        res.json({
            message: 'Thống kê công việc thành công',
            statistics: {
                total,
                todo,
                inProgress,
                done
            }
        });

    } catch (error) {
        res.status(500).json({
            message: error.message
        });
    }
};

module.exports = { getStatistics };