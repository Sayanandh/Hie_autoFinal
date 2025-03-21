const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const AuthMiddleware = require('../middlewares/auth.middleware');
const ridecontroller = require('../controllers/ride.controller');



router.post(
    '/get-price',
    AuthMiddleware.userAuth,
    [
        body('pickup')
            .notEmpty()
            .withMessage('Pickup location is required'),
        body('dropoff')
            .notEmpty()
            .withMessage('Dropoff location is required'),
    ],ridecontroller.getRouteDetails
);

router.post(
    '/request-ride',
    AuthMiddleware.userAuth,
    [
        body('pickup')
            .notEmpty()
            .withMessage('Pickup location is required'),
        body('dropoff')
            .notEmpty()
            .withMessage('Dropoff location is required'),
        body('price')
            .notEmpty()
            .withMessage('Price is required'),
    ],ridecontroller.requestRide
);

router.post(
    '/verify-otp',
    AuthMiddleware.captainAuth,
    [
        body('otp')
            .notEmpty()
            .withMessage('OTP is required'),
        body('rideId')
            .notEmpty() 
            .withMessage('Ride ID is required'),
        body('location')
            .notEmpty()
            .withMessage('Location is required'),
    ],ridecontroller.verifyOTP
)

router.post(
    '/ride-completed',
    AuthMiddleware.captainAuth,
    [
        body('rideId')
            .notEmpty() 
            .withMessage('Ride ID is required'),
        body("status")
            .notEmpty()
            .withMessage('Status is required'),
        body('location')
            .notEmpty()
            .withMessage('Location is required'),
    ],ridecontroller.completeRide
)


router.get(
    '/get-ride-history-for-user',   
    AuthMiddleware.userAuth,
    ridecontroller.getRideHistoryforUser
    
)


router.get(
    '/get-ride-history-for-captain',   
    AuthMiddleware.captainAuth,
    ridecontroller.getRideHistoryforCaptain
    
)



module.exports = router;