const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const AlertModel = require('../models/Alert');
const ContactModel = require('../models/Contact');

let twilioClient = null;
if(process.env.ENABLE_TWILIO === 'true' || process.env.ENABLE_TWILIO === '1'){
  const twilio = require('twilio');
  twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
}

// Create alert
router.post('/', auth, async (req,res) => {
  try{
    const { latitude, longitude, message, contactIds } = req.body;
    let contacts = [];
    if(Array.isArray(contactIds) && contactIds.length){
      contacts = await ContactModel.find({ _id: { $in: contactIds }, user: req.user._id });
    } else {
      contacts = await ContactModel.find({ user: req.user._id });
    }

    const alert = await AlertModel.create({
      user: req.user._id,
      latitude, longitude, message,
      contactsNotified: contacts.map(c=>c._id)
    });

    const locationText = (latitude && longitude) ? `Location: https://maps.google.com/?q=${latitude},${longitude}` : '';
    const text = `EMERGENCY ALERT from ${req.user.name}. ${message || ''} ${locationText}`;

    if(twilioClient){
      for(const c of contacts){
        try{
          await twilioClient.messages.create({
            body: text,
            from: process.env.TWILIO_FROM_NUMBER,
            to: c.phone
          });
        }catch(e){ console.warn('Twilio send failed for', c.phone, e.message); }
      }
    } else {
      console.log('Twilio disabled. Would send to:', contacts.map(c=>c.phone));
    }

    res.json({ alert, notified: contacts.length });
  }catch(err){ console.error(err); res.status(500).json({ error: 'server error' }); }
});

// List alerts
router.get('/', auth, async (req,res) => {
  try{
    const alerts = await AlertModel.find({ user: req.user._id }).populate('contactsNotified').sort({ createdAt: -1 });
    res.json(alerts);
  }catch(err){ console.error(err); res.status(500).json({ error: 'server error' }); }
});

module.exports = router;
