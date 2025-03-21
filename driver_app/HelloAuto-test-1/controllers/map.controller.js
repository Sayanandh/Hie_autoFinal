const mapService = require('../services/maps.services');
const { validationResult } = require('express-validator');

module.exports.getCoordinates = async (req, res) => {
const errorsq = validationResult(req);
if (!errorsq.isEmpty()) {
    console.log("Validation Errors:", errorsq.array()); // Log validation errors    
    return res.status(400).json({ errors: errorsq.array() });
}

    const { address } = req.query;
    try {
        const location = await mapService.getAddressLocation(address);
        res.status(200).json(location);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
}

module.exports.getDistanceTime = async (req, res) => {
    const errorsq = validationResult(req);      
    if (!errorsq.isEmpty()) {
        console.log("Validation Errors:", errorsq.array()); // Log validation errors    
        return res.status(400).json({ errors: errorsq.array() });
    }
    const { origin, destination } = req.query;
    try {
        const distanceTime = await mapService.getDistanceTime(origin, destination);
        res.status(200).json(distanceTime);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
}


module.exports.getSuggestions = async (req, res) => {
    const errorsq = validationResult(req);      
    if (!errorsq.isEmpty()) {
        console.log("Validation Errors:", errorsq.array()); // Log validation errors    
        return res.status(400).json({ errors: errorsq.array() });
    }
    const { query } = req.query;
    try {
        const suggestions = await mapService.getAutoSuggestions(query);
        res.status(200).json({suggestions});
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
}