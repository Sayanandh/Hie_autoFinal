const Ride = require('../models/ride.model');
const User = require('../models/user.model');
const Captain = require('../models/captain.model');
const getIOInstance = require('../services/socket.service').getIOInstance;

const handleVerification = async function(rideId, otp, location) {
    const io = await getIOInstance();

    try {
        const ride = await Ride.findOne({ rideID: rideId, otp: otp });
        if (!ride) {
            throw new Error('Invalid OTP or Ride ID');
        }

        // Fetch user and captain details to get their socket IDs
        const user = await User.findById(ride.userId);
        const captain = await Captain.findById(ride.captainID);
        if (!user || !captain) {
            throw new Error('User or captain not found');
        }

        const userSocketId = user.socketId;
        const captainSocketId = captain.socketId;

        if (!userSocketId || !captainSocketId) {
            throw new Error('User or captain socket ID not found');
        }

        // Update ride status
        ride.Status = 'in_progress';
        ride.startedAt = { location, time: new Date() };
        await ride.save();

        // Terminate previous WebSocket connections
        io.to(userSocketId).emit('terminate_location_sharing', { rideId });
        io.to(captainSocketId).emit('terminate_location_sharing', { rideId });

        // Fetch socket instances
        const userSocket = io.sockets.sockets.get(userSocketId);
        const captainSocket = io.sockets.sockets.get(captainSocketId);

        // Ensure sockets exist before performing operations
        if (userSocket) {
            userSocket.removeAllListeners(`location_update_user_${rideId}`);
        }
        if (captainSocket) {
            captainSocket.removeAllListeners(`location_update_captain_${rideId}`);
        }

        // Set up new WebSocket connections
        if (!captainSocket) {
            throw new Error('Captain socket not found');
        }

        // Attach a named event listener
        function handleLocationUpdate(data) {
            io.to(userSocketId).emit(`ride_location_update`, {
                captainLocation: data.captainLocation,
                destination: ride.dropoff,
                data,
            });
        }

        // Remove any previous listeners before attaching a new one
        captainSocket.off(`location_update_captain_${rideId}`, handleLocationUpdate);
        captainSocket.on(`location_update_captain_${rideId}`, handleLocationUpdate);

        return { message: 'Ride started successfully', ride };
    } catch (err) {
        console.error('Verification error:', err);
        throw new Error('Failed to verify OTP');
    }
};

module.exports = handleVerification;
