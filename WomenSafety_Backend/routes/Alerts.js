const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const AlertModel = require('../models/Alert');
const ContactModel = require('../models/Contact');

let twilioClient = null;
const enableTwilio = (process.env.ENABLE_TWILIO === 'true' || process.env.ENABLE_TWILIO === '1');

if (enableTwilio) {
  const twilio = require('twilio');
  if (!process.env.TWILIO_ACCOUNT_SID || !process.env.TWILIO_AUTH_TOKEN) {
    console.warn('Twilio enabled but missing SID or TOKEN');
  } else {
    twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
  }
}

// Helper to validate coordinates
function isValidLatLng(lat, lng) {
  const nLat = Number(lat);
  const nLng = Number(lng);
  return !Number.isNaN(nLat) && !Number.isNaN(nLng);
}

// Create alert (WhatsApp version)
router.post('/', auth, async (req, res) => {
  try {
    const { latitude, longitude, message, contactIds } = req.body;

    let contacts = [];
    if (Array.isArray(contactIds) && contactIds.length) {
      contacts = await ContactModel.find({ _id: { $in: contactIds }, user: req.user._id });
    } else {
      contacts = await ContactModel.find({ user: req.user._id });
    }

    if (!contacts.length) {
      return res.status(200).json({ warning: 'No contacts found' });
    }

    const locationText = isValidLatLng(latitude, longitude)
      ? `https://maps.google.com/?q=${latitude},${longitude}`
      : '';
    const text = `🚨 SOS ALERT from ${req.user.name || 'User'}! I need help!\nMy location: ${locationText}`;

    const notifyResults = [];

    if (twilioClient) {
      for (const c of contacts) {
        try {
          const toNumber = `whatsapp:${c.phone}`; // Send via WhatsApp
          const msg = await twilioClient.messages.create({
            body: text,
            from: `whatsapp:${process.env.TWILIO_FROM_NUMBER}`,
            to: toNumber
          });
          notifyResults.push({ phone: c.phone, success: true, sid: msg.sid });
        } catch (err) {
          notifyResults.push({ phone: c.phone, success: false, error: err.message });
          console.warn('WhatsApp send failed for', c.phone, err.message);
        }
      }
    } else {
      console.log('Twilio disabled. Would send to:', contacts.map(c => c.phone));
    }

    const alert = await AlertModel.create({
      user: req.user._id,
      latitude,
      longitude,
      message,
      contactsNotified: contacts.map(c => c._id),
      notifyResults
    });

    res.json({ alert, notified: notifyResults.length, results: notifyResults });
  } catch (err) {
    console.error('Alert create error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/', auth, async (req, res) => {
  try {
    const alerts = await AlertModel.find({ user: req.user._id })
      .populate('contactsNotified')
      .sort({ createdAt: -1 });
    res.json(alerts);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
