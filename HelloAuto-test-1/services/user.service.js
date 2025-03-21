const userModel = require('../models/user.model');
const generateOTP = require('./otp.service');
const OTP = require('../models/OTP.model');
const sendEmail = require('./mail.service');
const bcrpt = require('bcrypt');

module.exports.register = async ({ firstname,lastname, email, password }) => {
    if (!firstname ||!lastname || !email || !password) {
        throw new Error('All fields are required');
    }
    const existingUser = await userModel.findOne({ email });
    if (existingUser) {
        throw new Error('User with this email already exists');
    }
    const otp = generateOTP();
    console.log("OTP is this",otp);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // OTP expires in 10 minutes

    try {
        // Save OTP to the database
        await OTP.create({ email, otp, password,firstname,lastname, expiresAt });

        // Send OTP to the user's email
        await sendEmail(email, "Your OTP for Registration of Hye Auto", `Your OTP is ${otp} , it will expire in 10 minutes.`);

        return { message: "OTP sent to your email." };
    } catch (error) {
        console.error(error);
        throw new Error("Failed to send OTP.");
    }
}

module.exports.createUser = async ({ email, otp }) => {
    if (!email || !otp) {
        throw new Error('Email and OTP are required');
    }   
    const record = await OTP.findOne({ email }).select('+password');
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
    const userEmail = record.email;
    const hashedPassword = await userModel.hashPassword(passworduser);

    const user = await userModel.create({
        fullname: {
            firstname, 
            lastname,  
        },
        email: userEmail,          
        password: hashedPassword,  
    });
    
    
    const token = user.generateAuthToken();

    const userRec = {
        fullname: {
            firstname: user.fullname.firstname,
            lastname: user.fullname.lastname,
        },
        email: user.email,
        token: token,
        
    }
    
    await OTP.deleteOne({ email });
    return { userRec };
}
