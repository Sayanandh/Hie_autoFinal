const AutoStand = require('../models/autostand.model');
const Queue = require('../models/queue.model');
const Captain = require('../models/captain.model'); // Import captain model
const haversine = require('haversine-distance');
const { validationResult } = require('express-validator');

exports.toggleDriverQueue = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { autostandId } = req.params;
    const { driverID, toggleStatus, currentLocation } = req.body;

    if (!currentLocation || !currentLocation.lat || !currentLocation.lng) {
      return res.status(400).json({ message: 'Current location is required' });
    }

    const autostand = await AutoStand.findById(autostandId);
    if (!autostand) {
      return res.status(404).json({ message: 'Autostand not found' });
    }

    if (!autostand.members.includes(driverID)) {
      return res.status(400).json({ message: 'Driver is not a member of this AutoStand' });
    }

    const captain = await Captain.findById(driverID);
    if (!captain) {
      return res.status(404).json({ message: 'Driver not found' });
    }

    // Check if ride is already allocated
    if (captain.isRideAllocated) {
      return res.status(400).json({ message: 'Driver is currently allocated a ride and cannot join the queue.' });
    }

    // Get the distance between the driver's current location and the autostand
    const autostandLocation = { lat: autostand.location.ltd, lng: autostand.location.lng };
    const driverLocation = { lat: currentLocation.lat, lng: currentLocation.lng };

    const distance = haversine(driverLocation, autostandLocation); // Distance in meters

    if (distance > 50) {
      // If the driver is part of the queue, remove them
      const queue = await Queue.findById(autostand.queueID);
      if (queue) {
        const index = queue.items.findIndex(item => item.driverId.toString() === driverID);
        if (index !== -1) {
          queue.items.splice(index, 1);
          await queue.save();
        }

        // Update the captain's status to inactive
        captain.status = 'inactive';
        await captain.save();

        return res.status(400).json({
          message: 'Driver is too far away from the AutoStand and has been removed from the queue.',
        });
      }
    }

    const queue = await Queue.findById(autostand.queueID);
    if (!queue) {
      return res.status(400).json({ message: 'No queue has been created for this autostand yet.' });
    }

    // If toggleStatus is true, add driver to queue, else remove from queue
    if (toggleStatus) {
      if (!queue.items.some(item => item.driverId.toString() === driverID)) {
        queue.items.push({ driverId: driverID });
      }

      // Update the captain's status to active
      captain.status = 'active';
    } else {
      const index = queue.items.findIndex(item => item.driverId.toString() === driverID);
      if (index === -1) {
        return res.status(400).json({ message: 'Driver not found in the queue' });
      }
      queue.items.splice(index, 1);

      // Update the captain's status to inactive
      captain.status = 'inactive';
    }

    await captain.save(); // Save the updated status

    const updatedQueue = await queue.save();
    res.status(200).json({ message: 'Queue updated successfully', queue: updatedQueue });
  } catch (error) {
    console.error('Error updating queue:', error);
    res.status(500).json({ message: 'Error updating queue' });
  }
};