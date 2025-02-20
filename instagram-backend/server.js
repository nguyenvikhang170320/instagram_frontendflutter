const express = require("express");
const cors = require("cors");
require("dotenv").config();
console.log("JWT_SECRET từ .env:", process.env.JWT_SECRET);
const app = express();
app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
    res.send("Instagram Clone Backend Running!");
});

const authRoutes = require("./routes/auth");
app.use("/api/auth", authRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

//cloudinary
const { cloudinary } = require("./cloudinary");

app.get("/test-cloudinary", async (req, res) => {
    try {
        const result = await cloudinary.uploader.upload(
            "https://res.cloudinary.com/demo/image/upload/sample.jpg"
        );
        res.json({ message: "Cloudinary connected!", result });
    } catch (error) {
        res.status(500).json({ message: "Cloudinary connection failed!", error });
    }
});

const postRoutes = require("./routes/post");
app.use("/api/posts", postRoutes);

const userRoutes = require("./routes/user");
app.use("/api/users", userRoutes);


