const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { db } = require("../firebase");
const { body, validationResult } = require("express-validator");
const nodemailer = require("nodemailer");
const authMiddleware = require("./middleware/authMiddleware");

const router = express.Router();


// Đăng ký tài khoản
router.post(
    "/register",
    [
        body("email").isEmail().withMessage("Email không hợp lệ"),
        body("password").isLength({ min: 6 }).withMessage("Mật khẩu phải từ 6 ký tự"),
        body("username").notEmpty().withMessage("Tên người dùng không được để trống"),
        body("fullname").notEmpty().withMessage("Tên đầy đủ không được để trống"),
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { username, fullname, email, password } = req.body;
        console.log(req.body);
        try {
            const usernameRef = db.collection("users").where("username", "==", username);
            const fullnameRef = db.collection("users").where("fullname", "==", fullname);
            const usernameSnapshot = await usernameRef.get();
            const fullnameSnapshot = await fullnameRef.get();
            if (!usernameSnapshot.empty) {
                return res.status(400).json({ message: "Tên người dùng đã tồn tại" });
            }
            if (!fullnameSnapshot.empty) {
                return res.status(400).json({ message: "Tên đầy đủ đã tồn tại" });
            }
            const emailRef = db.collection("users").where("email", "==", email);
            const emailSnapshot = await emailRef.get();
            if (!emailSnapshot.empty) {
                return res.status(400).json({ message: "Email đã tồn tại" });
            }

            const hashedPassword = await bcrypt.hash(password, 10);

            const newUser = {
                username,
                fullname,
                email,
                password: hashedPassword,
                createdAt: new Date(),
            };
            const userDoc = await db.collection("users").add(newUser);

            res.status(201).json({ success: true, message: "Đăng ký thành công", userId: userDoc.id, username, fullname });
        } catch (error) {
            res.status(500).json({ message: "Lỗi server", error });
        }
    }
);

// Đăng nhập
router.post(
    "/login",
    [
        body("email").isEmail().withMessage("Email không hợp lệ"),
        body("password").notEmpty().withMessage("Mật khẩu không được để trống"),
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { email, password } = req.body;
        console.log(req.body);
        try {
            const userRef = db.collection("users").where("email", "==", email);
            const snapshot = await userRef.get();
            if (snapshot.empty) {
                return res.status(400).json({ message: "Email hoặc mật khẩu không đúng" });
            }

            let user;
            let userId;
            snapshot.forEach((doc) => {
                user = doc.data();
                userId = doc.id;
            });

            const isMatch = await bcrypt.compare(password, user.password);
            if (!isMatch) {
                return res.status(400).json({ message: "Email hoặc mật khẩu không đúng" });
            }

            const jwt = require("jsonwebtoken");
            require("dotenv").config(); // Load biến môi trường từ .env

            const token = jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: "7d" });

            console.log("Token:", token); // In ra để kiểm tra nếu cần


            res.status(200).json({ success: true, message: "Đăng nhập thành công", token, userId, username: user.username, avatar: user.avatar || "" });
        } catch (error) {
            res.status(500).json({ message: "Lỗi server", error });
        }
    }
);

// API Quên mật khẩu
router.post("/forgot-password", async (req, res) => {
    const { email } = req.body;

    try {
        const userRef = db.collection("users").where("email", "==", email);
        const snapshot = await userRef.get();
        if (snapshot.empty) {
            return res.status(400).json({ message: "Email không tồn tại" });
        }

        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const otpExpiration = new Date();
        otpExpiration.setMinutes(otpExpiration.getMinutes() + 10);

        snapshot.forEach(async (doc) => {
            await doc.ref.update({ resetOtp: otp, otpExpiresAt: otpExpiration });
        });

        let transporter = nodemailer.createTransport({
            service: "gmail",
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS,
            },
        });

        let mailOptions = {
            from: process.env.EMAIL_USER,
            to: email,
            subject: "Mã OTP để đặt lại mật khẩu",
            text: `Mã OTP của bạn là: ${otp}. Vui lòng không chia sẻ với ai.`,
        };

        await transporter.sendMail(mailOptions);
        res.json({ message: "Mã OTP đã được gửi đến email của bạn." });
    } catch (error) {
        res.status(500).json({ message: "Lỗi server", error });
    }
});

// API Xác minh OTP
router.post("/verify-otp", async (req, res) => {
    const { email, otp } = req.body;

    try {
        const userRef = db.collection("users").where("email", "==", email);
        const snapshot = await userRef.get();
        if (snapshot.empty) {
            return res.status(400).json({ message: "Email không tồn tại" });
        }

        let user;
        snapshot.forEach(doc => { user = doc; });

        if (user.data().resetOtp !== otp || new Date() > user.data().otpExpiresAt.toDate()) {
            return res.status(400).json({ message: "Mã OTP không hợp lệ hoặc đã hết hạn" });
        }

        res.json({ message: "Xác minh OTP thành công!" });
    } catch (error) {
        res.status(500).json({ message: "Lỗi server", error });
    }
});

// API Lấy thông tin user
router.get("/me", authMiddleware, async (req, res) => {
    try {
        const userDoc = await db.collection("users").doc(req.userId).get();
        if (!userDoc.exists) {
            return res.status(404).json({ message: "Người dùng không tồn tại" });
        }
        res.json({ success: true, user: userDoc.data() });
    } catch (error) {
        res.status(500).json({ message: "Lỗi server", error });
    }
});

module.exports = router;


//Tạo API Lấy Thông Tin Người Dùng
router.get("/getUser/:userId", async (req, res) => {
    try {
        const userId = req.params.userId;
        const userDoc = await db.collection("users").doc(userId).get();

        if (!userDoc.exists) {
            return res.status(404).json({ message: "Người dùng không tồn tại" });
        }

        const userData = userDoc.data();
        res.json({ success: true, user: userData });
    } catch (error) {
        res.status(500).json({ message: "Lỗi server", error });
    }
});

//kiểm tra mật khẩu mã hóa
// const hashedPassword = "$2b$10$XbumuXtAxUHD9rjYD5Y7Re8uGr/880Vl5MsiOmlH6heJeTJ0/JdWe"; // Lấy từ Firestore
// const plainPassword = "12345678"; // Mật khẩu thực tế

// bcrypt.compare(plainPassword, hashedPassword, (err, isMatch) => {
//     if (err) {
//         console.error("Lỗi:", err);
//     } else if (isMatch) {
//         console.log("Mật khẩu đúng ✅");
//     } else {
//         console.log("Mật khẩu sai ❌");
//     }
// });


module.exports = router;
