const express = require('express');
const router = express.Router();
const {body} = require('express-validator');
const userController = require('../controllers/user.controller');
const AuthMiddleware = require('../middlewares/auth.middleware');

router.post('/register', [
    body('email').isEmail().withMessage('Invalid email'),
    body('password').isLength({min: 5}).withMessage('Password must be at least 5 characters long'),
    body('fullname.firstname').isLength({min: 3}).withMessage('First name must be at least 3 characters long'),
    body('fullname.lastname').isLength({min: 1}).withMessage('Last name must be at least 1 characters long'),
], userController.registerUser );

router.post('/validate-otp',[
    body('email').isEmail().withMessage('Invalid email'),
    body('otp').isLength({min: 6}).withMessage('OTP must be 6 characters long'),
],userController.validateOTP);

router.post('/login',[
    body('email').isEmail().withMessage('Invalid email'),
    body('password').isLength({min: 5}).withMessage('Password must be at least 5 characters long'),

],userController.loginUser);

router.get('/profile',AuthMiddleware.userAuth,userController.profile);

router.get('/logout',AuthMiddleware.userAuth,userController.logout);


module.exports = router;