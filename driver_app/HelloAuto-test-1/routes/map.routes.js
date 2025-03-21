const express = require('express');
const router = express.Router();
const AuthMiddleware = require('../middlewares/auth.middleware');
const mapController = require('../controllers/map.controller');
const {query} = require('express-validator');

router.get('/get-coordinate',
    query("address").isString().isLength({min:3}).withMessage("Address must be a string with minimum length of 3 characters"),
    AuthMiddleware.userAuth,mapController.getCoordinates);

router.get("/get-distance-time",
    query("origin").isString().isLength({min:3}).withMessage("Origin must be a string with minimum length of 3 characters"),
    query("destination").isString().isLength({min:3}).withMessage("Destination must be a string with minimum length of 3 characters"),
    AuthMiddleware.userAuth,mapController.getDistanceTime   
);

router.get("/get-suggestions",
    query("query").isString().withMessage("Query must be a string."),
    AuthMiddleware.userAuth,mapController.getSuggestions
)

module.exports = router; 