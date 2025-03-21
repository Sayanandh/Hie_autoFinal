const captainModel = require("../models/captain.model");
const generateOTP = require('./otp.service');
const DriverOtpModel = require('../models/driver.otp');
const sendEmail = require('./mail.service');
const bcrpt = require('bcrypt');

module.exports.register = async ({ firstname,lastname,email,password,color,plate,capacity,vehicleType,LicenseNumber,VehicleRegistrationNumber,InsuranceNumber,CommertialRegistrationNumber }) => {
    if(!firstname || !lastname || !email || !password || !color || !plate || !capacity || !vehicleType || !LicenseNumber || !VehicleRegistrationNumber || !InsuranceNumber || !CommertialRegistrationNumber) {
        throw new Error('All fields are required');
    }
    const existingCaptain = await captainModel.findOne({ email });

    if (existingCaptain) {
        throw new Error('Captain with this email already exists');
    }

    const otp = generateOTP();
    console.log("OTP is this",otp);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // OTP expires in 10 minutes

    try {
        // Save OTP to the database
        await DriverOtpModel.create({
            firstname,
            lastname,
            email,
            otp,
            password,
            color,
            plate,
            capacity,
            vehicleType,
            LicenseNumber,
            VehicleRegistrationNumber,
            InsuranceNumber,
            CommertialRegistrationNumber,
            expiresAt
        }); 

        // Send OTP to the user's email
        await sendEmail(email, "Your OTP for driver registration of Hye Auto", `Your OTP is ${otp} , it will expire in 10 minutes.`);

        return { message: "OTP sent to your email." };
    } catch (error) {
        console.error(error);    
        throw new Error("Failed to send OTP."); 
    }

}

module.exports.createDriver = async ({ email, otp }) => {
    if (!email || !otp) {
        throw new Error('Email and OTP are required');
    }   
    const record = await DriverOtpModel.findOne({ email }).select('+password');
    if (!record) {
        throw new Error('Invalid email or OTP');
    }
    if (record.otp !== otp) {
        throw new Error('Invalid OTP');
    }
    if (record.expiresAt < new Date()) {
        throw new Error('OTP has expired');
    }
    const passworduser = record.password;
    const firstname = record.firstname;
    const lastname = record.lastname;
    const driverEmail = record.email;
    const color = record.color;
    const plate = record.plate;  
    const capacity = record.capacity;  
    const vehicleType = record.vehicleType;  
    const LicenseNumber = record.LicenseNumber;  
    const VehicleRegistrationNumber = record.VehicleRegistrationNumber;  
    const InsuranceNumber = record.InsuranceNumber;  
    const CommertialRegistrationNumber = record.CommertialRegistrationNumber;  
    const hashedPassword = await bcrpt.hash(passworduser, 10);



    const driver = await captainModel.create({
        fullname: {
            firstname,
            lastname,
        },
        email: driverEmail,
        password: hashedPassword,
        vehicle: {
            color,
            plate,
            capacity,
            vehicleType
        },
        verification: {
            LicenseNumber,
            VehicleRegistrationNumber,
            InsuranceNumber,
            CommertialRegistrationNumber
        }
    });
    
    const token = driver.generateAuthToken();

    await DriverOtpModel.deleteOne({ email });
    return { driver, token };           
}   