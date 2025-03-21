const mongoose = require('mongoose');
const autostandModel = require('../models/autostand.model'); // Adjust path as needed

async function findNearestAutostands(pickupLocation) {
    try {
        

        const maxDistance = 5000
        const { ltd, lng } = pickupLocation;

        if (!ltd || !lng) {
            throw new Error('Invalid pickup location. Latitude and longitude are required.');
        }

        const nearestAutostands = await autostandModel.aggregate([
            {
                $geoNear: {
                    near: { type: "Point", coordinates: [lng, ltd] },
                    distanceField: "distance",
                    maxDistance: maxDistance, // Maximum distance in meters
                    spherical: true,
                    key: "location"
                }
            },
            { $limit: 10 } // Limit results
        ]);
        
        return nearestAutostands;
    } catch (error) {
        console.error('Error finding nearest autostands:', error.message);
        throw error;
    }
}

module.exports = findNearestAutostands;
