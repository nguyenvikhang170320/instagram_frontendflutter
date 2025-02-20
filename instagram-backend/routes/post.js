const express = require("express");
const { cloudinary } = require("../cloudinary");
const { db } = require("../firebase");
const upload = require("../middlewares/upload");

const router = express.Router();

// API đăng bài
router.post("/create", upload.single("image"), async (req, res) => {
    try {
        const { caption, userId } = req.body;
        if (!req.file) {
            return res.status(400).json({ message: "Vui lòng tải lên một hình ảnh" });
        }

        // Upload ảnh lên Cloudinary
        const result = await cloudinary.uploader.upload_stream(
            { resource_type: "image", folder: "instagram-clone/posts" },
            async (error, result) => {
                if (error) {
                    return res.status(500).json({ message: "Lỗi upload ảnh", error });
                }

                // Lưu thông tin bài đăng vào Firestore
                const newPost = {
                    userId,
                    caption,
                    imageUrl: result.secure_url,
                    createdAt: new Date(),
                };

                const postRef = await db.collection("posts").add(newPost);
                res.status(201).json({ message: "Đăng bài thành công", postId: postRef.id });
            }
        );

        result.end(req.file.buffer);
    } catch (error) {
        res.status(500).json({ message: "Lỗi server", error });
    }
});

module.exports = router;
