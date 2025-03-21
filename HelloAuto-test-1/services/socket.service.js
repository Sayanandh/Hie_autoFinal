const { Server } = require('socket.io');
const Captain = require('../models/captain.model');
const mongoose = require('mongoose');
const userModel = require('../models/user.model');

let io = null;

const initializeSocket = (server) => {
  io = new Server(server);

  // Handle socket connections
  io.on('connection', (socket) => {
    console.log(`A user connected with socketId: ${socket.id}`);

    socket.on('register', async (data) => {
      try {

        if (!mongoose.Types.ObjectId.isValid(data.Id)) {
            console.error('data at socket', data);
            return; // Exit early if the ID is invalid
          } 

          if (data.type === 'captain') {
            const captain = await Captain.findById(data.Id);
            if (captain) {
              captain.socketId = socket.id;
             
    
              if (captain.offlineNotifications.length > 0) {
                captain.offlineNotifications.forEach((notification) => {
                  io.to(socket.id).emit("notifications", notification);
                });
                captain.offlineNotifications = [];
              }
    
              await captain.save();
            }
   
         
          }
          else if (data.type === 'user') {
            const user = await userModel.findById(data.Id);
            if (user) {
              
              user.socketId = socket.id;
             
    
              if (user.offlineNotifications.length > 0) {
                user.offlineNotifications.forEach((notification) => {
                  io.to(socket.id).emit("notifications", notification);
                });
                user.offlineNotifications = [];
              }
    
              await user.save();
            }

          }
        
      } catch (err) {
        console.error(err);
      }
    });

    socket.on('disconnect', async () => {
      try {
        await Captain.findOneAndUpdate({ socketId: socket.id }, { $unset: { socketId: '' } });
        await Captain.findOneAndUpdate({ socketId: socket.id }, {$set: { status: 'inactive' }});

        await userModel.findOneAndUpdate({ socketId: socket.id }, { $unset: { socketId: '' } });
        
      } catch (err) {
        console.error(err);
      }
    });
  });

  return io;
};

const getIOInstance = () => {
  if (!io) {
    throw new Error(
      'Socket.io instance has not been initialized! Please ensure initializeSocket() is called before accessing getIOInstance().'
    );
  }
  return io;
};

module.exports = { initializeSocket, getIOInstance };
