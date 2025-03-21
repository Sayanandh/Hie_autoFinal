const captainModel = require("../models/captain.model");
const { validationResult } = require('express-validator');
const blackListTokenModel = require('../models/blacklistToken.model');
const { register, createDriver} = require("../services/captain.service");

module.exports.registerCaptain = async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        console.log("Validation Errors:", errors.array()); // Log validation errors
        return res.status(400).json({ errors: errors.array() });
    }
    
   const { fullname, email, password, vehicle, verification } = req.body;
   let firstname = fullname.firstname;
   let lastname = fullname.lastname; 
   let color = vehicle.color;
   let plate = vehicle.plate;
   let capacity = vehicle.capacity;
   let vehicleType = vehicle.vehicleType;
   let LicenseNumber = verification.LicenseNumber;
    let VehicleRegistrationNumber = verification.VehicleRegistrationNumber;
    let InsuranceNumber = verification.InsuranceNumber;
    let CommertialRegistrationNumber = verification.CommertialRegistrationNumber;
   try {
      const result = await register({ firstname,lastname, email, password, color, plate, capacity, vehicleType, LicenseNumber, VehicleRegistrationNumber, InsuranceNumber, CommertialRegistrationNumber });
      res.status(200).json(result);
   } catch (error) {
       console.error("Registration Error:", error); // Log any errors during registration
       res.status(500).json({ message: error.message });
   }


}

module.exports.validateOTP = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            console.log("Validation Errors:", errors.array()); // Log validation errors
            return res.status(400).json({ errors: errors.array() });
        }
        const { email, otp } = req.body;
        const result = await createDriver({ email, otp});
        res.cookie('token', result.token);
        res.status(200).json({ result });
    } catch (error) {
        console.error("OTP Validation Error:", error); // Log any errors during OTP validation
        res.status(500).json({ message: error.message });
    }

}

module.exports.loginCaptain = async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        console.log("Validation Errors:", errors.array()); // Log validation errors
        return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;
    try {
        const record = await captainModel.findOne({ email }).select('+password');
        if (!record) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }
        const isPasswordValid = await record.comparePassword(password);
        if (!isPasswordValid) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }
        const token = record.generateAuthToken();
        res.cookie('token', token);
        res.status(200).json({ token, record });
    } catch (error) {
        console.error("Login Error:", error); // Log any errors during login
        res.status(500).json({ message: error.message });
    }
}

module.exports.profile = async (req, res) => {
    try {
        driver = req.captain;
        res.status(200).json({ driver });
    } catch (error) {
        console.error("Profile Error:", error); // Log any errors during profile retrieval
        res.status(500).json({ message: error.message });
    }
}

module.exports.logout = async (req, res) => {
    res.clearCookie('token');
    const token = req.cookies.token || req.headers.authorization.split(' ')[1];
    await blackListTokenModel.create({ token });
    res.status(200).json({ message: 'Logged out successfully' });
}