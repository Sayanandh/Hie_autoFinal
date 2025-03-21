const mongoose = require('mongoose');

const autostandSchema = new mongoose.Schema({
    standname: {
        type: String,
        required: true,
        minlength: [3, 'Autostand name must be at least 3 characters long'],
    },
    location: {
        type: {
            type: String,
            enum: ['Point'], // Only 'Point' is allowed
            required: true,
        },
        coordinates: {
            type: [Number], // [longitude, latitude]
            required: true,
        },
    },
    creatorID: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'captain',
        required: true,
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
    members: {
        type: [mongoose.Schema.Types.ObjectId],
        ref: 'captain',
        default: [],
    },
    queueID: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Queue',
    },
});

// Create a 2dsphere index on the `location` field
autostandSchema.index({ location: '2dsphere' });

const autostandModel = mongoose.model('autostand', autostandSchema);

module.exports = autostandModel;