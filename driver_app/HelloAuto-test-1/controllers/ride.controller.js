const axios = require('axios');
const calculatePrice = require('../services/calcPrice.service');
const handleRideRequest = require('../services/ride.service');
const { validationResult } = require('express-validator');
const handleVerification = require('../services/handleVerification.service')
const Ride = require('../models/ride.model');
const getIOInstance = require('../services/socket.service').getIOInstance;
const User = require('../models/user.model');
const Captain = require('../models/captain.model');





module.exports.getRouteDetails = async function(req, res) {
    const { pickup, dropoff } = req.body;
    const mapboxToken = process.env.MAPBOX_API_KEY;

    // Input validation
    if (!pickup || !dropoff) {
        return res.status(400).json({
            success: false,
            message: 'Both pickup and dropoff coordinates are required'
        });
    }

    try {
        // Validate coordinate format
        const coordRegex = /^-?\d+\.?\d*,-?\d+\.?\d*$/;
        if (!coordRegex.test(pickup) || !coordRegex.test(dropoff)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid coordinate format. Use "longitude,latitude"'
            });
        }

        const apiUrl = `https://api.mapbox.com/directions/v5/mapbox/driving/${encodeURIComponent(pickup)};${encodeURIComponent(dropoff)}?geometries=geojson&access_token=${mapboxToken}`;

        const response = await axios.get(apiUrl);

        if (!response.data.routes || response.data.routes.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No route found between the locations'
            });
        }

        const route = response.data.routes[0];
        const distanceKm = (route.distance / 1000).toFixed(2);
        const durationMinutes = (route.duration / 60).toFixed(2);

        const price = calculatePrice(distanceKm);

        // Send response to client
        res.json({
            success: true,
            message: 'Route calculated successfully',
            data: {
                distance: `${distanceKm} km`,
                duration: `${durationMinutes} minutes`,
                price: `${price}`,
                rawData: {
                    distance: route.distance,
                    duration: route.duration
                }
            }
        });

    } catch (error) {
        console.error('Route calculation error:', error);

        // Handle different error types
        let statusCode = 500;
        let errorMessage = 'Failed to calculate route';

        if (error.response) {
            // Mapbox API error response
            statusCode = error.response.status || 500;
            errorMessage = `Mapbox API error: ${error.response.statusText}`;
        } else if (error.request) {
            // No response received
            errorMessage = 'No response received from Mapbox API';
        }

        res.status(statusCode).json({
            success: false,
            message: errorMessage,
            error: error.message
        });
    }
};


module.exports.requestRide = async function(req, res) {

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

   try{

    const { pickup, dropoff, price } = req.body;
    const user = req.user;
    

    if (!pickup || !dropoff || !price) {
        return res.status(400).json({
            success: false,
            message: 'every field are required.'
        });
    }
     
    if (!user || !user._id) {
        return res.status(401).json({
            success: false,
            message: 'Unauthorized'
        });
    }
    const ride = await handleRideRequest(user, pickup, dropoff,price);

    res.status(200).json({ success: true, message: 'Ride requested successfully', data: ride });

   }catch(err){ 
    console.error('Ride request error:', err);
    res.status(500).json({ success: false, message: 'Failed to request ride', error: err.message });



   }


}


module.exports.verifyOTP = async function(req, res) {   
    
    const errors = validationResult(req);
    if (!errors.isEmpty()) {    
        return res.status(400).json({ errors: errors.array() });
    }
    const { rideId, otp , location} = req.body;


    if(!location.ltd || !location.lng){
        return res.status(400).json({
            success: false,
            message: 'Location is required'
        });
    }
   

    const verification = await handleVerification(rideId, otp, location);

    res.status(200).json({ success: true, message: 'OTP verified successfully', data: verification });

}



module.exports.completeRide = async function (req, res) {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    const { rideId, status, location } = req.body;

    if (!location || !location.ltd || !location.lng) {
        return res.status(400).json({ success: false, message: 'Location is required' });
    }

    if (status !== 'completed') {
        return res.status(400).json({ success: false, message: 'Invalid ride status' });
    }

    try {
        const ride = await Ride.findOne({ rideID: rideId });

        if (!ride) {
            return res.status(404).json({ success: false, message: 'Ride not found' });
        }

        const io = await getIOInstance();

        // Fetch user and captain details
        const user = await User.findById(ride.userId);
        const captain = await Captain.findById(ride.captainID);
        if (!user || !captain) {
            return res.status(404).json({ success: false, message: 'User or Captain not found' });
        }

        const userSocketId = user.socketId;
        const captainSocketId = captain.socketId;

        // Get active socket instances
        const userSocket = io.sockets.sockets.get(userSocketId);
        const captainSocket = io.sockets.sockets.get(captainSocketId);

        if (userSocket) {
            userSocket.emit('terminate_location_sharing', { rideId }); // Notify user
            userSocket.removeAllListeners(`ride_location_update`);
        }
    
        if (captainSocket) {
            captainSocket.emit('terminate_location_sharing', { rideId }); // Notify captain
            captainSocket.removeAllListeners(`location_update_captain_${rideId}`);
        }

        // Mark ride as completed
        ride.Status = 'completed';
        ride.EndedAt = { location, time: new Date() };
        await ride.save();

        res.status(200).json({
            success: true,
            message: 'Ride completed successfully',
            data: ride,
        });

    } catch (error) {
        console.error('Error completing ride:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
};



module.exports.getRideHistoryforUser = async function (req, res) {
    const userId = req.user._id;

    try {
    
        const rides = await Ride.find({ userId })
        .sort({ createdAt: -1 }) // Sort by creation date in descending order
        .exec(); 

        


        if (rides.length === 0) {  // Proper check for empty array
            return res.status(200).json({ success: true, message: 'No rides found.' });
        }
        res.status(200).json({ success: true, message: 'User rides fetched successfully', data: rides });

    } catch (error) {
        console.error('Error fetching user rides:', error);
        return res.status(500).json({ success: false, message: 'Failed to fetch user rides' });
    }
};


module.exports.getRideHistoryforCaptain = async function (req, res) {

    const captainID = req.captain._id;

    try {
        
        const rides = await Ride.find({ captainID })
        .sort({ createdAt: -1 }) // Sort by creation date in descending order
        .exec(); 

        if (rides.length === 0) {  // Proper check for empty array
            return res.status(200).json({ success: true, message: 'No rides found.' });
        }
        res.status(200).json({ success: true, message: 'Captain rides fetched successfully', data: rides });

    } catch (error) {
        console.error('Error fetching captain rides:', error);
        return res.status(500).json({ success: false, message: 'Failed to fetch captain rides' });
    }

}
