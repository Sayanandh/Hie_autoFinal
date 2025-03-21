const mongoose = require('mongoose');
const Ride = require('../models/ride.model');
const Captain = require('../models/captain.model');
const Autostand = require('../models/autostand.model');
const  findNearestAutostands  = require('./getNearestAutostands.service');
const  generateOTP  = require('./otp.service');
const getIOInstance = require('../services/socket.service').getIOInstance;




async function handleRideRequest(user, pickup, dropoff, price) {
    const io = await getIOInstance();
    try {
        // Find nearest autostands based on the user's pickup location
        const nearestAutostands = await findNearestAutostands(pickup);

        for (const autostand of nearestAutostands) {
            const queue = await Autostand.findById(autostand._id).populate('members');
            if (!queue || queue.members.length === 0) continue;

            for (const captainId of queue.members) {
                const captain = await Captain.findById(captainId);
                if (!captain || captain.status !== 'active' || !captain.socketId) continue;//MAKE IT ACTIVE 

                // Generate a ride ID and OTP
                const rideId = new mongoose.Types.ObjectId().toString();
                const otp = generateOTP();
                
                // Get the captain's socket instance
                const captainSocket = io.sockets.sockets.get(captain.socketId);
                
                if (!captainSocket) {
                    console.error('Captain socket not found:', captain.socketId);
                    continue;
                }

                // Send ride request to the specific captain
                captainSocket.emit('ride_request', {
                    rideId,
                    user: {
                        id: user._id,
                        name: `${user.fullname.firstname} ${user.fullname.lastname}`,
                    },
                    pickup,
                    dropoff,
                    price,
                });

                // Wait for the captain's response
                const resolved = await waitForResponse(captainSocket, captain._id, rideId);
                
                if (resolved.accepted) {
                    console.log('Ride accepted by captain:', captain._id);

                    // Save the ride details in the database
                    const ride = new Ride({
                        rideID: rideId,
                        userId: user._id,
                        captainID: captain._id,
                        Rate: price,
                        Status: 'accepted',
                        otp,
                        pickup,
                        dropoff,
                    
                    });
                    await ride.save();

                    // Notify the user that the ride has been accepted
                    io.to(user.socketId).emit('ride_accepted', { rideId, captain });
                    io.to(user.socketId).emit('otp_generated', { otp });

                    // Notify the captain to start location sharing
                    captainSocket.emit('start_location_sharing', { rideId, user });

                    // Start real-time location sharing
                    startLocationSharing(io, user.socketId, captain.socketId, rideId);
                    return  rideId, captain ;
                }
            }
        }

        // Notify the user if no captains are available
        io.to(user.socketId).emit('ride_not_found', { message: 'No captains available' });
        return { message: 'No captains available' }; 

    } catch (error) {
        console.error('Error handling ride request:', error);
        io.to(user.socketId).emit('ride_error', { message: 'An error occurred while processing your request' });

    }
}

function waitForResponse(captainSocket, captainId, rideId) {
    console.log('Waiting for response from captain:', captainId);

    return new Promise((resolve) => {
        // Set a 1-minute timeout
        const timeout = setTimeout(() => {
            console.log('Timeout: No response from captain:', captainId);
            captainSocket.off(`ride_response`, responseHandler); // Remove listener
            resolve({ accepted: false }); // Resolve with false if no response within timeout
        }, 60000);

        // Define the response handler
        function responseHandler(data) {
            console.log('Received response from ride_response:', data);
            if ( data.accepted && data.rideId == rideId && data.captainId == captainId) {
                
                clearTimeout(timeout); // Clear the timeout
                captainSocket.off(`ride_response`, responseHandler); // Remove listener
                resolve({ accepted: true }); // Resolve with true if the captain accepted
            }
        }

        // Listen for the captain's response on the captain's socket
        captainSocket.on(`ride_response`, responseHandler);

        // Handle disconnection
        captainSocket.on('disconnect', () => {
            console.log('Captain disconnected:', captainId);
            clearTimeout(timeout); // Clear the timeout
            captainSocket.off(`ride_response`, responseHandler); // Remove listener
            resolve({ accepted: false }); // Resolve with false on disconnection
        });
    });
}

function startLocationSharing(io, userSocketId, captainSocketId, rideId) {
    // Get the user and captain socket instances
    const userSocket = io.sockets.sockets.get(userSocketId);
    const captainSocket = io.sockets.sockets.get(captainSocketId);


    if (!userSocket || !captainSocket) {
        console.error('User or captain socket not found');
        return;
    }

    // Listen for location updates from the user
    userSocket.on(`location_update_user_${rideId}`, (userLocation) => {
        // Forward the user's location to the captain
       
       io.to(captainSocketId).emit(`location_update`, {
            userLocation,
        });
    });

    // Listen for location updates from the captain
    captainSocket.on(`location_update_captain_${rideId}`, (captainLocation) => {
        // Forward the captain's location to the user
       
        io.to(userSocketId).emit(`location_update`, {
            captainLocation,
        }); 
    });
}
module.exports = handleRideRequest;