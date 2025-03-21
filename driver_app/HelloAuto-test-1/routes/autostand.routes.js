const express = require('express');
const { body } = require('express-validator');
const router = express.Router();
const autoStandController = require('../controllers/autostand.controller');
const { checkUnionMember,captainAuth } = require('../middlewares/auth.middleware'); 

// Create an AutoStand
router.post(
    '/create',
    checkUnionMember, 
    [
        body('standname')
            .isLength({ min: 3 })
            .withMessage('Stand name must be at least 3 characters long')
            .notEmpty()
            .withMessage('Stand name is required'),
    ],
    autoStandController.createAutoStand
);

// Update an AutoStand
router.put(
    '/update/:id',
    checkUnionMember, 
    [
        body('standname')
            .isLength({ min: 3 })
            .withMessage('Stand name must be at least 3 characters long')
            .optional(), // Allow partial updates
        body('location')
            .notEmpty()
            .withMessage('Location is required')
            .optional(),
    ],
    autoStandController.updateAutoStand
);

// Delete an AutoStand
router.delete(
    '/delete/:id',
    checkUnionMember, 
    autoStandController.deleteAutoStand
);

router.post(
     '/add-member',
     captainAuth,
     autoStandController.addMemberToAutoStand
);

router.post(
    '/respond-to-request',
    checkUnionMember,
    autoStandController.respondToRequest
);

router.post(
    '/search',
    captainAuth,
    autoStandController.searchAutoStand
);

// Delete a member from an Autostand
router.delete(
    '/:id/remove-member',
    checkUnionMember, 
    autoStandController.removeMember
  );


// Get a list of all members in the AutoStand
router.get(
    '/:id/members', 
    captainAuth,
    autoStandController.viewMembers
);
  

module.exports = router;
