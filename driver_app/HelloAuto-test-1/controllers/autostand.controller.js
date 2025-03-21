const { validationResult } = require('express-validator');
const AutoStand = require('../models/autostand.model.js');
const Queue = require('../models/queue.model.js');
const { getIOInstance } = require('../services/socket.service');
const captainModel = require('../models/captain.model');
const sendEmail = require('../services/mail.service');
const calculateDistance = require('../services/distance.service');
const mongoose = require('mongoose');



const autoStandController =  {
  // Create a new AutoStand
  createAutoStand : async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    try {
        const { standname, location } = req.body;

        // Validate and transform location
        if (!location || !location.latitude || !location.longitude) {
            return res.status(400).json({
                message: 'Location with latitude and longitude is required',
            });
        }

        // Transform location to GeoJSON format
        const transformedLocation = {
            type: 'Point',
            coordinates: [location.longitude, location.latitude], // [longitude, latitude]
        };

        const creatorID = req.captain._id; // Assuming `req.captain` is set by middleware

        // Create a new queue for the AutoStand
        const newQueue = new Queue();
        const savedQueue = await newQueue.save();

        // Create a new AutoStand
        const newAutoStand = new AutoStand({
            standname,
            location: transformedLocation, // Use GeoJSON format
            creatorID,
            members: [creatorID], // Include the creator in the members list
            queueID: savedQueue._id,
        });

        const savedAutoStand = await newAutoStand.save();
        if (!savedAutoStand) {
            return res.status(400).json({ message: 'Error creating AutoStand' });
        }

        res.status(201).json({
            message: 'AutoStand created successfully',
            autoStand: savedAutoStand,
        });
    } catch (error) {
        console.error('Error creating AutoStand:', error);
        res.status(500).json({ message: error.message });
    }
},

  // Update an existing AutoStand
  updateAutoStand: async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { id } = req.params; // The ID of the AutoStand to update
      const { standname, location } = req.body;

      const updateFields = {};

      // Add standname to update fields if provided
      if (standname) {
        updateFields.standname = standname;
      }

      // Validate and transform location if provided
      if (location) {
        if (location.latitude && location.longitude) {
          updateFields.location = {
            ltd: location.latitude,
            lng: location.longitude,
          };
        } else {
          return res.status(400).json({
            message: 'Both latitude and longitude are required for location',
          });
        }
      }

      // Update the AutoStand
      const updatedAutoStand = await AutoStand.findByIdAndUpdate(
        id,
        { $set: updateFields }, // Update only the provided fields
        { new: true } // Return the updated document
      );

      if (!updatedAutoStand) {
        return res.status(404).json({ message: 'AutoStand not found' });
      }

      res.status(200).json({
        message: 'AutoStand updated successfully',
        autoStand: updatedAutoStand,
      });
    } catch (error) {
      console.error('Error updating AutoStand:', error);
      res.status(500).json({ message: error.message });
    }
  },

  // Delete an existing AutoStand
  deleteAutoStand: async (req, res) => {
    try {
      const { id } = req.params;

      // Find and delete the AutoStand
      const deletedAutoStand = await AutoStand.findByIdAndDelete(id);

      if (!deletedAutoStand) {
        return res.status(404).json({ message: 'AutoStand not found' });
      }

      // Delete the associated queue
      await Queue.findByIdAndDelete(deletedAutoStand.queueID);

      res.status(200).json({ message: 'AutoStand deleted successfully' });
    } catch (error) {
      console.error('Error deleting AutoStand:', error);
      res.status(500).json({ message: error.message });
    }
  },

    addMemberToAutoStand: async (req, res) => {
      const { standId, joiningCaptainId } = req.body;
      const io = await getIOInstance();
      try {
        const stand = await AutoStand.findById(standId).populate('members');
        const joiningCaptain = await captainModel.findById(joiningCaptainId);
    
        if (!stand) {
          return res.status(404).json({ message: 'AutoStand not found' });
        }
    
        if (!joiningCaptain) {
          return res.status(404).json({ message: 'Joining captain not found' });
        }
    
        // Check if the joining captain is already a member
        if (stand.members.some((member) => member._id.toString() === joiningCaptainId)) {
          return res.status(400).json({ message: 'Captain is already a member of this AutoStand' });
        }
    
        if (joiningCaptain.currentStandId) {
          return res.status(400).json({ message: 'Captain is already a member of another AutoStand' });
        }
    
        // Add the request to the joining captain's pendingRequests
        joiningCaptain.pendingRequests.push({
          requesterId: joiningCaptainId,
          standId: standId,
        });
        await joiningCaptain.save();
    
        // Notify union members sequentially
        const unionMembers = stand.members.filter((member) => member?.IsUnionMember);
        for (const member of unionMembers) {
          let email = member.email;
          sendEmail(email, 'Request to join AutoStand', `${joiningCaptain.fullname?.firstname || ''} ${joiningCaptain.fullname?.lastname || ''} wants to join  ${stand.standname} with vehicle number ${joiningCaptain.vehicle?.plate || 'unknown'}`);
          
          if (member.socketId) {
          
            io.to(member.socketId).emit('request_notification', {
              standId,
              joiningCaptainId,
              message: `${joiningCaptain.fullname?.firstname || ''} ${joiningCaptain.fullname?.lastname || ''} wants to join AutoStand ${stand.standname}, vehicle number is ${joiningCaptain.vehicle?.plate || 'unknown'}`,
            });
          } else if (member.offlineNotifications) {
            console.log('Adding offline notification');
            member.offlineNotifications.push({
              type: 'request_notification',
              standId,
              joiningCaptainId,
              message: `${joiningCaptain.fullname?.firstname || ''} ${joiningCaptain.fullname?.lastname || ''} wants to join AutoStand ${stand.standname}`,
            });
            await member.save(); // Wait for the save to complete before continuing
          }
        }
    
        res.status(200).json({ message: 'Request sent to union members' });
      } catch (error) {
        console.error(error);
        res.status(400).json({ message: 'An error occurred while processing the request' });
      }
    },
    
    

    respondToRequest: async (req, res) => { 

      const io = await getIOInstance();

      const { standId, joiningCaptainId, response } = req.body; // response: 'accept' or 'reject'
      const unionMemberId = req.captain._id; // Assuming authenticated user is the union member
      
      try {
        const stand = await AutoStand.findById(standId);
        const joiningCaptain = await captainModel.findById(joiningCaptainId);
    
        if (!stand) {
          return res.status(404).json({ message: 'AutoStand not found' });
        }
    
        if (!joiningCaptain) {
          return res.status(404).json({ message: 'Joining captain not found' });
        }

        if (stand.members.some((member) => member._id.toString() === joiningCaptainId)) {
          return res.status(400).json({ message: 'Captain is already a member of this AutoStand' });
        }
    
        
        if (joiningCaptain.currentStandId) {
          return res.status(400).json({ message: 'Captain is already a member of another AutoStand' });
        }



        

        // Find the pending request
        const request = joiningCaptain.pendingRequests.find(
          (req) => req.standId.toString() === standId && req.status === 'pending'
        );
    
        if (!request) {
          return res.status(404).json({ message: 'Pending request not found' });
        }
    
        if (response === 'accept') {
          // Add the joining captain to the AutoStand's members
          stand.members.push(joiningCaptainId);
          await stand.save();
          let email = joiningCaptain.email;
          // Update the joining captain's currentStandId
          joiningCaptain.currentStandId = standId;
    
          // Update the request status
          request.status = 'accepted';
          // Notify the joining captain
          sendEmail(email, 'Request accepted', `Your request to join AutoStand ${stand.standname} has been accepted`);
          io.to(joiningCaptain.socketId).emit('request_notification',`Your request to join AutoStand ${stand.standname} has been accepted`);

          console.log('Joining captain socket id:', joiningCaptain.socketId);

          if(joiningCaptain.socketId){
            io.to(joiningCaptain.socketId).emit('response_notification', {
              standId,
              response,
              message: `Your request to join AutoStand ${stand.standname} has been accepted`,
            });
          } else if(joiningCaptain.offlineNotifications) {  
            console.log('Adding offline notification'); 
            let joiningCaptainId = joiningCaptain._id;
            joiningCaptain.offlineNotifications.push({  
              type: 'response_notification',
              message: `Your request to join AutoStand ${stand.standname} has been accepted`,
              standId,
              joiningCaptainId,
              
            });
            await joiningCaptain.save(); // Wait for the save to complete before continuing
          }

          res.status(200).json({ message: 'Request accepted' });
        } else if (response === 'reject') {
          // Update the request status
          request.status = 'rejected';
          // Notify the joining captain
          sendEmail(joiningCaptain.email, 'Request rejected', `Your request to join AutoStand ${stand.standname} has been rejected`);
         

          if(joiningCaptain.socketId){
            io.to(joiningCaptain.socketId).emit('response_notification', {
              standId,    
              response,
              message: `Your request to join AutoStand ${stand.standname} has been rejected`,
            }); 
          } else if(joiningCaptain.offlineNotifications) {
            console.log('Adding offline notification');
            let joiningCaptainId = joiningCaptain._id;
            joiningCaptain.offlineNotifications.push({
              type: 'response_notification',
              message: `Your request to join AutoStand ${stand.standname} has been rejected`,
              standId,
              joiningCaptainId,
            });
            await joiningCaptain.save(); // Wait for the save to complete before continuing
          }
          res.status(200).json({ message: 'Request rejected' });
        }
    
        // Save the updated joining captain
        await joiningCaptain.save();
      } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'An error occurred while responding to the request' });
      }
      



  },
 
  searchAutoStand: async (req, res) => {
    const { name, captainLat, captainLng } = req.body;

    // Validate required parameters
    if (!name || typeof name !== 'string' || name.trim() === '') {
        return res.status(400).json({ message: 'Valid stand name is required.' });
    }

    if (!captainLat || !captainLng) {
        return res.status(400).json({ message: 'Captain location (latitude and longitude) is required.' });
    }

    // Validate captain location (must be valid numbers)
    const captainLatitude = parseFloat(captainLat);
    const captainLongitude = parseFloat(captainLng);

    if (isNaN(captainLatitude) || isNaN(captainLongitude)) {
        return res.status(400).json({ message: 'Valid latitude and longitude values are required.' });
    }

    try {
        // Step 1: Search for auto stands by name (case-insensitive)
        const autostands = await AutoStand.find({
            standname: { $regex: name.trim(), $options: 'i' }, // Case-insensitive match
        });

        if (!autostands.length) {
            return res.status(404).json({ message: 'No auto stands found matching the search criteria.' });
        }

        // Step 2: Filter valid locations and calculate distances
        const sortedAutostands = autostands
            .filter((stand) => stand.location && stand.location.ltd !== undefined && stand.location.lng !== undefined)
            .map((stand) => {
                const distance = calculateDistance(
                    captainLatitude,
                    captainLongitude,
                    stand.location.ltd,
                    stand.location.lng
                );
                return { ...stand._doc, distance }; // Add the distance to the result
            })
            .sort((a, b) => a.distance - b.distance); // Sort by distance

        // Respond with sorted results
        res.status(200).json(sortedAutostands);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'An error occurred while searching for auto stands.' });
    }
},

