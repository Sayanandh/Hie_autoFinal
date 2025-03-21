const mongoose = require('mongoose');

const driverOtpSchema = new mongoose.Schema({
    firstname: { type: String, required: true },
    lastname: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    otp: { type: String, required: true },
    password: {
        type: String,
        required: true,
        select: false,
    },
    color: { type: String, required: true },
    plate: { type: String, required: true },
    capacity: { type: Number, required: true },
    vehicleType: { type: String, required: true },
    LicenseNumber: { type: String, required: true },
    VehicleRegistrationNumber: { type: String, required: true },
    InsuranceNumber: { type: String, required: true },
    CommertialRegistrationNumber: { type: String, required: true },
    expiresAt: { type: Date, required: true },
});

// Automatically delete expired OTPs
driverOtpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

const DriverOtpModel = mongoose.model("DriverOtp", driverOtpSchema);

module.exports = DriverOtpModel;