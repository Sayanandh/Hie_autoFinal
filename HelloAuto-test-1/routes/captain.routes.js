const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const captainController = require('../controllers/captain.controller');
const AuthMiddleware = require('../middlewares/auth.middleware');

router.post('/register', [
    body('email').isEmail().withMessage('Invalid email'),
    body('password').isLength({ min: 5 }).withMessage('Password must be at least 5 characters long'),
    body('fullname.firstname').isLength({ min: 3 }).withMessage('First name must be at least 3 characters long'),
    body('fullname.lastname').isLength({ min: 1 }).withMessage('Last name must be at least 1 characters long'),
    body('vehicle.color').isLength({ min: 3 }).withMessage('Color must be at least 3 characters long'),
    body('vehicle.plate').isLength({ min: 3 }).withMessage('Plate must be at least 3 characters long'),
    body('vehicle.capacity').isInt({ min: 1 }).withMessage('Capacity must be at least 1'),
    body('vehicle.vehicleType').isIn(['Three Wheeler', 'Four Wheeler']).withMessage('Vehicle type must be either Three Wheeler or Four Wheeler'),
    body('verification.LicenseNumber').isLength({ min: 14 }).withMessage('License Number must be at least 14 characters long'),
    body('verification.VehicleRegistrationNumber').isLength({ min: 4 }).withMessage('Vehicle Registration Number must be at least 4 characters long'),
    body('verification.InsuranceNumber').isLength({ min: 5 }).withMessage('Insurance Number must be at least 5 characters long'),
    body('verification.CommertialRegistrationNumber').isLength({ min: 4 }).withMessage('Commertial Registration Number must be at least 4 characters long'),
], captainController.registerCaptain);

router.post('/validate-otp', [
    body('email').isEmail().withMessage('Invalid email'),
    body('otp').isLength({ min: 6 }).withMessage('OTP must be 6 characters long'),
], captainController.validateOTP);

router.post('/login', [
    body('email').isEmail().withMessage('Invalid email'),
    body('password').isLength({ min: 5 }).withMessage('Password must be at least 5 characters long'),
], captainController.loginCaptain);

router.get('/profile',AuthMiddleware.captainAuth,captainController.profile);

router.get('/logout',AuthMiddleware.captainAuth,captainController.logout);

module.exports = router;