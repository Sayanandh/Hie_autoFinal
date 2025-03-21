const express = require('express');
const router = express.Router();
const { toggleDriverQueue } = require('../controllers/toggle.controller');
const AuthMiddleware = require('../middlewares/auth.middleware');
const expressValidator = require('express-validator');

router.put('/toggle-queue/:autostandId',[
    expressValidator.body('driverID').notEmpty().withMessage('Driver ID is required'),
    expressValidator.body('toggleStatus').notEmpty().withMessage('Status is required'),

], AuthMiddleware.captainAuth, toggleDriverQueue);

module.exports = router;
