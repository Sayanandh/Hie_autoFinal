const mongoose = require('mongoose');

const queueSchema = new mongoose.Schema({
    items: [
        {
            driverId: {
                type: String,
                required: true,
            },
            timestamp: {
                type: Date,
                default: Date.now,
            },
        },
    ],
});

queueSchema.methods.push = async function(driverId) {
    this.items.push({ driverId, timestamp: new Date() });
    await this.save();
};

queueSchema.methods.pop = async function() {
    const item = this.items.shift(); 
    await this.save();
    return item;
};

queueSchema.methods.removeAt = async function(driverId) {
    const index = this.items.findIndex(item => item.driverId === driverId);
    if (index === -1) {
        throw new Error('Driver not found in the queue');
    }
    const removedItem = this.items.splice(index, 1)[0];
    await this.save();
    return removedItem;
};

queueSchema.methods.getQueue = function() {
    return this.items;
};

const Queue = mongoose.model('Queue', queueSchema);
module.exports = Queue;