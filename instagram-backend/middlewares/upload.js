const multer = require("multer");

const storage = multer.memoryStorage(); // Lưu trữ file trên bộ nhớ tạm
const upload = multer({ storage });

module.exports = upload;
