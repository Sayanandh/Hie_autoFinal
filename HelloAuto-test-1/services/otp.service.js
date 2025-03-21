const crypto = require('crypto');


function generateOTP() {
    return crypto.randomInt(100000, 1000000).toString(); // Generates a 6-digit OTP securely
  }

  module.exports = generateOTP;