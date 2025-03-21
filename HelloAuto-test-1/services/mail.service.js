const nodemailer = require("nodemailer");

async function sendEmail(to, subject, text) {
    const transporter = nodemailer.createTransport({
      service: "Gmail",
      auth: {
        user: process.env.EMAIL, // Replace with your email address
        pass: process.env.EMAIL_PASSWORD, // Replace with your email password or app password
      },
    });
  
    const mailOptions = {
      from: process.env.EMAIL, // Replace with your email address
      to,
      subject,
      text,
    };
  
    return transporter.sendMail(mailOptions);
  }

  module.exports = sendEmail;
  