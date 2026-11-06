
const express = require('express');

const app = express();

// Cho phép đọc dữ liệu JSON
app.use(express.json());

// API kiểm tra server
app.get('/', (req, res) => {
    res.json({
        message: 'Task Manager API is running!'
    });
});

// Khởi động server
const PORT = 3000;

app.listen(PORT, () => {
    console.log(`Server is running at http://localhost:${PORT}`);
});
