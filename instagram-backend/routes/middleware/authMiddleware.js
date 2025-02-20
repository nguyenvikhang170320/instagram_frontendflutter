const jwt = require("jsonwebtoken");
require("dotenv").config();

const authMiddleware = (req, res, next) => {
    const token = req.header("Authorization");

    if (!token) {
        return res.status(401).json({ message: "Không có token, truy cập bị từ chối!" });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.userId = decoded.userId;
        next(); // Cho phép tiếp tục
    } catch (error) {
        res.status(401).json({ message: "Token không hợp lệ!" });
    }
};

module.exports = authMiddleware;
