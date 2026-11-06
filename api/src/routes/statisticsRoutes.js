const express = require('express');
const router = express.Router();

const protect = require('../middleware/authMiddleware');
const { getStatistics } = require('../controllers/statisticsController');

// Thống kê công việc
router.get('/', protect, getStatistics);

module.exports = router;