removeMember: async (req, res) => {
  try {
    const { id } = req.params; 
    const { driverID } = req.body;

    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid AutoStand ID' });
    }

    
    const autoStand = await AutoStand.findById(id);
    if (!autoStand) {
      return res.status(404).json({ message: 'AutoStand not found' });
    }

    
    if (!autoStand.members.includes(driverID)) {
      return res.status(400).json({ message: 'Driver is not a member of this AutoStand' });
    }

    
    autoStand.members = autoStand.members.filter(member => member.toString() !== driverID);
    const updatedAutoStand = await autoStand.save();

    // Remove the driver from the queue associated with the AutoStand
    const queue = await Queue.findById(autoStand.queueID);
    if (queue) {
      try {
        await queue.removeAt(driverID); 
      } catch (error) {
        console.warn(`Driver not found in the queue: ${error.message}`);
      }
    }

    // Update the driver's `currentStandId` field
    const updatedCaptain = await captainModel.findByIdAndUpdate(
      driverID,
      { currentStandId: null }, 
      { new: true } 
    );

    if (!updatedCaptain) {
      return res.status(404).json({ message: 'Driver not found' });
    }

    // Send response
    res.status(200).json({
      message: 'Driver removed from AutoStand and queue successfully',
      autoStand: updatedAutoStand,
      
    });
  } catch (error) {
    console.error('Error removing member from AutoStand:', error);
    res.status(500).json({ message: error.message });
  }
},


  // View members of the Auto Stand

  viewMembers: async (req, res) => {
    try {
      const { id } = req.params;

      if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({ message: 'Invalid AutoStand ID' });
      }

      const autoStand = await AutoStand.findById(id).populate('members');

      if (!autoStand) {
        return res.status(404).json({ message: 'AutoStand not found' });
      }

      const members = autoStand.members.map(member => ({
        driverID: member._id,  
        fullname: `${member.fullname.firstname} ${member.fullname.lastname}`,  
        email: member.email,  
        status: member.status,  
        vehiclePlate: member.vehicle.plate, 
        isUnionMember: member.IsUnionMember  
      }));

      res.status(200).json({
        message: 'AutoStand members retrieved successfully',
        members,
      });

    } catch (error) {
      console.error('Error fetching AutoStand members:', error);
      res.status(500).json({ message: error.message });
    }
  }
  


};

module.exports = autoStandController;
