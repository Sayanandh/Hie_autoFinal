const dotenv = require("dotenv");
dotenv.config();
const connectDB = require("./db/db");
const express = require("express");
const app = express();
const cookieParser = require("cookie-parser");
const cors = require("cors");
const userRoutes = require("./routes/user.routes");
const captainRoutes = require("./routes/captain.routes");
const mapRoutes = require("./routes/map.routes");
const AutoRoutes = require("./routes/autostand.routes");
const rideRoutes = require("./routes/ride.routes");
const toggleRoutes = require("./routes/toggle.routes");

connectDB();


app.use(cors());

// Use Express built-in middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

app.get("/", (req, res) => {
  res.send("Hello World!");
});

app.use("/users", userRoutes);
app.use("/captains", captainRoutes);
app.use("/maps",mapRoutes );
app.use("/autostands", AutoRoutes);
app.use("/rides",rideRoutes );
app.use("/toggle",toggleRoutes);

module.exports = app;