const mongoose = require('mongoose');

// Define OTP schema and model
const otpSchema = new mongoose.Schema({
    email: { type: String, required: true },
    otp: { type: String, required: true },
    firstname: { type: String, required: true },
    lastname: { type: String, required: true },
    password: {
        type: String,
        required: true,
        select: false,
    },
    expiresAt: { type: Date, required: true },
  });
  // Automatically delete expired OTPs
  otpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  const OTP = mongoose.model("OTP", otpSchema);

  module.exports = OTP;