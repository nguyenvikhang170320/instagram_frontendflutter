const express = require("express");
const { db } = require("../firebase");
const { cloudinary } = require("../cloudinary");
const upload = require("../middlewares/upload");

const router = express.Router();

// Cập nhật Profile
router.put("/update/:userId", upload.single("avatar"), async (req, res) => {
    try {
        const { userId } = req.params;
        const { username, bio } = req.body;
        let avatarUrl = null;

        if (req.file) {
            const result = await cloudinary.uploader.upload_stream(
                { resource_type: "image", folder: "instagram-clone/avatars" },
                async (error, result) => {
                    if (error) {
                        return res.status(500).json({ message: "Lỗi upload ảnh", error });
                    }

                    avatarUrl = result.secure_url;

                    // Cập nhật dữ liệu
                    await db.collection("users").doc(userId).update({
                        username,
                        bio,
                        avatar: avatarUrl,
                    });

                    res.json({ message: "Cập nhật thành công", avatarUrl });
                }
            );

            result.end(req.file.buffer);
        } else {
            // Nếu không có ảnh mới, chỉ cập nhật username và bio
            await db.collection("users").doc(userId).update({
                username,
                bio,
            });

            res.json({ message: "Cập nhật thành công" });
        }
    } catch (error) {
        res.status(500).json({ message: "Lỗi server", error });
    }
});

module.exports = router;
