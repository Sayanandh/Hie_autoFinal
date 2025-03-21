const mongoose = require('mongoose');

const rideSchema = new mongoose.Schema({
    rideID: {
        type: String,
        unique: true,
        required: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user',
        required: true
    },
    captainID: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'captain'
    },
    startedAt: {
        location: {
            ltd: Number,
            lng: Number
        },
        time: Date
    },
    EndedAt: {
        location: {
            ltd: Number,
            lng: Number
        },
        time: Date
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    Rate: Number,
    Status: {
        type: String,
        enum: ['pending', 'accepted', 'in_progress', 'completed', 'canceled'],
        default: 'pending'
    },
    transactionID: String,
    otp: Number,
    pickup: {
        ltd: Number,
        lng: Number
    },
    dropoff: {
        ltd: Number,
        lng: Number
    }
});

module.exports = mongoose.model('Ride', rideSchema);    